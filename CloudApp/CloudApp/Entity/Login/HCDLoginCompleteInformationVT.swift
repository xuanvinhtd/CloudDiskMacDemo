//
//  HCDLoginCompleteInformation.swift
//  CloudDisk-AutoSync
//
//  Created by Hanbiro Inc on 8/22/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

struct HCDLoginCompleteInformationVT {
    var ID: String
    var password: String
    
    var pcName: String
    var mac: String
    
    var encode: String
    var ver: String
    
    init?(ID: String, password: String, pcName: String?, mac: String?, encode: String, ver: String) {
        guard let pcName = pcName, let mac = mac else {
            return nil
        }
        guard !ID.isEmpty, !password.isEmpty, !pcName.isEmpty, !mac.isEmpty else {
            return nil
        }
        self.ID = ID
        self.password = password
        self.pcName = pcName
        self.mac = mac
        self.encode = encode
        self.ver = ver
    }
}
