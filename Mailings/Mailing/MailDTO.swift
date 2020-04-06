//
//  MailDTO.swift
//  CustomerManager
//
//  Created on 04.12.17.
//

import Foundation

struct MailDTO {
    var mailingDTO: MailingDTO
    var emailAddresses: [String]
    var recipientAsBcc = false
    var emailSent = false
    var folder: String?
    var attachments = [String]()
}
