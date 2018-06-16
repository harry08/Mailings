//
//  MailingAttachementChange.swift
//  Mailings
//
//  Created on 04.06.18.
//

import Foundation
import CoreData

/**
 Type of list change action
 */
enum ListChangeAction: Int {
    case added, removed
}

/**
 Information about an attached file to the mailing or a removement.
 */
struct MailingAttachementChange: Hashable {
    var objectId: NSManagedObjectID?
    var fileName: String
    var action: ListChangeAction
    
    init(objectId : NSManagedObjectID, fileName: String, action: ListChangeAction) {
        self.objectId = objectId
        self.fileName = fileName
        self.action = action
    }
    
    init(fileName: String, action: ListChangeAction) {
        self.fileName = fileName
        self.action = action
    }
    
    var hashValue: Int {
        get {
            return fileName.hashValue
        }
    }
}

// For Equatable of AttachedFileChange
func ==(lhs: MailingAttachementChange, rhs: MailingAttachementChange) -> Bool {
    return lhs.fileName == rhs.fileName
}
