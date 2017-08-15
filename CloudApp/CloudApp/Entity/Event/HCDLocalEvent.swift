//
//  HCDLocalFileEvent.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 9/20/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

struct HCDLocalEvent: HCDPLocalEvent {
    var createdByComparingFileList: Bool = false 
    let fromLocal: Bool
    let eventType: HCDEventType
    let isDir: Bool
    let path: String
    let newPath: String
    let identified: String
    
    let localEventType: HCDLocalEventType
    let fullPath: String
    let fullNewPath: String
    
    private init(isDir: Bool, type: HCDLocalEventType, path: String, newPath: String?, isFullPath: Bool) {
        self.isDir = isDir
        
        self.fullPath = path
        self.path = isFullPath ? HCDPathHelper.pathFromFullPath(self.fullPath) : self.fullPath
        
        self.fullNewPath = newPath ?? ""
        self.newPath = isFullPath ? HCDPathHelper.pathFromFullPath(self.fullNewPath) : self.fullNewPath
        
        if type == .changeDir && path.deletingLastPathComponent == newPath!.deletingLastPathComponent {
            self.localEventType = .rename
        } else {
            self.localEventType = type
        }
        
        self.fromLocal = true
        self.eventType = HCDEventType(fromLocalEventType: self.localEventType)
        
        self.identified = HCDEventHelper.getIdentified(
            fromLocal: self.fromLocal,
            isDir: self.isDir,
            eventString: self.localEventType.rawValue,
            path: self.path,
            newPath: self.newPath
        )
    }
    
    init(isDir: Bool, type: HCDLocalEventType, fullPath: String, newFullPath: String?) {
        self.init(isDir: isDir, type: type, path: fullPath, newPath: newFullPath, isFullPath: true)
    }
    
    init(isDir: Bool, type: HCDLocalEventType, path: String, newPath: String?) {
        self.init(isDir: isDir, type: type, path: path, newPath: newPath, isFullPath: false)
    }
    
    var splitIfNeeded: [HCDLocalEvent] { // At this time only use for replace, replace = remove + move
        switch self.localEventType {
        case .replace:
            let delete = HCDLocalEvent(isDir: self.isDir, type: .remove   , path: self.newPath, newPath: nil)
            let move   = HCDLocalEvent(isDir: self.isDir, type: .changeDir, path: self.path   , newPath: self.newPath)
            return [delete, move]
        default:
            return [self]
        }
    }
}

extension HCDLocalEvent {
    private init(eventFromItem info: HCDItem, isCreate: Bool) {
        let eventType : HCDLocalEventType = isCreate ? .create : .remove
        self.init(isDir: info.isDir, type: eventType, path: info.path, newPath: nil)
    }
    init(eventCreateFromItem info: HCDItem) {
        self.init(eventFromItem: info, isCreate: true)
    }
}

