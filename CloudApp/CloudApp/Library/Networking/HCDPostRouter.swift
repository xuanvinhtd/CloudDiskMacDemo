//
//  HCDNetworkRouter.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/22/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation
import Alamofire

enum HCDPostRouter {
    case login(HCDLoginCompleteInformationVT)
    case fileList(HCDItem)
    case lastExecutedServerEventID
    case workList(String)
    case delete(String)
    case rename(String, String)
    case move(String, String)
    case put(String)
    case quota
    case getTest
}

extension HCDPostRouter {
    static var apiURLString: String? {
        guard let domain = HCDLoginInformationManager.domain else {
            return nil
        }
        let APIurl = HCDGlobalDefine.Url.API
        let fullURL = domain.appending(pathComponent: APIurl).addingSecureURL
        return fullURL
    }
    
    static var apiURL: URL? {
        let urlStrign = apiURLString
        return urlStrign != nil ? URL(string: urlStrign!) : nil
    }
}

extension HCDPostRouter: URLRequestConvertible {
    var isLegal: Bool {
        return !bodyString.isEmpty
    }
    
    var bodyString: String {
        switch self {
        case .login(let info):
            return HCDNetworkDataConverter.Request.Login.fromInfo(info)
        case .fileList(let item):
            return HCDNetworkDataConverter.Request.FileList.fromInfo(item)
        case .lastExecutedServerEventID:
            return HCDNetworkDataConverter.Request.WorkList.lastID()
        case .workList(let lastEventID):
            return HCDNetworkDataConverter.Request.WorkList.workList(fromLastEventID: lastEventID)
        case .delete(let path):
            return HCDNetworkDataConverter.Request.SyncAction.delete(withPath: path)
        case .rename(let fromPath, let toPath):
            return HCDNetworkDataConverter.Request.SyncAction.change(fromPath: fromPath, toPath: toPath, isRename: true)
        case .move(let fromPath, let toPath):
            return HCDNetworkDataConverter.Request.SyncAction.change(fromPath: fromPath, toPath: toPath, isRename: false)
        case .put(let path):
            return HCDNetworkDataConverter.Request.SyncAction.put(path: path)
        case .quota:
            return HCDNetworkDataConverter.Request.quota
        case .getTest:
            return "."
        }
    }
    
    var includeSensitiveInformation: Bool {
        //prevent print user password
        switch self {
        case .login(_):
            return true
        default:
            return false
        }
    }

    private var body: Data {
        return bodyString.data(using: .utf8)!
    }

    func asURLRequest() throws -> URLRequest {
        switch self {
        case .getTest:
            let url = URL(string: "https://n.hanbiro.com/cgi-bin/cloudXml.cgi?do=download&session=lec0tkub71h9ar4r4tl9qv5ll3&key=813394")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            return request
        default:
            break
        }
        guard let url = HCDPostRouter.apiURL else {
            throw HCDError.noDomainForAPIURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        
        return request
    }
}

extension HCDPostRouter {
    func translateSyncActionResponse(data: Data) -> Error? {
        var result:String? = nil
        switch self {
        case .delete:
            result = HCDNetworkDataConverter.Response.syncAction.deleteResult(data: data)
        case .rename:
            result = HCDNetworkDataConverter.Response.syncAction.renameResult(data: data)
        case .move:
            result = HCDNetworkDataConverter.Response.syncAction.moveResult(data: data)
        default:
            return HCDError.tryToConvertSyncActionFromRequestThatNotSyncAction
        }
        return result == nil ? HCDError.responseWithNilResult : HCDError.getInfo(result!)
    }
}

struct HCDTransferDataRouter {
    enum Action {
        case upload
        case download
    }
    
    internal let localDestination: String
    internal let action: Action
    internal let key: String
        
    var localDestinationURL: URL {
        return HCDPathHelper.fullURLForPath(path: localDestination)
    }
}

extension HCDTransferDataRouter: URLRequestConvertible {
    
    private var actionAPI: String {
        return action == .download ? HCDGlobalDefine.Url.downloadAPI : HCDGlobalDefine.Url.uploadAPI
    }
    
    func asURLRequest() throws -> URLRequest {
        guard
            let apiURLString = HCDPostRouter.apiURLString,
            let session = HCDLoginInformationManager.session
        else {
            throw HCDError.noSession
        }
        
        let fullURLString: String = apiURLString + actionAPI + "&session=\(session)" + "&key=\(key)"
        
        guard let fullURL = URL(string: fullURLString) else {
            throw HCDError.cannotConvertStringToURLForRouter
        }
        
        var request = URLRequest(url: fullURL)
        request.httpMethod = action == .upload ? "POST" : "GET"
        
        return request
    }
}
