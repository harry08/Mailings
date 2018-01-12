//
//  MailComposerUtil.swift
//  Mailings
//
//  Created on 11.01.18.
//

import Foundation
import MessageUI

/**
 Util class to create and present a MFMailComposerViewController
 The caller needs to implement the MFMailComposeViewControllerDelegate and
 needs to provide the didFinish function of the delegate.
 */
class MailComposerUtil {
  
    /**
     Shows the MFMailComposerViewController for the given email address.
     If mail sending is not possible an alert message is shown.
     
     @param      parent   parent UIViewController. Used as parent to call the mail view
     @param      delegate   Delegate class which implements the required functions
     @param      emailAddress   The email recipient
     */
    class func presentMailComposeViewController(parent: UIViewController, delegate: MFMailComposeViewControllerDelegate, emailAddress: String) {
        let mailComposeVc = configuredMailComposeViewController(delegate: delegate)
        
        mailComposeVc.setToRecipients([emailAddress])
        
        presentMailComposerViewController(mailComposeVc, parent: parent)
    }
    
    /**
     Shows the MFMailComposerViewController for the given email addresses.
     If mail sending is not possible an alert message is shown.
     
     @param      parentViewController   parent UIViewController. Used as parent to call the mail view
     @param      delegate   Delegate class which implements the required functions
     @param      emailAddresses      The email recipients
     */
    class func presentMailComposeViewController(parent: UIViewController, delegate: MFMailComposeViewControllerDelegate, emailAddresses: [String]) {
        let mailComposeVc = configuredMailComposeViewController(delegate: delegate)
        
        mailComposeVc.setBccRecipients(emailAddresses)
        
        presentMailComposerViewController(mailComposeVc, parent: parent)
    }
    
    class func presentMailComposerViewController(_ mailComposeVc: MFMailComposeViewController, parent: UIViewController) {
        
        if !MFMailComposeViewController.canSendMail() {
            let alertController = UIAlertController(title: "Mail kann nicht gesendet werden", message: "Bitte E-Mail Einstellungen überprüfen und erneut versuchen.", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            
            parent.present(alertController, animated: true, completion: nil)
        } else {
            parent.present(mailComposeVc, animated: true, completion: nil)
        }
    }
    
    /**
     Creates a MFMailComposerViewController for the given email adddress
     */
    class func configuredMailComposeViewController(delegate: MFMailComposeViewControllerDelegate) -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = delegate
        
        return mailComposerVC
    }
}
