//
//  HCDUtilityHelper.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/22/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Cocoa
import Fabric
import Crashlytics
import ServiceManagement

struct HCDUtilityHelper {
    static func appGlobalSetup() {
        Fabric.with([Crashlytics.self])
        HCDUtilityHelper.checkVersionThenClearDataIfNeeded()
        HCDUtilityHelper.getAccessToSyncFolder()
//        HCDLog.debugTools(enable: true)
//        _ = HCDFileManager.syncFolderRoot(createIfNeeded: true)
    }
    
    static func getDeviceInfo() -> HCDDeviceInformationVT {
        let deviceName: String? = Host.current().localizedName
        let maccAddress = GetPrimaryMACAddressInSwift.macAddress()
        let deviceInfo = HCDDeviceInformationVT(deviceName: deviceName, macAddress: maccAddress)
        return deviceInfo
    }
    
    static func getSerialOperationQueue(withName queueName: String) -> OperationQueue {
        let queue = OperationQueue()
        queue.name = queueName
        queue.maxConcurrentOperationCount = 1
        return queue
    }
    
    static func getConcurrentDispathQueue(withName name: String) -> DispatchQueue {
        return DispatchQueue(label: name, attributes: .concurrent)
    }
    
    static func setOpenAtLogin(_ shouldOpenAtLogin: Bool) {
        var helperBundleID = HCDGlobalDefine.appHelperBundleIdentifier
        #if MOFFICE
            helperBundleID = HCDGlobalDefine.appMofficeHelperBundleIdentifier
        #endif
        if SMLoginItemSetEnabled(helperBundleID as CFString, shouldOpenAtLogin) {
            HCDPrint.info("\(shouldOpenAtLogin ? "Successfully add login item." : "Successfully remove login item.")")
            HCDUserDefaults.openAtLogin = shouldOpenAtLogin
        } else {
            HCDPrint.error("\(shouldOpenAtLogin ? "Failed to login item." : "Failed to remove login item.")")
        }
    }
    
    static func dialogOKCancel(question: String, text: String) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = question
        myPopup.informativeText = text
        myPopup.alertStyle = NSAlertStyle.warning
        myPopup.addButton(withTitle: "OK".localized)
        myPopup.addButton(withTitle: "Cancel".localized)
        return myPopup.runModal() == NSAlertFirstButtonReturn
    }
    
    static func restartApp() {
        HCDPrint.info("Restart App!")
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        exit(0)
    }
    
    static func quitApp() {
        //terminate app
        HCDPrint.info("Termitate app!")
        NSApplication.shared().terminate(nil)
    }
    
    static func clearSyncFolderWithoutSyncToServer() {
        HCDLocalEventListenManager.stopListenRootFolder()
        if HCDUserDefaults.syncFolderPath != nil {
            HCDFileManager.removeIfFileExistedAtFullPath(fileDirectory: HCDPathHelper.defaultSyncRootPath)
        }
    }
    
    static func clearAllData() {
        // reset langauge
        Localize.resetCurrentLanguageToDefault()
        //delete user default data
        HCDUserDefaults.resetNeededKeyForLogout()
        HCDUserDefaults.syncFolderPath = nil
        
        //delete database
        HCDItemBook.deleteAllBook(shouldClearRealmFile: true)
        HCDEventDataManager.defaultManager().deleteRealmFile()
    }
    
    static func checkVersionThenClearDataIfNeeded() {
        let lastVersion = HCDUserDefaults.lastVersion
        if lastVersion < HCDGlobalDefine.appMinVersion {
            HCDUserDefaults.lastVersion = HCDGlobalDefine.appVersion
            clearAllData()
            restartApp()
        } else if lastVersion < HCDGlobalDefine.appVersion {
            HCDUserDefaults.lastVersion = HCDGlobalDefine.appVersion
            HCDDataManager.clearOldRealmFileIfNeeded(forVersion: lastVersion)
            logoutAndResetSyncFolderPathIfNeeded(forLastVersion: lastVersion)
        }
    }
    
    static let totalByteForEachMegaByte = 1024 * 1024
    static let totalByteForEachGigabyte = totalByteForEachMegaByte * 1024
    static let totalByteForEachTeraByte = totalByteForEachGigabyte * 1024
    
    static func storageValueString(fromBytesCount byteCount: Double) -> String {
        var total:Double = byteCount
        
        let labels = ["KB","MB","GB","TB"]
        
        var selectedLabel = "Bytes"
        for label in labels {
            guard total > 1024 else {
                break
            }
            total /= 1024
            selectedLabel = label
        }
        
        return String(format: "%.2f%@", total, selectedLabel)
    }
    
    static func getAccessToSyncFolder() {
        guard
            let registedUrl = HCDUserDefaults.syncFolderPath,
            let registedBookmarkData = HCDUserDefaults.syncFolderBookmarkData
        else
        {
                return
        }
        
        var bookmarkDataIsStale: Bool = false
        do {
            let bookmarkFileURL = try URL(resolvingBookmarkData: registedBookmarkData,
                                          options: URL.BookmarkResolutionOptions.withSecurityScope,
                                          relativeTo: nil,
                                          bookmarkDataIsStale: &bookmarkDataIsStale)
            
            if let canAccess = bookmarkFileURL?.startAccessingSecurityScopedResource(), canAccess == true {
                HCDPrint.info("Success access to \(registedUrl)")
            } else {
                HCDPrint.error("Can't access to \(registedUrl)")
            }
        } catch {
            HCDPrint.error(error)
        }
    }
    
    static func selectSyncFolder(completionHandle: (URL)->()) {
        let dialog = NSOpenPanel()
        
        dialog.title                    = "Select New Sync Folder".localized
        dialog.showsResizeIndicator     = true
        dialog.showsHiddenFiles         = false
        dialog.canChooseFiles           = false
        dialog.canChooseDirectories     = true
        dialog.canCreateDirectories     = true
        dialog.allowsMultipleSelection  = false
        
        if (dialog.runModal() == NSModalResponseOK) {
            if let result = dialog.url {
                completionHandle(result)
            }
        }
    }
    
    static func commitSyncURL(_ url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: URL.BookmarkCreationOptions.withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil)
            
            HCDUserDefaults.syncFolderPath = url.path
            HCDUserDefaults.syncFolderBookmarkData = bookmarkData
            restartApp()
        } catch {
            HCDPrint.error(error)
        }
    }
}

