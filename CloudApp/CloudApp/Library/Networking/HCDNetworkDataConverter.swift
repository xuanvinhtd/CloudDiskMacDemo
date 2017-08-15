//
//  HCDNetworkDataHandle.swift
//  CloudDisk-AutoSync
//
//  Created by Hanbiro Inc on 8/25/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import SWXMLHash

struct HCDNetworkDataConverter {
    
    struct Request {
        
        enum UtilityInfo {
            case session
            case pcName
            case folderKey
        }
        
        private static func getWrappedInfo(_ info: UtilityInfo) -> String? {
            var value: String? = nil
            switch info {
            case .session:
                value = HCDLoginInformationManager.session
            case .pcName:
                value = HCDLoginInformationManager.loginCompleteInfo?.pcName
            case .folderKey:
                value = HCDFileListManager.keyForPath(path: "")
            }
            return value?.wrapDoubleQuotes
        }
        
        struct Login {
            static func fromInfo(_ info: HCDLoginCompleteInformationVT) -> String {
                let ID = info.ID.wrapDoubleQuotes
                let password = info.password.wrapDoubleQuotes
                let encode = info.encode.wrapDoubleQuotes
                let pcName = info.pcName.wrapDoubleQuotes
                let mac = info.mac.wrapDoubleQuotes
                let ver = info.ver.wrapDoubleQuotes
                
                let label = HCDGlobalDefine.API.Login.label
                let XMLString = "<XML><\(label) ID=\(ID) PASSWORD=\(password) ENCODE=\(encode) PCNAME=\(pcName) MAC=\(mac) VER=\(ver)></\(label)></XML>" //quite "magic" here
                return XMLString
            }
        }
        
        struct FileList {
            static func fromInfo(_ info: HCDItem) -> String {
                guard let session = HCDNetworkDataConverter.Request.getWrappedInfo(.session) else {
                    return ""
                }
                
                var dirKeyXML: String = ""
                var label = HCDGlobalDefine.API.FileList.syncLabel
                if let key = info.key {
                    let dirKeyLabel = HCDGlobalDefine.API.FileList.dirLabel
                    dirKeyXML = "<\(dirKeyLabel)>\(key)</\(dirKeyLabel)>"
                    if !key.isEmpty {
                        label = HCDGlobalDefine.API.FileList.listLabel
                    }
                }
                
                let sessionKey = HCDGlobalDefine.API.FileList.Key.session
                let sessionXML = "<\(label) \(sessionKey)=\(session)>\(dirKeyXML)</\(label)>"
                let XMLString = "<XML>\(sessionXML)</XML>"
                
                return XMLString
            }
        }
        
        struct WorkList {
            static func lastID() -> String {
                guard let session = HCDNetworkDataConverter.Request.getWrappedInfo(.session) else {
                    return ""
                }
                
                let xml = "<XML><SERVERTIME SESSION=\(session)></SERVERTIME></XML>"
                return xml
            }
            
            static func workList(fromLastEventID ID: String) -> String {
                guard
                    let wrapedSession = HCDNetworkDataConverter.Request.getWrappedInfo(.session),
                    let wrapedPCName = HCDNetworkDataConverter.Request.getWrappedInfo(.pcName)
                else {
                    return ""
                }
                let wrapedID = ID.wrapDoubleQuotes
                
                let xml = "<XML><WORKLIST SESSION=\(wrapedSession) ID=\(wrapedID) PCNAME=\(wrapedPCName)></WORKLIST></XML>"
                return xml
            }
        }
        
        struct SyncAction {
            private static var wrappedSessionPCNameKind: (String, String, String)? {
                guard
                    let wrappedSession = HCDNetworkDataConverter.Request.getWrappedInfo(.session),
                    let wrappedPCName = HCDNetworkDataConverter.Request.getWrappedInfo(.pcName)
                else {
                    return nil
                }
                let wrappedKind = HCDGlobalDefine.API.defaultKindForSyncApi.wrapDoubleQuotes
                return (wrappedSession, wrappedPCName, wrappedKind)
            }
            
