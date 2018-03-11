//
//  MailingListContactAssignmentChange.swift
//  Mailings
//
//  Created on 07.03.18.
//

import Foundation
import CoreData

/**
 Information about a new mailing list assignment to the contact or a removement.
 */
struct MailingListAssignmentChange: Hashable {
    var objectId: NSManagedObjectID
    var action: String  // A, R
    
    var hashValue: Int {
        get {
            return objectId.hashValue
        }
    }
}

// For Equatable of MailingListAssignment
func ==(lhs: MailingListAssignmentChange, rhs: MailingListAssignmentChange) -> Bool {
    return lhs.objectId == rhs.objectId
}
