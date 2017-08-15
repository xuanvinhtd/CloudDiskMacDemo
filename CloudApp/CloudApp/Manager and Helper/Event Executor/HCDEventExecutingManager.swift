//
//  HCDEventExecutingManager.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/30/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation
import PromiseKit

class HCDEventExecutingManager {
    static internal let defaultManager = HCDEventExecutingManager()

    let statusQueue = HCDUtilityHelper.getConcurrentDispathQueue(withName: "executing_queue_for_checking_status")
    lazy var executingOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = HCDGlobalDefine.ParameterAndLimit.limitOfSameOperationCanRunAtTheSameTime
        queue.name = "operation_queue_for_executing_event"
        return queue
    }()
    
    var isReTry: Bool = false
    
    private var _isActive: Bool = false
    internal var isActive: Bool {
        set {
            HCDPrint.debug("[Event Executor] is Active = \(newValue)")
            _isActive = newValue
        }
        get {
            return _isActive && !HCDUserDefaults.userWantToPauseSync
        }
    }
    
    lazy var scheduler: Timer = Timer()
}

extension HCDEventExecutingManager {
    
    static func start() {
        HCDPrint.info("Start executing event")
        defaultManager.activeSync()
    }
    static func stop() {
        HCDPrint.info("Stop executing event")
        defaultManager.inactiveSync()
    }
    
    @objc func shouldRun(notif: Notification) {
        switch notif.name.rawValue {
        case HCDNotificationHelper.Notification.didTakeSomeEvents.rawValue:
            HCDNotificationHelper.removeObserverFromTarget(target: self, withNotif: .didTakeSomeEvents)
        case HCDNotificationHelper.Notification.retryTakeSomeEvents.rawValue:
            HCDNotificationHelper.removeObserverFromTarget(target: self, withNotif: .retryTakeSomeEvents)
            self.isReTry = true
        case HCDNotificationHelper.Notification.didActiveSync.rawValue:
            HCDNotificationHelper.removeObserverFromTarget(target: self, withNotif: .didActiveSync)
        default:
            break
        }
        run()
    }
    
