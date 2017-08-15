//
//  HCDLoginViewController.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/21/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import AppKit
import PromiseKit

protocol HCDPLoginAPI {
    func promiseLoginWithInfo(info: HCDLoginInputInformationVT) -> Promise<()>
}

class HCDLoginViewController: HCDBaseViewController {

    @IBOutlet weak var tfDomain: NSTextField!
    @IBOutlet weak var tfUserName: NSTextField!
    @IBOutlet weak var tfPassword: NSSecureTextField!
    @IBOutlet weak var logoLogin: NSImageView!
    @IBOutlet weak var btnLogin: NSButton!
    @IBOutlet weak var spinner: NSProgressIndicator!
    
    let API: HCDPLoginAPI = HCDLoginAPI()
    var segueDelegate: HCDPViewControllerSegue?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        changeLanguage()
        HCDNotificationHelper.addObserver(notif: .LCLLanguageChangeNotification, target: self, selector: #selector(changeLanguage))
        
        #if MOFFICE
            logoLogin.image = NSImage(named: "LogoMoffice")
        #endif
        // Do view setup here.
        tfDomain.stringValue   = HCDUserDefaults.savedDomain   ?? ""
        tfUserName.stringValue = HCDUserDefaults.savedUserName ?? ""
    }
    
    deinit {
        HCDNotificationHelper.removeObserverFromTarget(target: self, withNotif: .LCLLanguageChangeNotification)
    }
    
    @objc fileprivate func changeLanguage() {
        DispatchQueue.main.async {
            self.btnLogin.stringValue = "Login".localized
            self.tfDomain.placeholderString = "Domain".localized
            self.tfPassword.placeholderString = "Password".localized
            self.tfUserName.placeholderString = "User Name".localized
        }
    }
    
    @IBAction func didClickLogin(_ sender: Any) {
        let loginInfo = HCDLoginInputInformationVT(
            domain: tfDomain.stringValue,
            userID: tfUserName.stringValue,
            userPassword: tfPassword.stringValue)
        
        let startLogin = {
            [self.tfDomain, self.tfUserName, self.tfPassword, self.btnLogin].forEach {
                $0.isEnabled = false
            }
            self.spinner.isHidden = false
            self.spinner.startAnimation(nil)
        }
        
        let storeKeyChain: ()->() = {
            HCDPrint.info("Store to key chain")
            let loginInput = HCDLoginInformationManager.defaultManager.loginInputInfo
            HCDKeychainManager.save(data: loginInput!)
        }
        
        let endLogin = {
            [self.tfDomain, self.tfUserName, self.tfPassword, self.btnLogin].forEach {
                $0.isEnabled = true
            }
            self.spinner.isHidden = true
            self.spinner.stopAnimation(nil)
        }
        
        firstly {
            startLogin()
            return API.promiseLoginWithInfo(info: loginInfo)
        }.then {
            storeKeyChain()
        }.then {
            self.segueDelegate?.switchToSelectFolderView()
        }.always {
            endLogin()
        }.catch {
            HCDPrint.error($0)
            self.shack()
        }
    }
}
