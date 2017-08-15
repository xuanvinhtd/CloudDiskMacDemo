//
//  HCDFileListComparator.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 1/16/17.
//  Copyright © 2017 Hanbiro Inc. All rights reserved.
//

import PromiseKit

class HCDFileListComparator {
    static private let defaultManager = HCDFileListComparator()
    
    static func createEventByComparingFileLists() -> Promise<()> {
        return defaultManager.createEventByComparingFileLists()
    }
    
    internal var fileListDidChange = false
    internal var shouldCancel: Bool {
        return self.fileListDidChange
    }
    @objc private func fileBookDidChange() {
        fileListDidChange = true
    }

    func createEventByComparingFileLists() -> Promise<()> {
        let serverFileBook = HCDFileListManager.serverFileBook
        let localFileBook = HCDFileListManager.localFileBook
        
        let prepare: ()->Promise<()> = {
            HCDPrint.info("Start create event by compare local with server file list")
            HCDNotificationHelper.post(message: "Find missing files".localized + "...")

            self.fileListDidChange = false

            HCDNotificationHelper.addObserver(
                notif: .localFileBookDidChange,
                target: self,
                selector: #selector(self.fileBookDidChange)
            )
            
            HCDNotificationHelper.addObserver(
                notif: .serverFileBookDidChange,
                target: self,
                selector: #selector(self.fileBookDidChange)
            )
            
            serverFileBook.addNotificationToken()
            localFileBook.addNotificationToken()

            return Promise(value: ())
        }
        
        // process compare vs Check all event and clean event error by condition
        let compare: () -> Promise<([HCDPEvent])> = {
            var events = [HCDPEvent]()
            
            serverFileBook.enumerateAllItemThat(notInBook: localFileBook) {
                guard !self.shouldCancel else {
                    return
                }
                events.append($0.toServerEventWithTypeAdded)
            }
            localFileBook.enumerateAllItemThat(notInBook: serverFileBook) {
                guard !self.shouldCancel else {
                    return
                }
                events.append($0.toLocalEventWithTypeCreated)
            }
            
            //Check and clean event error when compare local and sever file and event of database.
            events.forEach {
                HCDEventTakingManager.defaultManager.removeEventErrors(withPath: [$0.path])
            }
            //Clean event excuted
            serverFileBook.checkAndCleanEventErrors()
            localFileBook.checkAndCleanEventErrors()
            
            // Clean error event if file path not contain in serverFileBook and localFileBook
            serverFileBook.enumerateAllItemThat(cleanErrorWith: localFileBook, withAction: {
                HCDEventTakingManager.defaultManager.removeEventErrors(withPath: [$0.path])
            })
            
            // Get agian sync fail.
            HCDNotificationHelper.post(notificaion: HCDNotificationHelper.Notification.countErrorEvent)
            
            return Promise(value: events)
        }
        
        let takeEvent: ([HCDPEvent]) -> Promise<()> = { events in
            HCDEventTakingManager.take(events: events)
            return Promise(value: ())
        }
        
        let cleanUp: ()->() = {
            serverFileBook.stopToken()
            localFileBook.stopToken()
        }
        
        let queue = HCDUtilityHelper.getConcurrentDispathQueue(withName: "unique_queue_for_create_events_by_comparing_local_with_server_file_list")

        return firstly {
            prepare()
        }.then(on: queue) {
            compare()
        }.then(on: queue) {
           takeEvent($0)
        }.always {
            cleanUp()
        }
    }
}
