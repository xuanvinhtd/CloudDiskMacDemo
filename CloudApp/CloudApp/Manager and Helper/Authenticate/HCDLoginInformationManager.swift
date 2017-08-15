//
//  HCDLoginInformationManager.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/21/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

class HCDLoginInformationManager {
    internal static let defaultManager = HCDLoginInformationManager()
    
    internal var loginInputInfo: HCDLoginInputInformationVT?
    internal lazy var deviceInfo: HCDDeviceInformationVT = {
        return HCDUtilityHelper.getDeviceInfo()
    }()
    
    internal var _session: String? = nil
}

extension HCDLoginInformationManager {
    internal var loginCompleteInfo: HCDLoginCompleteInformationVT? {
        guard  let loginInputInfo = loginInputInfo else {
            return nil
        }
        return HCDLoginCompleteInformationVT(
            ID: loginInputInfo.userID,
            password: loginInputInfo.userPassword,
            pcName: deviceInfo.deviceName,
            mac: deviceInfo.macAddress,
            encode: HCDGlobalDefine.LoginInfo.encode,
            ver: "\(HCDGlobalDefine.appVersion)"
        )
    }
    
    static var loginCompleteInfo: HCDLoginCompleteInformationVT? {
        return defaultManager.loginCompleteInfo
    }
    
    static func storeLoginInputInfo(info: HCDLoginInputInformationVT) {
        defaultManager.loginInputInfo = info
    }
    
}

extension HCDLoginInformationManager {
    private var isLogin: Bool {
        return session != nil
            && session!.isEmpty == false
            && session != HCDGlobalDefine.LoginInfo.failedCode
    }
    
    static var isLogin: Bool {
        return defaultManager.isLogin
    }
    
    private var session: String? {
        return _session
    }
    
    static var session: String? {
        return defaultManager.session
    }

    private func saveSession(session: String?) {
        _session = session
    }

    static func storeSession(session: String) {
        defaultManager.saveSession(session: session)
    }
    
    static func removeLoginSession() {
        defaultManager.saveSession(session: nil)
    }
    
}

extension HCDLoginInformationManager {
    static var domain: String? {
        return defaultManager.loginInputInfo?.domain
    }
    static var userName: String? {
        return defaultManager.loginInputInfo?.userID
    }
}

extension HCDLoginInformationManager {
    static var lastLoginInput: HCDLoginInputInformationVT? {
        return HCDKeychainManager.data
    }
    
    static var canAutoLogin: Bool {
        return HCDKeychainManager.data != nil
    }
}
