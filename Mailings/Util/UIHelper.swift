//
//  UIHelper.swift
//  Mailings
//
//  Created on 07.04.20.
//

import Foundation
import UIKit

/**
 Dark mode support
 */
class UIHelper {
    
    class func getUIBarStyle(traitCollection: UITraitCollection) -> UIBarStyle {
        if isDarkMode(traitCollection: traitCollection) {
            return UIBarStyle.black
        }
        
        return UIBarStyle.default
    }
    
    class func getBarTintColor(traitCollection: UITraitCollection) -> UIColor {
        if isDarkMode(traitCollection: traitCollection) {
            return UIColor.black
        }
        
        return UIColor.white
    }
    
    class func isDarkMode(traitCollection: UITraitCollection) -> Bool {
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark {
                return true
            }
        }
        
        return false
    }
}
