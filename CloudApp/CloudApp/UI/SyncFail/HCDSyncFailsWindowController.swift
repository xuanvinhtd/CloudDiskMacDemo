//
//  HCDErrorItemsWindowController.swift
//  CloudApp
//
//  Created by Hanbiro on 2/24/17.
//  Copyright © 2017 Hanbiro Inc. All rights reserved.
//

import Cocoa
import PromiseKit

class HCDSyncFailsWindowController: NSWindowController {
    //MARK: - Properties
    private var isUnCheckAll = true
    private var isActive = false
    @IBOutlet weak var progressView: NSProgressIndicator!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var reTryButton: NSButton!
    @IBOutlet weak var selectAllButton: NSButton!
    @IBOutlet weak var strError: NSTextField!
    @IBOutlet weak var notShowAgianCheckBox: NSButton!
    
    fileprivate var chooseDicts = [NSMutableDictionary]()
    
    //MARK: - Initialize method
    override func windowDidLoad() {
        super.windowDidLoad()
        
        HCDNotificationHelper.addObserver(notif: .retryTakeCompleteSomeEvents, target: self, selector: #selector(self.retryCompletion))
        HCDNotificationHelper.addObserver(notif: .countErrorEvent, target: self, selector: #selector(getData))
        HCDNotificationHelper.addObserver(notif: .appIsRunning, target: self, selector: #selector(appActive))
        HCDNotificationHelper.addObserver(notif: .appIsIdling, target: self, selector: #selector(appUnActive))
        
        self.notShowAgianCheckBox.state = !HCDUserDefaults.showFormSyncFails ? NSOnState : NSOffState
        getData()
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(nil)
        self.selectAllButton.title = "Select All".localized
        self.window?.title = "Sync fail".localized
        self.notShowAgianCheckBox.state = !HCDUserDefaults.showFormSyncFails ? NSOnState : NSOffState
    }

    //MARK: - Handling event
    @IBAction func actionRetry(_ sender: Any) {
        var eventIDs = [Int]()
        self.chooseDicts.forEach { (item) in
            if ((item["ChooseID"] as? Bool) ?? false) {
                eventIDs.append((item["eventID"] as? Int) ?? 0)
            }
        }
        if eventIDs.count == 0 {
            guard let w = self.window else {
                return
            }
            HCDAlert.showNSAlertSheet(with: .warning, window: w, title: "Select file", messageText: "Please select file to retry.", dismissText: "Ok", completion: { (_) in
                
            })
            HCDPrint.debug("not select sync fail.")
            return
        }
        
        if self.isActive {
            guard let w = self.window else {
                return
            }
            HCDAlert.showNSAlertSheet(with: .warning, window: w, title: "Notification", messageText: "Cannot retry sync because app is syncing. Please waiting...", dismissText: "Ok", completion: { (_) in
                
            })
            HCDPrint.debug("app is activing, so cannot retry sync fails.")
            return
        }
        
        HCDPrint.debug("---> START RETRY SYNC <---")
        DispatchQueue.main.async {
            self.progressView.startAnimation(self)
            self.selectAllButton.isEnabled = false
            self.reTryButton.isEnabled = false
        }
        
        firstly { // Update data error = nil
            self.clearErrors(eventIDs)
        }.then {
            //notif -> let excute event when clear error
            HCDNotificationHelper.post(message: "RETRYSYNC", notificaion: .retryTakeSomeEvents)
        }.catch { (error) in
            HCDPrint.error(error)
            DispatchQueue.main.async {
                self.progressView.stopAnimation(self)
                self.selectAllButton.isEnabled = true
                self.reTryButton.isEnabled = true
            }
        }
    }
    
    @IBAction func actionSelectAll(_ sender: Any) {
        if isUnCheckAll {
            self.selectAllButton.title = "UnSelect All".localized
            self.chooseDicts.forEach { (item) in
                item["ChooseID"] = isUnCheckAll
            }
            isUnCheckAll = !isUnCheckAll
        } else {
            self.selectAllButton.title = "Select All".localized
            self.chooseDicts.forEach { (item) in
                item["ChooseID"] = isUnCheckAll
            }
            isUnCheckAll = !isUnCheckAll
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @IBAction func checkNotShowAgian(_ sender: Any) {
        let isOn = ((sender as AnyObject).state == NSOnState)
        HCDUserDefaults.showFormSyncFails = !isOn
    }
    
    
    private func clearErrors(_ events:[Int]) -> Promise<()> {
        HCDEventTakingManager.clearErrors(events)
        return Promise(value: ())
    }
    
    @objc private func appActive() {
        self.isActive = true
    }
    
    @objc private func appUnActive() {
        self.isActive = false
    }
        
    @objc private func getData() {
        // Get event Sync fail
        let syncFailList = HCDEventDataManager.defaultManager().errorEvents(byErrorCodes: [HCDError.requestTimeOut.stringValue, HCDError.putRequestGetEmptyParentKeyForResponse.stringValue, HCDError.responseWithFailedResult.stringValue, HCDError.theNetworkConnectionWasLost.stringValue])
        
        // remove all event with error is NoFileToUpload, existNameFileOnServer
        HCDEventTakingManager.defaultManager.removeFailEventWithErrors(errors: [HCDError.noFileToUpload.stringValue, HCDError.existNameFileOnServer.stringValue])
        
        var chooseDics = [NSMutableDictionary]()
        
        syncFailList.forEach { (item) in
            let dict = NSMutableDictionary()
            dict["fromLocal"] = item.fromLocal
            dict["isDir"] = item.isDir
            dict["eventID"] = item.eventID
            dict["eventType"] = item.eventType
            dict["PathID"] = item.path
            dict["ErrorType"] = item.error
            dict["NameID"] = item.path.lastPathComponent
            dict["ChooseID"] = false
            chooseDics.append(dict)
            
            if chooseDics.count == syncFailList.count {
                self.chooseDicts.removeAll()
                self.chooseDicts = chooseDics
                DispatchQueue.main.async {
                 self.tableView.reloadData()
                }
            }
        }
        
        if syncFailList.count == 0 {
            DispatchQueue.main.async {
                self.chooseDicts.removeAll()
                self.tableView.reloadData()
                return
            }
        }
    }
    
    @objc func retryCompletion() {
        HCDPrint.debug("COMPLETION RETRY!")
        DispatchQueue.main.async {
            self.progressView.stopAnimation(self)
            self.selectAllButton.isEnabled = true
            self.reTryButton.isEnabled = true
        }
        getData()
    }
}

//MARK: - NSTableViewDelegate, NSTableViewDataSource
extension HCDSyncFailsWindowController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.chooseDicts.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {

        let object = self.chooseDicts[row] as NSMutableDictionary
        
        if tableColumn?.identifier == "PathID" {
            return object["PathID"] as? String ?? ""
        } else if tableColumn?.identifier == "NameID" {
            return object["NameID"] as? String ?? ""
        } else {
           return object["ChooseID"] as? Bool ?? false
        }
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        
        if !self.reTryButton.isEnabled {
            return
        }
        
        if tableColumn?.identifier == "ChooseID" {
            self.chooseDicts[row].setObject(object!, forKey: "ChooseID" as NSCopying)
            return
        }
        if tableColumn?.identifier == "ButtonID" {
            guard let path = HCDUserDefaults.syncFolderPath else {
                return
            }
            let objectSelect = self.chooseDicts[row] as NSMutableDictionary
            let pathFinder = (objectSelect["PathID"] as? String ?? "").deletingLastPathComponent
            let url = URL(fileURLWithPath: path.appending(pathComponent: pathFinder))
            NSWorkspace.shared().open(url)
            return
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        let object = self.chooseDicts[row] as NSMutableDictionary
        self.strError.stringValue = self.createDescriptionErrorOf(object)
        return true
    }
    
    private func createDescriptionErrorOf(_ error: NSMutableDictionary) -> String {
        guard let isFromLocal = error["fromLocal"] as? Bool,
        let isDir = error["isDir"] as? Bool,
        let nameItem = error["NameID"] as? String,
        let eventStr = error["eventType"] as? String,
        let errorName = error["ErrorType"] as? String else {
            return "Not found info."
        }
        var str = ""
        if isFromLocal {
            str += "Local request"
        } else {
            str += "Server request"
        }
        str += " \(eventStr)"
        if isDir {
            str += " folder: \(nameItem) \n"
        } else {
            str += " file: \(nameItem) \n"
        }
        // Description error
        str += "Error: "
        
        switch errorName {
        case HCDError.theNetworkConnectionWasLost.stringValue:
            str += "The network connection was lost."
        case HCDError.putRequestGetEmptyParentKeyForResponse.stringValue,
             HCDError.responseWithFailedResult.stringValue:
            if isDir {
                str += "Folder have a problem."
            } else {
                str += "File have a problem."
            }
        case HCDError.requestTimeOut.stringValue:
            str += "Request time out when connnect server."
        default:
            str += "..."
        }
        
        return str
    }
}
