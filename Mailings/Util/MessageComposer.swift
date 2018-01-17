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
    
    func canSendText() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {

        let mailComposerVc = MFMailComposeViewController()
        mailComposerVc.mailComposeDelegate = self
            
        return mailComposerVc
    }
    
    /**
     Creates a MFMailComposerViewController for the given email addresses
     */
    func configuredMailComposeViewController(emailAddresses: [String]) -> MFMailComposeViewController {
        
        let mailComposerVc = MFMailComposeViewController()
        mailComposerVc.mailComposeDelegate = self
        
        mailComposerVc.setBccRecipients(emailAddresses)
        
        return mailComposerVc
    }
    
    /**
     Creates a MFMailComposerViewController for the given email address
     */
    func configuredMailComposeViewController(emailAddress: String) -> MFMailComposeViewController {
        
        let mailComposerVc = MFMailComposeViewController()
        mailComposerVc.mailComposeDelegate = self
        
        mailComposerVc.setToRecipients([emailAddress])
        
        return mailComposerVc
    }
    
    /**
     Creates a MFMailComposerViewController for the provided mailing and given email addresses
     */
    func configuredMailComposeViewController(mailing: MailingDTO, emailAddresses: [String]) -> MFMailComposeViewController {
        
        let mailComposerVc = MFMailComposeViewController()
        mailComposerVc.mailComposeDelegate = self
        
        mailComposerVc.setSubject(mailing.title!)
        mailComposerVc.setBccRecipients(emailAddresses)
        mailComposerVc.setMessageBody(mailing.text!, isHTML: false)
        
        return mailComposerVc
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
