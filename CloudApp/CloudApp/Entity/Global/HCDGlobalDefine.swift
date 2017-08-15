//
//  HCDGlobalDefine.swift
//  CloudDisk-AutoSync
//
//  Created by Hanbiro Inc on 8/22/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

struct HCDGlobalDefine {
    
    static let appMinVersion : Double = 20170113.3
    static let nearestVersion: Double = 20170120.0
    static let appVersion    : Double = 20170322.0
    static let changeLog : String =
        "Change log from version \(nearestVersion):"
        + "\n-Satisfies App Store requirements."
        + "\n-Show log file action."
        + "\n-Fix bug lost file because of duplicate move event"
        + "\n-Prevent request server worklist before complete handle last request worklist"
        + "\n-Take off SwiftyUserDefaults (hoply it will remove app store issue)."
    
    static let appHelperBundleIdentifier = "com.hanbiro.CloudAppHelper"
    static let appMofficeHelperBundleIdentifier = "com.hanbiro.MofficeCloudAppHelper"
    static let scheduleTimeForEventExecutor      = 60.0
    static let scheduleTimeForSyncManager        = 60.0
    static let scheduleTimeForStartNewSyncSeason = 3600.0
    
    struct NotificationName {
        struct Login {
            static let didFinish = "HCDNotifLoginDidFinish"
        }
        
        struct FileList {
            static let didFinish = "HCDNotifFileListDidFinish"
        }
        
        struct Event {
            static let happened = "HCDNotifEventHappened"
        }
        
        struct Demo {
            static let shouldShowMessage = "HCDNotifDemoShouldShouldMessage"
        }
    }
    
    struct LoginInfo {
        static let encode = "raw"
        static let failedCode = "-1"
    }
    
    struct Url {
        static let API = "cgi-bin/cloudXml.cgi"
        static let downloadAPI = "?do=download"
        static let uploadAPI = "?do=upload"
    }
    
    struct FileName {
        static let fileLogName = "Hanbiro_AutoSync_DeBug_Console.log"
        static private let ignoreFileNames: Set<String> = Set([".DS_Store", fileLogName])
        static let magicKeyWordToOpenDebugTools = "abracadabra-pleaseopenthedebugtools"
        
        static func shouldIgnoreFile(hasName name: String) -> Bool {
            return ignoreFileNames.contains(name)
        }
    }
    
    struct Database {
        struct ManagerIndentify {
            static let localList1   = "Local_file_list_1"
            static let localList2   = "Local_file_list_2"
            static let serverList1  = "Server_file_list_1"
            static let serverList2  = "Server_file_list_2"
            
            static let events = "Events"
        }   
    }
    
    struct API {
        struct Login {
            static let label = "LOGIN"
            struct Key {
                static let userName = "ID"
                static let userPassword = "PASSWORD"
                static let encode = "ENCODE"
                static let deviceName = "PCNAME"
                static let MACAddress = "MAC"
                static let appVersion = "VER"
            }
        }
        struct FileList {
            static let listLabel = "LIST"
            static let syncLabel = "SYNCLIST"
            static let dirLabel = "DIRKEY"
            struct Key {
                static let session = "SESSION"
            }
        }
        struct EntityNeedToSync {
            enum EntityType: String {
                case directory = "DIR"
                case file = "FILE"
                case undefined = ""
            }
            struct Key {
                static let name = "NAME"
                static let time = "TIME"
                static let timezone = "TIMEZONE"
                static let size = "SIZE"
                static let key = "KEY"
                static let pkey = "PKEY"
                static let note = "MEMO"
                static let priv = "PRIV"
                static let sync = "SYNC"
                static let star = "STAR"
                static let notification = "NOTIFICATION"
                
                static let kind = "KIND"
                static let shared = "SHARE"
                
                static let md5 = "MD5"
            }
        }
        struct WorkList {
            static let scheduleTime = 60.0
            
            enum ActionType: String { //add more in the future
                case remove = "DEL"
                case add = "ADD"
                case rename = "RENAME"
                case move = "MOVE"
            }
            struct IsFolderValue {
                static let isFile = "0"
                static let isFolder = "1"
            }
            struct Key {
                static let key = "KEY"
                static let name = "NAME"
                static let folder = "FOLDER"
                static let size = "SIZE"
                static let md5 = "MD5"
                static let pkey = "PKEY"
                static let time = "TIME"
                static let timezone = "TIMEZONE"
                static let ID = "ID"
            }
        }
        static let defaultKindForSyncApi = "SYNC"
        
        struct Upload {
            static let kind = HCDGlobalDefine.API.defaultKindForSyncApi
        }
        struct Delete {
            static let kind = HCDGlobalDefine.API.defaultKindForSyncApi
        }
    }
    
    struct ParameterAndLimit {
        static let limitOfSameOperationCanRunAtTheSameTime = 10
        static let retryLimitForOperation = 1 //Number Of Time An Operation Can Try Again After Fail
        static let retryLimitForExecutingNetwork = 1
    }
    
    struct OtherStuff {
        static let nameForAutoSyncSubscribeNetworkWatcher = "autosync_subscribe_networking"
        static let nameForEventHandleSubscribeNetworkWatcher = "event_handler_subscribe_networking"
        static let appHelperBundleIndentifier = "com.hanbiro.Auto-Sync-Cloud-Disk-Helper"
    }
    
    struct DefaultFilePath {
    }
    
    enum Languge: String {
        case English    = "en"
        case Korean     = "ko"
    }
}
