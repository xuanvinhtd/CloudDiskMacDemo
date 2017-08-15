//
//  HCDSelectSyncFolder.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 1/17/17.
//  Copyright © 2017 Hanbiro Inc. All rights reserved.
//

import Cocoa

class HCDSelectSyncFolder: NSWindowController {

    @IBOutlet weak var submitButton: NSButton!
    @IBOutlet weak var selectedPath: NSTextField!
    @IBOutlet weak var openAtLoginCBB: NSButton!
    @IBOutlet weak var chooseFolderButton: NSButton!
    @IBOutlet weak var cancelButton: NSButtonCell!
    var selectedURL: URL!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        changeLanguage()
        HCDNotificationHelper.addObserver(notif: .LCLLanguageChangeNotification, target: self, selector: #selector(changeLanguage))
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    deinit {
        HCDNotificationHelper.removeObserverFromTarget(target: self, withNotif: .LCLLanguageChangeNotification)
    }
    
    @objc fileprivate func changeLanguage() {
        DispatchQueue.main.async {
            self.selectedPath.stringValue = "Please choose the location you wish to store your sync folder".localized
            
            self.openAtLoginCBB.title = "Open at login to sync files automatically".localized
            self.submitButton.stringValue = "Next".localized
            self.chooseFolderButton.stringValue = "Choose Sync Folder".localized
            self.cancelButton.stringValue = "Cancel".localized
        }
    }
    
    @IBAction func didClickOpenAtLogin(_ sender: NSButton) {
        HCDUtilityHelper.setOpenAtLogin(sender.state == NSOnState)
    }
    
    @IBAction func didClickChoose(_ sender: NSButton) {
        HCDUtilityHelper.selectSyncFolder() {
            selectedURL = $0
            self.selectedPath.stringValue   = "Your sync folder: ".localized + $0.path
            self.selectedPath.textColor     = NSColor.black
            self.submitButton.isEnabled     = true
        }
    }
    
    @IBAction func didClickSubmit(_ sender: Any) {
        HCDUtilityHelper.commitSyncURL(selectedURL)
    }
    
    @IBAction func didClickQuit(_ sender: NSButton) {
        HCDUtilityHelper.quitApp()
    }
}
