//
//  HCDEventAnalyzeHelper.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/28/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//
import Foundation

struct HCDEventAnalyzeHelper {
    // MARK: - ANALYZE TO GET LOCAL FILE EVENT
    static func getLocalEvent(fromDetail info: HCDPDetailForRawEvent) -> HCDLocalEvent? {
        
        //TODO ingore event root
        if info.thisPathIsRoot {
            return nil
        }
        
        let fileWasExisted: Bool = info.thisWasExisted
        let fileIsExisting : Bool = info.thisIsExisting && info.thisAttribute != nil
        
        if !fileWasExisted && !fileIsExisting {
            return getEventTemporary(info)
        }
        
        if !fileWasExisted && fileIsExisting {
            return getEventItemAppear(info)
        }
        
        if fileWasExisted && !fileIsExisting {
            return getEventItemDisappear(info)
        }
        
        if fileWasExisted && fileIsExisting {
            return getEventItemUnchange(info)
        }
        
        return nil
    }
    
    // MARK: - TEMPORARY (WAS NOT EXISTED - NOW IS NOT EXISTED TOO)
    static func getEventTemporary(_ info: HCDPDetailForRawEvent) -> HCDLocalEvent? {
        return nil
    }
    
    // MARK: - APPEAR (WAS NOT EXISTED - NOW IS EXISTED)
    static func getEventFileAppear(_ info: HCDPDetailForRawEvent) -> HCDLocalEvent? {
        return info.hasLegalCreatorCode ?
            HCDLocalEvent(isDir: false, type: .moveIn, fullPath: info.thisPath, newFullPath: nil):
        nil
    }
    
    static func getEventDirAppear(_ info: HCDPDetailForRawEvent) -> HCDLocalEvent? {
        return info.thisItemIsRenamed ?
            HCDLocalEvent(isDir: true, type: .moveIn, fullPath: info.thisPath, newFullPath: nil) :
            HCDLocalEvent(isDir: true, type: .create, fullPath: info.thisPath, newFullPath: nil)
    }
    
    static func getEventItemAppear(_ info: HCDPDetailForRawEvent) -> HCDLocalEvent? {
        //TODO: different copy from create
        if info.thisItemIsDir {
            return getEventDirAppear(info)
        } else {
            return getEventFileAppear(info)
        }
    }
    
    // MARK: - DISAPPEAR (WAS EXISTED - NOW IS NOT EXISTED)
    static func getEventItemDisappear(_ info: HCDPDetailForRawEvent) -> HCDLocalEvent? {
        if info.thisItemIsRenamed && info.nextEvent != nil {
            //compare file name +
            //TODO check MD5 rather than Size
            if info.nextIsExisting {
                if(info.thisEvent.name != info.nextEvent?.name){ //keep both
                       return HCDLocalEvent(isDir: info.thisItemIsDir, type: .remove, fullPath: info.thisPath, newFullPath: nil)
                }else{ // replace file
                if info.nextWasExisted { // next path still present
                    return HCDLocalEvent(isDir: info.thisItemIsDir, type: .replace, fullPath: info.thisPath, newFullPath: info.nextPath)
                } else { // next path appear
                    return HCDLocalEvent(isDir: info.thisItemIsDir, type: .changeDir, fullPath: info.thisPath, newFullPath: info.nextPath)
                }
                }
            }
        }
        return info.thisItemIsRenamed ? //itemIsRenamed ?
            HCDLocalEvent(isDir: info.thisItemIsDir, type: .moveOut, fullPath: info.thisPath, newFullPath: nil) :
            HCDLocalEvent(isDir: info.thisItemIsDir, type: .remove, fullPath: info.thisPath, newFullPath: nil)
    }
    
    // MARK: - UNCHANGE (WAS EXISTED - NOW IS EXISTED TOO)
    static func getEventFileUnchange(_ info: HCDPDetailForRawEvent) -> HCDLocalEvent? {
        if ((info.thisLastModifyTimeString ?? "x") != (info.thisCurrentModifyTimeString ?? "y")) {
            return HCDLocalEvent(isDir: false, type: .modify, fullPath: info.thisPath, newFullPath: nil)
        } else {
            return nil
        }
    }
    
    static func getEventItemUnchange(_ info: HCDPDetailForRawEvent) -> HCDLocalEvent? {
        if info.thisItemIsRenamed || info.thisItemIsModified { //if itemIsRenamed {
            return HCDLocalEvent(isDir: info.thisItemIsDir, type: .modify, fullPath: info.thisPath, newFullPath: nil)
        } else if info.thisItemIsDir {
            return nil
        } else {
            return getEventFileUnchange(info)
        }
    }
}

protocol HCDPDetailForRawEvent {
    var thisEvent: HCDLocalRawEvent {get}
    var nextEvent: HCDLocalRawEvent? {get}

    var thisAttribute: [FileAttributeKey: Any]? {get}
    var fileListInfoGetter: HCDPItemProvider {get}
}

extension HCDPDetailForRawEvent {
    var thisPath: String {
        return thisEvent.path
    }
    
    var thisPathIsRoot: Bool {
        return thisPath == HCDPathHelper.syncRootDirectory
    }
    
    var thisItemIsRenamed: Bool {
        return thisEvent.containFlag(flag: .ItemRenamed)
    }
    
    var thisItemIsModified: Bool {
        return thisEvent.containFlag(flag: .ItemModified)
    }
    
    var thisItemIsDir: Bool {
        return thisEvent.containFlag(flag: .ItemIsDir)
    }
    
    var nextPath: String? {
        return nextEvent?.path
    }
    
    //Past (use file list manager)
    var thisWasExisted: Bool {
        return fileListInfoGetter.getItem(atPath: HCDPathHelper.pathFromFullPath(thisPath)) != nil
    }
    var thisLastModifyTimeString: String? {
        let info = fileListInfoGetter.getItem(atPath: HCDPathHelper.pathFromFullPath(thisPath))
        return info?.modifyTime
    }
    
    var nextWasExisted: Bool {
        return fileListInfoGetter.getItem(atPath: HCDPathHelper.pathFromFullPath(nextPath!)) != nil
    }
    
    //Present (use file manager)
    var thisIsExisting: Bool {
        return HCDFileManager.fileIsExistedAtFullPath(pathNeedToCheck: thisPath)
    }
    var hasLegalCreatorCode: Bool {
        //TODO update code at 22Feb2017
//        let creatorCode: Int? = thisAttribute![.hfsCreatorCode] as? Int
//        return creatorCode == nil || creatorCode! == 0
        return true
    }
    var thisCurrentModifyTimeString: String? {
        return ((thisAttribute![.modificationDate] as? NSDate)?.toString())
    }
    var nextIsExisting: Bool {
        return HCDFileManager.fileIsExistedAtFullPath(pathNeedToCheck: nextPath!)
    }

}

struct HCDDetailForRawEvent: HCDPDetailForRawEvent {
    let thisEvent: HCDLocalRawEvent
    let nextEvent: HCDLocalRawEvent?

    internal var fileListInfoGetter: HCDPItemProvider
    internal var thisAttribute: [FileAttributeKey : Any]?
}
