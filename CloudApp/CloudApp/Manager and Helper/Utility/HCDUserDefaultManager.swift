//
//  HCDUserDefault.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 10/17/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation
/*
extension DefaultsKeys {
    static let syncFolderBookmarkData = DefaultsKey<Data?>("syncFolderBookmarkData")
    static let lastVersion      = DefaultsKey<Double>("lastVersion")
    static let syncFolderPath   = DefaultsKey<String?>("syncFolderPath")
    static let savedDomain      = DefaultsKey<String?>("savedDomain")
    static let savedUserName    = DefaultsKey<String?>("savedUserName")
    static let serverEventLogID = DefaultsKey<String?>("serverEventLogID")
    static let keyOfRootFolder  = DefaultsKey<String?>("keyOfRootFolder")
    static let localEventLogID  = DefaultsKey<Int>("localEventLogID")
    static let openAtLogin      = DefaultsKey<Bool>("openAtLogin")
    static let openDebugTools   = DefaultsKey<Bool>("openDebugTools")
    static let shouldLogNetwork = DefaultsKey<Bool>("shouldLogNetwork")
    static let shouldLogEvent   = DefaultsKey<Bool>("shouldLogEvent")
    static let shouldLogFile    = DefaultsKey<Bool>("shouldLogFile")
    static let shouldUseMD5     = DefaultsKey<Bool>("shouldUseMD5")
    static let userWantToPauseSync           = DefaultsKey<Bool>("userWantToPauseSync")
    static let didCompletefirstTimeSync      = DefaultsKey<Bool>("didCompletefirstTimeSync")
    static let shouldUseSecondLocalFileBook  = DefaultsKey<Bool>("shouldUseSecondLocalFileBook")
    static let shouldUseSecondServerFileBook = DefaultsKey<Bool>("shouldUseSecondServerFileBook")
    static let didCompleteFirstTimeGetServerFileList = DefaultsKey<Bool>("didCompleteFirstTimeGetServerFileList")
    static let allowDownloadWhileGettingFileList     = DefaultsKey<Bool>("allowDownloadWhileGettingFileList")
}

extension UserDefaults {
    func resetNeededKeyForLogout() {
        self[.serverEventLogID]            = nil
        self[.localEventLogID]             = 0
        self[.keyOfRootFolder]             = nil
        self[.didCompletefirstTimeSync]    = false
        self[.shouldUseSecondLocalFileBook]   = false
        self[.shouldUseSecondServerFileBook]  = false
        self[.didCompleteFirstTimeGetServerFileList] = false
    }
}
*/

struct HCDUserDefaults {
    static private unowned let userDefaults = UserDefaults.standard
    
    struct Key {
        static let lastVersion      = "lastVersion"
        static let savedDomain      = "savedDomain"
        static let savedUserName    = "savedUserName"
        static let openDebugTools   = "openDebugTools"
        static let syncFolderPath   = "SyncFolderPath"
        static let openAtLogin      = "openAtLogin"
        
        static let showFormSyncFails   = "showFormSyncFails"
        static let showNoficationDone       = "showNotificationWhenSyncDone"

        static let localEventLogID  = "LocalEventLogID"
        static let serverEventLogID = "serverEventLogID"
        static let keyOfRootFolder  = "keyOfRootFolder"
        static let shouldLogNetwork = "shouldLogNetwork"
        static let shouldLogEvent   = "shouldLogEvent"
        static let shouldLogFile    = "shouldLogFile"
        static let shouldUseMD5     = "shouldUseMD5"
        static let syncFolderBookmarkData       = "syncFolderBookmarkData"
        static let userWantToPauseSync          = "userWantToPauseSync"
        static let didCompletefirstTimeSync     = "didCompletefirstTimeSync"
        static let shouldUseSecondLocalFileBook    = "shouldUseSecondLocalFileBook"
        static let shouldUseSecondServerFileBook   = "shouldUseSecondServerFileBook"
        static let allowDownloadWhileGettingFileList     = "allowDownloadWhileGettingFileList"
        static let didCompleteFirstTimeGetServerFileList = "didCompleteFirstTimeGetServerFileList"
    }
    
    static func resetNeededKeyForLogout() {
        serverEventLogID            = nil
        localEventLogID             = 0
        keyOfRootFolder             = nil
        didCompleteFirstTimeSync    = false
        shouldUseSecondLocalFileBook   = false
        shouldUseSecondServerFileBook  = false
        didCompleteFirstTimeGetServerFileList = false
        showFormSyncFails = true
    }
    