            static private func getKey(forPath path: String) -> String? {
                let key = HCDFileListManager.keyForPath(path: path)
                
                if key == nil || key!.isEmpty {
                    HCDPrint.warning("Found key \(key == nil ? "nil": "empty") for path \(path)")
                    return nil
                }
                
                return key
            }
            
            private static func delete(key: String?, path: String?) -> String {
                guard
                    key != nil || path != nil,
                    let info = wrappedSessionPCNameKind
                else {
                    return ""
                }
                
                let elementXMLString = key != nil ? "<KEY KIND = \(info.2)>\(key!)</KEY>" : "<PATH KIND = \(info.2)>\(path!)</PATH>"
                
                let action = HCDGlobalDefine.API.WorkList.ActionType.remove.rawValue
                let xmlString = "<XML><\(action) SESSION=\(info.0) PCNAME=\(info.1)>\(elementXMLString)</\(action)></XML>"
                return xmlString
            }
            
            static func delete(withPath path: String) -> String {
                let key = getKey(forPath: path)
                return delete(key: key, path: path)
            }
            
            private static func change(from: String, to: String, isRenameNotMove: Bool, useKeyNotPath: Bool) -> String {
                guard let info = wrappedSessionPCNameKind else {
                    return ""
                }
                
                let wrappedSession  = info.0
                let wrappedPCName   = info.1
                let wrappedKind     = info.2
                
                let wrappedFrom     = from.wrapDoubleQuotes
                let wrappedTo       = to.wrapDoubleQuotes
                let command         = useKeyNotPath ? "KEY" : "PATH"
                
                let shouldOverride = "\"1\""//isReplace ? "\"1\"" : "\"0\"" // if destination is existed ? 1: override : 0: fail

                let elementXMLString = isRenameNotMove ?
                "<\(command) KIND=\(wrappedKind) NAME=\(wrappedTo)>\(from)</\(command)>" :
                "<\(command) KIND=\(wrappedKind) DEST=\(wrappedTo) SRC=\(wrappedFrom) FORCE=\(shouldOverride)></\(command)>"
                
                let action = isRenameNotMove ?
                HCDGlobalDefine.API.WorkList.ActionType.rename.rawValue :
                HCDGlobalDefine.API.WorkList.ActionType.move.rawValue
                
                let xmlString = "<XML><\(action) SESSION=\(wrappedSession) PCNAME=\(wrappedPCName)>\(elementXMLString)</\(action)></XML>"
                return xmlString
            }
            
            static func change(fromPath: String, toPath: String, isRename: Bool) -> String {
                if isRename {
                    let newName = toPath.lastPathComponent
                    let key = getKey(forPath: fromPath)
                    return change(from: key ?? fromPath, to: newName, isRenameNotMove: true, useKeyNotPath: key != nil)
                } else {
                    let toParentPath = toPath.deletingLastPathComponent//.isEmpty ? "/" : toPath.deletingLastPathComponent
                    
                    if  let fromKey = getKey(forPath: fromPath),
                        let toKey = getKey(forPath: toParentPath) {
                        return change(from: fromKey, to: toKey, isRenameNotMove: false, useKeyNotPath: true)
                    } else {
                        return change(from: fromPath, to: toParentPath, isRenameNotMove: false, useKeyNotPath: false)
                    }
                }
            }
            
