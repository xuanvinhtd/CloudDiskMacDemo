//
//  HCDLog.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/22/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation
import SwiftyBeaver

//extension SwiftyBeaver {
//    func io() {
//        let path = ""
//        URL(fileURLWithPath: path.appending(pathComponent: "log.log"))
//    }
//}

let HCDPrint: SwiftyBeaver.Type = {
    let log = SwiftyBeaver.self
    
    let console = ConsoleDestination()
    console.format = "$DHH:mm:ss$d $L: $M"
    log.addDestination(console)
    
    HCDLog.addFileLogIfCan(toLog: log)
    
    return log
}()

struct HCDLog {
    enum RequestCondition {
        case start, error, success, progress
    }

    struct Config {
        static var shouldLogNetWork : Bool {
            set {
                HCDUserDefaults.shouldLogNetwork = newValue
            }
            get {
                return HCDUserDefaults.shouldLogNetwork
            }
        }
        static var shouldLogEvent   : Bool {
            set {
                HCDUserDefaults.shouldLogEvent = newValue
            }
            get {
                return HCDUserDefaults.shouldLogEvent
            }
        }
        static var shouldLogFileAction  : Bool {
            set {
                HCDUserDefaults.shouldLogFile = newValue
            }
            get {
                return HCDUserDefaults.shouldLogFile
            }
        }
        static var shouldLogDebug       : Bool = false
        static var shouldLogNotification: Bool = false
    }
    
    static var fileUrl: URL?
    
    static func addFileLogIfCan(toLog logger: SwiftyBeaver.Type) {
        if let path = HCDUserDefaults.syncFolderPath {
            let file = FileDestination()
            file.format = "$Dyy-MM-dd HH:mm:ss$d $L: $M"
            
            let url = URL(fileURLWithPath: path.appending(pathComponent: HCDGlobalDefine.FileName.fileLogName))
            HCDLog.fileUrl = url
            file.logFileURL = url
            
            print("file log url: \(file.logFileURL?.path ?? "unknow")")
            logger.addDestination(file)
        }
    }
    
    static func debugTools(enable: Bool) {
        guard HCDUserDefaults.openDebugTools != enable else {
            return
        }
        HCDUserDefaults.openDebugTools = enable
        if enable {
            addFileLogIfCan(toLog: HCDPrint)
        } else {
            let fullPath = HCDPathHelper.fullPathForPath(path: HCDGlobalDefine.FileName.fileLogName)
            HCDFileManager.removeIfFileExistedAtFullPath(fileDirectory: fullPath)
        }
    }
    
//    static let defaultLog: SwiftyBeaver.Type = {
//        let log = SwiftyBeaver.self
//        
//        let console = ConsoleDestination()
//        let file = FileDestination()
//
//        console.format = "$L: $M"
//        HCDLog.fileUrl = file.logFileURL
//        
//        log.addDestination(console)
//        log.addDestination(file)
//        
//        return log
//    }()
}

//extension SwiftyBeaver {
//    public class  func error(_ message: Any) {
//        defaultLog.error(message)
//    }
//    public class  func info(_ message: Any) {
//        defaultLog.info(message)
//    }
//    public class  func debug(_ message: Any) {
//        guard Config.shouldLogDebug else {
//            return
//        }
//        defaultLog.debug(message)
//    }
//    public class  func verbose(_ message: Any) {
//        defaultLog.verbose(message)
//    }
//}

extension SwiftyBeaver {
    public class func event(_ message: Any) {
        guard HCDLog.Config.shouldLogEvent else {
            return
        }
        verbose("Event:\(message)")
    }
    
    public class func file(_ message: Any) {
        guard HCDLog.Config.shouldLogFileAction else {
            return
        }
        verbose("File: \(message)")
    }
    
    public class func notif(_ message: Any) {
        guard HCDLog.Config.shouldLogNotification else {
            return
        }
        verbose("Notif: \(message)")
    }
}

extension SwiftyBeaver {
    class func network(message: Any?, condition: HCDLog.RequestCondition) {
        guard HCDLog.Config.shouldLogNetWork else {
            return
        }
        switch condition {
        case .start:
            info("Start request with info: \(message ?? "nil")")
        case .error:
            error("Fail to request with error: \(message ?? "nil")")
        case .success:
            info("Succeed with response: \(message ?? "nil")")
        case .progress:
            verbose("Progress: \(message ?? "nil")")
        }
    }
}
