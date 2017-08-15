//
//  HCDUserPreferencesViewController.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 12/14/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Cocoa
import PromiseKit

class HCDAccountPreferencesViewController: HCDBaseViewController, HCDPreferencesController {

    override var identifier: String? { get {return "account"} set { super.identifier = newValue} }
    
    var toolbarItemLabel: String? {
        return "Account"
    }
    
    var toolbarItemImage: NSImage? {
        return NSImage(named: "Account_icon")
    }
    
    @IBOutlet weak var logOutButton: NSButtonCell!
    @IBOutlet weak var labelUserName: NSTextField!
    @IBOutlet weak var labelQuota: NSTextField!
    @IBOutlet weak var barQuota: NSLevelIndicator!
    @IBOutlet weak var spinnerQuota: NSProgressIndicator!
    
    func updateDetail() {
        self.logOutButton.title = "Logout".localized
        self.labelQuota.stringValue = "Quota".localized
        if  let username = HCDLoginInformationManager.userName,
            let domain = HCDLoginInformationManager.domain {
            labelUserName.stringValue = "\(username)@\(domain)"
        } else {
            labelUserName.stringValue = "not loged in".localized
        }
        
    }
    
    func updateQuota() {
        let showSpiner: ()->() = {
            self.spinnerQuota.startAnimation(nil)
            self.spinnerQuota.isHidden = false
        }
        let hideSpiner: ()->() = {
            self.spinnerQuota.stopAnimation(nil)
            self.spinnerQuota.isHidden = true
        }
        
        showSpiner()
        firstly {
            HCDNetworkManager.promiseRequestPostMethod(router: .quota)
            }.then {data in
                return Promise<()> { fullfill, reject in
                    if let quota: (Double, Double) = HCDNetworkDataConverter.Response.Quota.fromData(data) {
                        let percent = Int((quota.0 / quota.1) * 100)
                        let used = HCDUtilityHelper.storageValueString(fromBytesCount: quota.0)
                        let total = HCDUtilityHelper.storageValueString(fromBytesCount: quota.1)
                        self.labelQuota.stringValue = "Quota".localized + "\(used)/\(total)"
                        self.barQuota.intValue = Int32(percent)
                        fullfill()
                    } else {
                        self.labelQuota.stringValue = "Quota (can't calculating)".localized
                        reject(HCDError.cannotConvertResponseData)
                    }
                }
            }.always {
                hideSpiner()
            }.catch {
                HCDPrint.error($0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateDetail()
    }
    
    override func viewWillAppear() {
        updateQuota()
    }
    
    @IBAction func didClickLogout(_ sender: NSButton) {
        HCDLoginManager.logout()
    }
    
}
