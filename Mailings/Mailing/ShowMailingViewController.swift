//
//  ShowMailingViewController.swift
//  CustomerManager
//
//  Created on 22.11.17.
//

import UIKit
import CoreData
import MessageUI

class ShowMailingViewController: UIViewController, MFMailComposeViewControllerDelegate {

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

    @IBAction func sendMailing(_ sender: Any) {
        // TODO Implement
        // Unklar, ob Verteilerliste Attribut eines Mailings sein sollte.
    }
    
    // MARK: - Send Email
    
    func composeMailsToSend() -> [MailDTO] {
        var mailsToSend = [MailDTO]()
        let chunkSize = 80
        
        guard let container = container else {
            print("Sending mail not possible. No PersistentContainer.")
            return mailsToSend
        }
        /* TODO
        if let mailingDTO = mailingDTO {
            let emailAddresses = MailingContact.getEmailAddressesForMailingList(mailingDTO.mailingList!, in: container.viewContext)
            
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
        }*/
        
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
        } /* TODO Remove comment    else if segue.identifier == "showEmailsToSend",
            let destinationVC = segue.destination as? MailsToSendTableViewController
        {
            destinationVC.container = container
            let mailsToSend = composeMailsToSend()
            destinationVC.mailsToSend = mailsToSend
        }*/
    }
}
