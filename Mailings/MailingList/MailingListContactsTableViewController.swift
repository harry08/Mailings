//
//  MailingListContactsTableViewController.swift
//  Mailings
//
//  Created on 01.02.18.
//

import UIKit
import CoreData

/**
 Shows the assigned contacts of a MailingList.
 */
class MailingListContactsTableViewController: UITableViewController, ContactPickerTableViewControllerDelegate {
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer {
        didSet {
            updateUI()
        }
    }
    
    var mailingListDTO: MailingListDTO? {
        didSet {
            if let objectId = mailingListDTO?.objectId,
                let container = container {
                
                mailingContacts = MailingList.getMailingContacts(objectId: objectId, in: container.viewContext)
                updateUI()
            }
        }
    }
    
    var mailingContacts = [MailingContactDTO]()

    fileprivate var fetchedResultsController: NSFetchedResultsController<MailingContact>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        
        updateUI()
    }
    
    private func updateUI() {
        tableView.reloadData()
    }
    
    // MARK: - Navigation and Actions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickContact",
            let destinationVC = segue.destination as? ContactPickerTableViewController
        {
            destinationVC.delegate = self
            destinationVC.container = container
        }
    }
    
    // MARK: - TableView
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MailingContactCell", for: indexPath)
        
        let mailingContact = mailingContacts[indexPath.row]
        cell.textLabel?.text = mailingContact.lastname!
        cell.detailTextLabel?.text = mailingContact.firstname!
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mailingContacts.count
    }
    
    // MARK: - ContactPickerTableViewControllerDelegate
    
    /**
     Called when ContactPickerTableViewController returns with a list of chosen contacts.
     Assign them to the mailingList
     */
    func contactPicker(_ picker: ContactPickerTableViewController, didPick chosenContacts: [MailingContactDTO]) {
        
        if let objectId = mailingListDTO?.objectId,
            let container = container {
            
            // Add contacts
            do {
                try MailingList.addContacts(chosenContacts, objectId: objectId, in: container.viewContext)
            } catch {
                // TODO show Alert
            }
            
            navigationController?.popViewController(animated:true)
            
            // Reload contacts
            mailingContacts = MailingList.getMailingContacts(objectId: objectId, in: container.viewContext)
            updateUI()
        }
    }
}
