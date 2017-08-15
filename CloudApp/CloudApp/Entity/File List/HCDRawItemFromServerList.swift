//
//  HCDInfoOfEntityNeedToSync.swift
//  CloudDisk-AutoSync
//
//  Created by Hanbiro Inc on 8/26/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

//Define in Server Filelist's response XML
struct HCDRawItemFromServerList {
    var type: HCDGlobalDefine.API.EntityNeedToSync.EntityType
    
    var name, time, timezone, size, key, pkey, memo, priv, sync, star, notification: String // base attributes
    
    var kind, shared: String? // directory attributes
    var md5: String? // file attribute
    
    init(type: String, dictionary: [String: String]) {
        let entityType = HCDGlobalDefine.API.EntityNeedToSync.EntityType(rawValue: type)
        self.type = entityType != nil ? entityType! : HCDGlobalDefine.API.EntityNeedToSync.EntityType.undefined
        
        self.name = dictionary[HCDGlobalDefine.API.EntityNeedToSync.Key.name]!
        self.time = dictionary[HCDGlobalDefine.API.EntityNeedToSync.Key.time]!
        self.timezone = dictionary[HCDGlobalDefine.API.EntityNeedToSync.Key.timezone]!
        self.size = dictionary[HCDGlobalDefine.API.EntityNeedToSync.Key.size]!
        self.key = dictionary[HCDGlobalDefine.API.EntityNeedToSync.Key.key]!
        self.pkey = dictionary[HCDGlobalDefine.API.EntityNeedToSync.Key.pkey]!
        self.memo = dictionary[HCDGlobalDefine.API.EntityNeedToSync.Key.note]!
        self.priv = dictionary[HCDGlobalDefine.API.EntityNeedToSync.Key.priv]!
        self.sync = dictionary[HCDGlobalDefine.API.EntityNeedToSync.Key.sync]!
        self.star = dictionary[HCDGlobalDefine.API.EntityNeedToSync.Key.star]!
        self.notification = dictionary[HCDGlobalDefine.API.EntityNeedToSync.Key.notification]!
        
        self.kind = dictionary[HCDGlobalDefine.API.EntityNeedToSync.Key.kind]
        self.shared = dictionary[HCDGlobalDefine.API.EntityNeedToSync.Key.shared]
        
        self.md5 = dictionary[HCDGlobalDefine.API.EntityNeedToSync.Key.md5]
    }
}
