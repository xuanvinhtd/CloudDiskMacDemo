//
//  HCDLoginManager.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/21/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import PromiseKit

class HCDLoginManager {
    internal static let defaultManager = HCDLoginManager()
}

extension HCDLoginManager {
    static func promiseAutoLogin() -> Promise<()> {
        guard let data = HCDLoginInformationManager.lastLoginInput else {
            return Promise(error: HCDError.noDataInKeyChain)
        }
        HCDNotificationHelper.post(message: "Login to account".localized + " \(data.userID)...")
        
        return self.promiseLoginWithInfo(info: data).recover {_ in
            return after(interval: 60.0).then { promiseLoginWithInfo(info: data) }
        }
    }

    static func promiseLoginWithInfo(info: HCDLoginInputInformationVT) -> Promise<()> {
        HCDLoginInformationManager.storeLoginInputInfo(info: info)

        guard let fullInfo = HCDLoginInformationManager.loginCompleteInfo else {
            return Promise(error: HCDError.notEnoughResourceForRequest)
        }
        
        let router = HCDPostRouter.login(fullInfo)
        
        let storeResult: (Data)->Promise<()> = {
            guard let session = HCDNetworkDataConverter.Response.Login.fromData($0) else {
                return Promise(error: HCDError.loginResultNil)
            }
            HCDLoginInformationManager.storeSession(session: session)
            
            if HCDLoginInformationManager.isLogin {
                HCDPrint.info("Login successes")
                HCDNotificationHelper.post(message: "Success login to account".localized + " \(HCDLoginInformationManager.loginCompleteInfo!.ID)")
                return Promise(value: ())
            } else {
                return Promise(error: HCDError.wrongUserNameOrPassword)
            }
        }
        
        HCDPrint.info("Start login for user: \(info.userID)")
        
        return HCDNetworkManager.promiseRequestPostMethod(router: router).then {
            storeResult($0)
        }
    }
    
    static func logout() {
        //remove login session
        HCDLoginInformationManager.removeLoginSession()
        
        //delete stored keychain
        HCDKeychainManager.deleteData()
        
        //delete user default data
        HCDUserDefaults.resetNeededKeyForLogout()
        
        //delete database
        HCDItemBook.deleteAllBook()
        HCDEventDataManager.defaultManager().deleteAll()
        
        //reset sync state
        HCDSyncManager.reset()
        
        HCDUtilityHelper.setOpenAtLogin(false)
        HCDUtilityHelper.restartApp()
    }
}

struct HCDLoginAPI: HCDPLoginAPI {
    func promiseLoginWithInfo(info: HCDLoginInputInformationVT) -> Promise<()> {
        return HCDLoginManager.promiseLoginWithInfo(info: info)
    }
}
