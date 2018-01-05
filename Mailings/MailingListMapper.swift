//
//  MailingListMapper.swift
//  Mailings
//
//  Created on 03.01.18.
//

import Foundation

class MailingListMapper {
    
    class func mapToDTO(mailinglist: MailingList) -> MailingListDTO {
        let mailingListDTO = MailingListDTO(objectId: mailinglist.objectID, name: mailinglist.name, recipientAsBcc: mailinglist.recipientasbcc)
        
        return mailingListDTO
    }
    
    class func mapToEntity(mailingListDTO: MailingListDTO, mailinglist: inout MailingList) {
        mailinglist.name = mailingListDTO.name
        mailinglist.recipientasbcc = mailingListDTO.recipientAsBcc
    }
}
