//
//  AttachedFile.swift
//  Mailings
//
//  Created on 04.06.18.
//

import Foundation
import CoreData

class AttachedFile {
    var objectId: NSManagedObjectID?
    var name: String
    
    init(objectId : NSManagedObjectID, name: String) {
        self.objectId = objectId
        self.name = name
    }
    
    init(name: String) {
        self.name = name
    }
}
