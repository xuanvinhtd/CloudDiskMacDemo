//
//  HCDFileDirInformation.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 9/7/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation

struct HCDItem {
    //MARK: - MUST HAS
    let path: String
    let name: String
    let isDir: Bool
    let modifyTime: String // should be NSDate ? or Number ?
    let key: String?
    //MARK: - FILE ONLY
    let md5: String?
    let size: String?
    let parentKey: String? // only use for get sync folder key at the moment
}

extension HCDItem {
    func item(withNewKey newKey: String) -> HCDItem {
        return HCDItem(
            path: self.path,
            name: self.name,
            isDir: self.isDir,
            modifyTime: self.modifyTime,
            key: newKey,
            md5: self.md5,
            size: self.size,
            parentKey: self.parentKey
        )
    }
}

extension HCDItem {
    init(path: String, name: String, isDir: Bool, modifyTime: String?, key: String?, md5: String?, size: String?, parentKey: String?) {
        self.path = path
        self.name = name
        self.isDir = isDir
        self.modifyTime = modifyTime ?? ""
        self.key = key
        self.md5 = md5
        self.size = size
        self.parentKey = parentKey
    }    
}

extension HCDItem {
    static func rootItem() -> HCDItem {
        return HCDItem(
            path: "",
            name: "",
            isDir: true,
            modifyTime: nil,
            key: nil,
            md5: nil,
            size: nil,
            parentKey: nil
        )
    }
    
    init(fromRawItem info: HCDRawItemFromServerList, andParentPath parentPath: String) {
        name = info.name
        isDir = info.type == .directory
        modifyTime = info.time
        key = info.key
        md5 = info.md5
        path = parentPath.appending(pathComponent: info.name)
        size = info.size
        parentKey = info.pkey
    }
    
    init(fromServerRawEvent event: HCDServerRawEvent) {
        self.path = event.path
        self.name = event.path.lastPathComponent
        self.isDir = event.isFolder
        self.modifyTime = event.time ?? ""
        self.key = event.key
        self.md5 = event.md5
        self.size = event.size
        self.parentKey = event.pkey
    }
}

extension HCDItem {
    init(fromFileAttribute fileAttributes: [FileAttributeKey: Any], path: String) {
        let name: String = path.lastPathComponent
        let itemIsDir = fileAttributes[FileAttributeKey.type] as? String == FileAttributeType.typeDirectory.rawValue
        let modifyTime = fileAttributes[FileAttributeKey.modificationDate] as? NSDate
        let modifyTimeString = modifyTime?.toString()
        let size = fileAttributes[FileAttributeKey.size] as? Int
        let sizeString: String? = size != nil ? "\(size!)" : nil
        
        self.init(
            path: path,
            name: name,
            isDir: itemIsDir,
            modifyTime: modifyTimeString,
            key: nil,
            md5: nil,
            size: sizeString,
            parentKey: nil
        )
    }
}

extension HCDItem {
//    var toDictionary: [String: Any] {
//        var dict: [String: Any] = [
//            "path"      : path,
//            "name"      : name,
//            "isDir"     : isDir,
//            "modifyTime": modifyTime
//        ]
//        dict["key"] = key
//        dict["md5"] = md5
//        dict["size"] = size
//        dict["parentKey"] = parentKey
//
//        return dict
//    }
    
    var toLocalEventWithTypeCreated: HCDLocalEvent {
        var event = HCDLocalEvent.init(eventCreateFromItem: self)
        event.createdByComparingFileList = true
        return event
    }
    
    var toServerEventWithTypeAdded: HCDServerEvent {
        var event = HCDServerEvent(
            fromRawEvent: HCDServerRawEvent(
                brokenAddEventfromItem:self
            )
        )
        event.createdByComparingFileList = true
        return event
    }
}
