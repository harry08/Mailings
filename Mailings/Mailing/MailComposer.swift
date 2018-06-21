//
//  MailComposer.swift
//  Mailings
//
//  Created on 19.02.18.
//

import Foundation

class MailComposer {
    
    var mailingDTO: MailingDTO
    var files = [AttachedFile]()
    
    var settingsController : CommonSettingsController
    
    init(mailingDTO: MailingDTO, files: [AttachedFile]) {
        self.mailingDTO = mailingDTO
        self.files = files
        
        settingsController = CommonSettingsController.sharedInstance
    }
    
    func composeMailsToSend(emailAddresses: [String]) -> [MailDTO] {
        var mailsToSend = [MailDTO]()
        let splitMails = settingsController.getSplitReceivers()
        var chunkSize = settingsController.getMaxReceiver()
        
        if !splitMails {
            chunkSize = emailAddresses.count
        }
        
        var attachments = [String]()
        for i in 0 ..< files.count {
            let file = files[i]
            attachments.append(file.name)
        }
        
        var startIndex = 0
        var continueProcessing = true
        while (continueProcessing) {
            var endIndex = startIndex + chunkSize
            if endIndex >= emailAddresses.endIndex {
                endIndex = emailAddresses.endIndex
            }
            
            let chunk = emailAddresses[startIndex ..< endIndex]
            let ccAddresses = convertToArray(slice: chunk)
            
            let mailToSend = MailDTO(mailingDTO: mailingDTO, emailAddresses: ccAddresses, emailSent: false, folder: mailingDTO.folder, attachments: attachments)
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
