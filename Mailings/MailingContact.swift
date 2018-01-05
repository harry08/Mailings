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
    class func createContact(contact: CNContact, groupName: String, in context: NSManagedObjectContext) throws {
        var existing : Bool = false
        do {
            existing = try contactExists(contact: contact, in: context)
        } catch {
            throw error
        }
        
        if !existing {
            var email : String?
            if contact.emailAddresses.count > 0 {
                email = contact.emailAddresses[0].value as String
            }
            print("Creating customer \(contact.givenName) \(contact.familyName), \(String(describing: email))...")
            let mailingContact = MailingContact(context: context)
            mailingContact.lastname = contact.familyName
            mailingContact.firstname = contact.givenName
            if (email != nil) {
                mailingContact.email = email
            }
            mailingContact.createtime = Date()
            mailingContact.updatetime = Date()
            mailingContact.notes = "Import aus Kontaktgruppe: " + groupName
            
            // Assignment to default mailinglists
            let defaultMailingLists = MailingList.getDefaultMailingLists(in: context)
            for i in 0 ..< defaultMailingLists.count {
                let mailingList = defaultMailingLists[i]
                mailingList.addToContacts(mailingContact)
            }
        } else {
            print("Customer \(contact.givenName) \(contact.familyName) already exists.")
        }
    }
    
    // Creates a new contact or updates an already existing contact
    // Depends on the objectId in MailingContactDTO.
    class func createOrUpdateFromDTO(contactDTO: MailingContactDTO, in context: NSManagedObjectContext) throws {
        if contactDTO.objectId == nil {
            // New contact
            print("Creating new contact...")
            var contactEntity = MailingContact(context: context)
            contactEntity.createtime = Date()
            contactEntity.updatetime = Date()
            MailingContactMapper.mapToEntity(contactDTO: contactDTO, contact: &contactEntity)
            
            // Assignment to default mailinglists
            let defaultMailingLists = MailingList.getDefaultMailingLists(in: context)
            for i in 0 ..< defaultMailingLists.count {
                let mailingList = defaultMailingLists[i]
                mailingList.addToContacts(contactEntity)
            }
        } else {
            // Load and update existing contact
            if let objectId = contactDTO.objectId {
                print("Updating existing contact with id \(objectId) ...")
                
                do {
                    var contactEntity = try context.existingObject(with: objectId) as! MailingContact
                    MailingContactMapper.mapToEntity(contactDTO: contactDTO, contact: &contactEntity)
                    contactEntity.updatetime = Date()
                } catch let error as NSError {
                    print("Could not load contact. \(error), \(error.userInfo)")
                    throw error
                }
            }
        }
        
        do {
            try context.save()
            print("Saved changes")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
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
            print("Could not load contact. \(error), \(error.userInfo)")
            throw error
        }
    }
    
    // MARK: - statistic functions
    
    // Returns the number of non retired contacts
    class func getNrOfContacts(in context: NSManagedObjectContext) -> Int {
        var count = 0
        
        let request : NSFetchRequest<MailingContact> = MailingContact.fetchRequest()
        request.predicate = NSPredicate(format: "retired = false")
        do {
            let matches = try context.fetch(request)
            count = matches.count
        } catch let error as NSError {
            print("Could not count contacts. \(error), \(error.userInfo)")
        }
        
        return count
    }
}