    @objc func didCompleteAll() {
        HCDNotificationHelper.removeObserverFromTarget(target: self, withNotif: .didTakeSomeEvents)
        HCDNotificationHelper.addObserver(notif: .didTakeSomeEvents,   target: self, selector: #selector(self.shouldRun))
        HCDNotificationHelper.addObserver(notif: .retryTakeSomeEvents,   target: self, selector: #selector(self.shouldRun))
        if self.isReTry {
            self.isReTry = false
            HCDNotificationHelper.post(notificaion: .retryTakeCompleteSomeEvents)
        }
    }
    
    @objc func scheduleRun() {
        HCDPrint.debug("[Executing Manager][\(HCDGlobalDefine.scheduleTimeForEventExecutor) seconds schedule] Check if there're any event need to be execute")
        run()
    }
    
    func activeSync() {
        statusQueue.async(flags: .barrier) { [unowned self] in
            self.isActive = true
            HCDNotificationHelper.addObserver(notif: .didTakeSomeEvents,        target: self, selector: #selector(self.shouldRun))
            HCDNotificationHelper.addObserver(notif: .retryTakeSomeEvents,        target: self, selector: #selector(self.shouldRun))
            HCDNotificationHelper.addObserver(notif: .oldEventWasExecuted,      target: self, selector: #selector(self.shouldRun))
            HCDNotificationHelper.addObserver(notif: .didActiveSync,            target: self, selector: #selector(self.shouldRun))
            HCDNotificationHelper.addObserver(notif: .userDidChangeSyncStatus,  target: self, selector: #selector(self.shouldRun))
            HCDNotificationHelper.addObserver(notif: .didCompleteAllEvent, target: self, selector: #selector(self.didCompleteAll))
            HCDNotificationHelper.post(notificaion: .didActiveSync)
            
            HCDNetworkStatusInformationManager
                .subscribeWhenReachableWithName(name: .forEventExecutor) {
                    HCDEventTakingManager.clearError(.lostConnection)
                    HCDNotificationHelper.post(notificaion: .oldEventWasExecuted)
                }
            
            self.scheduler.invalidate()
            DispatchQueue.main.async {
                self.scheduler = Timer.scheduledTimer(
                    timeInterval: HCDGlobalDefine.scheduleTimeForEventExecutor,
                    target: self,
                    selector: #selector(self.scheduleRun),
                    userInfo: nil,
                    repeats: true
                )
            }
        }
    }
    
    func inactiveSync() {
        statusQueue.async(flags: .barrier) {
            self.isActive = false
        }
        HCDNotificationHelper.removeObserverFromTarget(target: self)
        HCDNetworkStatusInformationManager.unsubscribeForName(name: .forEventExecutor)
        self.scheduler.invalidate()
    }
}

extension HCDEventExecutingManager {
    var shouldRunWithEvents: [HCDPEvent] {
        var events: [HCDPEvent] = []
        statusQueue.sync {
            if self.isActive {
                events = HCDEventTakingManager.getNextPendingEvents()
            }
        }
        return events
    }
    
    func commit(event: HCDPEvent, error: Error?) {
        if error == nil {
            HCDFileListManager.updateFileList(afterExecuteLocalEvent: event)
        }
        HCDEventTakingManager.commit(event: event, error: error)
    }
    
    func run() {
        let events = self.shouldRunWithEvents
        guard !events.isEmpty else {
            return
        }
        HCDNotificationHelper.post(notificaion: .appIsRunning)
        HCDNotificationHelper.showAtMenuItem(message: "files need to sync:".localized + "\(HCDEventTakingManager.remainEvent)")

        for event in events {
            executingOperationQueue.addOperation {
                HCDPrint.verbose("execute event \(event.identified)")
                self.promiseExecute(event: event).then {
                    self.commit(event: event, error: nil)
                    }.catch {
                        self.commit(event: event, error: $0)
                        HCDPrint.error($0)
                }
            }
        }
    }
}

extension HCDEventExecutingManager {
    func promiseExecute(event: HCDPEvent) -> Promise<()> {
        
        if let event = event as? HCDPLocalEvent {
            if event.eventType == .create {
                return promiseEventCreateFromLocal(withEvent: event)
            } else {
                return promiseOtherEventFromLocal(withEvent: event)
            }
        } else if let event = event as? HCDPServerEvent {
            switch event.serverEventType {
            case .add :
                if event.isDir {
                    return Promise(value:
                            HCDFileManager.createDirectory(withPath: event.path))
                } else {
                    if let key = HCDFileListManager.keyForPath(path: event.path) {
                        return HCDNetworkManager.promiseTransferData(router:
                            HCDTransferDataRouter(localDestination: event.path, action: .download, key: key))
                    } else {
                        let error = HCDError.noKeyToTransfer
                        HCDPrint.error(error)
                        return Promise(error: error)
                    }
                }
            case .move :
                return Promise(value:
                    HCDFileManager.moveFromPath(oldPath: event.path, toPath: event.newPath, shouldOverride: true))
            case .rename:
                return Promise(value:
                    HCDFileManager.renameAtPath(path: event.path, withNewName: event.newPath.lastPathComponent))
            case .remove:
                return firstly {
                    return isError(with: event)
                    }.then {
                        if $0 {
                            HCDPrint.event("Cannot delete with path: \(event.path) because this path have in uploaded fail list.")
                            return Promise(value: ())
                        } else {
                            return Promise(value:
                                HCDFileManager.moveFileToTrash(path: event.path))
                        }
                }
            }
        } else {
            return Promise(error: HCDError.other)
        }
    }
    
    func isError(with event: HCDPServerEvent) -> Promise<Bool> {
        if HCDEventDataManager.defaultManager().errorEvents(byPath:
                                                event.isDir ? event.path + "/" : event.path).count == 0 {
            return Promise(value: false)
        }
        return Promise(value: true)
    }
}

//MARK: Local executing
extension HCDEventExecutingManager {
    func promiseEventCreateFromLocal(withEvent event: HCDPLocalEvent) -> Promise<()> {
        guard FileManager.default.fileExists(atPath: HCDPathHelper.fullPathForPath(path: event.path)) else {
            return Promise(error: HCDError.noFileToUpload)
        }
        
        return firstly {
            HCDNetworkManager.promiseRequestPostMethod(router: HCDPostRouter.put(event.path))
            }.then {
                let result = HCDNetworkDataConverter.Response.syncAction.putResult(data: $0, isDir: event.isDir)
                guard let parentKey = result.1, !parentKey.isEmpty else {
                    return Promise(error: HCDError.putRequestGetEmptyParentKeyForResponse)
                }
                guard let key = result.0, !key.isEmpty else {
                return Promise(error: HCDError.putRequestGetEmptyKeyForResponse)
                }
                
                if let rs = result.2, let er = HCDError.getInfoPut(rs) {
                    return Promise(error: er)
                }
                
            HCDFileListManager.put(key: key, forPath: event.path)
            if event.isDir {
                return Promise(value: ())
            } else {
                return HCDNetworkManager.promiseTransferData(router: HCDTransferDataRouter(localDestination: event.path, action: .upload, key: key))
            }
        }
    }
    
    func promiseOtherEventFromLocal(withEvent event: HCDPLocalEvent) -> Promise<()> {
        var routerForRequest: HCDPostRouter?
        switch event.eventType {
        case .remove:
            routerForRequest = .delete(event.path)
        case .change:
            routerForRequest = event.localEventType == .rename ?
                .rename(event.path, event.newPath) :
                .move(event.path, event.newPath)
        default:
            break
        }
        
        guard let router = routerForRequest else {
            return Promise(error: HCDError.tryToConvertSyncActionFromRequestThatNotSyncAction)
        }
        
        return firstly {
            HCDNetworkManager.promiseRequestPostMethod(router: router)
        }.then {
            router.translateSyncActionResponse(data: $0)
        }.then {
            return $0 == nil ? Promise(value: ()) : Promise(error: $0!)
        }

    }
    
}
