//
//  HCDPreferencesWindow.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 12/14/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Cocoa
import MASPreferences

protocol HCDPreferencesController: MASPreferencesViewController {
    
}

class HCDPreferencesWindow: MASPreferencesWindowController {
    
    
    static var defaultController: HCDPreferencesWindow {
        let generalCtl = HCDGeneralPreferencesViewController(nibName: "HCDGeneralPreferencesViewController", bundle: nil)!
        let accountCtl = HCDAccountPreferencesViewController(nibName: "HCDAccountPreferencesViewController", bundle: nil)!
        let aboutCtl = HCDAboutPreferencesViewController(nibName: "HCDAboutPreferencesViewController", bundle: nil)!
        return HCDPreferencesWindow(viewControllers: [generalCtl, accountCtl, aboutCtl], title: "Preferences")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
