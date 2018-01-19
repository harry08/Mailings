//
//  MailingListDTO.swift
//  Mailings
//
//  Created on 04.01.18.
//

import Foundation
import CoreData

struct MailingListDTO {
    var objectId: NSManagedObjectID?
    var name: String?
    var recipientAsBcc: Bool = false
    var assignAsDefault: Bool = false
}
