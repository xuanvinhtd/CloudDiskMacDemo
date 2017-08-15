//
//  HCDItemCollector.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/24/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.

enum HCDItemBook {
    case secondLocalBook
    case secondServerBook
    case firstLocalBook
    case firstServerBook
    
    static var allBooks: [HCDItemBook] {
        return [firstLocalBook, secondLocalBook, firstServerBook, secondServerBook]
    }
    
    static func deleteAllBook(shouldClearRealmFile: Bool = false) {
        allBooks.forEach {
            if shouldClearRealmFile {
                $0.deleteRealmFile()
            } else {
                $0.deleteAll()
            }
        }
    }
}

extension HCDItemBook {
    internal var dataManager: HCDItemDataManager {
        switch self {
        case .secondLocalBook:
            return HCDItemDataManager.local2
        case .firstLocalBook:
            return HCDItemDataManager.local1
        case .secondServerBook:
            return HCDItemDataManager.server2
        case .firstServerBook:
            return HCDItemDataManager.server1
        }
    }
}

//MARK: - GET
extension HCDItemBook: HCDPItemProvider {
    func getItem(atPath: String) -> HCDItem? {
        return dataManager.getItem(atPath: atPath)
    }
    
    var fileCount: Int {
        dataManager.realm.refresh()
        return dataManager.totalItem
    }
}

//MARK: - ADD
extension HCDItemBook: HCDPItemCollector {
    internal func collect(item: HCDItem) {
        if !HCDGlobalDefine.FileName.shouldIgnoreFile(hasName: item.name) {
            dataManager.add(items: [item])
        }
    }
    
    func collect(items: [HCDItem], brandNew: Bool) {
        let legalItems = items.filter {
            return !HCDGlobalDefine.FileName.shouldIgnoreFile(hasName: $0.name)
        }
        
        dataManager.add(items: legalItems)
        
        if !(HCDUserDefaults.didCompleteFirstTimeGetServerFileList && HCDUserDefaults.allowDownloadWhileGettingFileList) && self == .secondServerBook {
            legalItems.forEach {
                if HCDItemBook.secondLocalBook.getItem(atPath: $0.path) == nil {
                    HCDFileListManager.updateServerFileList(afterAddServerRawEvent: HCDServerRawEvent(brokenAddEventfromItem: $0))
                    HCDEventTakingManager.take(events: [$0.toServerEventWithTypeAdded])
                }
            }
        }
//        DEMO
        HCDNotificationHelper.post(message: "Reading server file list".localized + " (\(fileCount))...")
//        END
    }
    
    func dropAll() {
        deleteAll()
    }
}

//MARK: - REMOVE
extension HCDItemBook {
    func delete(atPath path: String, includeChild: Bool) {
        if includeChild {
            dataManager.delete(atPath: path)
            dataManager.delete(beginWithPath: path.stringByAddingSlash)
        } else {
            dataManager.delete(atPath: path)
        }
    }
    
    func deleteAll() {
        dataManager.deleteAll()
    }
    
    func deleteRealmFile() {
        dataManager.deleteRealmFile()
    }
}

//MARK: - UPDATE
extension HCDItemBook {
    func moveItems(fromPath: String, toPath: String, isDir: Bool) {
        moveSingleItems(fromPath: fromPath, toPath: toPath)
        if isDir {
            moveChildrenItems(fromParentPath: fromPath, newParentPath: toPath)
        }
    }
    private func moveSingleItems(fromPath: String, toPath: String) {
        dataManager.update(fromPath: fromPath, toPath: toPath)
    }
    private func moveChildrenItems(fromParentPath: String, newParentPath: String) {
        dataManager.update(newParentPath: newParentPath, fromParentPath: fromParentPath)
    }
}

//MARK: - ACTION TO WHOLE BOOK
extension HCDItemBook {
    func override(toBook bookNeedToBeOverrided: HCDItemBook) {
        dataManager.override(toManager: bookNeedToBeOverrided.dataManager)
    }
    
    func enumerateAllItemThat(notInBook otherBook: HCDItemBook, withAction action: (HCDItem)->Void) {
        dataManager.enumerateAllItemThat(notBeingContainedByManager: otherBook.dataManager) {
            action($0.item)
        }
    }
    
    func enumerateAllItemThat(cleanErrorWith otherBook: HCDItemBook, withAction action: (HCDEventObject)->Void) {
        dataManager.enumerateAllItemThat(cleanError: otherBook.dataManager) {
            action($0)
        }
    }
    
    func checkAndCleanEventErrors() {
        dataManager.allItems.forEach {
            //Compare event in database with files in server. and clean event error by condition.
            if let e = HCDEventDataManager.defaultManager().errorEvents(byPath: $0.path).first {
                if e.eventType == HCDEventType.create.rawValue {
                    HCDEventTakingManager.defaultManager.removeEventErrors(withPath: [$0.path])
                }
            }
        }
    }
}

//MARK: - NOTIFICATION
extension HCDItemBook {
    func addNotificationToken() {
        switch self {
        case .firstLocalBook:
            dataManager.addNotificationToken(notif: .localFileBookDidChange)
        case .firstServerBook:
            dataManager.addNotificationToken(notif: .serverFileBookDidChange)
        default:
            return
        }
        HCDPrint.info("Start listen item data for \(self)")
    }
    
    func stopToken() {
        switch self {
        case .firstLocalBook, .firstServerBook:
            dataManager.stopNotificationToken()
        default:
            break
        }
    }
}
