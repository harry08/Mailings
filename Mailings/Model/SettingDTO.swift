//
//  SettingDTO.swift
//  Mailings
//
//  Created on 27.02.18.
//

import Foundation

struct SettingDTO {
    
    var type: String
    var intValue: Int?
    var boolValue: Bool?
    var stringValue: String?
    var changed: Bool = false
}
