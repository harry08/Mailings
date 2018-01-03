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
    
    // Checks if for the given contact a customer already exists.
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
    
    // Creates a new customer or updates an already existing customer
    // Depends on the objectId in CustomerDTO.
    class func createOrUpdateFromDTO(contactDTO: MailingContactDTO, in context: NSManagedObjectContext) throws {
        if contactDTO.objectId == nil {
            // New contact
            print("Creating new contact...")
            var contactEntity = MailingContact(context: context)
            contactEntity.createtime = Date()
            contactEntity.updatetime = Date()
            MailingContactMapper.mapToEntity(contactDTO: contactDTO, contact: &contactEntity)
        } else {
            // Load and update existing contact
            if let objectId = contactDTO.objectId {
                print("Updating existing customer with id \(objectId) ...")
                
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
