//
//  HCDNetworkManager.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 11/21/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Alamofire
import PromiseKit

class HCDNetworkManager {
    private static let sharedInstatnce = HCDNetworkManager()
    
    lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "request_queue_for_network_manager"
        queue.maxConcurrentOperationCount = HCDGlobalDefine.ParameterAndLimit.limitOfSameOperationCanRunAtTheSameTime
        return queue
    }()
    
    internal lazy var Manager : Alamofire.SessionManager = {
        // Create the server trust policies
        let serverTrustPolicies: [String: ServerTrustPolicy] = [
            "dev.hanbiro.com": .disableEvaluation,
            "global2.hanbiro.com": .disableEvaluation,
            "global3.hanbiro.com": .disableEvaluation,
            "gw.hanbiro.vn"  : .disableEvaluation
        ]
        
        // Create custom manager
        URLSessionConfiguration.default.httpAdditionalHeaders
            = Alamofire.SessionManager.defaultHTTPHeaders
        
        
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        let man = Alamofire.SessionManager(
            configuration: configuration,
            serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
        )
        return man
    }()
    
//    static private func attempt(_ body: Promise<Data>) -> Promise<Data> {
//        var attempts = 0
//        func attempt() -> Promise<Data> {
//            attempts += 1
//            return body.recover { error -> Promise<Data> in
//                guard attempts < 2 && HCDError(fromNetworkError: error) != .requestTimeOut else { return Promise(error: error) }
//                return after(interval: 30).then(execute: attempt)
//            }
//        }
//        return attempt()
//    }
    
    static func promiseRequestPostMethod(router: HCDPostRouter) -> Promise<Data> {
        guard router.isLegal else {
            switch router {
            default:
                return Promise(error: HCDError.notEnoughResourceForRequest)
            }
        }
        
        return Promise<Data> { fullfill, reject in
            sharedInstatnce.requestPostMethod(router: router) {
                if let error = $1 {
                    HCDPrint.error(error)
                    reject(error)
                } else {
                    fullfill($0!)
                }
            }
        }
//        let promiseRequest = Promise<Data> { fullfill, reject in
//            sharedInstatnce.requestPostMethod(router: router) {
//                if let error = $1 {
//                    HCDPrint.error(error)
//                    HCDPrint.error(router.bodyString)
//                    reject(error)
//                } else {
//                    fullfill($0!)
//                }
//            }
//        }
//        
//        return attempt(promiseRequest).catch {
//            HCDPrint.error($0)
//            HCDPrint.error(router.bodyString)
//        }
    }
    
    static func promiseTransferData(router: HCDTransferDataRouter) -> Promise<()> {
        return Promise { fullfill, reject in
            sharedInstatnce.transferData(router: router) {
                if let error = $0 {
                    reject(error)
                } else {
                    fullfill()
                }
            }
        }
    }
    
    class NetworkOperation : AsynchronousOperation {
        
        // define properties to hold everything that you'll supply when you instantiate
        // this object and will be used when the request finally starts
        //
        // in this example, I'll keep track of (a) URL; and (b) closure to call when request is done
        
        let router: HCDPostRouter
        let networkOperationCompletionHandler: (Alamofire.DataResponse<Data>) -> Swift.Void
        
        // we'll also keep track of the resulting request operation in case we need to cancel it later
        
        weak var request: Alamofire.Request?
        
        // define init method that captures all of the properties to be used when issuing the request
        
        init(router: HCDPostRouter, networkOperationCompletionHandler: @escaping (Alamofire.DataResponse<Data>) -> Swift.Void) {
            self.router = router
            self.networkOperationCompletionHandler = networkOperationCompletionHandler
            super.init()
        }
        
        
        // when the operation actually starts, this is the method that will be called
        
        override func main() {
            guard !(HCDServerFileListUpdater.isCanceled && self.router.isRequestFileList) else {
                let result = Alamofire.Result<Data>.failure(HCDError.eventHappen)
                let response = Alamofire.DataResponse(request: nil, response: nil, data: nil, result: result)
                self.networkOperationCompletionHandler(response)
                self.completeOperation()
                return
            }
            
            if !router.includeSensitiveInformation {
                HCDPrint.network(message: router.bodyString, condition: .start)
            }

            request = sharedInstatnce.Manager.request(router)
                .responseData { response in
                    self.networkOperationCompletionHandler(response)
                    self.completeOperation()
            }
        }
        
        // we'll also support canceling the request, in case we need it
        
        override func cancel() {
            request?.cancel()
            super.cancel()
        }
    }

}