extension HCDUtilityHelper {
    static func logoutAndResetSyncFolderPathIfNeeded(forLastVersion lastVersion: Double) {
        if lastVersion < 20170117.5 {
            HCDUserDefaults.syncFolderPath = nil
            HCDLoginManager.logout()
        }
    }
}
// Notification when app have a new version.
extension HCDUtilityHelper {
    static func checkUpdateApp() {
        let strURL = "https://itunes.apple.com/lookup?bundleId=\(Bundle.main.bundleIdentifier!)"
        guard let url = URL(string: strURL) else { return }
      //  do {
        URLSession.shared.dataTask(with: url) {data,_,error in
            guard let data = data, error == nil else {
                return
            }
            
            guard let jsonInfo = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            guard let count = jsonInfo?["resultCount"] as? Int, count == 1 else {
                return
            }
            guard let result = jsonInfo?["results"] as? [[String: Any]] else {
                return
            }
            
            let strNewVersion = result[0]["version"] as? String ?? "0.0"
            let trackID = result[0]["trackId"] as? Int ?? 0
            guard let strCurrentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                return
            }
            
            let newVersion = Int(strNewVersion.replacingOccurrences(of: ".", with: "")) ?? 0
            let currentVersion = Int(strCurrentVersion.replacingOccurrences(of: ".", with: "")) ?? 0
            
            if newVersion > currentVersion {
                HCDNotificationHelper.post(object: strNewVersion, user: ["version":strNewVersion, "appID":"\(trackID)"],notificaion: .haveNewVersion)
            }
        }.resume()
    }
}

extension HCDUtilityHelper {
    // MARK: - UserNotification
    static func createUserNotification(with title: String, info: String, userInfo: [String : Any]?) {
        // create a User Notification
        let notification = NSUserNotification.init()
        
        // set the title and the informative text
        notification.title = title
        notification.informativeText = info
        notification.userInfo = userInfo
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.hasActionButton = true
        
        // Deliver the notification through the User Notification Center
        NSUserNotificationCenter.default.deliver(notification)
    }
}

//utility function :
//NSApp.orderFrontStandardAboutPanel(self) // open about
