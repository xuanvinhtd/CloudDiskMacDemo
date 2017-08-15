//
//  HCDServerFileEvent.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 10/3/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

struct HCDServerEvent: HCDPServerEvent {
    var createdByComparingFileList: Bool = false 
    let fromLocal: Bool
    let eventType: HCDEventType
    let isDir: Bool
    let path: String
    let newPath: String
    let identified: String

    let serverEventType: HCDGlobalDefine.API.WorkList.ActionType
    
    init(detailType: HCDGlobalDefine.API.WorkList.ActionType, isDir: Bool, path: String, newPath: String) {
        self.serverEventType = detailType
        self.path = path
        self.isDir = isDir
        self.newPath = newPath
        
        self.fromLocal = false
        self.eventType = HCDEventType(fromServerEventType: self.serverEventType)
        self.identified = HCDEventHelper.getIdentified(fromLocal: false,
                                                       isDir: self.isDir,
                                                       eventString: self.serverEventType.rawValue,
                                                       path: self.path,
                                                       newPath: self.newPath)
    }
    
    init(fromRawEvent event: HCDServerRawEvent) {
        self.init(
            detailType: event.type,
            isDir: event.isFolder,
            path: event.path,
            newPath: event.type == .rename || event.type == .move ? event.name : ""
        )
    }
    
}
