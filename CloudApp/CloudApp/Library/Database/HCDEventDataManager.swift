//
//  HCDEventDataManager.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/29/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import RealmSwift
import Foundation

class HCDEventDataManager: HCDDataManager {
    static private let sharedInstance = HCDEventDataManager(indentifyName: HCDGlobalDefine.Database.ManagerIndentify.events)
    static func defaultManager() -> HCDEventDataManager { return sharedInstance }
    
//    static func addNotificationToken() {
//        DispatchQueue.main.async {
//            HCDPrint.info("Start listen event data")
//            sharedInstance.token = sharedInstance.fullList.addNotificationBlock {(changes: RealmCollectionChange) in
//                switch changes {
//                case .update( _, let deletions, let insertions, _):
//                    if !deletions.isEmpty {
//                        if sharedInstance.fullList.isEmpty {
//                            HCDNotificationHelper.post(notificaion: .didCompleteAllEvent)
//                        } else {
//                            HCDNotificationHelper.post(notificaion: .oldEventWasExecuted)
//                        }
//                        HCDNotificationHelper.post(message: "files in waiting: \(sharedInstance.fullList.count)")
//                    }
//                    if !insertions.isEmpty {
//                        HCDNotificationHelper.post(notificaion: .didTakeSomeEvents)
//                    }
//                default:
//                    break
//                }
//            }
//        }
//    }
    
    static private var currentID: Int {
        set {
            HCDUserDefaults.localEventLogID = newValue
        }
        get {
            return HCDUserDefaults.localEventLogID
        }
    }
    
    static internal var nextKey: Int {
        currentID += 1
        return currentID
    }
    
    static internal func resetKey() {
        currentID = 0
    }
    
    //MARK: Notification - failed
    
    private lazy var fullListForNotification: Results<HCDEventObject> = {
        return self.fullList
    }()    
}

//MARK: - API ACTION
extension HCDEventDataManager {
    internal func commit(event: HCDPEvent, withErrorCode errorCode: String?) {
        writeWithBlock {
            let eventObjects = self.fullList.filter(byEvent: event)
            
            let commitFailEventObject: (HCDEventObject)->() = { eventObj in
                let errorCode = errorCode!
                
                // Handle event that ALREADY RETRIED
                if eventObj.notes.toEventNote == .isRetried {
                    HCDPrint.warning("retry failed for event \(event.identified)")
                    self.realm.delete(eventObj)
                    return
                }
                
                // Default behavior
                eventObj.error = errorCode
            }
            
            let commitSuccessEventObject: (HCDEventObject)->() = { eventObj in
                // Handle DELTE while DOWNLOADING folder
                if  eventObj.notes.toEventNote == .parentFolderHasBeenDeleted &&
                    !eventObj.fromLocal &&
                    event.eventType == .create {
                    eventObj.eventID = HCDEventDataManager.nextKey
                    eventObj.fromLocal = true
                    eventObj.detailEventType = HCDLocalEventType.create.rawValue
                    eventObj.error = nil
                    eventObj.notes = ""
                    return
                }
                
                // Default behavior
                self.realm.delete(eventObj)
            }
            
            let commitEvent: (HCDEventObject)->() = {
                return errorCode != nil && !errorCode!.isEmpty ? commitFailEventObject($0) : commitSuccessEventObject($0)
            }
            
            eventObjects.forEach(commitEvent)
        }
    }
}

//MARK: - GET
extension HCDEventDataManager {
    internal var fullList: Results<HCDEventObject> {
        return realm.objects(HCDEventObject.self).filter(byErrorCode: nil)
    }
    
    internal var fullListIncludeFailedEvent: Results<HCDEventObject> {
        return realm.objects(HCDEventObject.self)
    }
    
    internal var eventErrors: Results<HCDEventObject> {
        return realm.objects(HCDEventObject.self).filterErrors()
    }
    
    func errorEvents(byPath p: String?) -> Results<HCDEventObject> {
        return realm.objects(HCDEventObject.self).filterError(byPath: p)
    }
    
    func errorEvents(byErrorCodes errors: [String?]) -> Results<HCDEventObject> {
        return realm.objects(HCDEventObject.self).filter(byErrorCodes: errors)
    }
}

