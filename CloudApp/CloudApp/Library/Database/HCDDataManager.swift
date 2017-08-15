//
//  HCDDataManager.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 10/12/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import RealmSwift
import Foundation

class HCDDataManager {
    static var databaseFolderURL: URL? {
        return Realm.Configuration().fileURL?.deletingLastPathComponent()
    }
    
    private let indentifyName: String
    
    private lazy var realmConfiguration: Realm.Configuration = {
        var config = Realm.Configuration()
        config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("\(self.realmName).realm")
        return config
    }()
    
    internal var realm: Realm {
        //TODO: Should do real try catch here
        do {
            return try Realm(configuration: self.realmConfiguration)
        } catch {
            HCDPrint.error(error)
            deleteRealmFile()
        }
        return try! Realm(configuration: self.realmConfiguration)
    }
    
    internal var realmName: String {
        return indentifyName
    }

    internal var queueName: String {
        return "concurrent_\(realmName)_queue"
    }
    
    internal var token: NotificationToken?
    
    internal init(indentifyName: String) {
        self.indentifyName = indentifyName
    }

    static internal func completeDeleteRealmFileForPath(path: String) {
        let pathLock = path + ".Lock"
        let pathManagement = path + ".Management"
        HCDFileManager.removeIfFileExistedAtFullPath(fileDirectory: pathLock)
        HCDFileManager.removeIfFileExistedAtFullPath(fileDirectory: pathManagement)
        HCDFileManager.removeIfFileExistedAtFullPath(fileDirectory: path)
    }

    internal func deleteRealmFile(forVersionLowerThan minVersion: Double = HCDGlobalDefine.appVersion) {
        if let path = self.realmConfiguration.fileURL?.path {
            HCDDataManager.completeDeleteRealmFileForPath(path: path)
        }
    }
    
//    private func copyRealmFile(toURL: URL) {
//        HCDFileManager.copyItem(atURL: self.realmConfiguration.fileURL!, toURL: toURL)
//    }
    
//    func override(toManager managerDataNeedToBeOverrided: HCDDataManager) {
//        //TODO: need more safe herema
//        let realmURLNeedToBeOverrided = managerDataNeedToBeOverrided.realmConfiguration.fileURL!
//        managerDataNeedToBeOverrided.deleteRealmFile()
//        copyRealmFile(toURL: realmURLNeedToBeOverrided)
//    }
}

//MARK: - REALM WRAPPER
extension HCDDataManager {
    internal func writeWithBlock(block: @escaping ()->()) {
        realm.refresh()
        do {
            try realm.write {
                block()
            }
        } catch {
            HCDPrint.error("Realm Error while trying to write object: \(error)")
        }
    }
}

//MAR: - DELETE 
extension HCDDataManager {
    internal func deleteAll() {
        HCDPrint.debug("Delete all data for manager \(realmName)")
        self.writeWithBlock {
            self.realm.deleteAll()
        }
    }
}

extension HCDDataManager {
    static func clearOldRealmFileIfNeeded(forVersion lastVersion: Double) {
        if lastVersion < 20170113.3 {
            if let mainPath = Realm.Configuration().fileURL {
                ["current_local_file_book",
                 "new_local_file_book",
                 "current_server_file_book",
                 "new_server_file_book"].forEach {
                    let path = mainPath.deletingLastPathComponent().appendingPathComponent( $0 + ".realm").path
                    completeDeleteRealmFileForPath(path: path)
                }
            }
        }
    }
}

