//
//  HCDSyncState.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 10/24/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation

enum HCDSyncTask: Int {
    case setup//
//    case disableExecuteEvent
//    case setupFileList
    case readLocalList
//    case createLocalEventsByCompareOldAndNewLocalList
//    case updateLocalList
    case getServerEvent
    case startListenServer
    case enableExecuteEvent
    case requestServerList
//    case updateServerList
    case createEventByComparingFileBook
    case completed
    
//    static let taskHasProcess: Set<HCDSyncTask> = [
//        getServerEvent,
//        setupFileList,
//        readLocalList,
//        createLocalEventsByCompareOldAndNewLocalList,
//        updateLocalList,
//        requestServerList,
//        updateServerList,
//    ]
    
//    static let taskNeedToWaitUntilFinishAllEvents: Set<HCDSyncTask> = [
//        getServerEvent,
//        updateLocalList,
//        requestServerList
//    ]
//    
//    var hasProcess: Bool {
//        return HCDSyncTask.taskHasProcess.contains(self)
//    }
    
//    var taskNeedToBeCompletedBefore: [HCDSyncTask]? {
//        switch self {
//        case        .completed:
//            return [.compareLocalandServerListToCreateEventsThenExecuteThem]
//        case        .compareLocalandServerListToCreateEventsThenExecuteThem:
//            return [.updateServerList]
//        case        .updateServerList:
//            return [.requestServerList]
//        case        .requestServerList:
//            return [.startListenServer]
//        case        .startListenServer:
//            return [.enableExecuteEvent]
//        case        .enableExecuteEvent:
//            return [.updateLocalList, .getServerEvent]
//        case        .updateLocalList:
//            return [.createLocalEventsByCompareOldAndNewLocalList]
//        case        .createLocalEventsByCompareOldAndNewLocalList:
//            return [.readLocalList]
//        case        .readLocalList:
//            return [.setupFileList]
//        case        .setupFileList:
//            return  nil
//        case        .disableExecuteEvent:
//            return  nil
//        case        .getServerEvent:
//            return  nil
//        }
//        
//    }
//    
//    static let allTasksByPriority: [HCDSyncTask] = {
//        var tasks = [HCDSyncTask]()
//        var i = 0
//        
//        while let task = HCDSyncTask(rawValue: i) {
//            tasks.append(task)
//            i += 1
//        }
//        
//        return tasks
//    }()
}