            static func put(path: String) -> String {
                guard
                    let item = HCDFileListManager.itemForLocalPath(path: path),
                    let extraInfo = wrappedSessionPCNameKind
                else {
                    return ""
                }
                
                let fileName    = item.name.wrapDoubleQuotes
                let kind        = extraInfo.2
                let size        = (item.size ?? "").wrapDoubleQuotes
                let md5         = HCDUserDefaults.shouldUseMD5 ?
                    (HCDFileManager.md5ForPath(path: item.path) ?? "").wrapDoubleQuotes :
                    (item.md5 ?? "").wrapDoubleQuotes
                let directory   = ("/" + item.path).wrapDoubleQuotes
                
                let element: String = item.isDir ?
                    "<DIR NAME=\(fileName) KIND=\(kind)>\(directory)</DIR>" :
                    "<FILE NAME=\(fileName) SIZE=\(size) MD5=\(md5) KIND=\(kind)>\(directory)</FILE>"
                
                let session = extraInfo.0
                let pcName  = extraInfo.1

                let body    = "<XML><PUT SESSION=\(session) PCNAME=\(pcName)>\(element)</PUT></XML>"
                return body
            }
        }
        
        static var quota: String {
            guard
                let wrapedSession = getWrappedInfo(.session),
                let wrapedFolderKey = getWrappedInfo(.folderKey)
            else {
                return ""
            }
            return "<XML><QUOTA SESSION=\(wrapedSession) FOLDERKEY=\(wrapedFolderKey)></QUOTA></XML>"
        }
    }
    
