//
//  HCDSyncManager.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 12/7/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import PromiseKit
import Foundation

class HCDSyncManager {
    static private let defaultManager = HCDSyncManager()
    
    static func prepareWhenHasKeyChain() {
        HCDLocalEventListenManager.startListenRootFolder()
    }
    
    static func autoLoginThenStart() {
        firstly {
            HCDLoginManager.promiseAutoLogin()
        }.then {
            self.start()
        }.catch {
            HCDPrint.error($0)
        }
        
    }
    
    static func start() {
        defaultManager.run()
    }
    
    static func reset() {
        defaultManager.syncState.resetState()
    }
    
//    private let syncQueue = HCDUtilityHelper.getConcurrentDispathQueue(withName: "com.hanbiro.cloudapp.sync_manager_queue")
    private let syncQueue = DispatchQueue(label: "com.hanbiro.cloudapp.sync_manager_queue")
    private var syncState = HCDSyncState()
    lazy var scheduler: Timer = Timer()
    lazy var resetScheduler: Timer = Timer()
    var isRunning = false
    
    @objc func startNewSyncSeason() {
        syncState.resetState()
        run()
    }
    
    @objc func startTimerForBackgroundSync() {
        resetScheduler.invalidate()
        DispatchQueue.main.async {
            self.resetScheduler = Timer.scheduledTimer(
                timeInterval: HCDGlobalDefine.scheduleTimeForStartNewSyncSeason,
                target: self,
                selector: #selector(self.startNewSyncSeason),
                userInfo: nil,
                repeats: false
            )
        }
    }
    
    @objc func stopTimerForBackgroundSync() {
        resetScheduler.invalidate()
    }

    @objc func run() {
        func setupSync() {
            HCDNotificationHelper.addObserver(
                notif: .didCompleteAllEvent,
                target: self,
                selector: #selector(run)
            )
            
            HCDNetworkStatusInformationManager.subscribeWhenReachableWithName(name: .forSyncManager) { self.run()}
            
            self.scheduler.invalidate()
            self.resetScheduler.invalidate()

            DispatchQueue.main.async {
                self.scheduler = Timer.scheduledTimer(
                    timeInterval: HCDGlobalDefine.scheduleTimeForSyncManager,
                    target: self,
                    selector: #selector(self.run),
                    userInfo: nil,
                    repeats: true
                )
            }
            
            if HCDUserDefaults.didCompleteFirstTimeSync == false {
                HCDNotificationHelper.post(notificaion: .appIsRunning)
            }

            HCDEventExecutingManager.stop()
        }
        
        func completeSync() {
            HCDNetworkStatusInformationManager.unsubscribeForName(name: .forSyncManager)
            HCDNotificationHelper.removeObserverFromTarget(target: self)
            scheduler.invalidate()
            startTimerForBackgroundSync()
            
            HCDNotificationHelper.addObserver(
                notif: .didTakeSomeEvents,
                target: self,
                selector: #selector(stopTimerForBackgroundSync)
            )
            
            HCDNotificationHelper.addObserver(
                notif: .didCompleteAllEvent,
                target: self,
                selector: #selector(startTimerForBackgroundSync)
            )
            
            HCDUserDefaults.didCompleteFirstTimeSync = true
            HCDNotificationHelper.post(notificaion: .didCompleteAllEvent)
        }
        
        func promise(forTask task: HCDSyncTask) -> Promise<()> {
            switch task {
            case .setup:
                return HCDUserDefaults.syncFolderPath == nil ?
                    Promise(error: HCDError.noSelectedSyncFolder) : Promise(value: setupSync())
            case .readLocalList:
                return HCDFileListManager.getNewFileBook(fromLocal: true)
//            case .updateLocalList:
//                return HCDFileListManager.updateFileBook(fromLocal: true)
            case .getServerEvent:
                return HCDServerEventListenManager.promiseRequestWorkList()
            case .startListenServer:
                return Promise(value: HCDServerEventListenManager.startListenRootFolder())
            case .enableExecuteEvent:
                return Promise(value: HCDEventExecutingManager.start())
            case .requestServerList:
                return HCDFileListManager.getNewFileBook(fromLocal: false)
//            case .updateServerList:
//                return HCDFileListManager.updateFileBook(fromLocal: false)
            case .createEventByComparingFileBook:
                return HCDFileListComparator.createEventByComparingFileLists()
            case .completed:
                return Promise(value: completeSync())
            }
        }
        
        func executeTask(_ task: HCDSyncTask) -> Promise<()> {
            return Promise {fullfill, reject in
                let state = self.syncState.getStatus(forTask: task)
                switch state {
                case .pending:
                    promise(forTask: task).then{
                        self.syncState.didFinishTask(task)
                        }.then {
                            fullfill()
                        }.catch {
                            reject($0)
                    }
                case .running:
                    reject(HCDError.isRunningSameTask)
                case .completed:
                    fullfill()
                }
            }
        }
        
        func localSidePromise() -> Promise<()> {
            return firstly {
               executeTask(.setup)
            }.then {
                executeTask(.readLocalList)
//            }.then {
//                executeTask(.updateLocalList)
            }
        }
        
        func serverSidePromise() -> Promise<()> {
            return executeTask(.getServerEvent).then {
                executeTask(.startListenServer)
            }
        }
        
        guard !isRunning && !syncState.didFinishAllTasks else {
            return
        }
        
        isRunning = true
    HCDPrint.info("---------------START RUN()---------------")
        when(fulfilled: [localSidePromise(), serverSidePromise()])
        .then(on: syncQueue) {
            executeTask(.enableExecuteEvent)
        }.then {
            executeTask(.requestServerList)
//        }.then {
//            executeTask(.updateServerList)
        }.then {
            executeTask(.createEventByComparingFileBook)
        }.then(on: DispatchQueue.main) {
            executeTask(.completed)
        }.always(on: DispatchQueue.main) {
            self.isRunning = false
            HCDPrint.info("---------------END RUN()---------------")
        }.catch {
            self.syncState.removeAllRunning()
            HCDPrint.error($0)
            HCDPrint.info("---------------END RUN() AND ERROR---------------")
        }
            
    }
}
