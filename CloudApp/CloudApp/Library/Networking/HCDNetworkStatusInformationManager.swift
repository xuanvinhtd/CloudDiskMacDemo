//
//  HCDReachability.swift
//  autosync-clouddisk
//
//  Created by Hanbiro Inc on 10/11/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import ReachabilitySwift
import Foundation

class HCDNetworkStatusInformationManager {
    enum SubscribeName: String {
        case forEventExecutor = "NetworkSubscribeForEventExecutor"
        case forSyncManager = "NetworkSubscribeForSyncManager"
    }
    
    static private let sharedInstance = HCDNetworkStatusInformationManager()
    static private func defaultManager() -> HCDNetworkStatusInformationManager { return sharedInstance }
    
    let reachability: Reachability?
    var subscribeBlocks: [String: ()->()] = [:]
    
    init() {
        guard let reachabilityInstance = Reachability() else {
            reachability = nil
            HCDPrint.error("Unable to create Reachability")
            return
        }
        
        reachability = reachabilityInstance
        
        reachability!.whenReachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            for subscribeTuple in self.subscribeBlocks {
                subscribeTuple.1()
            }
            DispatchQueue.main.async {
                if reachability.isReachableViaWiFi {
                    HCDPrint.info("Reachable via WiFi")
                } else {
                    HCDPrint.info("Reachable via Cellular")
                }
                // CHECK VERSION APP
                HCDUtilityHelper.checkUpdateApp()
            }
        }
        reachability!.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            DispatchQueue.main.async {
                HCDPrint.error("Not reachable")
            }
        }
        
        do {
            try reachability!.startNotifier()
        } catch {
            HCDPrint.error("Unable to start notifier")
        }
    }
    
    static func subscribeWhenReachableWithName(name: SubscribeName, andBlock block: @escaping ()->()) {
        defaultManager().subscribeBlocks[name.rawValue] = block
    }
    
    static func unsubscribeForName(name: SubscribeName) {
        defaultManager().subscribeBlocks[name.rawValue] = nil
    }
    
}
