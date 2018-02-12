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
    class func getEmailAddressesForMailingList(objectId: NSManagedObjectID, in context: NSManagedObjectContext) -> [String] {
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
     Returns an array of all assinged contacts of a given mailingList.
     */
    class func getAssignedContacts(objectId: NSManagedObjectID, in context: NSManagedObjectContext) -> [AssignedContact] {
        
        var assingedContacts = [AssignedContact]()
        
        do {
            let mailingListEntity = try context.existingObject(with: objectId) as! MailingList
            
            if let contacts = mailingListEntity.contacts {
                assingedContacts.reserveCapacity(contacts.count)
                for case let contact as MailingContact in contacts {
                    let assingedContact = MailingContactMapper.mapToAssignedContact(contact: contact)
                    assingedContacts.append(assingedContact)
                }
            }
        } catch let error as NSError {
            print("Could not select mailingList. \(error)")
        }
        
        return assingedContacts
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
        try createOrUpdateFromDTO(mailingListDTO, assignmentChanges: [ContactAssignmentChange](), in: context)
    }
    
    /**
     Creates a new mailing or updates an already existing mailing
     Depends on the objectId in MailingDTO.
     */
    class func createOrUpdateFromDTO(_ mailingListDTO: MailingListDTO, assignmentChanges: [ContactAssignmentChange], in context: NSManagedObjectContext) throws {
        if mailingListDTO.objectId == nil {
            // New mailing
            os_log("Creating new mailingList...", log: OSLog.default, type: .debug)
            var mailingListEntity = MailingList(context: context)
            mailingListEntity.createtime = Date()
            mailingListEntity.updatetime = Date()
            MailingListMapper.mapToEntity(mailingListDTO: mailingListDTO, mailingList: &mailingListEntity)
            
            if assignmentChanges.count > 0 {
                try addContactAssignmentChanges(assignmentChanges, mailingList: mailingListEntity, in: context)
            }
        } else {
            // Load and update existing mailing
            if let objectId = mailingListDTO.objectId {
                os_log("Updating existing mailingList with id %s...", log: OSLog.default, type: .debug, objectId)
                
                do {
                    var mailingListEntity = try context.existingObject(with: objectId) as! MailingList
                    
                    MailingListMapper.mapToEntity(mailingListDTO: mailingListDTO, mailingList: &mailingListEntity)
                    mailingListEntity.updatetime = Date()
                    
                    if assignmentChanges.count > 0 {
                        try addContactAssignmentChanges(assignmentChanges, mailingList: mailingListEntity, in: context)
                    }
                } catch let error as NSError {
                    os_log("Could not update existing mailingList. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
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
    
    /**
     Saves the given list of contactassignment changes.
     */
    private class func addContactAssignmentChanges(_ assignmentChanges: [ContactAssignmentChange], mailingList: MailingList, in context: NSManagedObjectContext) throws {
    
        do {
            for i in 0 ..< assignmentChanges.count {
                let assignmentChange = assignmentChanges[i]
                
                let contact = try MailingContact.loadContactEntity(objectId: assignmentChange.objectId, in: context)
                if assignmentChange.action == "A" {
                    mailingList.addToContacts(contact)
                } else if assignmentChange.action == "R" {
                    mailingList.removeFromContacts(contact)
                }
            }
        } catch let error as NSError {
            os_log("Could not load contact and assign it to the mailingList. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            throw error
        }
    }
}
