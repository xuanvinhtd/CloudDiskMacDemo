//
//  HCDDebugReportView.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 12/19/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Cocoa

class HCDDebugReportView: NSView {
    
    @IBOutlet weak var tfDetail: NSTextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        HCDNotificationHelper.addObserver(notif: .postDebugMessage, target: self, selector: #selector(showDetail))
    }
    
    @objc func showDetail(_ notif: Notification) {
        let text = notif.object as! String
        presentText(text: text)
    }
    
    func presentText(text: String) {
        tfDetail.stringValue = text
    }
}
