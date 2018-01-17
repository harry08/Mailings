//
//  ShowContactViewController.swift
//  Mailings
//
//  Created on 08.01.18.
//

import UIKit
import CoreData
import MessageUI

class ShowContactViewController: UIViewController {
    
    @IBOutlet weak var firstnameLabel: UILabel!
    @IBOutlet weak var lastnameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    let messageComposer = MessageComposer()
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        navigationItem.largeTitleDisplayMode = .never
    }
    
    var contactDTO : MailingContactDTO? {
        didSet {
            loadViewIfNeeded()
            updateUI()
        }
    }
    
    private func updateUI() {
        if let contactDTO = self.contactDTO {
            firstnameLabel.text = contactDTO.firstname
            lastnameLabel.text = contactDTO.lastname
            emailLabel.text = contactDTO.email
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Send Email
    
    @IBAction func sendEmail(_ sender: Any) {
        if let email = contactDTO?.email {
            composeMail(emailAddress: email)
        }
    }
    
    /**
     Presents the iOS screen to write an email to the given email addresses
     */
    func composeMail(emailAddress: String) {
        if messageComposer.canSendText() {
            let messageComposeVc = messageComposer.configuredMailComposeViewController(emailAddress: emailAddress)
            self.present(messageComposeVc, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "Mail kann nicht gesendet werden", message: "Bitte E-Mail Einstellungen überprüfen und erneut versuchen.", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Navigation
    
    // Navigate back from editing contact. Save data in ContactDTO
    // ContactDTO is already filled
    @IBAction func unwindFromSave(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? EditContactViewController,
            let contactDTO = sourceViewController.contactDTO {
            
            guard let container = container else {
                print("Save not possible. No PersistentContainer.")
                return
            }
            
            do {
                // Update database
                try MailingContact.createOrUpdateFromDTO(contactDTO: contactDTO, in: container.viewContext)
                
                // Reload contactDTO. UI is updated automatically
                self.contactDTO = try MailingContact.loadContact(objectId: contactDTO.objectId!, in: container.viewContext)
            } catch {
                // TODO show Alert
            }
        }
    }
    
    // Prepare for navigate to editing the contact data
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editContact",
            let destinationVC = segue.destination as? EditContactViewController
        {
            // Edit contact
            destinationVC.container = container
            destinationVC.contactDTO = contactDTO
            destinationVC.editMode = true
        }
    }
}
