//
//  HCDNotificationHelper.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 9/7/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation

struct HCDNotificationHelper {
    
    enum Notification: String {
        case newEventHappened           = "HCDNotifEventHappened"
        case didTakeSomeEvents          = "HCDNotifDidTakeSomeEvents"
        case retryTakeSomeEvents        = "HCDNotifRetryTakeSomeEvents"
        case retryTakeCompleteSomeEvents        = "HCDNotifRetryCompleteSomeEvents"
        case oldEventWasExecuted        = "HCDNotifEventExecuted"
        case didCompleteAllEvent        = "HCDNotifDidCompleteAllEvent"
        case didActiveSync              = "HCDNotifDidActiveSync"
        case localFileBookDidChange     = "HCDNotifLocalFileBookDidChange"
        case serverFileBookDidChange    = "HCDNotifServerFileBookDidChange"
        case postMessage                = "HCDNotifPostMessage"
        case showMessage                = "HCDNotifShowMessage"
        case appIsRunning               = "HCDNotifAppIsRunning"
        case appIsIdling                = "HCDNotifAppIsIdling"
        case shouldShowDebugToolChanged = "shouldShowDebugToolChanged"
        case postDebugMessage           = "HCDNotifPostDebugMessage"
        case shouldRequestServerEvent   = "HCDNotifShouldRequestServerEvent"
        case userDidChangeSyncStatus    = "HCDNotifUserDidChangeSyncStatus"
        case LCLLanguageChangeNotification = "LCLLanguageChangeNotification"
        case countErrorEvent            = "HCDNotifCountErrorEvent"
        case haveNewVersion             = "HCDNotifHaveNewVersion"
    }
    
    static private let queue: DispatchQueue = DispatchQueue(label: "Notification_Serial_Queue")
    
    static func removeObserverFromTarget(target: AnyObject) {
        queue.async { // DispatchQueue.main.async {
            NotificationCenter.default.removeObserver(target)
        }
    }
    
    static func removeObserverFromTarget(target: AnyObject, withNotif notif: Notification) {
        NotificationCenter.default.removeObserver(
            target,
            name: NSNotification.Name(rawValue: notif.rawValue),
            object: nil)
    }
    
    static func addObserver(notif: Notification, target: Any, selector: Selector) {
        queue.async { // DispatchQueue.main.async {
            NotificationCenter.default.addObserver(
                target,
                selector: selector,
                name: NSNotification.Name(rawValue: notif.rawValue),
                object: nil
            )
        }
    }
    
    static private func postNotification(name: String, object: Any?) {
        queue.async { // DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: name), object: object)
        }
    }
    
    static private func postNotification(name: String, object: Any?, user: [AnyHashable : Any]?) {
        queue.async { // DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: name), object: object, userInfo: user)
        }
    }
    
    static func post(notificaion notif: Notification) {
        postNotification(
            name: notif.rawValue,
            object: nil
        )
        
        //Additional jobs
        switch notif {
        case .newEventHappened:
            HCDPrint.notif("NOTIF: new event happened!")
        case .oldEventWasExecuted:
            HCDPrint.notif("NOTIF: did finish some event")
        case .didActiveSync:
            HCDPrint.notif("NOTIF: did start active synchronize")
        case .didCompleteAllEvent:
            HCDPrint.info("NOTIF: did complete all event")
            if HCDEventTakingManager.eventListIsEmpty { //double check
                post(notificaion: .appIsIdling)
                post(notificaion: .shouldRequestServerEvent)
                post(message: "✓ " + "sync completed".localized)
                
                if HCDUserDefaults.showNotificationWhenSyncDone {
                    HCDUtilityHelper.createUserNotification(with: "Sync Successed".localized, info: "Done sync.".localized, userInfo: ["ID":""])
                }
            }
        default:
            HCDPrint.notif("NOTIF: \(notif.rawValue)")
        }
    }
    
    static func showAtMenuItem(message msg: String) {
        let notif = HCDUserDefaults.didCompleteFirstTimeGetServerFileList ? Notification.postMessage : Notification.showMessage
        postNotification(
            name: notif.rawValue,
            object: msg
        )
    }
    
    static func post(message msg: String) {
        postNotification(
            name: Notification.postMessage.rawValue,
            object: msg
        )
    }
    
    static func post(message msg: String, notificaion: Notification) {
        postNotification(
            name: notificaion.rawValue,
            object: msg
        )
    }
    
    static func post(object obj: Any?, user: [AnyHashable : Any]?,notificaion: Notification) {
        postNotification(
            name: notificaion.rawValue,
            object: obj,
            user: user
            )
    }
    
    static func show(runningList list: Set<String>) {
        if HCDUserDefaults.openDebugTools {
            postNotification(
                name: Notification.postDebugMessage.rawValue,
                object: list.toString
            )            
        }
    }
    
}
