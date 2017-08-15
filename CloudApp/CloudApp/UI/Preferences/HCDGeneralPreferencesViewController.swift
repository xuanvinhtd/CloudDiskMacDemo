//
//  HCDGeneralPreferencesViewController.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 12/14/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Cocoa

class HCDGeneralPreferencesViewController: HCDBaseViewController, HCDPreferencesController {

    override var identifier: String? { get {return "general"} set { super.identifier = newValue} }
    
    var langs = [String: String]()
    
    var toolbarItemLabel: String? {
        return "General"
    }
    
    var toolbarItemImage: NSImage? {
        return NSImage(named: "General_icon")
    }
    
    @IBOutlet weak var changeSyncFolderButton: NSButton!
    @IBOutlet weak var syncFolderLabel: NSTextField!
    @IBOutlet weak var languageLabel: NSTextField!
    @IBOutlet weak var doNotShowSyncFailsAgian: NSButton!
    @IBOutlet weak var displayNofication: NSButton!
    @IBOutlet weak var langComboBox: NSPopUpButton!
    @IBOutlet weak var btnOpenAtLogin: NSButton!
    @IBOutlet weak var labelRootFolder: NSTextField!
    
    func updateDetail() {
        btnOpenAtLogin.state            = HCDUserDefaults.openAtLogin ? NSOnState : NSOffState
        doNotShowSyncFailsAgian.state   = !HCDUserDefaults.showFormSyncFails ? NSOnState : NSOffState
        displayNofication.state         = HCDUserDefaults.showNotificationWhenSyncDone ? NSOnState : NSOffState
        labelRootFolder.stringValue     = HCDPathHelper.syncRootDirectory.stringByAddingSlash
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        updateDetail()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateDetail()
        //Language
        langs = [HCDGlobalDefine.Languge.English.rawValue: "English",
                     HCDGlobalDefine.Languge.Korean.rawValue: "Korean"]
        langs.forEach { (_, value) in
            langComboBox.addItem(withTitle: value)
        }
        let currentLang = Localize.currentLanguage()
        langComboBox.selectItem(withTitle: langs[currentLang] ?? "en")
        
        changeLanguage()
        
        HCDNotificationHelper.addObserver(notif: .LCLLanguageChangeNotification, target: self, selector: #selector(changeLanguage))
    }
    
    deinit {
        HCDNotificationHelper.removeObserverFromTarget(target: self, withNotif: .LCLLanguageChangeNotification)
    }
    
    @objc fileprivate func changeLanguage() {
        DispatchQueue.main.async {
            self.btnOpenAtLogin.title = "Open At Login".localized
            self.changeSyncFolderButton.title = "Change Sync Folder".localized
            self.syncFolderLabel.stringValue = "Sync Folder:".localized
            self.languageLabel.stringValue = "Language".localized
            self.doNotShowSyncFailsAgian.title = "Do not auto show sync fails.".localized
            self.displayNofication.title = "ShowNotification".localized
        }
    }
    
    @IBAction func showNotification(_ sender: Any) {
        HCDUserDefaults.showNotificationWhenSyncDone = ((sender as AnyObject).state == NSOnState)
    }
    
    @IBAction func doNotShowFormSyncFail(_ sender: Any) {
        HCDUserDefaults.showFormSyncFails = !((sender as AnyObject).state == NSOnState)
    }
    
    @IBAction func clickChooseLang(_ sender: Any) {
        let key = findKeyForValue(langComboBox.titleOfSelectedItem!, dictionary: langs) ?? HCDGlobalDefine.Languge.English.rawValue
        Localize.setCurrentLanguage(key)
        
    }
    
    @IBAction func didClickOpenAtLogin(_ sender: NSButton) {
        HCDUtilityHelper.setOpenAtLogin(sender.state == NSOnState)
        updateDetail()
    }
    
    @IBAction func didClickChangeFolder(_ sender: NSButton) {
        HCDUtilityHelper.selectSyncFolder { url in
            if HCDUtilityHelper.dialogOKCancel(question: "Warning".localized, text: "App Will Restart To Make Change".localized) {
                HCDUtilityHelper.commitSyncURL(url)
            }
        }
    }
    
    func findKeyForValue(_ value: String, dictionary: [String: String]) ->String? {
        for (key, strValue) in dictionary {
            if (value == strValue) {
                return key
            }
        }
        
        return nil
    }
}