    // MARK: - FILE LIST REQUEST / RESPONSE
    
    
//    static func XMLStringFromRequestFileListInfo(_ info: HCDItem) -> String {
//        guard let session = HCDLoginInformationManager.session else {
//            return ""
//        }
//        
//        var dirKeyXML: String = ""
//        var label = HCDGlobalDefine.API.FileList.syncLabel
//        if let key = info.key {
//            let dirKeyLabel = HCDGlobalDefine.API.FileList.dirLabel
//            dirKeyXML = "<\(dirKeyLabel)>\(key)</\(dirKeyLabel)>"
//            if !key.isEmpty {
//                label = HCDGlobalDefine.API.FileList.listLabel
//            }
//        }
//        
//        let sessionKey = HCDGlobalDefine.API.FileList.Key.session
//        let sessionXML = "<\(label) \(sessionKey)=\"\(session)\">\(dirKeyXML)</\(label)>"
//        let XMLString = "<XML>\(sessionXML)</XML>"
//
//        return XMLString
//    }
    
//    private static func resultArrayOfTupleFrom(fileListResponseData data: Data) -> [(String,[String: String])] {
//        let XML = SWXMLHash.parse(data)
//        
//        var resultList = [(String,[String: String])]()
//        guard let XMLList = XML.children.first?.children.first else { return resultList }
//        
//        for child in XMLList.children {
//            guard let allAttributes = child.element?.allAttributes else {
//                continue
//            }
//            var result: (String,[String: String]) = ("",[:])
//            result.0 = child.element!.name
//            for (_, attributeValue) in allAttributes {
//                result.1[attributeValue.name] = attributeValue.text
//            }
//            resultList.append(result)
//        }
//        
//        return resultList
//    }
//    
//    static func resultListFromFileListResponseData(data: Data) -> [HCDRawItemFromServerList] {
//        let resultTuplesArray = resultArrayOfTupleFrom(fileListResponseData: data)
//        let resultList: [HCDRawItemFromServerList] = resultTuplesArray.map { HCDRawItemFromServerList(type: $0.0, dictionary: $0.1)
//        }
//        return resultList
//    }
//
//    // MARK: - UPLOAD REQUEST / RESPONSE
//    
//    static func HCDUploadRequestXMLDataBodyStringFromInfo(info: HCDFileUploadRequestInformationVT) -> String {
//        let fileName = info.fileName.wrapDoubleQuotes
//        let size = info.size.wrapDoubleQuotes
//        let md5 = info.md5.wrapDoubleQuotes
//        let kind = info.kind.wrapDoubleQuotes
//        let directory = info.directory.wrapDoubleQuotes
//        let element: String = info.isDir ?
//            "<DIR NAME=\(fileName) KIND=\(kind)>\(directory)</DIR>" :
//            "<FILE NAME=\(fileName) SIZE=\(size) MD5=\(md5) KIND=\(kind)>\(directory)</FILE>"
//        
//        let session = info.session.wrapDoubleQuotes
//        let pcName = info.pcName.wrapDoubleQuotes
//        let body = "<XML><PUT SESSION=\(session) PCNAME=\(pcName)>\(element)</PUT></XML>"
//        return body
//    }
//    
//    static func keyFromUploadResponseData(data: Data, isDir: Bool) -> String {
//        let xml = SWXMLHash.parse(data)
//        let keyForDir = isDir ? "DIR" : "FILE"
//        let result: String? = xml["XML"]["PUT"][keyForDir].element?.allAttributes["KEY"]?.text
//        return result!
//    }
//    
//    // MARK: - DELETE REQUEST / RESPONSE
//    
//    static func deleteRequestXMLDataBodyString(session: String, pcName: String, kind: String, key: String?, path: String?) -> String? {
//        guard key != nil || path != nil else {
//            return nil
//        }
//        let wrappedSession = session.wrapDoubleQuotes
//        let wrappedKind = kind.wrapDoubleQuotes
//        let wrappedPCName = pcName.wrapDoubleQuotes
//        
//        let elementXMLString = key != nil ? "<KEY KIND = \(wrappedKind)>\(key!)</KEY>" : "<PATH KIND = \(wrappedKind)>\(path!)</PATH>"
//        
//        let action = HCDGlobalDefine.API.WorkList.ActionType.remove.rawValue
//        let xmlString = "<XML><\(action) SESSION=\(wrappedSession) PCNAME=\(wrappedPCName)>\(elementXMLString)</\(action)></XML>"
//        return xmlString
//    }
//    
//    static func resultFromDeleteResponseData(data: Data) -> Bool {
//        return resultForResponseData(data, kindOfRequest: .remove)
//    }
//    
//    // MARK: - RENAME REQUEST / RESPONSE
//    
//    static func renameRequestXMLDataBodyString(session: String, pcName: String, kind: String, newName: String, info: String, useKeyNotPath: Bool) -> String? {
//        let wrappedSession = session.wrapDoubleQuotes
//        let wrappedPCName = pcName.wrapDoubleQuotes
//        let wrappedKind = kind.wrapDoubleQuotes
//        let wrappedNewName = newName.wrapDoubleQuotes
//        let command = useKeyNotPath ? "KEY" : "PATH"
//        
//        let elementXMLString = "<\(command) KIND = \(wrappedKind) NAME = \(wrappedNewName)>\(info)</\(command)>"
//        
//        let action = HCDGlobalDefine.API.WorkList.ActionType.rename.rawValue
//        let xmlString = "<XML><\(action) SESSION=\(wrappedSession) PCNAME=\(wrappedPCName)>\(elementXMLString)</\(action)></XML>"
//        return xmlString
//    }
//    
//    static func resultFromRenameResponseData(data: Data) -> Bool {
//        return resultForResponseData(data, kindOfRequest: .rename)
//    }
//    
//    // MARK: - MOVE REQUEST / RESPONSE
//    
//    static func moveItemRequestXMLDataBodyString(session: String, pcName: String, kind: String, moveFrom: String, moveTo: String, useKeyNotPath: Bool) -> String? {
//        let wrappedSession = session.wrapDoubleQuotes
//        let wrappedPCName = pcName.wrapDoubleQuotes
//        let wrappedKind = kind.wrapDoubleQuotes
//        let wrappedMoveFrom = moveFrom.wrapDoubleQuotes
//        let wrappedMoveTo = moveTo.wrapDoubleQuotes
//        let shouldOverride = "\"1\""//isReplace ? "\"1\"" : "\"0\"" // if destination is existed ? 1: override : 0: fail
//        let command = useKeyNotPath ? "KEY" : "PATH"
//        
//        let elementXMLString = "<\(command) KIND = \(wrappedKind) DEST=\(wrappedMoveTo) SRC=\(wrappedMoveFrom) FORCE=\(shouldOverride)></\(command)>"
//        
//        let action = HCDGlobalDefine.API.WorkList.ActionType.move.rawValue
//        let xmlString = "<XML><\(action) SESSION=\(wrappedSession) PCNAME=\(wrappedPCName)>\(elementXMLString)</\(action)></XML>"
//        return xmlString
//    }
//    
//    static func resultFromMoveItemResponseData(data: Data) -> Bool {
//        return resultForResponseData(data, kindOfRequest: .move)
//    }
//    
//    // MARK: - RESULT FOR RESPONSE
//    static func resultForResponseData(data: Data, kindOfRequest: HCDGlobalDefine.API.WorkList.ActionType) -> Bool {
//        let xml = SWXMLHash.parse(data)
//        let result: String? = kindOfRequest == .move ?
//            xml["XML"][kindOfRequest.rawValue]["RESULT"].element?.allAttributes["RESULT"]?.text:
//            xml["XML"][kindOfRequest.rawValue]["RESULT"].element?.text
//        return result == "1"
//    }
    
