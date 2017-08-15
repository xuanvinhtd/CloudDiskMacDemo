//
//  HCDKeychainManager.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 10/17/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Locksmith

class HCDKeychainManager {
    static internal let defaultManager = HCDKeychainManager()
    
    static private let userAccountFromKeychain = "hanbiro-autosync-cloudisk"
    static private let keyForPassword = "password"

    private var data: HCDLoginInputInformationVT? {
        let dictionary = Locksmith.loadDataForUserAccount(userAccount: HCDKeychainManager.userAccountFromKeychain)
        guard let domain = HCDUserDefaults.savedDomain,
            let username = HCDUserDefaults.savedUserName,
            let password = dictionary?[HCDKeychainManager.keyForPassword] as? String
        else {
            return nil
        }
        return HCDLoginInputInformationVT(domain: domain, userID: username, userPassword: password)
    }
    
    static var data: HCDLoginInputInformationVT? {
        return defaultManager.data
    }
    

    private func saveToKeyChain(domain: String, username: String, password: String) {
        // Store to user default
        HCDUserDefaults.savedDomain   = domain
        HCDUserDefaults.savedUserName = username
        
        // Store to keychain
        let rawData = [
            HCDKeychainManager.keyForPassword: password
        ]
        do {
            if self.data != nil {
                try Locksmith.updateData(
                    data: rawData,
                    forUserAccount: HCDKeychainManager.userAccountFromKeychain
                )
            } else {
                try Locksmith.saveData(
                    data: rawData,
                    forUserAccount: HCDKeychainManager.userAccountFromKeychain
                )
            }
        } catch {
            HCDPrint.error(error)
        }
    }
    
    private func save(data: HCDLoginInputInformationVT) {
        saveToKeyChain(domain: data.domain, username: data.userID, password: data.userPassword)
    }
    
    static func save(data: HCDLoginInputInformationVT) {
        defaultManager.save(data: data)
    }

    private func deleteData() {
        do {
            try Locksmith.deleteDataForUserAccount(userAccount: HCDKeychainManager.userAccountFromKeychain)
        } catch {
            HCDPrint.error(error)
        }
    }
    
    static func deleteData() {
        defaultManager.deleteData()
    }
}
