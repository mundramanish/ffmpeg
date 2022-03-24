//
//  String+Localization.swift
//  iLife
//
//  Created by footy on 27/11/19.
//  Copyright © 2019 App Infotech Ltd. All rights reserved.
//

import UIKit

extension String {
    
    /// This will get the Localization String from the string file based on the current language
    ///
    ///        "Your String".localized -> "Localized string from the file" // second week in the current year.
    ///
    public var localized: String {
        
        // Set your Application Langugage here. You can set your custom logic here to get the language code string.
        var strLang : String? = "en"
        
        // Check for the default Language
        if strLang == nil {
            strLang = "en"
        }
        
        // Get the Path for the String file based on language selction
        guard let path = Bundle.main.path(forResource: strLang, ofType: "lproj") else {
            return self
        }
        
        // Get the Bundle Path
        let langBundle = Bundle(path: path)
        
        // Get the Local String for Key and return it
        return langBundle?.localizedString(forKey: self, value: "", table: nil) ?? self
        
    }
    
}


