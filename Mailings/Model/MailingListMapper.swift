//
//  MailingListMapper.swift
//  Mailings
//
//  Created on 03.01.18.
//

import Foundation

class MailingListMapper {
    
    class func mapToDTO(mailingList: MailingList) -> MailingListDTO {
        let mailingListDTO = MailingListDTO(objectId: mailingList.objectID, name: mailingList.name, recipientAsBcc: mailingList.recipientasbcc, assignAsDefault: mailingList.assignasdefault)
        
        return mailingListDTO
    }
    
    class func mapToEntity(mailingListDTO: MailingListDTO, mailingList: inout MailingList) {
        mailingList.name = mailingListDTO.name
        mailingList.recipientasbcc = mailingListDTO.recipientAsBcc
        mailingList.assignasdefault = mailingListDTO.assignAsDefault
    }
}
