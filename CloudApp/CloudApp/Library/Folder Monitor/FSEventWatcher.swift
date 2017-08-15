//
//  HCDFileSystemWatcher.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 9/16/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation

class FSEventWatcher {
    
    // MARK: - Initialization / Deinitialization
    
    init(pathsToWatch: [String], sinceWhen: FSEventStreamEventId) {
        self.lastEventId = sinceWhen
        self.pathsToWatch = pathsToWatch
    }
    
    convenience init(pathsToWatch: [String]) {
        self.init(pathsToWatch: pathsToWatch, sinceWhen: FSEventStreamEventId(kFSEventStreamEventIdSinceNow))
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Private Properties
    
    private let eventCallback: FSEventStreamCallback = { (
        stream: ConstFSEventStreamRef,
        contextInfo: UnsafeMutableRawPointer?,
        numEvents: Int,
        eventPaths: UnsafeMutableRawPointer,
        eventFlags: UnsafePointer<FSEventStreamEventFlags>?,
        eventIds: UnsafePointer<FSEventStreamEventId>?) -> ()
        in
        
        let fileSystemWatcher: FSEventWatcher = unsafeBitCast(contextInfo, to: FSEventWatcher.self)
        
        let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]
        
        if let eventIds = eventIds {
            fileSystemWatcher.processEvents(numEvents: numEvents, eventFlags: eventFlags, eventIds: eventIds, paths: paths)
            fileSystemWatcher.lastEventId = eventIds[numEvents - 1]
        }
    }
    private let pathsToWatch: [String]
    private var started = false
    private var streamRef: FSEventStreamRef!
    
    // MARK: - Private Methods
    
    func processEvents(numEvents: Int,
                       eventFlags: UnsafePointer<FSEventStreamEventFlags>?,
                       eventIds: UnsafePointer<FSEventStreamEventId>,
                       paths:[String]) {
        guard let eventFlags = eventFlags else { return }
        for index in 0..<numEvents {
            processEvent(eventId: eventIds[index], eventPath: paths[index], eventFlags: eventFlags[index])
        }
    }
    
    func processEvent(eventId: FSEventStreamEventId, eventPath: String, eventFlags: FSEventStreamEventFlags) {
        print("\t\(eventId) - \(eventFlags) - \(eventPath)")
    }
    
    // MARK: - Pubic Properties
    
    private(set) var lastEventId: FSEventStreamEventId
    
    // MARK: - Pubic Methods
    
    func start() {
        guard started == false else { return }
        
        var context = FSEventStreamContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutableRawPointer(mutating: Unmanaged.passUnretained(self).toOpaque())
        let flags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes |
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagIgnoreSelf |
            kFSEventStreamCreateFlagMarkSelf   |
            kFSEventStreamCreateFlagWatchRoot)
        
        if let streamReference = FSEventStreamCreate(kCFAllocatorDefault, eventCallback, &context, pathsToWatch as CFArray, lastEventId, 0, flags) {
            streamRef = streamReference
            FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(streamRef)
            
            started = true
        }
    }
    
    func stop() {
        guard started == true else { return }
        
        FSEventStreamStop(streamRef)
        FSEventStreamInvalidate(streamRef)
        FSEventStreamRelease(streamRef)
        streamRef = nil
        
        started = false
    }
    
}
