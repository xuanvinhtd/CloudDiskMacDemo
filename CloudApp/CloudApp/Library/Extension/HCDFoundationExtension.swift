//
//  HCDFoundationExtension.swift
//  CloudDisk-AutoSync
//
//  Created by Hanbiro Inc on 8/31/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Foundation

extension Data {
    func toString() -> String? {
        guard let dataString: String = NSString(data: self, encoding: String.Encoding.utf8.rawValue) as? String else {
            HCDPrint.error("Can't convert data to string")
            return nil
        }
        return dataString
    }
}

extension NSDate {
    func toString() -> String {
        return String(describing: self)
    }
}


