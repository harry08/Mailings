//
//  MailingContact.swift
//  Mailings
//
//  Created on 28.12.17.
//

import Foundation
import CoreData
import Contacts

class MailingContact: NSManagedObject {

    // MARK: -  class functions
    
    // Checks if for the given addressbook contact a mailingcontact already exists.
    // Check is done by firstname and lastname
    class func contactExists(contact: CNContact, in context: NSManagedObjectContext) throws -> Bool {        
        return try contactExists(firstname: contact.givenName, lastname: contact.familyName, in: context)
    }
    
    class func contactExists(firstname: String, lastname: String, in context: NSManagedObjectContext) throws -> Bool {
    
        var existing : Bool = false
        
        let request : NSFetchRequest<MailingContact> = MailingContact.fetchRequest()
        request.predicate = NSPredicate(format: "lastname = %@ and firstname = %@", lastname, firstname)
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
            print("Creating contact \(contactInfo)")
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
            print("Contact \(contactInfo) already exists.")
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
     The assignmentChanges array is optional. i.e. if not set, the default values get set
     */
    class func createOrUpdateFromDTO(contactDTO: MailingContactDTO, assignmentChanges: [MailingListAssignmentChange]?, in context: NSManagedObjectContext) throws {
        if contactDTO.objectId == nil {
            // New contact
            print("Creating new contact...")
            var contactEntity = MailingContact(context: context)
            MailingContactMapper.mapToEntity(contactDTO: contactDTO, contact: &contactEntity)
            // The DTO can contain craetetime and updatetime in case of a data import. Then these values are used
            // Otherwise newly set
            if let createtime = contactDTO.createtime {
                contactEntity.createtime = createtime
            } else {
                contactEntity.createtime = Date()
            }
            if let updatetime = contactDTO.updatetime {
                contactEntity.updatetime = updatetime
            } else {
                contactEntity.updatetime = Date()
            }
            
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
                print("Updating existing contact with id \(objectId)")
                
                do {
                    var contactEntity = try context.existingObject(with: objectId) as! MailingContact
                    MailingContactMapper.mapToEntity(contactDTO: contactDTO, contact: &contactEntity)
                    contactEntity.updatetime = Date()
                    
                    if let assignmentChanges = assignmentChanges {
                        try addMailingListAssignmentChanges(assignmentChanges, contact: contactEntity, in: context)
                    }
                } catch let error as NSError {
                    print("Could not load contact. \(error), \(error.userInfo)")
                    throw error
                }
            }
        }
        
        do {
            try context.save()
            print("Contact saved")
        } catch let error as NSError {
            print("Could not load contact. \(error), \(error.userInfo)")
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
            print("Could not mailinglists and assign it to the mailingList. \(error), \(error.userInfo))")
            throw error
        }
    }
    
    class func deleteContact(contactDTO: MailingContactDTO, in context: NSManagedObjectContext) throws {
        
        if let objectId = contactDTO.objectId {
            print("Deleting existing contact with id \(objectId)...")
            
            do {
                let contactEntity = try context.existingObject(with: objectId) as! MailingContact
                context.delete(contactEntity)
            } catch let error as NSError {
                print("Could not delete contact. \(error), \(error.userInfo))")
                throw error
            }
        }
        
        do {
            try context.save()
            print("Contact deleted")
        } catch let error as NSError {
            print("Could not delete contact. \(error), \(error.userInfo))")
            throw error
        }
    }
    
    // Loads a contact with a given id.
    class func loadContact(_ objectId: NSManagedObjectID, in context: NSManagedObjectContext) throws -> MailingContactDTO {
        do {
            let contactEntity = try context.existingObject(with: objectId) as! MailingContact
            let contactDTO = MailingContactMapper.mapToDTO(contact: contactEntity)
            
            return contactDTO
        } catch let error as NSError {
            print("Could not load contact. \(error), \(error.userInfo))")
            throw error
        }
    }
    
    // Loads a contact with a given id.
    class func loadContactEntity(objectId: NSManagedObjectID, in context: NSManagedObjectContext) throws -> MailingContact {
        do {
            let contactEntity = try context.existingObject(with: objectId) as! MailingContact
            return contactEntity
        } catch let error as NSError {
            print("Could not load contact. \(error), \(error.userInfo))")
            throw error
        }
    }
    
    // Returns all Email addresses for the given mailinglist
    class func getEmailAddressesForMailingList(_ mailingList: String, in context: NSManagedObjectContext) -> [String] {
        var emailAddresses = [String]()
        
        let request : NSFetchRequest<MailingList> = MailingList.fetchRequest()
        let predicate = NSPredicate(format: "name = %@", mailingList)
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
    
    class func getAllContacts(in context: NSManagedObjectContext) -> [MailingContact] {
        let request : NSFetchRequest<MailingContact> = MailingContact.fetchRequest()
        do {
            let matches = try context.fetch(request)
            return matches
        } catch let error as NSError {
            print("Could not select contacts. \(error)")
        }
        
        return []
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
            print("Could not count contacts. \(error), \(error.userInfo))")
        }
        
        return count
    }
}
