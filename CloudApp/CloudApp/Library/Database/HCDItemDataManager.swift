//
//  HCDItemDataManager.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/24/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import RealmSwift
import Foundation

class HCDItemDataManager: HCDDataManager {
    static private let sharedInstanceLocal2      =
        HCDItemDataManager(indentifyName: HCDGlobalDefine.Database.ManagerIndentify.localList2)
    static private let sharedInstanceServer2     =
        HCDItemDataManager(indentifyName: HCDGlobalDefine.Database.ManagerIndentify.serverList2)
    static private let sharedInstanceLocal1  =
        HCDItemDataManager(indentifyName: HCDGlobalDefine.Database.ManagerIndentify.localList1)
    static private let sharedInstanceServer1 =
        HCDItemDataManager(indentifyName: HCDGlobalDefine.Database.ManagerIndentify.serverList1)
    
    static var local2: HCDItemDataManager {
        return sharedInstanceLocal2
    }
    static var server2: HCDItemDataManager {
        return sharedInstanceServer2
    }
    static var local1: HCDItemDataManager {
        return sharedInstanceLocal1
    }
    static var server1: HCDItemDataManager {
        return sharedInstanceServer1
    }
    
    func addNotificationToken(notif: HCDNotificationHelper.Notification) {
        DispatchQueue.main.async {
            self.token = self.allItems.addNotificationBlock {(changes: RealmCollectionChange) in
                switch changes {
                case .update( _, _, _, _):
                    HCDNotificationHelper.post(notificaion: notif)
                default:
                    break
                }
            }
        }
    }
    
    func stopNotificationToken() {
        self.token?.stop()
    }
    
    internal var allItems: Results<HCDItemObject> {
        return self.realm.objects(HCDItemObject.self)
    }
}

//MARK: GET 
extension HCDItemDataManager {
    func getItem(atPath: String) -> HCDItem? {
        let legalPath = atPath.precomposedStringWithCanonicalMapping
        realm.refresh()
        return allItems.filterByPath(exactly: legalPath).first?.item
    }
    
    var totalItem: Int {
        realm.refresh()
        return allItems.count
    }
}

//MARK: ADD
extension HCDItemDataManager {
//    func addItemFromDictionary(dict: [String: Any]) {
//        delete(atPath: dict[HCDItemObject.PropertyName.path] as! String)
//        writeWithBlock {
//            let item = HCDItemObject(value: dict)
//            self.realm.add(item)
//        }
//    }
    
    func add(items: [HCDItem], brandNew: Bool = false) {
        writeWithBlock {
            let db = self.realm
            var tmpItem: HCDItemObject!
            for item in items {
                let legalPath = item.path.precomposedStringWithCanonicalMapping
                if !brandNew {
                    db.objects(HCDItemObject.self).filterByPath(exactly: legalPath).forEach {
                        db.delete($0)
                    }
                }
                tmpItem = HCDItemObject()
                tmpItem.from(item: item)
                db.add(tmpItem)
            }
        }
    }
}

//MARK: DELETE
extension HCDItemDataManager {
    func delete(atPath path: String) {
        let legalPath = path.precomposedStringWithCanonicalMapping
        writeWithBlock {
            if let item = self.allItems.filterByPath(exactly: legalPath).first {
                self.realm.delete(item)
            }
        }
    }
    func delete(beginWithPath path: String) {
        let legalPath = path.precomposedStringWithCanonicalMapping
        writeWithBlock {
            self.allItems.filterByPath(beginsWith: legalPath).forEach {
                self.realm.delete($0)
            }
        }
    }
}

//MARK: UPDATE
extension HCDItemDataManager {
    func update(newParentPath: String, fromParentPath: String) {
        let legalNewParentPath  = newParentPath.stringByAddingSlash.precomposedStringWithCanonicalMapping
        let legalFromParentPath = fromParentPath.stringByAddingSlash.precomposedStringWithCanonicalMapping
        writeWithBlock {
            self.allItems
                .filterByPath(beginsWith: legalFromParentPath)
                .update(newParentPath: legalNewParentPath, fromParentPath: legalFromParentPath)
        }
    }
    
    func update(fromPath: String, toPath: String) {
        let legalNewPath = toPath.precomposedStringWithCanonicalMapping
        let legalFromPath = fromPath.precomposedStringWithCanonicalMapping
        writeWithBlock {
            self.allItems
                .filterByPath(exactly: legalFromPath)
                .update(newParentPath: legalNewPath, fromParentPath: legalFromPath)
        }
    }
}

//MARK: CROSS-REALM TASKS
extension HCDItemDataManager {
    func enumerateAllItemThat(notBeingContainedByManager otherManager: HCDItemDataManager, andExecuteAction action: (HCDItemObject)->Void) {
        self.realm.refresh()
        self.allItems.forEach {
            if otherManager.allItems.filterByPath(exactly: $0.path).isEmpty {
                action($0)
            }
        }
    }
    
    func enumerateAllItemThat(cleanError otherManager: HCDItemDataManager, andExecuteAction action: (HCDEventObject)->Void) {
        self.realm.refresh()
        HCDEventDataManager.defaultManager().eventErrors.forEach {
            if self.allItems.filterByPath(exactly: $0.path).isEmpty && otherManager.allItems.filterByPath(exactly: $0.path).isEmpty {
                action($0)
            }
        }
    }
    
    func override(toManager managerDataNeedToBeOverrided: HCDItemDataManager) {
//        guard let urlNeedToBeDeleted = managerDataNeedToBeOverrided.realm.configuration.fileURL else {
//            return
//        }
//        HCDPrint.debug("delete realm file \(managerDataNeedToBeOverrided.realmName)")
//        managerDataNeedToBeOverrided.deleteRealmFile()
//        HCDPrint.debug("begin update file list \(realmName)")
//        do {
//            try self.realm.writeCopy(toFile: urlNeedToBeDeleted)
//        } catch {
//            HCDPrint.error(error)
//        }
//        HCDPrint.debug("done")
        
        //TODO: need more safe here
        managerDataNeedToBeOverrided.deleteAll()
        let items: [HCDItem] = self.allItems.map{ return $0.item}
        managerDataNeedToBeOverrided.add(items: items, brandNew: true)
 
        /* newest but have some problem, current list got redundant files
        self.writeWithBlock {
            self.enumerateAllItemThat(notBeingContainedByManager: managerDataNeedToBeOverrided) {
                managerDataNeedToBeOverrided.add(fromItem: $0.item)
            }
        }
        managerDataNeedToBeOverrided.writeWithBlock {
            managerDataNeedToBeOverrided.enumerateAllItemThat(notBeingContainedByManager: self) {
                managerDataNeedToBeOverrided.realm.delete($0)
            }
        }
         */
    }
}

//MARK: Realm Result Extension
extension Results where T: HCDItemObject {
    func filterByPath(exactly path: String) -> Results<T> {
        return filter("\(HCDItemObject.PropertyName.path) = \(path.wrapDoubleQuotes)")
    }
    func filterByPath(beginsWith path: String) -> Results<T> {
        return filter("\(HCDItemObject.PropertyName.path) BEGINSWITH \(path.wrapDoubleQuotes)")
    }
    func update(newParentPath: String, fromParentPath: String) {
        self.forEach {
            let newPath = $0.path.stringByDeletingStringFromBeginWithLenghtOfString(removeString: fromParentPath, thenReplaceWithString: newParentPath)
            $0.path = newPath
        }
    }
}
