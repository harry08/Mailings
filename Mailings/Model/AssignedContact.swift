//
//  AssignedContact.swift
//  Mailings
//
//  Created 06.02.18.
//

import Foundation
import CoreData

class AssignedContact {
    var objectId: NSManagedObjectID
    var firstname: String?
    var lastname: String?
    
    init(objectId : NSManagedObjectID, firstname: String, lastname: String) {
        self.objectId = objectId
        self.firstname = firstname
        self.lastname = lastname
    }
}
