//
//  Localize.swift
//  CRMCall092016
//
//  Created by Hanbiro on 11/21/16.
//  Copyright © 2016 xuanvinhtd. All rights reserved.
//

import Foundation

/// Internal current language key
let LCLCurrentLanguageKey = "LCLCurrentLanguageKey"

/// Default language. English. If English is unavailable defaults to base localization.
let LCLDefaultLanguage = "en"

/// Base bundle as fallback.
let LCLBaseBundle = "Base"

/// Name for language change notification
//public let LCLLanguageChangeNotification = "LCLLanguageChangeNotification"

class Localize: NSObject {
    /**
     List available languages
     - Returns: Array of avaiable languages.
    */
    class func availableLanguages(_ excludeBase: Bool = false) -> [String] {
        var availiableLanguages = Bundle.main.localizations
        // If excludeBase = true. dont include "Base" in available languages
        if let indexOfBase = availiableLanguages.index(of: "Base") , excludeBase == true {
            availiableLanguages.remove(at: indexOfBase)
        }
        return availiableLanguages
    }
    
    /**
     Default language
     - Returns: The app's default language. String
    */
    class func defaultLanguge() -> String {
        var defaultLanguage: String = String()
        guard let preferredLanguage = Bundle.main.preferredLocalizations.first else {
            return LCLDefaultLanguage
        }
        
        let availableLanguages: [String] = self.availableLanguages()
        if availableLanguages.contains(preferredLanguage) {
            defaultLanguage = preferredLanguage
        } else {
            defaultLanguage = LCLDefaultLanguage
        }
        return defaultLanguage
    }
    
    /**
    Current language
    - Returns: The current language. String.
    */
    
    class func currentLanguage() -> String {
        if let currentLanguage = UserDefaults.standard.object(forKey: LCLCurrentLanguageKey) as? String {
            return currentLanguage
        }
        
        return defaultLanguge()
    }
    
    class func setCurrentLanguage(_ language: String) {
        let selectLanguage = availableLanguages().contains(language) ? language : defaultLanguge()
        if selectLanguage != currentLanguage() {
            UserDefaults.standard.set(selectLanguage, forKey: LCLCurrentLanguageKey)
            HCDNotificationHelper.post(notificaion: .LCLLanguageChangeNotification)
        }
    }
    
    class func resetCurrentLanguageToDefault() {
        setCurrentLanguage(self.defaultLanguge())
    }
}
