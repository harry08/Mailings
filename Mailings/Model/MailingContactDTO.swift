//
//  MailingContactDTO.swift
//  Mailings
//
//  Created on 03.01.18.
//

import Foundation

import CoreData

struct MailingContactDTO {
    var objectId: NSManagedObjectID?
    var firstname: String?
    var lastname: String?
    var email: String?
    var notes: String?
}
