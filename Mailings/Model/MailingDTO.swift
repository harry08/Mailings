//
//  MailingDTO.swift
//  Mailings
//
//  Created on 07.01.18.
//

import Foundation
import CoreData

struct MailingDTO {
    var objectId: NSManagedObjectID?
    var title: String?
    var text: String?
    // folder for attachments
    var folder: String?
    var createtime: Date?
    var updatetime: Date?
}
