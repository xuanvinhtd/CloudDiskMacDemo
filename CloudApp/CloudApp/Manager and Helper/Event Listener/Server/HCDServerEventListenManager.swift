//
//  HCDServerEventListenManager.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/29/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation
import PromiseKit

class HCDServerEventListenManager {
    static internal let defaultManager = HCDServerEventListenManager()
    
    lazy var scheduler: Timer = Timer()
    var isRunning = false
    
    deinit {
        HCDNotificationHelper.removeObserverFromTarget(target: self)
    }
}

extension HCDServerEventListenManager {
    func startListen() {
        scheduler.invalidate()
        DispatchQueue.main.async {
            self.scheduler = Timer.scheduledTimer(
                timeInterval: HCDGlobalDefine.API.WorkList.scheduleTime,
                target: self,
                selector: #selector(self.shouldRequestWorkList),
                userInfo: nil,
                repeats: true
            )
        }
        HCDNotificationHelper.addObserver(notif: .shouldRequestServerEvent, target: self, selector: #selector(requestWorkList))
    }
    
    func stopListen() {
        scheduler.invalidate()
    }
    
    @objc func shouldRequestWorkList() {
        HCDNotificationHelper.post(notificaion: .shouldRequestServerEvent)
    }
    
    @objc private func requestWorkList() {
        promiseRequestWorkList().catch {
            HCDPrint.error($0)
        }
    }
    
    static func promiseRequestWorkList() -> Promise<()> {
        return defaultManager.promiseRequestWorkList()
    }
    
    func promiseRequestWorkList() -> Promise<()> {
        let promiseGetLastEventID: () -> Promise<(String)> = {
            if let lastEventID = HCDUserDefaults.serverEventLogID {
                return Promise(value: lastEventID)
            } else {
                return firstly {
                    HCDNetworkManager.promiseRequestPostMethod(router: HCDPostRouter.lastExecutedServerEventID)
                    }.then {
                        if let lastEventID = HCDNetworkDataConverter.Response.WorkList.lastEventIdFromData($0) {
                            HCDUserDefaults.serverEventLogID = lastEventID
                            return Promise(value: lastEventID)
                        } else {
                            return Promise(error: HCDError.cannotConvertResponseData)
                        }
                }
            }
        }
        
        let promiseAnalyzeEvent: (Data) -> Promise<()> = {
            let rawEvents = HCDNetworkDataConverter.Response.WorkList.eventListFromData($0)
            if !rawEvents.isEmpty {
                rawEvents.forEach {
                    HCDFileListManager.updateServerFileList(afterAddServerRawEvent: $0)
                }
                let events = rawEvents.map {
                    return HCDServerEvent(fromRawEvent: $0)
                }
                //warning: need handle when can't store data, in this case it will cause losing event if events can be stored
                HCDEventTakingManager.take(events: events)
                
                if let lastID = HCDNetworkDataConverter.Response.WorkList.workListIDFromData($0) {
                    HCDUserDefaults.serverEventLogID = lastID
                } else {
                    return Promise(error: HCDError.cannotConvertResponseData)
                }
            }
            return Promise(value: ())
        }
        
        guard !isRunning else {
            return Promise(value: ())
        }
        isRunning = true
        return firstly {
            promiseGetLastEventID()
        }.then {
            HCDNetworkManager.promiseRequestPostMethod(router: HCDPostRouter.workList($0))
        }.then {
            promiseAnalyzeEvent($0)
        }.always {
            self.isRunning = false
        }
    }
}

extension HCDServerEventListenManager: HCDFolderListener {
    static func startListenRootFolder() {
        HCDPrint.info("start listen server event")
        defaultManager.startListen()
    }
    static func stopListenRootFolder() {
        HCDPrint.info("stop listen server event")
        defaultManager.stopListen()
    }
}
