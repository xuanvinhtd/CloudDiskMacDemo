//
//  HCDSyncState.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 10/24/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.

class HCDSyncState {
    enum TaskStatus {
        case pending
        case running
        case completed
    }
    
    lazy var tasks = [HCDSyncTask: TaskStatus]() // only running and completed available
    
    internal let checkingQueue = HCDUtilityHelper.getConcurrentDispathQueue(withName: "checking_queue_for_sync_state")
}

extension HCDSyncState {
    
//    func debugCurrentState(header: String) {
//        let status = tasks.reduce(header) {
//            return $0 + "\n" + "\($1.key)" + ":" + "\($1.value)"
//        }
//        HCDNotificationHelper.debug(message: status)
//    }
    
    func getStatus(forTask task: HCDSyncTask) -> TaskStatus {
        var result = TaskStatus.pending
        checkingQueue.sync(flags: [.barrier]) {
            if let status = tasks[task] {
                result = status
            } else {
                tasks[task] = .running
            }
        }
//        debugCurrentState(header: "Get status:")
        return result
    }
    
    func didFinishTask(_ task: HCDSyncTask) {
        HCDPrint.info("_Finish task \(task)")
        checkingQueue.async(flags: [.barrier]) {
            self.tasks[task] = .completed
        }
//        debugCurrentState(header: "Did finish:")
    }
    
    func removeAllRunning() {
        checkingQueue.async(flags: [.barrier]) {
            for (key,value) in self.tasks {
                if value == .running {
                    self.tasks[key] = nil
                }
            }
        }
//        debugCurrentState(header: "Remove all running:")
    }
    
    var didFinishAllTasks: Bool {
        var result = false
        checkingQueue.sync {
            result = self.tasks[.completed] == .completed
        }
        return result
    }
}

extension HCDSyncState {
    func resetState() {
        HCDPrint.info("+Did reset state")
        checkingQueue.async(flags: .barrier) {
            self.tasks = [:]
        }
    }
}
