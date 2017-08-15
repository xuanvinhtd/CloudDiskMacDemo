//
//  HCDFileSystemWatcher.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 9/16/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation

protocol HCDPDirectoryMonitorDelegate: class {
    func directoryMonitorDidObserveChangeWithEvents(events: [HCDLocalRawEvent])
}

class HCDLocalFolderWatcher: FSEventWatcher {
    weak var delegate: HCDPDirectoryMonitorDelegate?
    
    override func processEvents(numEvents: Int, eventFlags: UnsafePointer<FSEventStreamEventFlags>?, eventIds: UnsafePointer<FSEventStreamEventId>, paths: [String]) {
        guard let eventFlags = eventFlags else { return }
        var events = [HCDLocalRawEvent]()
        for index in 0..<numEvents {
            let event: HCDLocalRawEvent? = getEvent(eventId: eventIds[index], eventPath: paths[index], eventFlags: eventFlags[index])
            if event != nil {
                events.append(event!)
            }
        }
        self.delegate?.directoryMonitorDidObserveChangeWithEvents(events: events)
    }
    
    func getEvent(eventId: FSEventStreamEventId, eventPath: String, eventFlags: FSEventStreamEventFlags) -> HCDLocalRawEvent? {
        let event = HCDLocalRawEvent(path: eventPath, flagInt: eventFlags, ID: eventId)
        
        guard event.name != HCDGlobalDefine.FileName.magicKeyWordToOpenDebugTools else {
            HCDFileManager.removeIfFileExistedAtFullPath(fileDirectory: event.path)
            HCDLog.debugTools(enable: true)
            HCDNotificationHelper.post(notificaion: .shouldShowDebugToolChanged)
            return nil
        }

        return event.shouldBeSkipped ? nil : event
    }    
}
