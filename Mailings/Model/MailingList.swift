//
//  MailingList.swift
//  Mailings
//
//  Created on 03.01.18.
//

import Foundation
import CoreData
import os.log

class MailingList: NSManagedObject {
    
    // MARK: -  class functions
    
    // Loads a contact with a given id.
    class func loadMailingList(objectId: NSManagedObjectID, in context: NSManagedObjectContext) throws -> MailingListDTO {
        do {
            let mailingListEntity = try context.existingObject(with: objectId) as! MailingList
            let mailinglistDTO = MailingListMapper.mapToDTO(mailingList: mailingListEntity)
            
            return mailinglistDTO
        } catch let error as NSError {
            print("Could not load mailingList. \(error), \(error.userInfo)")
            throw error
        }
    }
    
    /**
     Returns all Email addresses from the contacts assigned to the given mailingList
     Used when a mailing should be send to a mailingList.
     */
    class func getEmailAddressesForMailing(objectId: NSManagedObjectID, in context: NSManagedObjectContext) -> [String] {
        var emailAddresses = [String]()
        
        do {
            let mailingListEntity = try context.existingObject(with: objectId) as! MailingList
            
            if let contacts = mailingListEntity.contacts {
                emailAddresses.reserveCapacity(contacts.count)
                for case let contact as MailingContact in contacts {
                    if let email = contact.email {
                        emailAddresses.append(email)
                    }
                }
            }
        } catch let error as NSError {
            print("Could not select mailingList. \(error)")
        }
        
        return emailAddresses
    }
    
    /**
     Returns an array of all contacts of a given mailingList.
     */
    class func getMailingContacts(objectId: NSManagedObjectID, in context: NSManagedObjectContext) -> [MailingContactDTO] {
        
        var mailingContacts = [MailingContactDTO]()
        
        do {
            let mailingListEntity = try context.existingObject(with: objectId) as! MailingList
            
            if let contacts = mailingListEntity.contacts {
                mailingContacts.reserveCapacity(contacts.count)
                for case let contact as MailingContact in contacts {
                    let mailingContactDTO = MailingContactMapper.mapToDTO(contact: contact)
                    mailingContacts.append(mailingContactDTO)
                }
            }
        } catch let error as NSError {
            print("Could not select mailingList. \(error)")
        }
        
        return mailingContacts
    }
    
    /**
     Returns the mailingLists that are marked as default.
     These mailingLists are automatically assigned to a newly created contact.
     */
    class func getDefaultMailingLists(in context: NSManagedObjectContext) -> [MailingList] {
        let request : NSFetchRequest<MailingList> = MailingList.fetchRequest()
        request.predicate = NSPredicate(format: "assignasdefault = true")
        do {
            let matches = try context.fetch(request)
            return matches
        } catch let error as NSError {
           print("Could not select mailingLists. \(error)")
        }
        
        return []
    }
    
    /**
     Creates a new mailing or updates an already existing mailing
     Depends on the objectId in MailingDTO.
     */
    class func createOrUpdateFromDTO(_ mailingListDTO: MailingListDTO, in context: NSManagedObjectContext) throws {
        if mailingListDTO.objectId == nil {
            // New mailing
            os_log("Creating new mailingList...", log: OSLog.default, type: .debug)
            var mailingListEntity = MailingList(context: context)
            mailingListEntity.createtime = Date()
            mailingListEntity.updatetime = Date()
            MailingListMapper.mapToEntity(mailingListDTO: mailingListDTO, mailingList: &mailingListEntity)
        } else {
            // Load and update existing mailing
            if let objectId = mailingListDTO.objectId {
                os_log("Updating existing mailingList with id %s...", log: OSLog.default, type: .debug, objectId)
                
                do {
                    var mailingListEntity = try context.existingObject(with: objectId) as! MailingList
                    
                    MailingListMapper.mapToEntity(mailingListDTO: mailingListDTO, mailingList: &mailingListEntity)
                    mailingListEntity.updatetime = Date()
                } catch let error as NSError {
                    os_log("Could not load mailingList. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
                    throw error
                }
            }
        }
        
        do {
            try context.save()
            os_log("MailingList saved", log: OSLog.default, type: .debug)
        } catch let error as NSError {
            os_log("Could not save mailingList. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            throw error
        }
    }
    
    class func addContacts(_ contacts: [MailingContact], objectId: NSManagedObjectID, in context: NSManagedObjectContext) throws {
      
        do {
            let mailingListEntity = try context.existingObject(with: objectId) as! MailingList
            
            for i in 0 ..< contacts.count {
                let contact = contacts[i]
                mailingListEntity.addToContacts(contact)
            }
            
            try context.save()
            os_log("MailingList saved", log: OSLog.default, type: .debug)
        } catch let error as NSError {
            os_log("Could not save mailingList. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            throw error
        }
    }
    
    class func addContacts(_ contacts: [MailingContactDTO], objectId: NSManagedObjectID, in context: NSManagedObjectContext) throws {
        
        do {
            let mailingListEntity = try context.existingObject(with: objectId) as! MailingList
            
            for i in 0 ..< contacts.count {
                let contactDTO = contacts[i]
                let contact = try MailingContact.loadContactEntity(objectId: contactDTO.objectId!, in: context)
                mailingListEntity.addToContacts(contact)
            }
            
            try context.save()
            os_log("MailingList saved", log: OSLog.default, type: .debug)
        } catch let error as NSError {
            os_log("Could not save mailingList. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            throw error
        }
    }
}
