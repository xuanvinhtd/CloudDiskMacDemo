//
//  HCDEvent.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 10/6/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

//MARK: - EVENT TYPE
enum HCDEventType: String {
    case create = "CREATE"
    case remove = "REMOVE"
    case change = "CHANGE"
    
    init(fromServerEventType eventType: HCDGlobalDefine.API.WorkList.ActionType) {
        switch eventType {
        case .add:
            self = .create
        case .remove:
            self = .remove
        case .move, .rename:
            self = .change
        }
    }
    
    init(fromLocalEventType eventType: HCDLocalEventType) {
        switch eventType {
        case .create, .modify, .moveIn:
            self = .create
        case .remove, .moveOut:
            self = .remove
        case .changeDir, .replace, .rename:
            self = .change
        }
    }
}

enum HCDLocalEventType: String {
    case changeDir  = "REDIR" // move around
    case modify     = "MODIFY"
    case moveIn     = "MOVE IN"
    case moveOut    = "MOVE OUT"
    case create     = "CREATE"
    case remove     = "REMOVE"
    case replace    = "REPLACE"
    case rename     = "RENAME"
}

//MARK: - EVENT
protocol HCDPEvent {
    var createdByComparingFileList: Bool {get}
    var fromLocal   : Bool {get}
    var isDir       : Bool {get}
    var eventType   : HCDEventType {get}
    var path        : String {get}
    var newPath     : String {get}
    var identified  : String {get}
}

extension HCDPEvent {
//    func isSameAsEvent(otherEvent: HCDPEvent) -> Bool {
//        return self.eventType == otherEvent.eventType
//            && self.isDir == otherEvent.isDir
//            && self.path == otherEvent.path
//            && self.newPath == otherEvent.newPath
//    }
    
    var legalPath: String {
        return path.decomposedStringWithCanonicalMapping
    }
    
    var legalNewPath: String {
        return newPath.decomposedStringWithCanonicalMapping
    }
    
    var simpleIndentify: String {
        return "[\(isDir ? "DIR ": "FILE")][\(self.eventType.rawValue)][\(self.path)][\(self.newPath)]"
    }
    
    func canBeExecutedAtTheSameTimeWithEvent(otherEvent: HCDPEvent?) -> Bool {
        if let otherEvent = otherEvent {
            return self.eventType == otherEvent.eventType
                && self.eventType != .change
                && self.fromLocal == otherEvent.fromLocal
        } else {
            return true
        }
    }
    
}

//MARK: - LOCAL EVENT
protocol HCDPLocalEvent: HCDPEvent {
    var localEventType: HCDLocalEventType {get}
    var fullPath: String {get}
    var fullNewPath: String {get}
}

//extension HCDLocalEvent {
//    var toDict: [String: AnyObject] {
//        var dict: [String: AnyObject] = [
//            "eventType": localEventType.rawValue,
//            "isDir": isDir,
//            "path": path
//        ]
//        dict["newPath"] = newPath
//        return dict
//    }
//}

//MARK: - SERVER EVENT
protocol HCDPServerEvent: HCDPEvent {
    var serverEventType: HCDGlobalDefine.API.WorkList.ActionType {get}
}

extension HCDPServerEvent {
    var newName: String {
        return self.serverEventType == .rename ?
            self.newPath.lastPathComponent : ""
    }
}

//MARK: - HELPER
struct HCDEventHelper {
    static func getIdentified(fromLocal: Bool, isDir: Bool, eventString: String, path: String, newPath: String) -> String {
        return "[\(fromLocal ? "LOCAL ": "SERVER")][\(isDir ? "DIR ": "FILE")][\(eventString)][\(path)][\(newPath)]"
    }
}