extension HCDPostRouter {
    var isRequestFileList: Bool {
        switch self {
        case .fileList(_):
            return true
        default:
            return false
        }
    }
}

extension HCDNetworkManager {
    internal func requestPostMethod(router: HCDPostRouter, completion: @escaping (Data?, Error?) -> Void) {
        
        let operation = NetworkOperation(router: router) { (response) in
            guard response.result.isSuccess else {
                    let error = response.result.error!
                    
                    HCDPrint.network(message: error, condition: .error)
                    
                    completion(nil, error.toCloudAppError)
                    return
            }
            
            if !router.includeSensitiveInformation {
                HCDPrint.network(message: response.data!.toString(), condition: .success)
            }
            
            completion(response.data, nil)
        }
        queue.addOperation(operation)
    }
}

extension HCDNetworkManager {
    internal func transferData(router: HCDTransferDataRouter, completion: @escaping (Error?) -> Void) {
        let fileURL: URL = router.localDestinationURL
        
        switch router.action {
        case .upload :
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                completion(HCDError.noFileToUpload)
                return
            }
            
            HCDPrint.network(message: "UPLOAD AT \(fileURL)", condition: .start)
            
            Manager.upload(fileURL, with: router)
                .response { response in
                    HCDPrint.network(message: "UPLOAD SUCCESS AT \(fileURL)", condition: .success)
                    
                    completion(response.error)
            }
            
        case .download:
            
            HCDPrint.network(message: "download at \(fileURL)", condition: .start)
            let destination: DownloadRequest.DownloadFileDestination = { url, response in
                return (fileURL, [.createIntermediateDirectories, .removePreviousFile])
            }
            
            Manager.download(router, to: destination).response { response in
                HCDPrint.network(message: "end download at \(fileURL)", condition: .success)
                
                completion(response.error)
            }
        }
    }
}

//class OriginNetworkOperation : AsynchronousOperation {
//    
//    // define properties to hold everything that you'll supply when you instantiate
//    // this object and will be used when the request finally starts
//    //
//    // in this example, I'll keep track of (a) URL; and (b) closure to call when request is done
//    
//    let URLString: String
//    let networkOperationCompletionHandler: (_ responseObject: Any?, _ error: Error?) -> ()
//    
//    // we'll also keep track of the resulting request operation in case we need to cancel it later
//    
//    weak var request: Alamofire.Request?
//    
//    // define init method that captures all of the properties to be used when issuing the request
//    
//    init(URLString: String, networkOperationCompletionHandler: @escaping (_ responseObject: Any?, _ error: Error?) -> ()) {
//        self.URLString = URLString
//        self.networkOperationCompletionHandler = networkOperationCompletionHandler
//        super.init()
//    }
//    
//    
//    // when the operation actually starts, this is the method that will be called
//    
//    override func main() {
//        request = Alamofire.request(URLString, method: .get, parameters: ["foo" : "bar"])
//            .responseJSON { response in
//                // do whatever you want here; personally, I'll just all the completion handler that was passed to me in `init`
//                
//                self.networkOperationCompletionHandler(response.result.value, response.result.error)
//                
//                // now that I'm done, complete this operation
//                
//                self.completeOperation()
//        }
//    }
//    
//    // we'll also support canceling the request, in case we need it
//    
//    override func cancel() {
//        request?.cancel()
//        super.cancel()
//    }
//}
