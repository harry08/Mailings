//
//  ShowContactViewController.swift
//  Mailings
//
//  Created on 08.01.18.
//

import UIKit
import CoreData
import MessageUI

class ShowContactViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var firstnameLabel: UILabel!
    @IBOutlet weak var lastnameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var infoEmailLabel: UILabel!
    @IBOutlet weak var eventEmailLabel: UILabel!
    
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
        let mailComposeViewController = configuredMailComposeViewController()
        if !MFMailComposeViewController.canSendMail() {
            self.showSendMailErrorAlert()
        } else {
            self.present(mailComposeViewController, animated: true, completion: nil)
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Set the mailComposeDelegate property to self
        
        mailComposerVC.setToRecipients([(contactDTO?.email)!])
        mailComposerVC.setSubject("Sending an in-app e-mail...")
        mailComposerVC.setMessageBody("Sending e-mail in-app!", isHTML: false)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let alertController = UIAlertController(title: "Mail kann nicht gesendet werden", message: "Bitte E-Mail Einstellungen überprüfen und erneut versuchen.", preferredStyle: .alert)
        
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
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
