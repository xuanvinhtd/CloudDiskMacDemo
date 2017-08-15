//
//  HCDLocalEventListenManager.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/23/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation

protocol HCDFolderListener {
    static func startListenRootFolder()
    static func stopListenRootFolder()
}

protocol HCDPLocalEventAnalyzer {
    func getLocalEvent(byAnalyzeRawEvents rawEvents: [HCDLocalRawEvent]) -> [HCDPLocalEvent]
}

protocol HCDPEventCollector {
    func collectEvents(_ events: [HCDPEvent])
}

class HCDLocalEventListenManager{
    static internal let defaultManager = HCDLocalEventListenManager()
    
    lazy var fileSystemWatcher: HCDLocalFolderWatcher = {
        let rootPath = HCDPathHelper.defaultSyncRootPath
        let paths = [rootPath]
        let watcher = HCDLocalFolderWatcher(pathsToWatch: paths)
        watcher.delegate = self
        return watcher
    }()
    
    lazy var eventAnalyzeQueue: OperationQueue = HCDUtilityHelper.getSerialOperationQueue(withName: "com.hambiro.autosyncclouddisk.locallistener.handlelisteneroperationqueue")
}

extension HCDLocalEventListenManager: HCDFolderListener {
    static func startListenRootFolder() {
        HCDPrint.info("Start listen event from local sync folder")
        defaultManager.fileSystemWatcher.start()
    }
    
    static func stopListenRootFolder() {
        defaultManager.fileSystemWatcher.stop()
        HCDPrint.info("Stop listen event from local sync folder")
    }
}

extension HCDLocalEventListenManager: HCDPDirectoryMonitorDelegate {
    func directoryMonitorDidObserveChangeWithEvents(events: [HCDLocalRawEvent]) {
        if !events.isEmpty {
            HCDPrint.event("Occur Events")
            eventAnalyzeQueue.addOperation {
                let analyzer = HCDEventAnalyzer()
                let localEvents = analyzer.getLocalEvent(byAnalyzeRawEvents: events) as! [HCDLocalEvent]
                HCDEventTakingManager.take(events: localEvents)
            }
        }
    }
}

extension HCDLocalEventListenManager {
    
}
