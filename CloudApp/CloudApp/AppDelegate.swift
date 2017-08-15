//
//  AppDelegate.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/18/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
//        HCDPrint.debug("Register push notification")
//        let type: NSRemoteNotificationType = [NSRemoteNotificationType.alert, NSRemoteNotificationType.badge, NSRemoteNotificationType.sound]
//        NSApp.registerForRemoteNotifications(matching: type)
        
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions":true])
        
        HCDPrint.debug("Register Notification local")
        NSUserNotificationCenter.default.delegate = self
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

extension AppDelegate: NSUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        if let idApp = notification.userInfo?["appID"] as? String {
            NSWorkspace.shared().open(URL(string: "macappstore://itunes.apple.com/app/id\(idApp)?mt=12")!)
        }
    }
}

