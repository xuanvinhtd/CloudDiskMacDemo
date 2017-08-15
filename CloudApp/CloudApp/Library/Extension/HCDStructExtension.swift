//
//  HCDStructExtension.swift
//  CloudDisk-AutoSync
//
//  Created by Hanbiro Inc on 8/24/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import CryptoSwift
import Foundation

//MARK - MD5

//extension String {
//    func md5() -> String {
//        let str = self.cString(usingEncoding: NSUTF8StringEncoding)
//        let strLen = CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
//        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
//        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
//        
//        CC_MD5(str!, strLen, result)
//        
//        let hash = NSMutableString()
//        for i in 0..<digestLen {
//            hash.appendFormat("%02x", result[i])
//        }
//        
//        result.dealloc(digestLen)
//        
//        return String(format: hash as String)
//    }
//}
//extension NSData {
//    func md5() -> String {
//        let digestLength = Int(CC_MD5_DIGEST_LENGTH)
//        let md5Buffer = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLength)
//        
//        CC_MD5(bytes, CC_LONG(length), md5Buffer)
//        let output = NSMutableString(capacity: Int(CC_MD5_DIGEST_LENGTH * 2))
//        for i in 0..<digestLength {
//            output.appendFormat("%02x", md5Buffer[i])
//        }
//        
//        return NSString(format: output) as String
//    }
//}

//END


extension String {
    var addingSecureURL: String {
        let secureURLString = "https://"
        return secureURLString + self
    }
    var wrapDoubleQuotes: String {
        return "\"\(self)\""
    }
    var deletingLastPathComponent: String {
        let nsSt = self as NSString
        return nsSt.deletingLastPathComponent
    }
    var lastPathComponent: String {
        let nsSt = self as NSString
        return nsSt.lastPathComponent
    }
    var stringByAddingSlash: String {
        guard self.characters.last != "/" else {
            return self
        }
        return self + "/"
    }
    func appending(pathComponent: String) -> String {
        let nsSt = self as NSString
        return nsSt.appendingPathComponent(pathComponent)
    }
    func begins(with str: String) -> Bool {
        if let range = self.range(of: str) {
            return range.lowerBound == self.startIndex
        }
        return false
    }
    func stringByDeletingStringFromBeginWithLenghtOfString(removeString: String, thenReplaceWithString newString: String) -> String {
        return newString + substring(from: removeString.endIndex)
        
    }
}

extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    var toPredicateString: String {
        let array: [String] = self.map {
            var stringValue = ""
            if let str: String = $1 as? String {
                stringValue = str.wrapDoubleQuotes
            } else {
                stringValue = "\($1)"
            }
            return "\($0 as! String) = \(stringValue)"
        }
        return array.joined(separator: " AND ")
    }
}

extension Set where Element: ExpressibleByStringLiteral {
    var toString: String {
        return self.reduce("") {
            return $0.0 + (($0.1 as? String) ?? "") + "\n"
        }
    }
}

// NOTE : Dictionary at right position will override value if has conflicted
func + <K,V>(left: [K:V], right: [K:V]) -> [K:V] {
    var new = left
    for (k, v) in right {
        new.updateValue(v, forKey: k)
    }
    return new
}

func - <K,V>(left: [K:V], right: [K:V]) -> [K:V] {
    var new = left
    for k in right.keys {
        new.removeValue(forKey: k)
    }
    return new
}

func += <K, V> (left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

//Localized
class HCDLocalizeStore {
    static private let sharedInstance = HCDLocalizeStore()
    static func printLocalizeList() {
        sharedInstance.stringNeedToTranslated.forEach {
            print($0.wrapDoubleQuotes)
        }
        
    }
    static func store(value: String) {
        sharedInstance.stringNeedToTranslated.insert(value)
    }
    
    var stringNeedToTranslated = Set<String>()
}
