//
//  HCDDebugWindowController.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 12/23/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Cocoa

class HCDDebugWindowController: NSWindowController {
    
    @IBOutlet var tfDetails: NSTextView!
    @IBOutlet weak var allowDownloadWhileGetFileList: NSButton!
    @IBOutlet weak var shouldLogEvent: NSButton!
    @IBOutlet weak var shouldLogNetwork: NSButton!
    @IBOutlet weak var shouldLogFile: NSButton!
    @IBOutlet weak var showRunningEvent: NSButton!
    @IBOutlet weak var shouldUseMD5: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        allowDownloadWhileGetFileList.state = HCDUserDefaults.allowDownloadWhileGettingFileList ? NSOnState : NSOffState
        HCDNotificationHelper.addObserver(notif: .postDebugMessage, target: self, selector: #selector(showDetail))
        
        shouldLogEvent.state    = HCDLog.Config.shouldLogEvent      ? NSOnState : NSOffState
        shouldLogNetwork.state  = HCDLog.Config.shouldLogNetWork    ? NSOnState : NSOffState
        shouldLogFile.state     = HCDLog.Config.shouldLogFileAction ? NSOnState : NSOffState
        shouldUseMD5.state      = HCDUserDefaults.shouldUseMD5           ? NSOnState : NSOffState
    }
    
    @objc func showDetail(_ notif: Notification) {
        guard showRunningEvent.state == NSOnState else {
            return
        }
        
        let text = notif.object as! String
        DispatchQueue.main.async {
            self.presentText(text: text)
        }
    }
    
    func presentText(text: String) {
        tfDetails.string = text
    }
    
    @IBAction func didClickResetApp(_ sender: NSButton) {
        HCDUtilityHelper.clearSyncFolderWithoutSyncToServer()
        HCDUtilityHelper.clearAllData()
        didClickHideDebugTools(sender)
        HCDUtilityHelper.quitApp()
    }
    @IBAction func didClickGetServerEvent(_ sender: Any) {
        HCDNotificationHelper.post(notificaion: .shouldRequestServerEvent)
    }
    @IBAction func didClickOpenLog(_ sender: NSButton) {
        if let logURL = HCDLog.fileUrl {
            NSWorkspace.shared().open(logURL)
        }
        HCDPrint.debug("should show log")
    }
    @IBAction func didClickOpenDatabaseFolder(_ sender: NSButton) {
        if let databaseURL = HCDDataManager.databaseFolderURL {
            NSWorkspace.shared().open(databaseURL)
        }
    }
    @IBAction func didClickOpenSyncFolder(_ sender: NSButton) { // change to comapre list
        
        let localBook  = HCDFileListManager.localFileBook
        let serverBook = HCDFileListManager.serverFileBook
        
        var report =
        "\(localBook) file count: \(localBook.fileCount)\n"
        + "\(serverBook) file count: \(serverBook.fileCount)\n"
        
        serverBook.enumerateAllItemThat(notInBook: localBook) {
            report += "[server]\($0.path)\n"
        }
        
        localBook.enumerateAllItemThat(notInBook: serverBook) {
            report += "[local]\($0.path)\n"
        }
        
        presentText(text: report)
        HCDPrint.debug("Compare result:")
        HCDPrint.debug(report)
        HCDPrint.debug("End compare result")
    }
    @IBAction func didClickHideDebugTools(_ sender: NSButton) {
        HCDLog.debugTools(enable: false)
        HCDNotificationHelper.post(notificaion: .shouldShowDebugToolChanged)
        self.close()
    }
    
    @IBAction func didClickShowingLog(_ sender: NSButton) {
        let isON = sender.state == NSOnState
        switch sender.title {
        case "Event":
            HCDLog.Config.shouldLogEvent        = isON
        case "Network":
            HCDLog.Config.shouldLogNetWork      = isON
        case "File Action":
            HCDLog.Config.shouldLogFileAction   = isON
        case "Notification":
            HCDLog.Config.shouldLogNotification = isON
        case "Allow download while getting file list after reset app":
            HCDUserDefaults.allowDownloadWhileGettingFileList  = isON
        case "Use MD5":
            HCDUserDefaults.shouldUseMD5 = isON
        default:
            break
        }
    }
}
