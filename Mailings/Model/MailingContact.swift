//
//  MailingContact.swift
//  Mailings
//
//  Created on 28.12.17.
//

import Foundation
import CoreData
import Contacts
import os.log

class MailingContact: NSManagedObject {

    // MARK: -  class functions
    
    // Checks if for the given addressbook contact a mailingcontact already exists.
    // Check is done by firstname and lastname
    class func contactExists(contact: CNContact, in context: NSManagedObjectContext) throws -> Bool {
        var existing : Bool = false
        
        let request : NSFetchRequest<MailingContact> = MailingContact.fetchRequest()
        request.predicate = NSPredicate(format: "lastname = %@ and firstname = %@", contact.familyName, contact.givenName)
        do {
            let matches = try context.fetch(request)
            if (matches.count > 0) {
                existing = true
            }
        } catch {
            throw error
        }
        
        return existing
    }
    
    // Creates a new mailingcontact from a given addressbook contact.
    class func createContact(contact: CNContact, in context: NSManagedObjectContext) throws {
        var existing : Bool = false
        do {
            existing = try contactExists(contact: contact, in: context)
        } catch {
            throw error
        }
        
        var email : String?
        if contact.emailAddresses.count > 0 {
            email = contact.emailAddresses[0].value as String
        }
        let contactInfo = contact.givenName + " " + contact.familyName + ", " + String(describing: email)
        
        if !existing {
            os_log("Creating contact %s ...", log: OSLog.default, type: .info, contactInfo)
            let mailingContact = MailingContact(context: context)
            mailingContact.lastname = contact.familyName
            mailingContact.firstname = contact.givenName
            if (email != nil) {
                mailingContact.email = email
            }
            mailingContact.createtime = Date()
            mailingContact.updatetime = Date()
            
            // Assignment to default mailinglists
            let defaultMailingLists = MailingList.getDefaultMailingLists(in: context)
            for i in 0 ..< defaultMailingLists.count {
                let mailingList = defaultMailingLists[i]
                mailingList.addToContacts(mailingContact)
            }
        } else {
            os_log("Contact %s already exists...", log: OSLog.default, type: .info, contactInfo)
        }
    }
    
    // Creates a new contact or updates an already existing contact
    // Depends on the objectId in MailingContactDTO.
    class func createOrUpdateFromDTO(contactDTO: MailingContactDTO, in context: NSManagedObjectContext) throws {
        try createOrUpdateFromDTO(contactDTO: contactDTO, assignmentChanges: nil, in: context)
    }
    
