//
//  MessageComposer.swift
//  Mailings
//
//  Created on 17.01.18.
//

import Foundation
import MessageUI

/**
 Util class to create and present a MFMailComposerViewController
 */
class MessageComposer: NSObject, MFMailComposeViewControllerDelegate {
    
    class func canSendText() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }
    
    /**
     Updates the given MFMailComposerViewController with the given email address
     */
    class func updateMailComposeViewController(_ mailComposerVC: MFMailComposeViewController, emailAddress: String) {
        
        updateMailComposeViewController(mailComposerVC, emailAddresses: [emailAddress])
    }
    
    /**
     Updates the given MFMailComposerViewController with the given email addresses.
     */
    class func updateMailComposeViewController(_ mailComposerVC: MFMailComposeViewController, emailAddresses: [String]) {
        
        if emailAddresses.count == 1 {
            mailComposerVC.setToRecipients(emailAddresses)
        } else {
            mailComposerVC.setBccRecipients(emailAddresses)
        }
    }
    
    /**
     Updates the given MFMailComposerViewController for the given mailing and email address
     */
    class func updateMailComposeViewController(_ mailComposerVC: MFMailComposeViewController, mailing: MailingDTO, attachedFiles: [AttachedFile], emailAddress: String) {
        
        var emailAddresses = [String]()
        emailAddresses.append(emailAddress)
        
        updateMailComposeViewController(mailComposerVC, mailing: mailing, attachedFiles: attachedFiles, emailAddresses: emailAddresses)
    }
    
    class func updateMailComposeViewController(_ mailComposerVC: MFMailComposeViewController, mailing: MailingDTO, attachedFiles: [AttachedFile], emailAddresses: [String]) {
       
        if emailAddresses.count == 1 {
            mailComposerVC.setToRecipients(emailAddresses)
        } else {
            mailComposerVC.setBccRecipients(emailAddresses)
        }
        
        if let title = mailing.title {
            mailComposerVC.setSubject(title)
        }
        if let text = mailing.text {
            let htmlEmail = HtmlUtil.isHtml(text)
            mailComposerVC.setMessageBody(text, isHTML: htmlEmail)
        }
        
        if attachedFiles.count > 0 {
            if let folderName = mailing.folder {
                for i in 0 ..< attachedFiles.count {
                    let file = attachedFiles[i]
                    let url = FileAttachmentHandler.getUrlForFile(fileName: file.name, folderName: folderName)
                    let mimeType = FileAttachmentHandler.mimeTypeForUrl(url)
                    do {
                        let fileData = try Data.init(contentsOf: url)
                        mailComposerVC.addAttachmentData(fileData, mimeType: mimeType, fileName: file.name)
                    } catch let error as NSError {
                        print("Error loading file: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    class func updateMailComposeViewController(_ mailComposerVC: MFMailComposeViewController, mailDTO: MailDTO) {
        mailComposerVC.setBccRecipients(mailDTO.emailAddresses)
        
        if let messageSubject = mailDTO.mailingDTO.title {
            mailComposerVC.setSubject(messageSubject)
        }
        if let messageBody = mailDTO.mailingDTO.text {
            let htmlEmail = HtmlUtil.isHtml(messageBody)
            mailComposerVC.setMessageBody(messageBody, isHTML: htmlEmail)
        }
        
        if mailDTO.attachments.count > 0 {
            if let folderName = mailDTO.folder {
                for i in 0 ..< mailDTO.attachments.count {
                    let fileName = mailDTO.attachments[i]
                    let url = FileAttachmentHandler.getUrlForFile(fileName: fileName, folderName: folderName)
                    let mimeType = FileAttachmentHandler.mimeTypeForUrl(url)
                    do {
                        let fileData = try Data.init(contentsOf: url)
                        mailComposerVC.addAttachmentData(fileData, mimeType: mimeType, fileName: fileName)
                    } catch let error as NSError {
                        print("Error loading file: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