extension HCDEventDataManager {
    var nextEvents: [HCDPEvent] {
        var oldestEvents: [HCDPEvent] = []
        
        realm.refresh()
        
        let events = fullList.sortedByID()
        let limit = HCDGlobalDefine.ParameterAndLimit.limitOfSameOperationCanRunAtTheSameTime
        
        for i in 0 ..< min(limit, events.count) {
            let nextEvent = events[i].event
            if oldestEvents.isEmpty || oldestEvents.last!.canBeExecutedAtTheSameTimeWithEvent(otherEvent: nextEvent) {
                oldestEvents.append(nextEvent)
            } else {
                break
            }
        }
    
//        HCDPrint.debug("get event:\n" + oldestEvents.map { return $0.identified }.joined(separator: "\n") + "\nend")
        
        return oldestEvents
    }
    
    var isEmpty: Bool {
        realm.refresh()
        return fullList.isEmpty
    }
    
    var remainEvent: Int {
        realm.refresh()
        return fullList.count
    }
    
    var remainErrorEvent: Int {
        realm.refresh()
        return self.errorEvents(byErrorCodes: [HCDError.requestTimeOut.stringValue, HCDError.putRequestGetEmptyParentKeyForResponse.stringValue, HCDError.responseWithFailedResult.stringValue, HCDError.theNetworkConnectionWasLost.stringValue]).count
    }
    
    func checkIfExist(event: HCDPEvent, withErrorCode errorCode: String) -> Bool {
        self.realm.refresh()
        return !self.fullListIncludeFailedEvent
            .filter(byEvent: event)
            .filter(byErrorCode: errorCode)
            .isEmpty
    }
}

//MARK: - ADD
extension HCDEventDataManager {
//    func add<T:HCDPEvent>(fromEvents events: [T]) {
    func add(fromEvents events: [HCDPEvent]) {
        writeWithBlock {
            events.forEach { event in
                // Delete same event
                self.fullListIncludeFailedEvent.filter(byEvent: event).forEach {
                    self.realm.delete($0)
                }
                // Create event object for realm
                let eventObject = HCDEventObject()
                eventObject.eventID = HCDEventDataManager.nextKey
                eventObject.fromEvent(event: event)
                
                
                let legalPath = event.path.decomposedStringWithCanonicalMapping
                let legalNewPath = event.newPath.decomposedStringWithCanonicalMapping
                
                // Handle DELTE while DOWNLOADING folder
                if event.eventType == .remove {
                    self.fullList
                        .filter(byType: .create)
                        .filterByPath(isSelfOrChildOfPath: legalPath, isDir: event.isDir)
                        .forEach {
                            if $0.notes.toEventNote == .isRunning {
                                $0.notes = HCDEventNote.parentFolderHasBeenDeleted.stringValue
                            } else {
                                self.realm.delete($0)
                            }
                        }
                }
                
                // Handle RENAME/MOVE while DOWNLOADING folder
                if event.eventType == .change {
                    self.fullListIncludeFailedEvent
                        .filter(byType: .create)
                        .filterByPath(isSelfOrChildOfPath: legalPath, isDir: event.isDir)
                        .forEach {
                            let newPath = $0.path.stringByDeletingStringFromBeginWithLenghtOfString(
                                removeString: legalPath,
                                thenReplaceWithString: legalNewPath
                            )
                            $0.path = newPath
                            $0.eventID = HCDEventDataManager.nextKey
                        }
                }
                
                // Add to database
                self.realm.add(eventObject)
            }
        }
    }
}

//MARK: - REMOVE
extension HCDEventDataManager {
    func remove(event: HCDPEvent) {
        writeWithBlock {
            self.fullList.filter(byEvent: event).forEach {
                self.realm.delete($0)
            }
        }
    }
    
    func remove(eventByError errors:[String]) {
        writeWithBlock {
            self.errorEvents(byErrorCodes: errors).forEach {
                self.realm.delete($0)
            }
        }
    }
    
    func removeEventErrors(ByPaths paths:[String]) {
        paths.forEach {
            self.removeEventError(ByPath: $0)
        }
    }
    
    func removeEventError(ByPath path:String) {
        writeWithBlock {
            self.errorEvents(byPath: path).forEach {
                self.realm.delete($0)
            }
        }
    }
    
