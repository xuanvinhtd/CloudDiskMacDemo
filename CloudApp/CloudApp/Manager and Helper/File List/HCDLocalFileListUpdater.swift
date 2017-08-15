//
//  HCDLocalFileListUpdater.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/24/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import PromiseKit
import Foundation


class HCDLocalFileListUpdater {
    static private let defaultManager = HCDLocalFileListUpdater()
    
    internal var fileListDidChange = false
    internal var shouldCancel: Bool {
        return self.fileListDidChange
    }

    @objc private func fileBookDidChange() {
        fileListDidChange = true
    }

    static func promiseUpdateFileList(withCollector collector: HCDPItemCollector) -> Promise<()> {
        let prepare: () -> Promise<()> = {
            HCDPrint.info("Start getting local file list")

            collector.dropAll()
            
            defaultManager.fileListDidChange = false
            
            HCDNotificationHelper.addObserver(
                notif: .localFileBookDidChange,
                target: defaultManager,
                selector: #selector(fileBookDidChange)
            )

            return Promise(value: ())
        }
        
        let complete: ()->() = {
            HCDPrint.info("Finish getting local file list")
        }
        return firstly {
            prepare()
        }.then(on: HCDUtilityHelper.getConcurrentDispathQueue(withName: "reading_local_file_list")) {
            defaultManager.promiseGetFileList(
                atPath: "",
                collector: collector,
                shouldReturnValueAndIgnoreCancel: false)
        }.then(on: DispatchQueue.main) {_ in
            complete()
        }
    }
    
    
    static func promiseUpdateFile(collector: HCDPItemCollector, atPath path: String) -> [HCDItem]? {
        return defaultManager.promiseGetFileList(
            atPath: path,
            collector: collector,
            shouldReturnValueAndIgnoreCancel: true
            ).value
    }
}

extension HCDLocalFileListUpdater {
    func promiseGetFileList(atPath path: String, collector: HCDPItemCollector, shouldReturnValueAndIgnoreCancel: Bool) -> Promise<([HCDItem])> {
        let fileManager = FileManager.default
        let fullPath = HCDPathHelper.fullPathForPath(path: path)
        
        guard let enumerator = fileManager.enumerator(atPath: fullPath) else {
            return Promise(error: HCDError.cannotEnumerateFileManager)
        }
        
        var items: [HCDItem] = []
        var count = 1
        while let element = enumerator.nextObject() as? String {
            guard let attributes = enumerator.fileAttributes,
                shouldReturnValueAndIgnoreCancel || shouldCancel == false
            else {
                continue
            }
            let infoPath = path.appending(pathComponent: element)
            let info = HCDItem(fromFileAttribute: attributes, path: infoPath)
            //TODO: should calculate md5 here
            if !HCDGlobalDefine.FileName.shouldIgnoreFile(hasName: info.name) {
                items.append(info)
                count += 1
                if count > 1000 {
                    HCDNotificationHelper.post(message: "Reading Sync Folder".localized + " (\(items.count))")
                    count = 1
                }
            }
        }
        
        collector.collect(items: items, brandNew: true)
        
        return shouldReturnValueAndIgnoreCancel ? Promise(value: items) : Promise(value: [])
    }
}