    static var lastVersion: Double {
        set {
            userDefaults.set(newValue, forKey: Key.lastVersion)
        }
        get {
            return userDefaults.double(forKey: Key.lastVersion)
        }
    }
    
    static var savedDomain: String? {
        set {
            userDefaults.setValue(newValue, forKey: Key.savedDomain)
        }
        get {
            return userDefaults.string(forKey: Key.savedDomain)
        }
    }
    
    static var savedUserName: String? {
        set {
            userDefaults.setValue(newValue, forKey: Key.savedUserName)
        }
        get {
            return userDefaults.string(forKey: Key.savedUserName)
        }
    }
    
    static var syncFolderBookmarkData: Data? {
        set {
            userDefaults.setValue(newValue, forKey: Key.syncFolderBookmarkData)
        }
        get {
            return userDefaults.data(forKey: Key.syncFolderBookmarkData)
        }
    }
    
    static var syncFolderPath: String? {
        set {
            userDefaults.setValue(newValue, forKey: Key.syncFolderPath)
        }
        get {
            return userDefaults.string(forKey: Key.syncFolderPath)
        }
    }
    
    static var serverEventLogID: String? {
        set {
            userDefaults.setValue(newValue, forKey: Key.serverEventLogID)
        }
        get {
            return userDefaults.string(forKey: Key.serverEventLogID)
        }
    }
    
    static var localEventLogID: Int {
        set {
            userDefaults.set(newValue, forKey: Key.localEventLogID)
        }
        get {
            return userDefaults.integer(forKey: Key.localEventLogID)
        }
    }
    
    static var userWantToPauseSync: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.userWantToPauseSync)
        }
        get {
            return userDefaults.bool(forKey: Key.userWantToPauseSync)
        }
    }
    
    static var shouldUseSecondLocalFileBook: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.shouldUseSecondLocalFileBook)
        }
        get {
            return userDefaults.bool(forKey: Key.shouldUseSecondLocalFileBook)
        }
    }

    static var shouldUseSecondServerFileBook: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.shouldUseSecondServerFileBook)
        }
        get {
            return userDefaults.bool(forKey: Key.shouldUseSecondServerFileBook)
        }
    }
    
    static var keyOfRootFolder: String? {
        set {
            userDefaults.setValue(newValue, forKey: Key.keyOfRootFolder)
        }
        get {
            return userDefaults.string(forKey: Key.keyOfRootFolder)
        }
    }
    
    static var allowDownloadWhileGettingFileList: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.allowDownloadWhileGettingFileList)
        }
        get {
            return userDefaults.bool(forKey: Key.allowDownloadWhileGettingFileList)
        }
    }
    
    static var didCompleteFirstTimeGetServerFileList: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.didCompleteFirstTimeGetServerFileList)
        }
        get {
            return userDefaults.bool(forKey: Key.didCompleteFirstTimeGetServerFileList)
        }
    }
    
    static var didCompleteFirstTimeSync: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.didCompletefirstTimeSync)
        }
        get {
            return userDefaults.bool(forKey: Key.didCompletefirstTimeSync)
        }
    }
    
    static var showNotificationWhenSyncDone: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.showNoficationDone)
        }
        get {
            return userDefaults.bool(forKey: Key.showNoficationDone)
        }
    }
    
    static var showFormSyncFails: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.showFormSyncFails)
        }
        get {
            return userDefaults.bool(forKey: Key.showFormSyncFails)
        }
    }
    
    static var openAtLogin: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.openAtLogin)
        }
        get {
            return userDefaults.bool(forKey: Key.openAtLogin)
        }
    }
    
    static var openDebugTools: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.openDebugTools)
        }
        get {
            return userDefaults.bool(forKey: Key.openDebugTools)
        }
    }
    
    static var shouldLogNetwork: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.shouldLogNetwork)
        }
        get {
            return userDefaults.bool(forKey: Key.shouldLogNetwork)
        }
    }
    static var shouldLogEvent: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.shouldLogEvent)
        }
        get {
            return userDefaults.bool(forKey: Key.shouldLogEvent)
        }
    }
    static var shouldLogFile: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.shouldLogFile)
        }
        get {
            return userDefaults.bool(forKey: Key.shouldLogFile)
        }
    }
    static var shouldUseMD5: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.shouldUseMD5)
        }
        get {
            return userDefaults.bool(forKey: Key.shouldUseMD5)
        }
    }
}
