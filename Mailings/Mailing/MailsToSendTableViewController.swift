//
//  MailsTableViewController.swift
//  CustomerManager
//
//  Created 04.12.17.
//

import UIKit
import MessageUI

/**
 Shows all mails that the user can send out of a given mailing.
 The user has to sent each mail manually using the iOS mail composer.
 */
class MailsToSendTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    var mailsToSend : [MailDTO]? {
        didSet {
            loadViewIfNeeded()
            tableView.reloadData()
        }
    }
    
    var currentMailToSendIndex : Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func updateMailSent(index: Int) {
        var mail = mailsToSend![index]
        mail.emailSent = true
        mailsToSend![index] = mail
    }
    
    func getNrOfRecipients() -> Int {
        var count = 0
        if let mailsToSend = mailsToSend {
            for mailToSend in mailsToSend {
                count += mailToSend.emailAddresses.count
            }
        }
        return count
    }
    
    func getEmailsAsString(index: Int) -> String {
        var emailString = ""
        
        let mailToSend = self.mailsToSend![index]
        for email in mailToSend.emailAddresses {
            if emailString.count == 0 {
                emailString = email
            } else {
                emailString.append(",")
                emailString.append(email)
            }
        }
        
        return emailString
    }
   
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let mailsToSend = mailsToSend {
            return mailsToSend.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let mailsToSend = mailsToSend {
            let nrOfMails = mailsToSend.count
            let nrOfRecipients = getNrOfRecipients()
            let title = "Das Mailing an \(nrOfRecipients) Empfänger wird auf \(nrOfMails) Emails aufgeteilt. Zum Senden der Email die jeweilige Zeile nach links ziehen und Email wählen."
            return title
        }
        
        return ""
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MailToSendCell", for: indexPath)

        let mail = mailsToSend![indexPath.row]
        cell.textLabel?.text = mail.mailingDTO.title
        let count = mail.emailAddresses.count
        var labelText : String = ""
        if count >= 1 {
            labelText = mail.emailAddresses[0]
        }
        if count >= 2 {
            labelText = labelText + ", \(count-1) weitere."
        }
        cell.detailTextLabel?.text = labelText
        
        configureCheckmark(for: cell, at: indexPath)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let sendMail = UITableViewRowAction(style: .normal, title: "EMail") { action, index in
            self.composeMail(index: index.row)
        }
        sendMail.backgroundColor = UIColor.orange
        let moreAction = UITableViewRowAction(style: .normal, title: "...") { action, index in
            self.showActionMenu(indexPath: index)
        }
        moreAction.backgroundColor = UIColor.lightGray
       
        return [sendMail, moreAction]
    }
    
    func configureCheckmark(for cell: UITableViewCell,
                            at indexPath: IndexPath) {
        let mail = mailsToSend![indexPath.row]
        
        if mail.emailSent {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }
    
    // MARK: - Actions and Navigation
    func showActionMenu(indexPath: IndexPath) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Email-Adressen kopieren", style: .default) { _ in
            let emailString = self.getEmailsAsString(index: indexPath.row)
            
            // Set emailString into pasteboard
            let pasteboard = UIPasteboard.general
            pasteboard.string = emailString
        })
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel) { _ in
            // Do nothing
        })
        // The following 2 lines are needed for iPad.
        alert.popoverPresentationController?.sourceView = view
        if let cell = tableView.cellForRow(at: indexPath) {
            alert.popoverPresentationController?.sourceRect = cell.frame
        }
        
        self.present(alert, animated: true)
    }
    
    @IBAction func done(_ sender: Any) {
        if let owningNavigationController = navigationController {
            // The mailsToSend Scene was pushed on the navigation stack.
            owningNavigationController.popViewController(animated: true)
        }
    }
    
    // MARK: - Send mail
    
    func composeMail(index: Int) {
        currentMailToSendIndex = index
        let mailDTO = mailsToSend![index]
        let mailComposeViewController = configuredMailComposeViewController(mailDTO: mailDTO)
        if !MFMailComposeViewController.canSendMail() {
            self.showSendMailErrorAlert()
        } else {
            self.present(mailComposeViewController, animated: true, completion: nil)
        }
    }
    
    func showSendMailErrorAlert() {
        let alertController = UIAlertController(title: "Mail kann nicht gesendet werden", message: "Bitte E-Mail Einstellungen überprüfen und erneut versuchen.", preferredStyle: .alert)
        
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if result != MFMailComposeResult.failed {
            updateMailSent(index: currentMailToSendIndex!)
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func configuredMailComposeViewController(mailDTO: MailDTO) -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Set the mailComposeDelegate property to self
        
        mailComposerVC.setBccRecipients(mailDTO.emailAddresses)
        if let messageSubject = mailDTO.mailingDTO.title {
            mailComposerVC.setSubject(messageSubject)
        }
        if let messageBody = mailDTO.mailingDTO.text {
            mailComposerVC.setMessageBody(messageBody, isHTML: false)
        }
        return mailComposerVC
    }
}