  /*  func removeFailedEvent() {
        writeWithBlock {
            self.realm.objects(HCDEventObject.self).filter("error != nil")
                .forEach {
                    self.realm.delete($0)
            }
        }
    }*/
    
//    func removeEventWithTypeCreate(pathBeginsWith pathBegins: String) {
//        let legalPathBegins = pathBegins.precomposedStringWithCanonicalMapping
//        writeWithBlock {
//            self.fullListIncludeFailedEvent
//                .filter(byType: HCDEventType.create)
//                .filterByPath(beginsWith: legalPathBegins)
//                .forEach {
//                    self.realm.delete($0)
//            }
//        }
//    }
    
//    func removeEventThatDamaged(byEventDelete event: HCDPEvent) {
//        let legalPath = event.path.decomposedStringWithCanonicalMapping
//        writeWithBlock {
//            self.fullListIncludeFailedEvent
//                .filter(byErrorCode: HCDError.folderGotDeletedBeforeDownloadThis.stringValue)
//                .filter(byType: .create)
//                .filterByPath(isSelfOrChildOfPath: legalPath, isDir: event.isDir)
//                .forEach {
//                    self.realm.delete($0)
//                }
//        }
//    }
    
//    func removeEventWithTypeCreate(withErrorCode errorCode: String) {
//        writeWithBlock {
//            self.fullListIncludeFailedEvent
//                .filter(byErrorCode: errorCode)
//                .filter(byType: .create)
//                .forEach {
//                    self.realm.delete($0)
//            }
//        }
//    }
}

//MARK: - UPDATE
extension HCDEventDataManager {
//    func update(event: HCDPEvent, withErrorCode errorCode: String?) {
//        writeWithBlock {
//            self.fullList.filter(byEvent: event).forEach {
//                $0.error = errorCode
//            }
//        }
//    }
    
    func noteIsRunning(forEvents events: [HCDPEvent]) {
        self.writeWithBlock {
            events.forEach {
                self.fullList.filter(byEvent: $0).forEach { $0.notes = HCDEventNote.isRunning.stringValue }
            }
        }
    }
    
    func clearAllError(code: String) {
        writeWithBlock {
            self.fullListIncludeFailedEvent.filter(byErrorCode: code).forEach {
                $0.error = nil
            }
        }
    }
    
    func clearAllError(codes: [String]) {
        writeWithBlock {
            self.fullListIncludeFailedEvent.filter(byErrorCodes: codes)?.forEach {
                $0.error = nil
            }
        }
    }
    
    func clearAllError(eventIDs: [Int]) {
        writeWithBlock {
            self.fullListIncludeFailedEvent.filter(byEventIDs: eventIDs)?.forEach {
                $0.error = nil
            }
        }
    }
    
//    func bringToFrontAndUpdateAllEventsWithTypeCreate(hasFailedWithErrorCode errorCode: String?, pathBeginsWith pathBegins: String, toNewPath newPath: String) {
//        let legalPathBegins = pathBegins.decomposedStringWithCanonicalMapping
//        let legalNewPath    = newPath.decomposedStringWithCanonicalMapping
//        writeWithBlock {
//            self.fullListIncludeFailedEvent
//                .filter(byErrorCode: errorCode)
//                .filter(byFromLocal: true)
//                .filter(byType: HCDEventType.create)
//                .filterByPath(beginsWith: legalPathBegins)
//                .updateNewID(andNewPath: legalNewPath, fromBeginPath: legalPathBegins)
//        }
//    }
    
//    func updateEventsWithTypeCreate(pathBeginWith pathBegins: String, withErrorCode errorCode: String) {
//        let legalPathBegins = pathBegins.decomposedStringWithCanonicalMapping
//        writeWithBlock {
//            self.fullList
//                .filter(byType: .create)
//                .filterByPath(beginsWith: legalPathBegins)
//                .forEach {$0.error = errorCode}
//        }
//    }
    
//    func bringToFrontAndMakeItFromLocal(forEvent event: HCDPEvent, hasErrorCode errorCode: String) {
//        writeWithBlock {
//            self.fullListIncludeFailedEvent
//                .filter(byEvent: event)
//                .filter(byErrorCode: errorCode)
//                .forEach {
//                    $0.eventID = HCDEventDataManager.nextKey
//                    $0.fromLocal = true
//                    $0.detailEventType = HCDLocalEventType.create.rawValue
//                    $0.error = nil
//            }
//        }
//    }
}

//MARK: - REALM RESULTS EXTENSION
extension Results where T: HCDEventObject {
    internal func filter(fromDict dict: [String: Any]) -> Results<T> {
        return filter(dict.toPredicateString)
    }
    
    internal func filter(byFromLocal fromLocal: Bool) -> Results<T> {
        return filter(fromDict: [
            HCDEventObject.PropertyNames.fromLocal: fromLocal]
        )
    }
    
    internal func filter(byEvent event: HCDPEvent) -> Results<T> {
        return filter(fromDict: HCDEventObject.fullDictionaryFromEvent(event))
    }
    
    internal func filterErrors() -> Results<T> {
        return filterAllError()
    }
    
    internal func filter(byType eventType: HCDEventType) -> Results<T> {
        return filter(fromDict: [
            HCDEventObject.PropertyNames.eventType: eventType.rawValue])
    }
    
