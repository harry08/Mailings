//
//  MailingAttachementChange.swift
//  Mailings
//
//  Created on 04.06.18.
//

import Foundation
import CoreData

/**
 Type of list change action
 */
enum ListChangeAction: Int {
    case added, removed
}

/**
 Information about a change to the attachments of a mailing.
 Add or removal of a file.
 */
struct MailingAttachmentChange: Hashable {
    var objectId: NSManagedObjectID?
    var fileName: String
    var folderName : String
    var action: ListChangeAction
    
    init(objectId : NSManagedObjectID, fileName: String, folderName: String, action: ListChangeAction) {
        self.objectId = objectId
        self.fileName = fileName
        self.folderName = folderName
        self.action = action
    }
    
    init(fileName: String, folderName: String, action: ListChangeAction) {
        self.fileName = fileName
        self.folderName = folderName
        self.action = action
    }
    
    var hashValue: Int {
        get {
            return fileName.hashValue
        }
    }
}

// For Equatable of MailingAttachmentChange
func ==(lhs: MailingAttachmentChange, rhs: MailingAttachmentChange) -> Bool {
    return lhs.fileName == rhs.fileName
}
