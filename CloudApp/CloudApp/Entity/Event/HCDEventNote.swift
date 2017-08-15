//
//  HCDEventNotes.swift
//  CloudApp
//
//  Created by Hanbiro Inc on 1/9/17.
//  Copyright © 2017 Hanbiro Inc. All rights reserved.
//

enum HCDEventNote: String {
    case parentFolderHasBeenDeleted
    case isRetried
    case isRunning
    case nothing
    
    var stringValue: String {
        return "\(self)"
    }
}

extension String {
    var toEventNote: HCDEventNote {
        return HCDEventNote(rawValue: self) ?? .nothing
    }
}
