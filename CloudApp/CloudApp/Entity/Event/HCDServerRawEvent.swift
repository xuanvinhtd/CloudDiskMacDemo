//
//  HCDServerFileEvent.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 9/19/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

struct HCDServerRawEvent {
    let type: HCDGlobalDefine.API.WorkList.ActionType
    let ID: String
    let key: String
    let name: String
    let isFolder: Bool
    let path: String
    let size: String?
    let md5: String?
    let pkey: String?
    let time: String?
    let timezone: String?
    
    init?(type: String, dictionary: [String: String], path: String) {
        guard let actionType = HCDGlobalDefine.API.WorkList.ActionType(rawValue: type) else {
            return nil
        }
        self.type = actionType
        
        self.path = path
        self.ID         = dictionary[HCDGlobalDefine.API.WorkList.Key.ID]!
        self.key        = dictionary[HCDGlobalDefine.API.WorkList.Key.key]!
        self.name       = dictionary[HCDGlobalDefine.API.WorkList.Key.name]!
        self.isFolder   = dictionary[HCDGlobalDefine.API.WorkList.Key.folder]! == HCDGlobalDefine.API.WorkList.IsFolderValue.isFolder
        
        self.size       = dictionary[HCDGlobalDefine.API.WorkList.Key.size]
        self.md5        = dictionary[HCDGlobalDefine.API.WorkList.Key.md5]
        self.pkey       = dictionary[HCDGlobalDefine.API.WorkList.Key.pkey]
        self.time       = dictionary[HCDGlobalDefine.API.WorkList.Key.time]
        self.timezone   = dictionary[HCDGlobalDefine.API.WorkList.Key.timezone]        
    }
}

extension HCDServerRawEvent {
    init(brokenAddEventfromItem item: HCDItem) {
        self.type = .add
        
        //defined values
        self.isFolder = item.isDir
        self.path = item.path
        self.key = item.key!
        self.size = item.size
        self.pkey = item.parentKey
        self.time = item.modifyTime
        self.md5 = item.md5
        
        //broken values
        self.ID = ""
        self.name = ""
        self.timezone = nil
    }
}
