//
//  AttachedFileChange.swift
//  Mailings
//
//  Created on 04.06.18.
//

import Foundation
import CoreData

/**
 Information about an attached file to the mailing or a removement.
 */
struct MailingAttachementChange: Hashable {
    var objectId: NSManagedObjectID
    var action: String  // A, R
    
    var hashValue: Int {
        get {
            return objectId.hashValue
        }
    }
}

// For Equatable of AttachedFileChange
func ==(lhs: MailingAttachementChange, rhs: MailingAttachementChange) -> Bool {
    return lhs.objectId == rhs.objectId
}
