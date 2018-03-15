//
//  Mailing.swift
//  Mailings
//
//  Created on 28.12.17.
//

import Foundation
import CoreData
import os.log

class Mailing: NSManagedObject {
    
    // MARK: -  class functions
    
    /**
     Creates a new mailing or updates an already existing mailing
     Depends on the objectId in MailingDTO.
     */
    class func createOrUpdateFromDTO(mailingDTO: MailingDTO, in context: NSManagedObjectContext) throws {
        if mailingDTO.objectId == nil {
            // New mailing
            os_log("Creating new mailing...", log: OSLog.default, type: .debug)
            var mailingEntity = Mailing(context: context)
            mailingEntity.createtime = Date()
            mailingEntity.updatetime = Date()
            MailingMapper.mapToEntity(mailingDTO: mailingDTO, mailing: &mailingEntity)
        } else {
            // Load and update existing mailing
            if let objectId = mailingDTO.objectId {
                os_log("Updating existing mailing with id %s...", log: OSLog.default, type: .debug, objectId)
                
                do {
                    var mailingEntity = try context.existingObject(with: objectId) as! Mailing
                    
                    MailingMapper.mapToEntity(mailingDTO: mailingDTO, mailing: &mailingEntity)
                    mailingEntity.updatetime = Date()
                } catch let error as NSError {
                    os_log("Could not load contact. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
                    throw error
                }
            }
        }
        
        do {
            try context.save()
            os_log("Mailing saved", log: OSLog.default, type: .debug)
        } catch let error as NSError {
            os_log("Could not save mailing. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            throw error
        }
    }
    
    class func deleteMailing(mailingDTO: MailingDTO, in context: NSManagedObjectContext) throws {
        
        if let objectId = mailingDTO.objectId {
            os_log("Deleting existing mailing with id %s...", log: OSLog.default, type: .debug, objectId)
            
            do {
                let mailingEntity = try context.existingObject(with: objectId) as! Mailing
                context.delete(mailingEntity)
            } catch let error as NSError {
                os_log("Could not delete mailing. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
                throw error
            }
        }
        
        do {
            try context.save()
            os_log("Mailing deleted", log: OSLog.default, type: .debug)
        } catch let error as NSError {
            os_log("Could not delete mailing. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            throw error
        }
    }
    
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
