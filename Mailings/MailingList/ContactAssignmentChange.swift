//
//  ContactAssignmentChange.swift
//  Mailings
//
//  Created on 08.02.18.
//

import Foundation
import CoreData

/**
 Information about a new contact assignment to the mailingList or a removement.
 */
struct ContactAssignmentChange: Hashable {
    var objectId: NSManagedObjectID
    var action: String  // A, R
    
    var hashValue: Int {
        get {
            return objectId.hashValue
        }
    }
}

// For Equatable of ContactAssignment
func ==(lhs: ContactAssignmentChange, rhs: ContactAssignmentChange) -> Bool {
    return lhs.objectId == rhs.objectId
}

