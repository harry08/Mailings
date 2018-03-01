//
//  CommonSettingsController.swift
//  Mailings
//
//  Created on 27.02.18.
//

import UIKit
import Foundation
import os.log

/**
 Util class to access the common settings.
 Implemented as Singleton.
 */
class CommonSettingsController {
    
    var settings : [String: SettingDTO]
    
    static let sharedInstance = CommonSettingsController()
    
    init() {
        if let container = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer {
            do {
                try settings = CommonSetting.loadCommonSettings(in: container.viewContext)
                return
            } catch let error as NSError {
                os_log("Could not load settings. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            }
        }
        
        settings = [:]
    }
    
    public func getMaxReceiver() -> Int {
        if let setting = settings[CommonSetting.keyMaxReceiver] {
            return Int(setting.intValue!)
        }
        
        return CommonSetting.defaultValueMaxReceiver
    }
    
    public func setMaxReveiver(_ maxReceiver : Int) {
        if var setting = settings[CommonSetting.keyMaxReceiver] {
            setting.intValue = maxReceiver
            setting.changed = true
            
            settings.updateValue(setting, forKey: CommonSetting.keyMaxReceiver)
            
            saveSettings()
        }
    }
    
    public func getSplitReceivers() -> Bool {
        if let setting = settings[CommonSetting.keySplitReceiver] {
            return setting.boolValue!
        }
        
        return CommonSetting.defaultValueSplitReceiver
    }
    
    public func setSplitReceivers(_ splitReceiver : Bool) {
        if var setting = settings[CommonSetting.keySplitReceiver] {
            setting.boolValue = splitReceiver
            setting.changed = true
            
            settings.updateValue(setting, forKey: CommonSetting.keySplitReceiver)
            
            saveSettings()
        }
    }
    
    /**
     Saves the changed values and reloads the settings
     */
    public func saveSettings() {
        if let container = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer {
            do {
                try CommonSetting.saveValues(settings: settings, in: container.viewContext)
                
                settings = try CommonSetting.loadValues(in: container.viewContext)
            } catch let error as NSError {
                os_log("Could not save settings. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            }
        }
    }
}