    // MARK: - WORK LIST REQUEST / RESPONSE
    
//    static func worklistRequestXMLDataBodyString() -> String {
//        guard
//            let wrapedSession = HCDLoginInformationManager.session?.wrapDoubleQuotes,
//            let wrapedID = HCDLoginInformationManager.loginCompleteInfo?.ID.wrapDoubleQuotes,
//            let wrapedPCName = HCDLoginInformationManager.loginCompleteInfo?.pcName.wrapDoubleQuotes
//        else {
//            return ""
//        }
//        
//        let xml = "<XML><WORKLIST SESSION=\(wrapedSession) ID=\(wrapedID) PCNAME=\(wrapedPCName)></WORKLIST></XML>"
//        return xml
//    }
    
//    static func eventListFromWorklistResponse(data: Data) -> [HCDServerRawEvent] {
//        let xml = SWXMLHash.parse(data)
//        guard let XMLList = xml.children.first?.children.first?.children else { return [HCDServerRawEvent]() }
//        
//        let events: [HCDServerRawEvent] = XMLList.map { (content) -> HCDServerRawEvent in
//            let actionType = content.element!.name
//            let dict = Dictionary(content.element!.allAttributes.map{ return ($0.0, $0.1.text) })
//            let dir = content.element!.text!
//            let event = HCDServerRawEvent(type: actionType, dictionary: dict, path: dir)
//            return event!
//        }
//        return events
//    }
//    
//    static func idFromWorkListResponse(data: Data) -> Int? {
//        let xml = SWXMLHash.parse(data)
//        guard
//            let result: String = xml["XML"]["WORKLIST"].element?.allAttributes["ID"]?.text,
//            let id: Int = Int(result)
//        else {
//            return nil
//        }
//        return id
//    }
    
    // MARK: - SERVER TIME REQUEST / RESPONSE
    
//    static func XMLStringFromRequestServerLastEventID() -> String {
//        guard let session = HCDLoginInformationManager.session else {
//            return ""
//        }
//        
//        let wrapedSession = session.wrapDoubleQuotes
//        let xml = "<XML><SERVERTIME SESSION=\(wrapedSession)></SERVERTIME></XML>"
//        return xml
//    }
//    
//    static func idFromServerTimeResponse(data: Data) -> String? {
//        let xml = SWXMLHash.parse(data)
//        let result: String? = xml["XML"]["SERVERTIME"].element?.allAttributes["ID"]?.text
//        return result
//    }
    
    struct Response {
        
        struct Login {
            static func fromData(_ data: Data) -> String? {
                let xml = SWXMLHash.parse(data)
                let result: String? = xml["XML"]["LOGIN"].element?.allAttributes["RESULT"]?.text
                return result
            }
        }
        
