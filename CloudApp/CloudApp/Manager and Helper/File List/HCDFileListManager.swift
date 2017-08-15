//
//  HCDFileListManager.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/24/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import PromiseKit
import Foundation

protocol HCDPItemProvider {
    func getItem(atPath: String) -> HCDItem?
}

protocol HCDPFileListUpdater {
    var fromLocal: Bool {get}
    func promiseGetNewList(withItemCollector: HCDPItemCollector) -> Promise<()>
}

enum HCDFileListUpdater: HCDPFileListUpdater {
    case local
    case server
    
    var fromLocal: Bool {
        return self == .local
    }
    
    func promiseGetNewList(withItemCollector collector: HCDPItemCollector) -> Promise<()> {
        switch self {
        case .local:
            return HCDLocalFileListUpdater.promiseUpdateFileList(withCollector: collector)
        case .server:
            return HCDServerFileListUpdater.promiseRequestFileList(withCollector: collector)
        }
    }
}

class HCDFileListManager {
    static internal let defaultManager = HCDFileListManager()
    
    let serverUpdater: HCDPFileListUpdater = HCDFileListUpdater.server
    let localUpdater: HCDPFileListUpdater = HCDFileListUpdater.local

    
    static internal var serverFileBook: HCDItemBook {
        return defaultManager.getFileBook(fromLocal: false)
    }
    static internal var localFileBook: HCDItemBook {
        return defaultManager.getFileBook(fromLocal: true)
    }
    
    private func getFileBook(fromLocal: Bool, inUse: Bool = true) -> HCDItemBook {
        let isUsingSecondFileBook = fromLocal ?
            HCDUserDefaults.shouldUseSecondLocalFileBook :
            HCDUserDefaults.shouldUseSecondServerFileBook
        let shouldChooseSecondFileBook = inUse == isUsingSecondFileBook
        return shouldChooseSecondFileBook ?
            fromLocal ? HCDItemBook.secondLocalBook : HCDItemBook.secondServerBook :
            fromLocal ? HCDItemBook.firstLocalBook  : HCDItemBook.firstServerBook
    }
    
    static func getNewFileBook(fromLocal: Bool) -> Promise<()> {
        return defaultManager.getNewFileBook(fromLocal: fromLocal)
    }
    
    func getNewFileBook(fromLocal: Bool) -> Promise<()> {
        guard fromLocal || HCDEventTakingManager.eventListIsEmpty else {
            return Promise(error: HCDError.eventHappen)
        }
        
        let updater = fromLocal ? localUpdater : serverUpdater
        
        let book = getFileBook(fromLocal: fromLocal, inUse: true)
        let newBook = getFileBook(fromLocal: fromLocal, inUse: false)
        
        book.addNotificationToken()
        return updater.promiseGetNewList(withItemCollector: newBook)
            .then {
                self.updateFileBook(fromLocal: fromLocal)
            }.always {
                book.stopToken()
            }
    }
    
    private func updateFileBook(fromLocal: Bool) -> Promise<()> { //should retry when file book change while copying
        guard fromLocal || HCDUserDefaults.didCompleteFirstTimeGetServerFileList else {
            HCDUserDefaults.didCompleteFirstTimeGetServerFileList = true
            return Promise(value: ())
        }
        
        guard fromLocal || HCDEventTakingManager.eventListIsEmpty else {
            return Promise(error: HCDError.eventHappen)
        }
        
        HCDNotificationHelper.post(message: "Update \(fromLocal ? "Local": "Server") File List".localized + "...")
        
        if fromLocal {
            HCDUserDefaults.shouldUseSecondLocalFileBook = !HCDUserDefaults.shouldUseSecondLocalFileBook
        } else {
            HCDUserDefaults.shouldUseSecondServerFileBook = !HCDUserDefaults.shouldUseSecondServerFileBook
        }
        
        HCDPrint.info("did update \(fromLocal ? "local" : "server") file book")
        return Promise(value: ())
    }
}

extension HCDFileListManager {
    static func keyForPath(path: String) -> String? {
        guard !path.isEmpty else {
            return HCDUserDefaults.keyOfRootFolder
        }
        return serverFileBook.getItem(atPath: path)?.key
    }
    
    static func itemForLocalPath(path: String) -> HCDItem? {
        return localFileBook.getItem(atPath: path)
    }
    
    static func put(key: String, forPath path: String) {
        if let item = localFileBook.getItem(atPath: path)?.item(withNewKey: key) {
            serverFileBook.collect(item: item)
        }
    }
}

extension HCDFileListManager {
    static func updateServerFileList(afterAddServerRawEvent event: HCDServerRawEvent) {
        switch event.type {
        case .add:
            serverFileBook.collect(item: HCDItem(fromServerRawEvent: event))
        case .remove:
            serverFileBook.delete(atPath: event.path, includeChild: true)
        case .move, .rename:
            let convertedEvent = HCDServerEvent(fromRawEvent: event)
            serverFileBook.moveItems(fromPath: convertedEvent.path, toPath: convertedEvent.newPath, isDir: convertedEvent.isDir)
        }
    }
}
extension HCDFileListManager {
    static func updateFileList(afterExecuteLocalEvent event: HCDPEvent) {
        if event is HCDPLocalEvent {
            switch event.eventType {
            case .remove:
                serverFileBook.delete(atPath: event.path, includeChild: event.isDir)
            case .change:
                serverFileBook.moveItems(fromPath: event.path, toPath: event.newPath, isDir: event.isDir)
            default:
                break
            }
        } else if event is HCDPServerEvent {
            switch event.eventType {
            case .create:
                if let fileAttribute = HCDFileManager.fileAttributesAtFullPath(fullPath: HCDPathHelper.fullPathForPath(path: event.path)) {
                    let item = HCDItem(fromFileAttribute: fileAttribute, path: event.path)
                    HCDFileListManager.localFileBook.collect(item: item)
                }
            case .remove:
                localFileBook.delete(atPath: event.path, includeChild: event.isDir)
            case .change:
                localFileBook.moveItems(fromPath: event.path, toPath: event.newPath, isDir: event.isDir)
            }
        } else {
            HCDPrint.error("EVENT IS NOT FROM LOCAL NOR SERVER ???!!!")
        }
    }
}

struct HCDFileListUpdaterByLocalEvent: HCDPFileListUpdaterByLocalEvent {
    func add(path: String, fileAttribute: [FileAttributeKey: Any]) {
        let item = HCDItem(fromFileAttribute: fileAttribute, path: path)
        HCDFileListManager.localFileBook.collect(item: item)
    }
    func addChildren(path: String) -> [HCDItem] {
        return HCDLocalFileListUpdater.promiseUpdateFile(collector: HCDFileListManager.localFileBook, atPath: path) ?? [HCDItem]()
    }
    func remove(path: String, includeChildren: Bool) {
        HCDFileListManager.localFileBook.delete(atPath: path, includeChild: includeChildren)
    }
    func move(fromPath: String, toPath: String, isDir: Bool) {
        HCDFileListManager.localFileBook.moveItems(fromPath: fromPath, toPath: toPath, isDir: isDir)
    }
}
