//
//  HCDFileManager.swift
//  CloudDisk-AutoSync
//
//  Created by Hanbiro Inc on 8/29/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Cocoa

class HCDFileManager {
    static internal let defaultManager: HCDFileManager = HCDFileManager()
    
    static func syncFolderRoot(createIfNeeded: Bool) -> String {
        return defaultManager.syncFolderRoot(createIfNeeded: createIfNeeded)
    }
    
//    // MARK: - GETDIR
    
    private func syncFolderRoot(createIfNeeded: Bool) -> String {
        if createIfNeeded {
            createDirectory(withFullPath: HCDPathHelper.defaultSyncRootPath)
        }
        return HCDPathHelper.defaultSyncRootPath
    }

    // MARK: - GET INFORMATION
    
    static func fileAttributesAtFullPath(fullPath: String) -> [FileAttributeKey: Any]? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fullPath)
            return attributes
        } catch {
            return nil
        }
    }
    

    // MARK: - CHECK
    
    static func fileIsExistedAtFullPath(pathNeedToCheck: String) -> Bool {
        return FileManager.default.fileExists(atPath: pathNeedToCheck)
    }

    // MARK: - CREATE
    
    private func createDirectory(withFullPath fullPath: String?) {
        // check if file exist
        guard let fullPath = fullPath else { return }
        guard fullPath.isEmpty == false else { return }
        
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fullPath) == false else {
            return
        }
        
        // create directory
        let parentPath = fullPath.deletingLastPathComponent
        createDirectory(withFullPath: parentPath)
        do {
            try fileManager.createDirectory(atPath: fullPath, withIntermediateDirectories: false, attributes: nil)
            HCDPrint.file("Success create folder \(fullPath)")
        } catch {
            HCDPrint.error(error)
        }
    }

    //Create directory include its parent
    static func createDirectory(withPath path: String?, isFullPath: Bool = false) {
        if isFullPath {
            defaultManager.createDirectory(withFullPath: path)
        } else {
            defaultManager.createDirectory(withPath: path)
        }
    }
    
    private func createDirectory(withPath path: String?) {
        guard let path = path else { return }
        let fullPath = HCDPathHelper.fullPathForPath(path: path)
        createDirectory(withFullPath: fullPath)
    }
    
    private func moveFromUrl(oldURL: URL, toURL newURL: URL, shouldOverride: Bool) {
        guard FileManager.default.fileExists(atPath: oldURL.path) else {
            HCDPrint.error("No file to move from path \(oldURL.path)")
            return
        }
        if shouldOverride {
            removeIfFileExistedAtFullPath(fileDirectory: newURL.path)
        }
        do {
            try FileManager.default.moveItem(at: oldURL, to: newURL)
            HCDPrint.file("Success move item from \(oldURL) to \(newURL)")
        } catch {
            HCDPrint.error(error)
        }

    }

    static func moveFromPath(oldPath: String, toPath newPath: String, shouldOverride: Bool) {
        defaultManager.moveFromPath(oldPath: oldPath, toPath: newPath, shouldOverride: shouldOverride)
    }
    
    private func moveFromPath(oldPath: String, toPath newPath: String, shouldOverride: Bool) {
        let oldURL = HCDPathHelper.fullURLForPath(path: oldPath)
        let newURL = HCDPathHelper.fullURLForPath(path: newPath)
        moveFromUrl(oldURL: oldURL, toURL: newURL, shouldOverride: shouldOverride)
    }
    
    static func renameAtPath(path: String, withNewName newName: String) {
        defaultManager.renameAtPath(path: path, withNewName: newName)
    }
    
    private func renameAtPath(path: String, withNewName newName: String) {
        var fullURL = HCDPathHelper.fullURLForPath(path: path)
        do {
            var resourseValues = URLResourceValues()
            resourseValues.name = newName
            try fullURL.setResourceValues(resourseValues)
            HCDPrint.file("Success rename at path \(path) with new name \(newName)")
        } catch {
            HCDPrint.error(error)
        }
    }
    
    // MARK: - COPY
    static func copyItem(atURL: URL, toURL: URL) {
        defaultManager.copyItem(atURL: atURL, toURL: toURL)
    }
    
    private func copyItem(atURL: URL, toURL: URL) {
        do {
            try FileManager.default.copyItem(at: atURL, to: toURL)
            HCDPrint.file("Copy success from: \(atURL)\nTo: \(toURL)")
        } catch {
            HCDPrint.error(error)
        }
    }
    
    private func trashItem(atURL url: URL) {
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            HCDPrint.file("Trash item at path: \(url)")
        } catch {
            HCDPrint.error(error)
        }
    }

    // MARK: - REMOVE
    static func moveFileToTrash(url: URL) {
        defaultManager.trashItem(atURL: url)
//        let trashURL = HCDPathHelper.fullTrashURLForPath(path: url.path)
//        defaultManager.moveFromUrl(oldURL: url, toURL: trashURL, shouldOverride: true)
    }
    
    static func removeIfFileExistedAtFullPath(fileDirectory: String) {
        defaultManager.removeIfFileExistedAtFullPath(fileDirectory: fileDirectory)
    }
    
    private func removeFileAtFullPath(fileDirectory: String) {
        do {
            try FileManager.default.removeItem(atPath: fileDirectory)
            HCDPrint.file("Success delete at directory: \(fileDirectory)")
        } catch {
            HCDPrint.error("Fail to delete at directory: \(fileDirectory)")
            HCDPrint.error(error)
        }
    }
    
    private func removeIfFileExistedAtFullPath(fileDirectory: String) {
        if FileManager.default.fileExists(atPath: fileDirectory) {
            removeFileAtFullPath(fileDirectory: fileDirectory)
        }
    }
    
    private func removeFileAtPath(path: String) {
        let fullPath = HCDPathHelper.fullPathForPath(path: path)
        removeFileAtFullPath(fileDirectory: fullPath)
    }
    
    static func moveFileToTrash(path: String) {
        defaultManager.moveFileToTrash(path: path)
    }
    
    private func moveFileToTrash(path: String) {
        let fullURL = HCDPathHelper.fullURLForPath(path: path)
        trashItem(atURL: fullURL)
//        let trashURL = HCDPathHelper.fullTrashURLForPath(path: path)
//        moveFromUrl(oldURL: fullURL, toURL: trashURL, shouldOverride: true)
    }
  
    //MARK: MD5
    static func md5ForPath(path: String) -> String? {
        return defaultManager.md5ForPath(path: path)
    }
    
    private func md5ForPath(path: String) -> String? {
        let fullPath = HCDPathHelper.fullPathForPath(path: path)
        if let data = FileManager.default.contents(atPath: fullPath) {
            return data.md5().toHexString()
        }
        return nil
    }
}
