//
//  MailingContactMapper.swift
//  Mailings
//
//  Created on 03.01.18.
//

import Foundation

class MailingContactMapper {
    
    class func mapToDTO(contact: MailingContact) -> MailingContactDTO {
        let contactDTO = MailingContactDTO(objectId: contact.objectID, firstname: contact.firstname, lastname: contact.lastname, email: contact.email, notes: contact.notes)
        
        return contactDTO
    }
    
    class func mapToEntity(contactDTO: MailingContactDTO, contact: inout MailingContact) {
        contact.firstname = contactDTO.firstname
        contact.lastname = contactDTO.lastname
        contact.email = contactDTO.email
        contact.notes = contactDTO.notes
    }
    
    class func mapToAssignedContact(contact: MailingContact) -> AssignedContact {
        let assingedContact = AssignedContact(objectId: contact.objectID, firstname: contact.firstname!, lastname: contact.lastname!)
        
        return assingedContact
    }
}
