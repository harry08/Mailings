//
//  MailingMapper.swift
//  Mailings
//
//  Created on 07.01.18.
//

import Foundation

class MailingMapper {
    
    class func mapToDTO(mailing: Mailing) -> MailingDTO {
        let mailingDTO = MailingDTO(objectId: mailing.objectID, title: mailing.title, text: mailing.text)
        
        return mailingDTO
    }
    
    class func mapToEntity(mailingDTO: MailingDTO, mailing: inout Mailing) {
        mailing.title = mailingDTO.title
        mailing.text = mailingDTO.text
    }
}
