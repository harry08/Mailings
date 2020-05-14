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
    
    // Loads a mailinglist with a given id.
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
    
    class func loadMailingListByBame(_ name: String, in context: NSManagedObjectContext) throws -> MailingListDTO? {
        do {
            let request : NSFetchRequest<MailingList> = MailingList.fetchRequest()
            let predicate = NSPredicate(format: "name = %@", name)
            request.predicate = predicate
            
            let mailingLists = try context.fetch(request)
            if let mailingList = mailingLists.first {
                let mailinglistDTO = MailingListMapper.mapToDTO(mailingList: mailingList)
                
                return mailinglistDTO
            }
        } catch let error as NSError {
            print("Could not load mailingList. \(error), \(error.userInfo)")
            throw error
        }
        
        return nil
    }
    
    // Loads a mailinglist with a given id.
    class func loadMailingListEntity(objectId: NSManagedObjectID, in context: NSManagedObjectContext) throws -> MailingList {
        do {
            let mailingListEntity = try context.existingObject(with: objectId) as! MailingList
            return mailingListEntity
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
        
        assingedContacts.sort()
        
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
     Returns the mailingLists that are marked as default.
     */
    class func getDefaultMailingListsAsDTO(in context: NSManagedObjectContext) -> [MailingListDTO] {
        var mailingLists = [MailingListDTO]()
        
        let defaultMailingLists = getDefaultMailingLists(in: context)
        for mailingList in defaultMailingLists {
            let mailingListDTO = MailingListMapper.mapToDTO(mailingList: mailingList)
            mailingLists.append(mailingListDTO)
        }
        
        return mailingLists
    }
    
    /**
     Returns all mailingLists
     */
    class func getAllMailingLists(in context: NSManagedObjectContext) -> [MailingList] {
        let request : NSFetchRequest<MailingList> = MailingList.fetchRequest()
        do {
            let matches = try context.fetch(request)
            return matches
        } catch let error as NSError {
            print("Could not select mailingLists. \(error)")
        }
        
        return []
    }
    
    class func getAllMailingListsAsDTO(in context: NSManagedObjectContext) -> [MailingListDTO] {
        var mailingLists = [MailingListDTO]()
        
        let allMailingLists = getAllMailingLists(in: context)
        for mailingList in allMailingLists {
            let mailingListDTO = MailingListMapper.mapToDTO(mailingList: mailingList)
            mailingLists.append(mailingListDTO)
        }
        
        return mailingLists
    }
    
    class func getMailingListByName(_ name: String, mailingLists: [MailingListDTO]) -> MailingListDTO? {
        for mailingList in mailingLists {
            if mailingList.name == name {
                return mailingList
            }
        }
        
        return nil
    }
    
    /**
     Creates a new mailing or updates an already existing mailing
     Depends on the objectId in MailingDTO.
     */
    class func createOrUpdateFromDTO(_ mailingListDTO: MailingListDTO, in context: NSManagedObjectContext) throws {
        try createOrUpdateFromDTO(mailingListDTO, assignmentChanges: nil, in: context)
    }
    
    /**
     Creates a new mailing or updates an already existing mailing
     Depends on the objectId in MailingDTO.
     */
    class func createOrUpdateFromDTO(_ mailingListDTO: MailingListDTO, assignmentChanges: [ContactAssignmentChange]?, in context: NSManagedObjectContext) throws {
        if mailingListDTO.objectId == nil {
            // New mailing
            print("Creating new mailingList...")
            var mailingListEntity = MailingList(context: context)
            mailingListEntity.createtime = Date()
            mailingListEntity.updatetime = Date()
            MailingListMapper.mapToEntity(mailingListDTO: mailingListDTO, mailingList: &mailingListEntity)
            
            if let assignmentChanges = assignmentChanges {
                try addContactAssignmentChanges(assignmentChanges, mailingList: mailingListEntity, in: context)
            }
        } else {
            // Load and update existing mailing
            if let objectId = mailingListDTO.objectId {
                print("Updating existing mailingList with id \(objectId)...")
                
                do {
                    var mailingListEntity = try context.existingObject(with: objectId) as! MailingList
                    
                    MailingListMapper.mapToEntity(mailingListDTO: mailingListDTO, mailingList: &mailingListEntity)
                    mailingListEntity.updatetime = Date()
                    
                    if let assignmentChanges = assignmentChanges {
                        try addContactAssignmentChanges(assignmentChanges, mailingList: mailingListEntity, in: context)
                    }
                } catch let error as NSError {
                    print("Could not update existing mailingList. \(error), \(error.userInfo)")
                    throw error
                }
            }
        }
        
        do {
            try context.save()
            print("MailingList saved")
        } catch let error as NSError {
            print("Could not save mailingList. \(error), \(error.userInfo)")
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
            print("Could not load contact and assign it to the mailingList. \(error), \(error.userInfo)")
            throw error
        }
    }
    
    class func deleteMailingList(_ mailingListDTO: MailingListDTO, in context: NSManagedObjectContext) throws {
        
        if let objectId = mailingListDTO.objectId {
            print("Deleting existing mailingList with id \(objectId)...")
            
            do {
                let mailingListEntity = try context.existingObject(with: objectId) as! MailingList
                context.delete(mailingListEntity)
            } catch let error as NSError {
                print("Could not delete mailingList. \(error), \(error.userInfo)")
                throw error
            }
        }
        
        do {
            try context.save()
            print("MailingList deleted")
        } catch let error as NSError {
            print("Could not delete mailingList. \(error), \(error.userInfo)")
            throw error
        }
    }
}
