//
//  HCDAlert.swift
//  CloudApp
//
//  Created by Hanbiro on 2/28/17.
//  Copyright © 2017 Hanbiro Inc. All rights reserved.
//
import Cocoa
import Foundation

final class HCDAlert {

    class func showNSAlert(with alertStyle: NSAlertStyle, title: String, messageText: String, dismissText: String, completion: ((Bool) ->Void)?) {
        DispatchQueue.main.async {
            let myAlert = NSAlert()
            myAlert.messageText = title
            myAlert.informativeText = messageText
            myAlert.alertStyle = alertStyle
            myAlert.addButton(withTitle: dismissText)
            let res = myAlert.runModal()
            
            guard let completion = completion else {
                HCDPrint.error("Not found clouse completion")
                return
            }
            
            if res == NSAlertFirstButtonReturn {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    class func showNSAlertResponce(with alertStyle: NSAlertStyle, title: String, messageText: String, agreeText: String, dismissText: String, completion: ((Bool) ->Void)?) {
        DispatchQueue.main.async {
            let myAlert = NSAlert()
            myAlert.messageText = title
            myAlert.informativeText = messageText
            myAlert.alertStyle = alertStyle
            myAlert.addButton(withTitle: dismissText)
            myAlert.addButton(withTitle: agreeText)
            let res = myAlert.runModal()
            
            guard let completion = completion else {
                HCDPrint.error("Not found clouse completion")
                return
            }
            
            if res == NSAlertFirstButtonReturn {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    class func showNSAlertResponceSheet(with alertStyle: NSAlertStyle, window: NSWindow, title: String, messageText: String, agreeText: String, dismissText: String, completion: ((Bool) ->Void)?) {
        
        let myAlert = NSAlert()
        myAlert.messageText = title
        myAlert.informativeText = messageText
        myAlert.alertStyle = alertStyle
        myAlert.addButton(withTitle: dismissText)
        myAlert.addButton(withTitle: agreeText)
        
        guard let completion = completion else {
            HCDPrint.error("Not found clouse completion")
            return
        }
        
        myAlert.beginSheetModal(for: window, completionHandler: { responce in
            if responce == NSAlertFirstButtonReturn {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    class func showNSAlertSheet(with alertStyle: NSAlertStyle, window: NSWindow, title: String, messageText: String, dismissText: String, completion: ((Bool) ->Void)?) {
        DispatchQueue.main.async {
            let myAlertSheet = NSAlert()
            myAlertSheet.messageText = title
            myAlertSheet.informativeText = messageText
            myAlertSheet.alertStyle = alertStyle
            myAlertSheet.addButton(withTitle: dismissText)
            
            guard let completion = completion else {
                HCDPrint.error("Not found clouse completion")
                return
            }
            
            myAlertSheet.beginSheetModal(for: window, completionHandler: { responce in
                completion(true)
            })
        }
    }
    
}
