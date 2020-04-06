//
//  AssignedContact.swift
//  Mailings
//
//  Created 06.02.18.
//

import Foundation
import CoreData

class AssignedContact : Comparable {
    var objectId: NSManagedObjectID
    var firstname: String
    var lastname: String
    
    init(objectId : NSManagedObjectID, firstname: String, lastname: String) {
        self.objectId = objectId
        self.firstname = firstname
        self.lastname = lastname
    }
    
    static func <(lhs: AssignedContact, rhs: AssignedContact) -> Bool {
        if (lhs.lastname == rhs.lastname) {
            return lhs.firstname < rhs.firstname
        } else {
            return lhs.lastname < rhs.lastname
        }
    }
    
    static func == (lhs: AssignedContact, rhs: AssignedContact) -> Bool {
         return lhs.objectId == rhs.objectId
    }
}
