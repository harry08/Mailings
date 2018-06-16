//
//  Mailing.swift
//  Mailings
//
//  Created on 28.12.17.
//

import Foundation
import CoreData
import os.log

// TODO Create unique folder for mailing when attachments available.

class Mailing: NSManagedObject {
    
    // MARK: -  class functions
    class func createOrUpdateFromDTO(mailingDTO: MailingDTO, in context: NSManagedObjectContext) throws {
        try createOrUpdateFromDTO(mailingDTO: mailingDTO, attachmentChanges: nil, in: context)
    }
    
    /**
     Creates a new mailing or updates an already existing mailing
     Depends on the objectId in MailingDTO.
     */
    class func createOrUpdateFromDTO(mailingDTO: MailingDTO, attachmentChanges: [MailingAttachementChange]?, in context: NSManagedObjectContext) throws {
        if mailingDTO.objectId == nil {
            // New mailing
            os_log("Creating new mailing...", log: OSLog.default, type: .debug)
            var mailingEntity = Mailing(context: context)
            mailingEntity.createtime = Date()
            mailingEntity.updatetime = Date()
            MailingMapper.mapToEntity(mailingDTO: mailingDTO, mailing: &mailingEntity)
            
            if let attachementChanges = attachmentChanges {
                try addMailingAttachmentChanges(attachementChanges, mailing: mailingEntity, in: context)
            }
        } else {
            // Load and update existing mailing
            if let objectId = mailingDTO.objectId {
                os_log("Updating existing mailing with id %s...", log: OSLog.default, type: .debug, objectId)
                
                do {
                    var mailingEntity = try context.existingObject(with: objectId) as! Mailing
                    
                    MailingMapper.mapToEntity(mailingDTO: mailingDTO, mailing: &mailingEntity)
                    mailingEntity.updatetime = Date()
                    
                    if let attachementChanges = attachmentChanges {
                        try addMailingAttachmentChanges(attachementChanges, mailing: mailingEntity, in: context)
                    }
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
    
    /**
     Saves the given list of file attachment changes.
     The file entity is created on demand inside this function.
     */
    private class func addMailingAttachmentChanges(_ attachmentChanges: [MailingAttachementChange], mailing: Mailing, in context: NSManagedObjectContext) throws {
        
        do {
            for i in 0 ..< attachmentChanges.count {
                let attachmentChange = attachmentChanges[i]
                
                // load or create file entity.
                var fileEntity : File?
                if let objectId = attachmentChange.objectId {
                    fileEntity = try File.loadFile(objectId: objectId, in: context)
                } else {
                    fileEntity = File(context: context)
                    fileEntity!.createtime = Date()
                    fileEntity!.filename = attachmentChange.fileName
                }
                if let fileEntity = fileEntity {
                    if attachmentChange.action == .added {
                        mailing.addToAttachments(fileEntity)
                    } else if attachmentChange.action == .removed {
                        let fileName = fileEntity.filename
                        mailing.removeFromAttachments(fileEntity)
                        if let fileName = fileName {
                            FileAttachmentHandler.removeFile(fileName: fileName)
                        }
                    }
                }
            }
        } catch let error as NSError {
            os_log("Could not assign file attachment to mailing. %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
            throw error
        }
    }
    
    /**
     Deletes the given mailing and all attached files
     */
    class func deleteMailing(mailingDTO: MailingDTO, in context: NSManagedObjectContext) throws {
        
        if let objectId = mailingDTO.objectId {
            os_log("Deleting existing mailing with id %s...", log: OSLog.default, type: .debug, objectId)
            
            do {
                let mailingEntity = try context.existingObject(with: objectId) as! Mailing
                
                // Delete attached files
                if let files = mailingEntity.attachments {
                    for case let fileEntity as File in files {
                        let fileName = fileEntity.filename
                        context.delete(fileEntity)
                        if let fileName = fileName {
                            FileAttachmentHandler.removeFile(fileName: fileName)
                        }
                    }
                }
                // Delete mailing
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
    
    /**
     Returns an array of all attached files for the given mailing
     */
    class func getAttachedFiles(objectId: NSManagedObjectID, in context: NSManagedObjectContext) -> [AttachedFile] {
        
        var attachedFiles = [AttachedFile]()
        
        do {
            let mailingEntity = try context.existingObject(with: objectId) as! Mailing
            
            if let files = mailingEntity.attachments {
                attachedFiles.reserveCapacity(files.count)
                for case let fileEntity as File in files {
                    let attachedFile = AttachedFile(objectId: fileEntity.objectID, name: fileEntity.filename!)
                    attachedFiles.append(attachedFile)
                }
            }
        } catch let error as NSError {
            print("Could not load attached files. \(error)")
        }
        
        return attachedFiles
    }
    
    class func generateSubFolderName() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        
        let formattedDate = dateFormatter.string(from: date)
        
        return formattedDate
    }
}
