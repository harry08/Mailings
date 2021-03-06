//
//  MailingListContactsTableViewController.swift
//  Mailings
//
//  Created on 01.02.18.
//

import UIKit
import CoreData

/**
 Delegate that is called after doing assigning new contacts to the mailingList or removing contacts from the list.
 */
protocol MailingListContactsTableViewControllerDelegate: class {
    func mailingListContactsTableViewController(_ controller: MailingListContactsTableViewController, didChangeContacts contactAssignmentChanges: [ContactAssignmentChange])
}

/**
 Shows the assigned contacts of a MailingList.
 In editMode assignments can be removed and new assignments can be added.
 */
class MailingListContactsTableViewController: UITableViewController, ContactPickerTableViewControllerDelegate {
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    /**
     Delegate to call after adding or removing contacts
     */
    weak var delegate: MailingListContactsTableViewControllerDelegate?
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer {
        didSet {
            updateUI()
        }
    }
    
    /**
     Flag indicates whether the view is in readonly mode or edit mode.
     */
    var editMode = false {
        didSet {
            configureControls()
        }
    }
    
    /**
     List of assigned contacts to display
     */
    var assignedContacts : AssigndContacts? {
        didSet {
            updateUI()
        }
    }
    
    /**
     Returns all assigned contacts of this mailing list as an array of MailingContactDTO
     */
    private func getAssignedContacts() -> [MailingContactDTO] {
        var contacts =  [MailingContactDTO]()
        
        if let assignedContacts = self.assignedContacts {
            if assignedContacts.contacts.count > 0 {
                for assignedContact in assignedContacts.contacts {
                    var mailingContact = MailingContactDTO()
                    mailingContact.objectId = assignedContact.objectId
                    mailingContact.lastname = assignedContact.lastname
                    mailingContact.firstname = assignedContact.firstname
                    contacts.append(mailingContact)
                }
            }
        }
        return contacts
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        
        configureControls()
        updateUI()
    }
    
    private func updateUI() {
        tableView.reloadData()
        updateControls()
    }
    
    private func configureControls() {
        addButton.isEnabled = editMode
    }
    
    private func updateControls() {
        updateTableFooter()
    }
    
    private func updateTableFooter() {
        footerView.isHidden = !shouldDisplayFooter()
        
        if !footerView.isHidden {
            let count = getNrOfAssignedContacts()
            footerLabel.text = "\(count) Kontakte"
        } else {
            footerLabel.text = ""
        }
    }
    
    /**
     Display a TableView footer with info about contacts when there are at least 15 contacts.
     */
    private func shouldDisplayFooter() -> Bool {
        if getNrOfAssignedContacts() >= 10 {
            return true
        }
        
        return false
    }
    
    private func getNrOfAssignedContacts() -> Int {
        if let assingedContacts = self.assignedContacts {
            return assingedContacts.contacts.count
        } else {
            return 0
        }
    }
    
    // MARK: - Navigation and Actions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickContact",
            let destinationVC = segue.destination as? ContactPickerTableViewController
        {
            destinationVC.delegate = self
            destinationVC.excludedContacts = getAssignedContacts()
            destinationVC.container = container
        }
    }
    
    // MARK: - TableView
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MailingContactCell", for: indexPath)
        
        let assignedContact = assignedContacts!.contacts[indexPath.row]
        cell.textLabel?.text = assignedContact.lastname
        cell.detailTextLabel?.text = assignedContact.firstname
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getNrOfAssignedContacts()
    }
    
    /**
     Delete contact assignment.
     When the commitEditingStyle method is present inside the view controller, the table view will automatically enable swipe-to-delete.
     */
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,        forRowAt indexPath: IndexPath) {
        
            let removedContact = assignedContacts!.contacts[indexPath.row]
            let contactAssignmentChange = ContactAssignmentChange(objectId: removedContact.objectId, action: "R")
        
            assignedContacts!.contacts.remove(at: indexPath.row)
        
            let indexPaths = [indexPath]
            tableView.deleteRows(at: indexPaths, with: .automatic)
            updateControls()
        
            delegate?.mailingListContactsTableViewController(self, didChangeContacts: [contactAssignmentChange])
        
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        if editMode == true {
            return .delete
        } else {
            return .none
        }
    }
    
    // MARK: - ContactPickerTableViewControllerDelegate
    
    /**
     Called when ContactPickerTableViewController returns with a list of chosen contacts.
     Assign them to the mailingList
     */
    func contactPicker(_ picker: ContactPickerTableViewController, didPick chosenContacts: [MailingContactDTO]) {
        
        // Add chosen contacts
        var contactAssignmentChanges = [ContactAssignmentChange]()
        for i in 0 ..< chosenContacts.count {
            let chosenContact = chosenContacts[i]
            let contactAlreadyAdded = assignedContacts!.contacts.contains {$0.objectId == chosenContact.objectId}
            if !contactAlreadyAdded {
                let assignedContact = AssignedContact(objectId: chosenContact.objectId!, firstname: chosenContact.firstname!, lastname: chosenContact.lastname!)
                assignedContacts!.contacts.append(assignedContact)
                
                contactAssignmentChanges.append(ContactAssignmentChange(objectId: chosenContact.objectId!, action: "A"))
            }
        }
    
        if contactAssignmentChanges.count > 0 {
            delegate?.mailingListContactsTableViewController(self, didChangeContacts: contactAssignmentChanges)
        }
    
        navigationController?.popViewController(animated:true)
    
        updateUI()
    }
}
