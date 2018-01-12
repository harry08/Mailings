//
//  Mailing.swift
//  Mailings
//
//  Created on 28.12.17.
//

import Foundation
import CoreData

class Mailing: NSManagedObject {
    
    // MARK: -  class functions
    
    // Loads a mailing with a given id.
    class func loadMailing(objectId: NSManagedObjectID, in context: NSManagedObjectContext) throws -> MailingDTO {
        do {
            let mailingEntity = try context.existingObject(with: objectId) as! Mailing
            let mailingDTO = MailingMapper.mapToDTO(mailing: mailingEntity)
            
            return mailingDTO
        } catch let error as NSError {
            print("Could not load mailing. \(error), \(error.userInfo)")
            throw error
        }
    }
    
}
