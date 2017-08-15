//
//  HCDEventAnalyzer.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/25/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation

struct HCDEventAnalyzer: HCDPLocalEventAnalyzer {
    func getLocalEvent(byAnalyzeRawEvents rawEvents: [HCDLocalRawEvent]) -> [HCDPLocalEvent] {
        var shouldSkip: Bool = false
        var localEvents: [HCDPLocalEvent] = [HCDLocalEvent]()
        for (index,rawEvent) in rawEvents.enumerated() {
            
            HCDPrint.event(rawEvent.description())
            
            guard !shouldSkip else {
                shouldSkip = false
                continue
            }
            
            let nextEvent: HCDLocalRawEvent? = index + 1 < rawEvents.count ? rawEvents[index + 1] : nil
            let fileAttribute = HCDFileManager.fileAttributesAtFullPath(fullPath: rawEvent.path)
//            HCDPrint.event(fileAttribute ?? [:])

            let info: HCDPDetailForRawEvent = HCDDetailForRawEvent(
                thisEvent: rawEvent,
                nextEvent: nextEvent,
                fileListInfoGetter: HCDFileListManager.localFileBook,
                thisAttribute: fileAttribute)
            
            //debug
//            if info.thisItemIsRenamed &&
//                (info.thisEvent.path == "/Users/hanbiroinc/NewCloudFolder/việt 한국어 *[].as"
//                    || info.thisEvent.path == "/Users/hanbiroinc/NewCloudFolder/weird/việt 한국어 *[].as") {
//                print("gotcha")
//            }
            //end
            
            guard let localEvent = HCDEventAnalyzeHelper.getLocalEvent(fromDetail: info) else {
                continue
            }
            
            var fileListUpdater: HCDPLocalFileListUpdaterByEvent = HCDLocalFileListUpdaterByEvent(
                event: localEvent,
                fileAttribute: info.thisAttribute)
            
            fileListUpdater.updateLocalFileList()
            fileListUpdater.additionalChildrenItems?.forEach {
                localEvents.append(HCDLocalEvent(eventCreateFromItem: $0))
            }
            
            localEvent.splitIfNeeded.forEach {
                localEvents.append($0)
            }
            
            if !localEvent.newPath.isEmpty {
                shouldSkip = true
            }
        }
        
        return localEvents
    }
}

protocol HCDPFileListUpdaterByLocalEvent {
    func add(path: String, fileAttribute: [FileAttributeKey: Any])
    func addChildren(path: String) -> [HCDItem]
    func remove(path: String, includeChildren: Bool)
    func move(fromPath: String, toPath: String, isDir: Bool)
}

protocol HCDPLocalFileListUpdaterByEvent {
    var event: HCDLocalEvent {get}
    var fileAttribute: [FileAttributeKey: Any]? {get}
    var updater: HCDPFileListUpdaterByLocalEvent {get}
    var additionalChildrenItems: [HCDItem]? {get set}
}

extension HCDPLocalFileListUpdaterByEvent {
    mutating func updateLocalFileList() {
        let isDir = event.isDir
        if isDir {
            switch event.localEventType {
            case .moveIn:
                add()
                addChild()
            case .moveOut:
                removeIncludeItsChild()
            case .remove:
                remove()
            case .changeDir, .rename:
                move()
            case .create:
                add()
            case .modify: // equal to move out then move in
                removeIncludeItsChild()
                add()
                addChild()
            case .replace: // equal to >>move out<< destination path then >>change dir<< to that path
//                removeIncludeItsChild() // is this a mistake ?
                removeIncludeItsChild(toNewPath: true)
                move()
            }
        } else {
            switch event.localEventType {
            case .moveIn, .modify, .create:
                // FILE IS EXISTED
                add()
            case .moveOut, .remove:
                // FILE ISN'T EXISTED
                remove()
            case .changeDir, .rename:
                move()
            case .replace: // equal to move out destination path then change dir to that path
//                remove() // mistake ?
                remove(toNewPath: true)
                move()
            }
        }
    }
}

extension HCDPLocalFileListUpdaterByEvent {
    func add() {
        updater.add(path: event.path, fileAttribute: fileAttribute!)
    }
    mutating func addChild() {
        additionalChildrenItems = updater.addChildren(path: event.path)
    }
    func remove(toNewPath: Bool = false) {
        let pathToRemove = toNewPath ? event.newPath : event.path
        updater.remove(path: pathToRemove, includeChildren: false)
    }
    func removeIncludeItsChild(toNewPath: Bool = false) {
        let pathToRemove = toNewPath ? event.newPath : event.path
        updater.remove(path: pathToRemove, includeChildren: true)
    }
    func move() {
        updater.move(fromPath: event.path, toPath: event.newPath, isDir: event.isDir)
    }
}

struct HCDLocalFileListUpdaterByEvent: HCDPLocalFileListUpdaterByEvent {
    var event: HCDLocalEvent
    var fileAttribute: [FileAttributeKey : Any]?
    var updater: HCDPFileListUpdaterByLocalEvent = HCDFileListUpdaterByLocalEvent()
    internal var additionalChildrenItems: [HCDItem]?
    
    init(event: HCDLocalEvent, fileAttribute: [FileAttributeKey: Any]?) {
        self.event = event
        self.fileAttribute = fileAttribute
    }
}