    /**
     Creates a new contact or updates an already existing contact
     Depends on the objectId in MailingContactDTO.
     The assignmentChanges array is optional. i.e. if not set, the default values get
     */
    class func createOrUpdateFromDTO(contactDTO: MailingContactDTO, assignmentChanges: [MailingListAssignmentChange]?, in context: NSManagedObjectContext) throws {
        if contactDTO.objectId == nil {
            // New contact
            os_log("Creating new contact...", log: OSLog.default, type: .debug)
            var contactEntity = MailingContact(context: context)
            contactEntity.createtime = Date()
            contactEntity.updatetime = Date()
            MailingContactMapper.mapToEntity(contactDTO: contactDTO, contact: &contactEntity)
            
            if assignmentChanges == nil {
                // Assignment to default mailinglists
                let defaultMailingLists = MailingList.getDefaultMailingLists(in: context)
                for i in 0 ..< defaultMailingLists.count {
                    let mailingList = defaultMailingLists[i]
                    mailingList.addToContacts(contactEntity)
                }
            } else {
                try addMailingListAssignmentChanges(assignmentChanges!, contact: contactEntity, in: context)
            }
        } else {
            // Load and update existing contact
            if let objectId = contactDTO.objectId {
                os_log("Updating existing contact with id %s...", log: OSLog.default, type: .debug, objectId)
                
                do {
                    var contactEntity = try context.existingObject(with: objectId) as! MailingContact
                    MailingContactMapper.mapToEntity(contactDTO: contactDTO, contact: &contactEntity)
                    contactEntity.updatetime = Date()
                    
                    if let assignmentChanges = assignmentChanges {
                        try addMailingListAssignmentChanges(assignmentChanges, contact: contactEntity, in: context)
                    }
                } catch let error as NSError {
                    os_log("Could not load contact. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
                    throw error
                }
            }
        }
        
        do {
            try context.save()
            os_log("Contact saved", log: OSLog.default, type: .debug)
        } catch let error as NSError {
            os_log("Could not save contact. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            throw error
        }
    }
    
    /**
     Saves the given list of mailinglist assignment changes.
     */
    private class func addMailingListAssignmentChanges(_ assignmentChanges: [MailingListAssignmentChange], contact: MailingContact, in context: NSManagedObjectContext) throws {
        
        do {
            for i in 0 ..< assignmentChanges.count {
                let assignmentChange = assignmentChanges[i]
                
                let mailingList = try MailingList.loadMailingListEntity(objectId: assignmentChange.objectId, in: context)
                if assignmentChange.action == "A" {
                    mailingList.addToContacts(contact)
                } else if assignmentChange.action == "R" {
                    mailingList.removeFromContacts(contact)
                }
            }
        } catch let error as NSError {
            os_log("Could not mailinglists and assign it to the mailingList. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            throw error
        }
    }
    
    class func deleteContact(contactDTO: MailingContactDTO, in context: NSManagedObjectContext) throws {
        
        if let objectId = contactDTO.objectId {
            os_log("Deleting existing contact with id %s...", log: OSLog.default, type: .debug, objectId)
            
            do {
                let contactEntity = try context.existingObject(with: objectId) as! MailingContact
                context.delete(contactEntity)
            } catch let error as NSError {
                os_log("Could not delete contact. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
                throw error
            }
        }
        
        do {
            try context.save()
            os_log("Contact deleted", log: OSLog.default, type: .debug)
        } catch let error as NSError {
            os_log("Could not delete contact. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            throw error
        }
    }
    
    // Loads a contact with a given id.
    class func loadContact(objectId: NSManagedObjectID, in context: NSManagedObjectContext) throws -> MailingContactDTO {
        do {
            let contactEntity = try context.existingObject(with: objectId) as! MailingContact
            let contactDTO = MailingContactMapper.mapToDTO(contact: contactEntity)
            
            return contactDTO
        } catch let error as NSError {
            os_log("Could not load contact. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            throw error
        }
    }
    
    // Loads a contact with a given id.
    class func loadContactEntity(objectId: NSManagedObjectID, in context: NSManagedObjectContext) throws -> MailingContact {
        do {
            let contactEntity = try context.existingObject(with: objectId) as! MailingContact
            return contactEntity
        } catch let error as NSError {
            os_log("Could not load contact. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            throw error
        }
    }
    
    // Returns all Email addresses for the given mailinglist
    class func getEmailAddressesForMailingList(_ mailingList: String, in context: NSManagedObjectContext) -> [String] {
        var emailAddresses = [String]()
        
        let request : NSFetchRequest<MailingList> = MailingList.fetchRequest()
        let predicate = NSPredicate(format: "name = = %@", mailingList)
        request.predicate = predicate
        
        do {
            let mailingLists = try context.fetch(request)
            if let mailingList = mailingLists.first {
                let contacts = mailingList.contacts?.allObjects as! [MailingContact]
                
                emailAddresses.reserveCapacity(contacts.count)
                contacts.forEach { contact in
                    if let email = contact.email {
                        emailAddresses.append(email)
                    }
                }
            }
        } catch let error as NSError {
            print("Could not select contacts for mailinglist. \(error)")
        }
        
        return emailAddresses
    }
    
    /**
     Returns an array of all assinged mailing lists of a given contact.
     */
    class func getAssignedMailingLists(objectId: NSManagedObjectID, in context: NSManagedObjectContext) -> [AssignedMailingList] {
        
        var assignedMailingLists = [AssignedMailingList]()
        
        do {
            let contactEntity = try context.existingObject(with: objectId) as! MailingContact
            
            if let mailingLists = contactEntity.lists {
                assignedMailingLists.reserveCapacity(mailingLists.count)
                for case let mailingList as MailingList in mailingLists {
                    let assignedMailingList = MailingListMapper.mapToAssignedMailingList(mailingList: mailingList)
                    assignedMailingLists.append(assignedMailingList)
                }
            }
        } catch let error as NSError {
            print("Could not select contact. \(error)")
        }
        
        return assignedMailingLists
    }
    
    // MARK: - statistic functions
    
    // Returns the number of non retired contacts
    class func getNrOfContacts(in context: NSManagedObjectContext) -> Int {
        var count = 0
        
        let request : NSFetchRequest<MailingContact> = MailingContact.fetchRequest()
        do {
            let matches = try context.fetch(request)
            count = matches.count
        } catch let error as NSError {
            os_log("Could not count contacts. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
        }
        
        return count
    }
}
