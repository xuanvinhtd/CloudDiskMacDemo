//
//  HCDAboutPreferencesViewController.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 12/14/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Cocoa

class HCDAboutPreferencesViewController: HCDBaseViewController, HCDPreferencesController {
    
    @IBOutlet weak var versionLabel: NSTextFieldCell!
    override var identifier: String? { get {return "about"} set { super.identifier = newValue} }
    
    var toolbarItemLabel: String? {
        return "About"
    }
    
    var toolbarItemImage: NSImage? {
        return NSImage(named: "About_icon")
    }
    
    @IBOutlet var changeLog: NSTextView!
    @IBOutlet weak var detailBackgroud: NSView!
    override func viewDidLoad() {
        super.viewDidLoad()
        versionLabel.title = "Version".localized + " " + String(HCDGlobalDefine.appVersion)
        // Do view setup here.
        changeLog.string = HCDGlobalDefine.changeLog
    }
    
}
