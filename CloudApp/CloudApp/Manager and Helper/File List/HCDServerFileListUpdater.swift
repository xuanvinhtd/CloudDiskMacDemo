//
//  HCDServerFileListUpdater.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/23/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import PromiseKit
import Foundation

protocol HCDPItemCollector {
    func collect(item: HCDItem)
    func collect(items: [HCDItem], brandNew: Bool) 
    func dropAll()
}

class HCDServerFileListUpdater {
    static private let defaultManager = HCDServerFileListUpdater()

    internal var itemCollector: HCDPItemCollector!
    
    static func promiseRequestFileList(withCollector collector: HCDPItemCollector) -> Promise<()> {
        return defaultManager.promiseRequestFileList(withCollector: collector)
    }
    
    internal var fileListDidChange = false
    internal var shouldCancel: Bool {
        return self.fileListDidChange
    }
    
    static var isCanceled: Bool {
        return defaultManager.shouldCancel
    }
}

extension HCDServerFileListUpdater {
    @objc private func serverFileBookDidChange() {
        fileListDidChange = true
    }
    
    internal func promiseRequestFileList(withCollector collector: HCDPItemCollector) -> Promise<()> {
        self.itemCollector = collector
        
        let complete: ()->() = {
            HCDPrint.info("Finish request server file list")
        }
        
        let tryToPromise: (Promise<()>)->Promise<()> = { body -> Promise<()> in
            var attempts = 0
            func attempt() -> Promise<()> {
                attempts += 1
                return body.recover { error -> Promise<()> in
                    HCDPrint.error(error)
                    if let error = error as? HCDError {
                        switch error {
                        case .lostConnection, .eventHappen:
                            return Promise(error: error)
                        default:
                            break
                        }
                    }
                    return after(interval: 30).then(execute: attempt)
                }
            }
            return attempt()
        }

        HCDPrint.info("Start request server file list")
        
        fileListDidChange = false
        if HCDUserDefaults.didCompleteFirstTimeGetServerFileList {
            HCDNotificationHelper.addObserver(
                notif: .newEventHappened,//.serverFileBookDidChange,
                target: self,
                selector: #selector(serverFileBookDidChange)
            )
        }
        itemCollector.dropAll()
        
        return firstly {
            tryToPromise(promiseRequest(folderItem: HCDItem.rootItem()))
        }.then {
            complete()
        }.always {
            HCDNotificationHelper.removeObserverFromTarget(target: self)
        }
        
    }
    
    private func promiseRequest(folderItem: HCDItem) -> Promise<()> {
        guard folderItem.isDir else {
            return Promise(error: HCDError.requestFileListFromItemThatIsNotDirectory)
        }
        
        guard !shouldCancel else {
            return Promise(error: HCDError.eventHappen)
        }
        
        let handleData: (Data, String)->(Promise<()>) = { (data, parentPath) -> Promise<()> in
            
            guard !self.shouldCancel else {
                return Promise(error: HCDError.eventHappen)
            }

            let rawItems = HCDNetworkDataConverter.Response.FileList.fromData(data)
            
            //get key of root folder sync
            if parentPath.isEmpty && HCDUserDefaults.keyOfRootFolder == nil {
                HCDUserDefaults.keyOfRootFolder = rawItems.first?.pkey
            }
            
            //get items
            let items = rawItems.map {
                HCDItem(fromRawItem: $0, andParentPath: parentPath)
            }
            
            //collect items, store to data base
            self.itemCollector.collect(items: items, brandNew: false)
            //HCDPrint.debug(items.reduce("") {$0 + $1.path + "\n"})
            
            //get promises
            let promises =
                items.filter {
                    $0.isDir
                }.map {
                    self.promiseRequest(folderItem: $0)
                }
            
            guard promises.count > 0 else {
                return Promise(value: ())
            }
            //fullfill promises
            return when(fulfilled: promises)
            
            //chain promises
            /*
            var prev = promises[0]
            promises.remove(at: 0)
            for promise in promises {
                prev = prev.then {
                    promise
                }
            }
            return prev
             */
        }
        
        let router = HCDPostRouter.fileList(folderItem)
        return firstly {
            HCDNetworkManager.promiseRequestPostMethod(router: router)
        }.then {
            handleData($0,folderItem.path)
        }.catch {
            HCDPrint.error("CANT GET LIST \(folderItem.path) WITH ERROR: \($0)")
        }
    }
}
