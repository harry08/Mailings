//
//  MailComposer.swift
//  Mailings
//
//  Created on 19.02.18.
//

import Foundation

class MailComposer {
    
    var mailingDTO: MailingDTO
    
    init(mailingDTO: MailingDTO) {
        self.mailingDTO = mailingDTO
    }
    
    func composeMailsToSend(emailAddresses: [String]) -> [MailDTO] {
        var mailsToSend = [MailDTO]()
        let chunkSize = 4
        
            var startIndex = 0
            var continueProcessing = true
            while (continueProcessing) {
                var endIndex = startIndex + chunkSize
                if endIndex >= emailAddresses.endIndex {
                    endIndex = emailAddresses.endIndex
                }
                
                let chunk = emailAddresses[startIndex ..< endIndex]
                let ccAddresses = convertToArray(slice: chunk)
                
                print("Sending mails to \(ccAddresses)")
                let mailToSend = MailDTO(mailingDTO: mailingDTO, emailAddresses: ccAddresses, emailSent: false)
                mailsToSend.append(mailToSend)
                
                startIndex = endIndex
                if startIndex >= emailAddresses.endIndex {
                    continueProcessing = false
                }
            }
        
        return mailsToSend
    }
    
    func convertToArray(slice: ArraySlice<String>) -> [String] {
        var result = [String]()
        result.reserveCapacity(slice.count)
        slice.forEach{ element in
            result.append(element)
        }
        
        return result
    }
}