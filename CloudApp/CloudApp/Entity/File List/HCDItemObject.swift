//
//  HCDItemObject.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 10/13/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import RealmSwift
import Foundation

public final class HCDItemObject: Object {
    struct PropertyName {
        static let path = "path"
        static let isDir = "isDir"
        static let name = "name"
        static let modifyTime = "modifyTime"
        static let key = "key"
        static let md5 = "md5"
        static let size = "size"
        static let parentKey = "parentKey"
    }
    
    public dynamic var path: String = ""
    public dynamic var isDir: Bool = false
    public dynamic var name: String = ""
    public dynamic var modifyTime: String = ""
    public dynamic var key: String? = nil
    public dynamic var md5: String? = nil
    public dynamic var size: String? = nil
    public dynamic var parentKey: String? = nil
    
//    public override static func primaryKey() -> String? {
//        return "path"
//    }
    public override static func indexedProperties() -> [String] {
        return ["path"]
    }
 }

extension HCDItemObject {
    func from(item: HCDItem) {
        self.path   = item.path.precomposedStringWithCanonicalMapping
        self.isDir  = item.isDir
        self.name   = item.name
        self.key    = item.key
        self.md5    = item.md5
        self.size   = item.size
        self.modifyTime = item.modifyTime
        self.parentKey  = item.parentKey
    }
    
    var item: HCDItem {
        return HCDItem(
            path: path,
            name: name,
            isDir: isDir,
            modifyTime: modifyTime,
            key: key,
            md5: md5,
            size: size,
            parentKey: parentKey
        )
    }
}
