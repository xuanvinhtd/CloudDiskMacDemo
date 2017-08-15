//
//  HCDError.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 10/20/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation

enum HCDError: Error {
    case other
    
    case lostConnection, cannotGetData, justFailButNoError, notEnoughResourceForRequest, otherNetworkErrorFromNSError, requestTimeOut, couldNotConnectToTheServer, cannotConvertResponseData, cannotConvertStringToURLForRouter, noSession, theNetworkConnectionWasLost
    case noSelectedSyncFolder, eventHappen, isRunningSameTask
    case deleteFail, cannotConvertData, serverError
    case notAutoLogin, loginFailCode, loginResultNil, loginResultEmpty, wrongUserNameOrPassword, noDataInKeyChain
    case noFileToUpload, noKeyToTransfer, putRequestGetEmptyKeyForResponse, putRequestGetEmptyParentKeyForResponse
    case noDomainForAPIURL, requestFileListFromItemThatIsNotDirectory, tryToConvertSyncActionFromRequestThatNotSyncAction, responseWithFailedResult, tryToTransferShorcut, responseWithNilResult
    case cannotEnumerateFileManager
    case existNameFileOnServer, notEnoughSpaceOnServer, notAuthorized, anonymous
    
    static let errorThatShouldBeRetryWhenCompleteAllEvent = [putRequestGetEmptyKeyForResponse, putRequestGetEmptyParentKeyForResponse]
    
//    static let network = [lostConnection, cannotGetData, justFailButNoError, notEnoughResourceForRequest, otherNetworkErrorFromNSError, requestTimeOut, couldNotConnectToTheServer, cannotConvertResponseData, cannotConvertStringToURLForRouter, noSession]
//    static let syncTask = [eventHappen, lostConnection, isRunningSameTask]
//    static let operation = [lostConnection, deleteFail, cannotConvertData]
//    static let login = [notAutoLogin, loginFailCode, loginResultNil, loginResultEmpty, wrongUserNameOrPassword, noDataInKeyChain]
//    static let transfer = [noFileToUpload, noKeyToTransfer]
//    static let request = [noDomainForAPIURL, requestFileListFromItemThatIsNotDirectory, tryToConvertSyncActionFromRequestThatNotSyncAction, responseWithFailedResult, tryToTransferShorcut]
//    static let file = [cannotEnumerateFileManager]
    
    /*
    init(fromNetworkError error: Error?) {
        if let error = error as? HCDError {
            self = error
            return
        }
        guard let error = error as? NSError else {
            self = .other
            return
        }
        switch error.code {
        case -1009:
            self = .lostConnection
        case -1004:
            self = .couldNotConnectToTheServer
        case -1001:
            self = .requestTimeOut
        case 21:
            self = .tryToTransferShorcut
        default:
            HCDPrint.error("can't recognize error: \(error)")
            self = .otherNetworkErrorFromNSError
        }
    }
    */
    
    var stringValue: String {
        return "\(self)"
    }
    
    var shouldRetry: Bool {
        switch self {
//        case .theNetworkConnectionWasLost :
//            return true
        default:
            return false
        }
    }
    
    func description() -> String {
        switch self {
        case .lostConnection:
            return "lost internet connection"
        case .cannotGetData:
            return "response can't convert to NSData"
        case .justFailButNoError:
            return "ERROR OF ERROR: mystery - request fail without throwing any error"
        case .notEnoughResourceForRequest:
            return "dont have enought data to make xml body for request"
        default :
            return "no info about this error at this time"
        }
    }
    
    static func getInfoPut(_ info: String) -> HCDError? {
        switch info {
        case "-1":
            return nil//.existNameFileOnServer
        case "-2":
            return .notEnoughSpaceOnServer
        case "-3":
            return .notAuthorized
        case "-4":
            return .anonymous
        default:
            return nil
        }
    }
    
    static func getInfo(_ info: String) -> HCDError? {
        switch info {
        case "1":
            return nil
        case "2":
            return nil //.existNameFileOnServer
        case "3":
            return .notEnoughSpaceOnServer
        case "4":
            return .notAuthorized
        case "5":
            return .anonymous
        default:
            return nil
        }
    }
}

extension Error {
    var toCloudAppError: HCDError {
        if let error = self as? HCDError {
            return error
        }
        switch (self as NSError).code {
        case -1009:
            return .lostConnection
        case -1005:
            return .theNetworkConnectionWasLost
        case -1004:
            return .couldNotConnectToTheServer
        case -1001:
            return .requestTimeOut
        case 21:
            return .tryToTransferShorcut
        default:
            HCDPrint.error("Can't recognize error: \(self)")
            return .other
        }
    }
}
