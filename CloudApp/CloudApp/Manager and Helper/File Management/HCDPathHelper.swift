//
//  HCDPathHelper.swift
//  CloudDisk-AutoSync
//
//  Created by Hanbiro Inc on 8/29/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation

struct HCDPathHelper {
    
    private static let homePath = NSHomeDirectory()
//    static let trashPath: String = HCDPathHelper.homePath + "/.Trash"
    
    static private let _syncRootDirectory: String = HCDUserDefaults.syncFolderPath! //?? HCDPathHelper.homePath.appending(pathComponent: "CloudDiskFolder")
    static var syncRootDirectory: String {
            return _syncRootDirectory
    }
    
    static let syncRootURL: URL = URL(fileURLWithPath: HCDPathHelper.syncRootDirectory)
    
    static let defaultSyncRootPath: String = HCDPathHelper.syncRootDirectory
    
    static func pathWithFolderNames(folderNames: [String]) -> String {
        return folderNames.joined(separator: "/")
    }
    
//    static func pathWithFolderNames(parentNames: [String], andFileName name: String) -> String {
//        let fullDirectoryNamesArray = parentNames + ["\(name)"]
//        return pathWithFolderNames(fullDirectoryNamesArray)
//    }
    
//    static func fullPathWithFolderNames(parentNames: [String], andName name: String) -> String {
//        let fullDirectoryNamesArray = parentNames + ["\(name)"]
//        return self.fullPathWithFolderNames(fullDirectoryNamesArray)
//    }
    /*
    static func fullPathWithFolderNames(folderNames: [String]) -> String {
        let tailPath = self.pathWithFolderNames(folderNames)
        let rootPath = self.defaultSyncRootPath
        let fullPath = rootPath + "/" + tailPath
        return fullPath
    }
    */
    static func fullPathForPath(path: String) -> String {
        return syncRootDirectory.appending(pathComponent: path)
    }
    
//    static func fullTrashURLForPath(path: String) -> URL {
//        return URL(fileURLWithPath: trashPath.appending(pathComponent: path.lastPathComponent))
//    }
    
    static func fullURLForPath(path: String) -> URL {
        let fullPath = fullPathForPath(path: path)
        return URL(fileURLWithPath: fullPath)
    }
    
    static func pathFromFullPath(_ fullPath: String) -> String {
        guard fullPath != HCDPathHelper.syncRootDirectory else {
            return ""
        }
        
        guard let rootRange = fullPath.range(of: HCDPathHelper.syncRootDirectory.stringByAddingSlash) else {
            return fullPath
        }
        let range = rootRange.upperBound ..< fullPath.endIndex
        let path = fullPath[range]
        return path
    }
    
//    private static let applicationFilesDirectory : URL? = {
//        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return nil }
//        let appSupportURL: URL? = FileManager.default.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last
//        return appSupportURL?.appendingPathComponent(bundleIdentifier)
//    }()
    
//    private static let MD5ListFileName = "HashList.plist"
//    private static let MD5ListFolderName = "FileAuthenticate"
    
//    static let MD5ListFolderDirectory : URL = {
//        let dirName = HCDPathHelper.applicationFilesDirectory?.URLByAppendingPathComponent(HCDPathHelper.MD5ListFolderName)
//        return dirName!
//    }()
//    
//    static let MD5ListFileDirectory : URL = {
//        let dir = HCDPathHelper.MD5ListFolderDirectory.URLByAppendingPathComponent(HCDPathHelper.MD5ListFileName)
//        return dir!
//    }()
}
