//
//  HCDEventTakingManager.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/29/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import PromiseKit

class HCDEventTakingManager {
    static let defaultManager = HCDEventTakingManager()
    
    let takingEventQueue = HCDUtilityHelper.getSerialOperationQueue(withName: "taking_event_queue")
    let eventBook = HCDEventDataManager.defaultManager()
    
    let listQueue = HCDUtilityHelper.getConcurrentDispathQueue(withName: "executing_queue_for_using_support_list")
    private var _runningList = [String:HCDPEvent]()
    internal var runningList: [String:HCDPEvent] {
        var result: [String:HCDPEvent]? = nil
        listQueue.sync {
            result = _runningList
        }
        return result!
    }
    internal var lastExecuted: HCDPEvent? = nil
    
    static var eventListIsEmpty: Bool {
        return defaultManager.isEmpty
    }
    
    static func take(events: [HCDPEvent]) {
        defaultManager.take(events: events)
    }
    
    static func getNextPendingEvents() -> [HCDPEvent] {
        return defaultManager.get()
    }
    
    static func commit(event: HCDPEvent, error: Error?) {
        defaultManager.commit(event: event, error: error)
    }
    
    
    static func clearError(_ error: HCDError) {
        defaultManager.clearError(error)
    }
    
    static func clearErrors(_ errors: [HCDError]) {
        defaultManager.clearErrors(errors)
    }
    
    static func clearErrors(_ eventIDs: [Int]) {
        defaultManager.clearErrors(eventIDs)
    }

    private var isEmpty: Bool {
        return eventBook.isEmpty
    }
    
    static var remainEvent: Int {
        return defaultManager.eventBook.remainEvent
    }
    
    static var remainErrorEvent: Int {
        return defaultManager.eventBook.remainErrorEvent
    }
    
    private func take(events: [HCDPEvent]) {
        guard !events.isEmpty else {
            return
        }
        
        takingEventQueue.addOperation {

            let operationBeforeTaking: (HCDPEvent)->() = { event in
                switch event.eventType {
                case .remove:
                    if event.isDir {
                        let runningListOfEventWithTypeCreate = Array(self.runningList.values).filter {
                            return $0.eventType == .create && $0.path.begins(with: event.path.stringByAddingSlash)
                        }
                        self.eventBook.noteIsRunning(forEvents: runningListOfEventWithTypeCreate)
                    }
                default:
                    break
                }
            }
            
            events.forEach {
                HCDPrint.verbose("take event \($0.identified)")
                operationBeforeTaking($0)
            }
            
            //add legit events to database
            self.eventBook.add(fromEvents: events)//self.eventBook.addEvents(events: newEvents)
            
            //notif 
            HCDNotificationHelper.post(notificaion: .didTakeSomeEvents)
            
            if !events.first!.createdByComparingFileList { //if !newEvents.first!.createdByComparingFileList {
                HCDNotificationHelper.post(notificaion: .newEventHappened)
            }
        }
    }
    
    private func get() -> [HCDPEvent] {
        let shouldRun: (HCDPEvent)->Bool = { event in
            guard self.runningList.isEmpty || event.canBeExecutedAtTheSameTimeWithEvent(otherEvent: self.lastExecuted) else {
                return false
            }
            
            var result = false
            self.listQueue.sync(flags: .barrier) {
                if self._runningList[event.identified] == nil {
                    self._runningList[event.identified] = event
                    result = true
                }
            }
            return result
        }
        
        let operationBeforeExecuting: (HCDPEvent)->() =  { event in
            self.lastExecuted = event
        }
        
        var events: [HCDPEvent] = []
        events = eventBook.nextEvents.filter {
            return shouldRun($0)
        }
        events.forEach {
            operationBeforeExecuting($0)
        }
        return events
    }
    
    private func commit(event: HCDPEvent, error: Error?) {
        //database update
        let errorString = error?.toCloudAppError.stringValue
        self.eventBook.commit(event: event, withErrorCode: errorString)
        
        //running list update
        listQueue.async(flags: .barrier) {
            self._runningList[event.identified] = nil
        }
        
        //debug
        HCDPrint.debug("Finish event: \(event.identified)")
        if HCDUserDefaults.openDebugTools {
            HCDNotificationHelper.show(runningList: Set(runningList.keys))
        }
        if let errorString = errorString {
            HCDPrint.error(errorString)
        }
        
        //notif
        if self.isEmpty {
            HCDNotificationHelper.post(notificaion: HCDNotificationHelper.Notification.countErrorEvent)
            HCDNotificationHelper.post(notificaion: .didCompleteAllEvent)
        } else {
            HCDNotificationHelper.post(notificaion: .oldEventWasExecuted)
        }
    }
    
    private func clearError(_ error: HCDError) {
        eventBook.clearAllError(code: error.stringValue)
    }
    
    private func clearErrors(_ errors: [HCDError]) {
        eventBook.clearAllError(codes: errors.map {return $0.stringValue})
    }
    
    private func clearErrors(_ eventIDs: [Int]) {
        eventBook.clearAllError(eventIDs: eventIDs)
    }
    
    func removeFailEventWithErrors(errors: [String]) {
        eventBook.remove(eventByError: errors)
    }
    
    func removeEventErrors(withPath p: [String]) {
        eventBook.removeEventErrors(ByPaths: p)
    }
}
