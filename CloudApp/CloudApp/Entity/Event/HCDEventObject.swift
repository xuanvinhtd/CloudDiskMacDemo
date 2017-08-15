//
//  HCDEventObject.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/29/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import RealmSwift
import Foundation

class HCDEventObject: Object {
    struct PropertyNames {
        static let fromLocal = "fromLocal"
        static let eventID = "eventID"
        static let eventType = "eventType"
        static let detailEventType = "detailEventType"
        static let isDir = "isDir"
        static let path = "path"
        static let newPath = "otherPath" // use "new***" word like "newPath" will cause critical crash !!!
        static let error = "error"
    }

    dynamic var fromLocal: Bool = true
    dynamic var eventID: Int = 0

    dynamic var eventType: String = ""
    dynamic var detailEventType: String = ""
    dynamic var isDir: Bool = false
    dynamic var path: String = ""
    dynamic var otherPath: String? = nil // don't you dare to use "new***" word like "newPath", you'll summon the devil of bug !!!
    dynamic var error: String? = nil
    dynamic var notes: String = "" //should be use for check stuff only, not recommend use this for query
    
    public override static func indexedProperties() -> [String] {
        return [PropertyNames.eventID, PropertyNames.path]
    }

}

extension HCDEventObject {
    func fromEvent(event: HCDPEvent) {
        fromLocal = event.fromLocal
        eventType = event.eventType.rawValue
        detailEventType = event.fromLocal ?
            (event as! HCDLocalEvent).localEventType.rawValue :
            (event as! HCDServerEvent).serverEventType.rawValue
        isDir = event.isDir
        path = event.path.precomposedStringWithCanonicalMapping
        otherPath = event.newPath.precomposedStringWithCanonicalMapping
    }
    
    var event: HCDPEvent {
        return self.fromLocal ?
            HCDLocalEvent(
                isDir: self.isDir,
                type: HCDLocalEventType(rawValue: self.detailEventType)!,
                path: self.path,
                newPath: self.otherPath
            ) :
            HCDServerEvent(
                detailType: HCDGlobalDefine.API.WorkList.ActionType(rawValue: self.detailEventType)!,
                isDir: self.isDir,
                path: self.path,
                newPath: self.otherPath ?? ""
            )
    }
}

extension HCDEventObject {
    static func fullDictionaryFromEvent(_ event: HCDPEvent) -> [String: Any] {
        return [
            PropertyNames.fromLocal : event.fromLocal,
            PropertyNames.eventType : event.eventType.rawValue,
            PropertyNames.isDir     : event.isDir,
            PropertyNames.path      : event.path.precomposedStringWithCanonicalMapping,
            PropertyNames.newPath   : event.newPath.precomposedStringWithCanonicalMapping
        ]
    }
}