    internal func filterByPath(isSelfOrChildOfPath path: String, isDir: Bool) -> Results<T> {
        let pathLabel = HCDEventObject.PropertyNames.path
        let exactlyPathPredicate = "\(pathLabel) = \(path.wrapDoubleQuotes)"
        
        if isDir {
            let beginsWithPredicate = "\(pathLabel) BEGINSWITH \(path.stringByAddingSlash.wrapDoubleQuotes)"
            return filter("\(exactlyPathPredicate) || \(beginsWithPredicate)")
        } else {
            return filter(exactlyPathPredicate)
        }
    }
    
//    private func filter(byPath path: String, exactly: Bool) -> Results<T> {
//        let compareKey = exactly ? "=" : "BEGINSWITH"
//        let pathLabel = HCDEventObject.PropertyNames.path
//        return filter("\(pathLabel) \(compareKey) \(path.wrapDoubleQuotes)")
//    }
//    
//    internal func filterByPath(exactly path: String) -> Results<T> {
//        return filter(byPath: path, exactly: true)
//    }
//
//    internal func filterByPath(beginsWith path: String) -> Results<T> {
//        return filter(byPath: path, exactly: false)
//    }
    
    internal func sortedByID() -> Results<T> {
        return sorted(byKeyPath: HCDEventObject.PropertyNames.eventID, ascending: true)
    }
    
    func filter(byErrorCode errorCode: String?) -> Results<T> {
        return filter("\(HCDEventObject.PropertyNames.error) = %@", errorCode as Any)
    }
    
    func filter(byErrorCodes errorCodes: [String?]) -> Results<T> {
        var strCondition = ""
        errorCodes.forEach { (errorCode) in
            if let error = errorCode {
                if error == (errorCodes.last ?? "") {
                    strCondition += "\(HCDEventObject.PropertyNames.error) = %@"
                } else {
                    strCondition += "\(HCDEventObject.PropertyNames.error) = %@ OR "
                }
            }
        }
        let pre = NSPredicate(format: strCondition, argumentArray: errorCodes)
        return filter(pre)
    }
    
    func filterEventError(byPath path: String?) -> Results<T> {
        return filter("\(HCDEventObject.PropertyNames.error) != nil AND \(HCDEventObject.PropertyNames.path) CONTAINS %@", path as Any)
    }
    
    func filterError(byPath path: String?) -> Results<T> {
        return filter("\(HCDEventObject.PropertyNames.error) != nil AND \(HCDEventObject.PropertyNames.path) = %@", path as Any)
    }
    
    func filterAllError() -> Results<T> {
        return filter("\(HCDEventObject.PropertyNames.error) != nil")
    }
    
    func filter(byErrorCodes errorCodes: [String]) -> Results<T>? {
        guard !errorCodes.isEmpty else {
            return nil
        }
        let propertyNameForError = HCDEventObject.PropertyNames.error
        let predicateStrings = errorCodes.map {
            return "\(propertyNameForError) = \($0.wrapDoubleQuotes)"
        }
        let predicateString = predicateStrings.joined(separator: " || ")
        return filter(predicateString)
    }
    
    func filter(byEventIDs eventIDs: [Int]) -> Results<T>? {
        guard !eventIDs.isEmpty else {
            return nil
        }
        let propertyNameForError = HCDEventObject.PropertyNames.eventID
        let predicateStrings = eventIDs.map {
            return "\(propertyNameForError) = \($0)"
        }
        let predicateString = predicateStrings.joined(separator: " || ")
        return filter(predicateString)
    }

  
    internal func updateNewID(andNewPath newBeginPath: String, fromBeginPath: String) {
        self.forEach {
            $0.eventID = HCDEventDataManager.nextKey
            let newPath = $0.path.stringByDeletingStringFromBeginWithLenghtOfString(removeString: fromBeginPath, thenReplaceWithString: newBeginPath)
            $0.path = newPath
            $0.error = nil
        }
    }
//    private func getByID(min: Bool) -> HCDEventObject? {
//        let IDLabel = HCDEventObject.PropertyNames.eventID
//        let choosenID: Int? = min ?
//            self.min(ofProperty: "\(IDLabel)") as Int?:
//            self.max(ofProperty: "\(IDLabel)") as Int?
//
//        if let choosenID = choosenID {
//            return filter("\(IDLabel) = \(choosenID)").first
//        } else {
//            return nil
//        }
//    }
//    
//    var newest: HCDEventObject? {
//        return getByID(min: false)
//    }
//    
//    var oldest: HCDEventObject? {
//        return getByID(min: true)
//    }
}
