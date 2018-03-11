//
//  AssignedMailingList.swift
//  Mailings
//
//  Created on 06.03.18.

import Foundation
import CoreData

class AssignedMailingList {
    var objectId: NSManagedObjectID
    var name: String?
    
    init(objectId : NSManagedObjectID, name: String) {
        self.objectId = objectId
        self.name = name
    }
}
