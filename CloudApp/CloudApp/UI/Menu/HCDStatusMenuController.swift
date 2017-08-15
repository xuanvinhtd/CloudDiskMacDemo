//
//  HCDStatusMenuController.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 11/2/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Cocoa

protocol HCDPViewControllerSegue: class {
    func switchToSelectFolderView()
    func backToLoginView()
}


class HCDStatusMenuController: NSObject {
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    lazy var debugToolWindow: HCDDebugWindowController? = HCDDebugWindowController(windowNibName: "HCDDebugWindowController")
    lazy var selectSyncFolderWindow: HCDSelectSyncFolder = HCDSelectSyncFolder(windowNibName: "HCDSelectSyncFolder")
    lazy var syncFailsWindow: HCDSyncFailsWindowController = HCDSyncFailsWindowController(windowNibName: "HCDSyncFailsWindowController")

    var preferencesWindow = HCDPreferencesWindow.defaultController
    
    @IBOutlet weak var versionShowing: NSMenuItem!
    @IBOutlet weak var loginMenuItem: NSMenuItem!
    @IBOutlet weak var syncPausedLabel: NSMenuItem!
    @IBOutlet weak var processMenuItem: NSMenuItem!
    @IBOutlet weak var countFileNeedToSync: NSMenuItem!
    @IBOutlet weak var syncCommandMenuItem: NSMenuItem!
    @IBOutlet weak var debugToolItem: NSMenuItem!
    @IBOutlet weak var preferencesMenuItem: NSMenuItem!
    @IBOutlet weak var openCloudFolderItem: NSMenuItem!
    @IBOutlet weak var quitItem: NSMenuItem!
    @IBOutlet weak var syncErrorCountMenuItem: NSMenuItem!
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    
    lazy var loginWindowController: NSWindowController = {
        let loginVC                 = HCDLoginViewController(nibName: "HCDLoginViewController", bundle: nil)!
        loginVC.segueDelegate       = self
        let loginWindow             = NSWindow(contentViewController: loginVC)
        loginWindow.title           = "Login".localized
        let loginWindowController   = NSWindowController(window: loginWindow)
        return loginWindowController
    }()
    
    @objc func setupItemsState() {
        setupWhenShowDebugTool()
        DispatchQueue.main.async {
            self.setMenuIconImage(enable: false)
        }
    }
    
    @objc func setupWhenShowDebugTool() {
        versionShowing.title            = "Version".localized + ": \(HCDGlobalDefine.appVersion)"
        openCloudFolderItem.isHidden    = HCDUserDefaults.syncFolderPath == nil
        versionShowing.isHidden         = !HCDUserDefaults.openDebugTools
        debugToolItem.isHidden          = !HCDUserDefaults.openDebugTools
        
        DispatchQueue.main.async {
            let paused = HCDUserDefaults.userWantToPauseSync
            self.syncCommandMenuItem.title  = paused ? "Resume Syncing".localized : "Pause Syncing".localized
            self.processMenuItem.isHidden   = paused || !HCDLoginInformationManager.canAutoLogin || HCDUserDefaults.syncFolderPath == nil
            self.syncPausedLabel.isHidden   = !paused || !HCDLoginInformationManager.canAutoLogin || HCDUserDefaults.syncFolderPath == nil
        }
    }
    
    func setupMenuIcon() {
        statusItem.menu = statusMenu
        setMenuIconAndHideCountEventForIdling()
        
        if HCDEventTakingManager.remainErrorEvent == 0 {
           syncErrorCountMenuItem.isHidden = true
        } else {
            syncErrorCountMenuItem.isHidden = false
            syncErrorCountMenuItem.attributedTitle = NSAttributedString(string: "Sync fail: ".localized + String(HCDEventTakingManager.remainErrorEvent) + " item".localized, attributes:  [NSFontAttributeName : NSFont.systemFont(ofSize: 14.0),NSForegroundColorAttributeName : NSColor.red])
            if HCDUserDefaults.showFormSyncFails {
                self.syncFailsWindow.showWindow(nil)
            }
        }
    }
    
