//
//  CommonSettings.swift
//  Mailings
//
//  Created on 26.02.18.
//

import Foundation
import CoreData
import os.log

class CommonSetting: NSManagedObject {
    
    // MARK: -  constants
    
    static let defaultValueMaxReceiver = 100
    static let defaultValueSplitReceiver = false
    
    static let keyMaxReceiver = "maxreceiver"
    static let keySplitReceiver = "splitreceiver"
    
    static let typeInt = "int"
    static let typeString = "string"
    static let typeBool = "bool"
    
    // MARK: -  class functions
    
    /**
     Saves changed values in the settings dictionary to the DB
     */
    class func saveValues(settings: [String: SettingDTO], in context: NSManagedObjectContext) throws {
        var hasChanges = false
        
        for setting in settings {
            if setting.value.changed {
                hasChanges = true
                let request : NSFetchRequest<CommonSetting> = CommonSetting.fetchRequest()
                request.predicate = NSPredicate(format: "key = %@", setting.key)
                do {
                    let matches = try context.fetch(request)
                    if matches.count == 0 {
                        // Create entry
                        let newSetting = CommonSetting(context: context)
                        newSetting.key = setting.key
                        newSetting.valuetype = setting.value.type
                        if setting.value.type == typeString {
                            newSetting.stringvalue = setting.value.stringValue!
                        } else if setting.value.type == typeBool {
                            newSetting.boolvalue = setting.value.boolValue!
                        } else if setting.value.type == typeBool {
                            newSetting.intvalue = Int16(setting.value.intValue!)
                        }
                        newSetting.createtime = Date()
                        newSetting.updatetime = Date()
                    } else if matches.count == 1 {
                        // Update existing entry
                        let existingSetting = matches[0]
                        existingSetting.valuetype = setting.value.type
                        if setting.value.type == typeString {
                            existingSetting.stringvalue = setting.value.stringValue!
                        } else if setting.value.type == typeBool {
                            existingSetting.boolvalue = setting.value.boolValue!
                        } else if setting.value.type == typeInt {
                            existingSetting.intvalue = Int16(setting.value.intValue!)
                        }
                        existingSetting.updatetime = Date()
                    } else {
                        // Illegal state. Throw new error
                    }
                } catch {
                    throw error
                }
            }
        }
        
        do {
            if hasChanges {
                try context.save()
            }
        } catch {
            throw error
        }
    }
    
    /**
     Loads the values from the DB into the settings dictionary
     */
    class func loadValues(in context: NSManagedObjectContext) throws -> [String: SettingDTO] {
        var settings : [String: SettingDTO] = [:]
        
        let request : NSFetchRequest<CommonSetting> = CommonSetting.fetchRequest()
        do {
            let matches = try context.fetch(request)
            for i in 0 ..< matches.count {
                let setting = matches[i]
                let settingDTO = SettingDTO(type: setting.valuetype!, intValue: Int(setting.intvalue), boolValue: setting.boolvalue, stringValue: setting.stringvalue, changed: false)
                settings[setting.key!] = settingDTO
            }
        } catch {
            throw error
        }
        
        return settings
    }
    
    /**
     Loads the common settings from the database.
     If the values are not yet set, the database is initialized with default values.
     */
    class func loadCommonSettings(in context: NSManagedObjectContext) throws -> [String: SettingDTO] {
        // Create dictionary with default values
        var settings : [String: SettingDTO] = [
            keyMaxReceiver: SettingDTO(type: typeInt, intValue: defaultValueMaxReceiver, boolValue: nil, stringValue: nil, changed: true),
            keySplitReceiver: SettingDTO(type: typeBool, intValue: nil, boolValue: defaultValueSplitReceiver, stringValue: nil, changed: true)
        ]
        
        // Override dictionary with values from DB.
        // During the first call no values are in the DB and nothing is overridden.
        let request : NSFetchRequest<CommonSetting> = CommonSetting.fetchRequest()
        do {
            let settingEntries = try context.fetch(request)
            for i in 0 ..< settingEntries.count {
                let entry = settingEntries[i]
                if entry.key == keyMaxReceiver {
                    let val = entry.intvalue
                    let setting = SettingDTO(type: typeInt, intValue: Int(val), boolValue: nil, stringValue: nil, changed: false)
                    settings.updateValue(setting, forKey: entry.key!)
                } else if entry.key == keySplitReceiver {
                    let val = entry.boolvalue
                    let setting = SettingDTO(type: typeBool, intValue: nil, boolValue: val, stringValue: nil, changed: false)
                    settings.updateValue(setting, forKey: entry.key!)
                }
            }
        } catch let error as NSError {
            os_log("Could not load settings. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            throw error
        }
        
        do {
            // Update database with default values
            try saveValues(settings: settings, in: context)
            
            // Reload data
            try settings = loadValues(in: context)
        } catch let error as NSError {
            os_log("Could not save and reload settings. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            throw error
        }
        
        return settings
    }
}
