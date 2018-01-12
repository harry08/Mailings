//
//  MailingList.swift
//  Mailings
//
//  Created on 03.01.18.
//

import Foundation
import CoreData

class MailingList: NSManagedObject {
    
    // MARK: -  class functions
    
    // Loads a contact with a given id.
    class func loadMailinglist(objectId: NSManagedObjectID, in context: NSManagedObjectContext) throws -> MailingListDTO {
        do {
            let mailingListEntity = try context.existingObject(with: objectId) as! MailingList
            let mailinglistDTO = MailingListMapper.mapToDTO(mailinglist: mailingListEntity)
            
            return mailinglistDTO
        } catch let error as NSError {
            print("Could not load mailinglist. \(error), \(error.userInfo)")
            throw error
        }
    }
    
    // Returns all Email addresses of the given mailinglist
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
            print("Could not select mailinglist. \(error)")
        }
        
        return emailAddresses
    }
    
    class func getDefaultMailingLists(in context: NSManagedObjectContext) -> [MailingList] {
        let request : NSFetchRequest<MailingList> = MailingList.fetchRequest()
        request.predicate = NSPredicate(format: "assignasdefault = true")
        do {
            let matches = try context.fetch(request)
            return matches
        } catch let error as NSError {
           print("Could not select mailinglists. \(error)")
        }
        
        return []
    }
}
