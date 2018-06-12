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
    //var objectId: NSManagedObjectID
    var fileName: String
    var action: ListChangeAction
    
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
