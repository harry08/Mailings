//
//  ShowMailingViewController.swift
//  CustomerManager
//
//  Created on 22.11.17.
//

import UIKit
import CoreData
import MessageUI

class ShowMailingViewController: UIViewController, MailingListPickerTableViewControllerDelegate, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mailingTextViewLabel: UITextView!
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        navigationItem.largeTitleDisplayMode = .never
    }
    
    var mailingDTO : MailingDTO? {
        didSet {
            loadViewIfNeeded()
            updateUI()
        }
    }
    
    private func updateUI() {
        if let mailingDTO = self.mailingDTO {
            titleLabel.text = mailingDTO.title
            mailingTextViewLabel.text = mailingDTO.text
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mailingTextViewLabel.isEditable = false
    }
 
    // MARK: - Send Email
    
    func composeMailsToSend(emailAddresses: [String]) -> [MailDTO] {
        var mailsToSend = [MailDTO]()
        let chunkSize = 80
        
        if let mailingDTO = mailingDTO {
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
                let mailToSend = MailDTO(mailingDTO: mailingDTO, emailAddresses: ccAddresses)
                mailsToSend.append(mailToSend)
                
                startIndex = endIndex
                if startIndex >= emailAddresses.endIndex {
                    continueProcessing = false
                }
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
    
    // MARK: - Navigation
    
    // Navigate back from editing mailing. Save data in MailingDTO
    // MailingDTO is already filled
    @IBAction func unwindFromSave(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? EditMailingViewController,
            let mailingDTO = sourceViewController.mailingDTO {
            
            guard let container = container else {
                print("Save not possible. No PersistentContainer.")
                return
            }
            
            do {
                // Update database
                try Mailing.createOrUpdateFromDTO(mailingDTO: mailingDTO, in: container.viewContext)
                
                // Reload mailingDTO. UI is updated automatically
                self.mailingDTO = try Mailing.loadMailing(objectId: mailingDTO.objectId!, in: container.viewContext)
            } catch let error as NSError {
                // TODO show Alert
            }
        }
    }
    
    // Prepare for navigate to editing the Mailing data
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editMailing",
            let destinationVC = segue.destination as? EditMailingViewController
        {
            // Edit mailing
            destinationVC.container = container
            destinationVC.mailingDTO = mailingDTO
            destinationVC.editMode = true
        } else if segue.identifier == "pickMailingList",
            let destinationVC = segue.destination as? MailingListPickerTableViewController
        {
            // Choose mailing list to send mailing to.
            destinationVC.container = container
            destinationVC.delegate = self            
        } /* TODO Remove comment    else if segue.identifier == "showEmailsToSend",
            let destinationVC = segue.destination as? MailsToSendTableViewController
        {
            destinationVC.container = container
            let mailsToSend = composeMailsToSend()
            destinationVC.mailsToSend = mailsToSend
        }*/
    }
    
    // MARK: - MailingListPickerTableViewController Delegate
    /**
     Called after mailing list was chosen. Send the selected mailing to the chosen mailing list.
     */
    func mailingListPicker(_ picker: MailingListPickerTableViewController, didPick chosenMailingList: MailingListDTO) {
        // Return from view
        navigationController?.popViewController(animated:true)
        
        // Get email addresses of mailing list
        guard let container = container else {
            return
        }
        
        let emailAddresses = MailingList.getEmailAddressesForMailingList(objectId: chosenMailingList.objectId!, in: container.viewContext)
        
        // Prepare mails to send
        let mailsToSend = composeMailsToSend(emailAddresses: emailAddresses)
        print("Mails to send: \(mailsToSend)")
    }
}