    func updateDetail(isLoggedin: Bool) {
        if isLoggedin {
            loginWindowController.close()
        }
        
        processMenuItem.isHidden     = !isLoggedin
        preferencesMenuItem.isHidden = !isLoggedin
        syncCommandMenuItem.isHidden = !isLoggedin
        loginMenuItem.isHidden       = isLoggedin
    }
    
    @objc fileprivate func changeLanguage() {
        DispatchQueue.main.async {
            self.preferencesMenuItem.title = "Preferences".localized
            self.openCloudFolderItem.title = "Open cloud folder".localized
            self.loginMenuItem.title = "Login".localized
            
            let paused = HCDUserDefaults.userWantToPauseSync
            self.syncCommandMenuItem.title  = paused ? "Resume Syncing".localized : "Pause Syncing".localized
            self.processMenuItem.title = "✓ " + "sync completed".localized
            //self.countFileNeedToSync.title = "✓ " + "sync completed".localized
            self.syncPausedLabel.title = "Pause Syncing".localized
            self.quitItem.title = "Quit".localized
        }
    }
    
    override func awakeFromNib() {
        //#APP BEGIN HERE!
        //create sync root if needed (mostly use after reset app)
        HCDUtilityHelper.appGlobalSetup()

        setupMenuIcon()
        setupItemsState()
        addNeededObserver()
//        updateDetail(isLoggedin: false)
        tryAutoLogin()
        
        //LANGUAGE
        changeLanguage()
    }
    
    deinit {
        HCDNotificationHelper.removeObserverFromTarget(target: self)
    }
    