        struct FileList {
            private static func resultArrayOfTuple(fromData data: Data) -> [(String,[String: String])] {
                let XML = SWXMLHash.parse(data)
                
                var resultList = [(String,[String: String])]()
                guard let XMLList = XML.children.first?.children.first else { return resultList }
                
                for child in XMLList.children {
                    guard let allAttributes = child.element?.allAttributes else {
                        continue
                    }
                    var result: (String,[String: String]) = ("",[:])
                    result.0 = child.element!.name
                    for (_, attributeValue) in allAttributes {
                        result.1[attributeValue.name] = attributeValue.text
                    }
                    resultList.append(result)
                }
                
                return resultList
            }
            
            static func fromData(_ data: Data) -> [HCDRawItemFromServerList] {
                let resultTuplesArray = resultArrayOfTuple(fromData: data)
                let resultList: [HCDRawItemFromServerList] = resultTuplesArray.map { HCDRawItemFromServerList(type: $0.0, dictionary: $0.1)
                }
                return resultList
            }
        }
        
        struct WorkList {
            static func eventListFromData(_ data: Data) -> [HCDServerRawEvent] {
                let xml = SWXMLHash.parse(data)
                guard let XMLList = xml.children.first?.children.first?.children else { return [HCDServerRawEvent]() }
                
                let events: [HCDServerRawEvent] = XMLList.map { (content) -> HCDServerRawEvent in
                    let actionType = content.element!.name
                    let dict = Dictionary(content.element!.allAttributes.map{ return ($0.0, $0.1.text) })
                    let dir = content.element!.text!
                    let event = HCDServerRawEvent(type: actionType, dictionary: dict, path: dir)
                    return event!
                }
                return events
            }
            
            static func workListIDFromData(_ data: Data) -> String? {
                let xml = SWXMLHash.parse(data)
                let result: String? = xml["XML"]["WORKLIST"].element?.allAttributes["ID"]?.text
                return result
            }
            
            static func lastEventIdFromData(_ data: Data) -> String? {
                let xml = SWXMLHash.parse(data)
                let result: String? = xml["XML"]["SERVERTIME"].element?.allAttributes["ID"]?.text
                return result
            }
        }
        
        struct syncAction {
            static private func resultForResponse(data: Data, kindOfRequest: HCDGlobalDefine.API.WorkList.ActionType) -> String? {
                let xml = SWXMLHash.parse(data)
                let result: String? = kindOfRequest == .move ?
                    xml["XML"][kindOfRequest.rawValue]["RESULT"].element?.allAttributes["RESULT"]?.text:
                    xml["XML"][kindOfRequest.rawValue]["RESULT"].element?.text
                return result
            }

            static func deleteResult(data: Data) -> String? {
                return resultForResponse(data: data, kindOfRequest: .remove)
            }
            
            static func renameResult(data: Data) -> String? {
                return resultForResponse(data: data, kindOfRequest: .rename)
            }
            
            static func moveResult(data: Data) -> String? {
                return resultForResponse(data: data, kindOfRequest: .move)
            }
            
            static func putResult(data: Data, isDir: Bool) -> (String?,String?, String?) {
                let xml = SWXMLHash.parse(data)
                let keyForDir = isDir ? "DIR" : "FILE"
                let key: String? = xml["XML"]["PUT"][keyForDir].element?.allAttributes["KEY"]?.text
                let pkey: String? = xml["XML"]["PUT"][keyForDir].element?.allAttributes["PKEY"]?.text
                let result: String? = xml["XML"]["PUT"][keyForDir].element?.text
                return (key,pkey,result)
            }
        }
        
        struct Quota {
            static func fromData(_ data: Data) -> (Double, Double)? {
                let xml = SWXMLHash.parse(data)
                if
                    let usedStr  = xml["XML"]["QUOTA"].element?.allAttributes["USED"]?.text,
                    let totalStr = xml["XML"]["QUOTA"].element?.allAttributes["TOTAL"]?.text,
                    let used = Double(usedStr),
                    let total = Double(totalStr)
                {
                    return (used, total)
                }
                else
                {
                    return nil
                }
                
            }
        }
    }
}
