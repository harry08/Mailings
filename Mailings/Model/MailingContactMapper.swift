//
//  MailingContactMapper.swift
//  Mailings
//
//  Created on 03.01.18.
//

import Foundation

class MailingContactMapper {
    
    class func mapToDTO(contact: MailingContact) -> MailingContactDTO {
        let contactDTO = MailingContactDTO(objectId: contact.objectID, firstname: contact.firstname, lastname: contact.lastname, email: contact.email)
        
        return contactDTO
    }
    
    class func mapToEntity(contactDTO: MailingContactDTO, contact: inout MailingContact) {
        contact.firstname = contactDTO.firstname
        contact.lastname = contactDTO.lastname
        contact.email = contactDTO.email
    }
}