    @IBAction func didClickLogin(_ sender: NSMenuItem) {
        if sender.title == loginItemTitleWhenSelectSyncFolder() {
            showSelectSyncFolder()
        } else {
            showLoginWindow()
        }
    }
    @IBAction func DidClickChangeSyncStatus(_ sender: NSMenuItem) {
        HCDUserDefaults.userWantToPauseSync = !HCDUserDefaults.userWantToPauseSync
        HCDNotificationHelper.post(notificaion: .userDidChangeSyncStatus)
    }
    @IBAction func didClickPreferences(_ sender: NSMenuItem) {
        preferencesWindow.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    @IBAction func didClickShowFolder(sender: AnyObject) {
        let rootPath = HCDFileManager.syncFolderRoot(createIfNeeded: true)
        NSWorkspace.shared().openFile(rootPath)
    }
    @IBAction func didClickQuit(sender: AnyObject) {
        NSApplication.shared().terminate(self)
    }

    @IBAction func showFileSyncFail(_ sender: Any) {
        self.syncFailsWindow.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    //MARK: DEBUG
    @IBAction func didClickShowDebugTools(_ sender: NSMenuItem) {
        self.debugToolWindow?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension HCDStatusMenuController {
    enum MenuIconState {
        case enable
    }
    
    internal func setMenuIconImage(enable: Bool) {
        let iconName     = HCDUserDefaults.userWantToPauseSync ?
                            "cloud-pause":
                            enable ? "cloud-active" : "cloud-inactive"
        let icon         = NSImage(named: iconName)!
        icon.isTemplate  = true // best for dark mode
        statusItem.image = icon
    }
    
    @objc private func setMenuIconAndShowCountEventForRunning() {
        DispatchQueue.main.async {
            self.setMenuIconImage(enable: true)
        }
        if !HCDUserDefaults.didCompleteFirstTimeGetServerFileList {
            countFileNeedToSync.isHidden = false
        }
    }
    
    @objc internal func setMenuIconAndHideCountEventForIdling() {
        DispatchQueue.main.async {
            self.setMenuIconImage(enable: false)
        }
        countFileNeedToSync.isHidden = true
    }
    
    @objc private func displayEventCounter(_ notif: Notification) {
        guard !HCDUserDefaults.userWantToPauseSync else {
            return
        }
        let text = notif.object as! String
        DispatchQueue.main.async {
            self.countFileNeedToSync.title = text
        }
    }
    
    @objc private func displayEventErrorCounter(_ notif: Notification) {
        guard !HCDUserDefaults.userWantToPauseSync else {
            return
        }
        if HCDEventTakingManager.remainErrorEvent == 0 && self.syncErrorCountMenuItem.isHidden == false {
            self.syncErrorCountMenuItem.isHidden = true
            DispatchQueue.main.async {
               self.syncFailsWindow.close()
            }
        } else if(HCDEventTakingManager.remainErrorEvent != 0) {
            self.syncErrorCountMenuItem.isHidden = false
            DispatchQueue.main.async {
                self.syncErrorCountMenuItem.isHidden = false
                self.syncErrorCountMenuItem.attributedTitle = NSAttributedString(string: "Sync fail: ".localized + String(HCDEventTakingManager.remainErrorEvent) + " item".localized, attributes:  [NSFontAttributeName : NSFont.systemFont(ofSize: 14.0),NSForegroundColorAttributeName : NSColor.red])
            }
            if HCDUserDefaults.showFormSyncFails {
                DispatchQueue.main.async {
                self.syncFailsWindow.showWindow(nil)
                NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
    
    @objc func showProcessMessage(_ notif: Notification) {
        guard !HCDUserDefaults.userWantToPauseSync else {
            return
        }
        let text = notif.object as! String
        DispatchQueue.main.async {
            self.processMenuItem.title = text
        }
    }
    
    @objc func showUpdateAppMessage(_ notif: Notification) {
        let numberVersion = notif.object as! String
        let user = ["appID":notif.userInfo?["appID"]]
        HCDUtilityHelper.createUserNotification(with: "New version".localized + " \(numberVersion)", info: "Please update new version.".localized, userInfo: user)
    }

    func addNeededObserver() {
        HCDNotificationHelper.addObserver(notif: .appIsRunning, target: self, selector: #selector(setMenuIconAndShowCountEventForRunning))
        HCDNotificationHelper.addObserver(notif: .appIsIdling, target: self, selector: #selector(setMenuIconAndHideCountEventForIdling))
        HCDNotificationHelper.addObserver(notif: .countErrorEvent, target: self, selector: #selector(displayEventErrorCounter))
        HCDNotificationHelper.addObserver(notif: .showMessage, target: self, selector: #selector(displayEventCounter))
        HCDNotificationHelper.addObserver(notif: .postMessage, target: self, selector: #selector(showProcessMessage))
        
        HCDNotificationHelper.addObserver(notif: .shouldShowDebugToolChanged, target: self, selector: #selector(setupWhenShowDebugTool))
        HCDNotificationHelper.addObserver(notif: .userDidChangeSyncStatus, target: self, selector: #selector(setupItemsState))
        HCDNotificationHelper.addObserver(notif: .LCLLanguageChangeNotification, target: self, selector: #selector(changeLanguage))
        
        HCDNotificationHelper.addObserver(notif: .haveNewVersion, target: self, selector: #selector(showUpdateAppMessage))
    }
    
}

extension HCDStatusMenuController {
    func switchToMainUI() {
        HCDSyncManager.prepareWhenHasKeyChain()
        updateDetail(isLoggedin: true)
    }

    func tryAutoLogin() {
        self.loginMenuItem.isHidden = true
        
        if HCDLoginInformationManager.canAutoLogin && HCDUserDefaults.syncFolderPath != nil {
            switchToMainUI()
            HCDSyncManager.autoLoginThenStart()
        } else {
            self.backToLoginView()
        }
    }
}

extension HCDStatusMenuController {
    func showLoginWindow() {
        loginWindowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func loginItemTitleWhenSelectSyncFolder() -> String {
        return "Choose Sync Folder".localized
    }
    
    func showSelectSyncFolder() {
        self.loginMenuItem.title = loginItemTitleWhenSelectSyncFolder()
        self.selectSyncFolderWindow.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension HCDStatusMenuController: HCDPViewControllerSegue {
    
    func switchToSelectFolderView() {
        self.loginWindowController.close()
        if let syncPath = HCDUserDefaults.syncFolderPath, !syncPath.isEmpty {
            switchToMainUI()
            HCDSyncManager.start()
        } else {
            showSelectSyncFolder()
        }
    }
    
    func backToLoginView() {
        updateDetail(isLoggedin: false)
        showLoginWindow()
    }
}
