//
//  File.swift
//  Mailings
//
//  Created on 14.06.18.
//

import Foundation
import CoreData

class File: NSManagedObject {
    
    // MARK: -  class functions
    
    class func loadFile(objectId: NSManagedObjectID, in context: NSManagedObjectContext) throws -> File {
        do {
            let fileEntity = try context.existingObject(with: objectId) as! File
            return fileEntity
        } catch let error as NSError {
            print("Could not load file. \(error), \(error.userInfo)")
            throw error
        }
    }    
}
