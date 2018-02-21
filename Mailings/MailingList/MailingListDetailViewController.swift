//
//  MailingListDetailViewController.swift
//  Mailings
//
//  Created on 26.01.18.
//

import UIKit
import os.log
import CoreData

/**
 Delegate that is called after closing the DetailController.
 Database update can be done in the implementing classes.
 */
protocol MailingListDetailViewControllerDelegate: class {
    func mailingListDetailViewControllerDidCancel(_ controller: MailingListDetailViewController)
    func mailingListDetailViewController(_ controller: MailingListDetailViewController, didFinishAdding mailingList: MailingListDTO, assignmentChanges: [ContactAssignmentChange])
    func mailingListDetailViewController(_ controller: MailingListDetailViewController, didFinishEditing mailingList: MailingListDTO, assignmentChanges: [ContactAssignmentChange])
}

class MailingListDetailViewController: UITableViewController, UITextFieldDelegate, MailingListContactsTableViewControllerDelegate {
    
    var editMode = false
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var defaultAssignmentSwitch: UISwitch!
    @IBOutlet weak var recipientAsBccSwitch: UISwitch!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    /**
     Delegate to call after finish editing
     Weak reference to avoid ownership cycles.
     The detailView has only a weak reference back to the owning tableView.
     */
    weak var delegate: MailingListDetailViewControllerDelegate?
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    // In case of editing an existing mailing list this variable is filled on startup.
    // In case of a new one this will be created in the prepare method.
    var mailingListDTO : MailingListDTO?
    
    /**
     List of contacts assinged to this MailingList.
     Used for displaying assignments in the sub view.‚
     */
    var assignedContacts = AssigndContacts()
    
    /**
     List of changes of contact assignments for this MailingList.
     */
    var contactAssignmentChanges = [ContactAssignmentChange]()
    
    /**
     Controls the doneButton
     */
    var viewEdited = false {
        didSet {
            updateDoneButtonState()
        }
    }
    
    private func isEditMode() -> Bool {
        return editMode
    }
    
    private func isAddMode() -> Bool {
        return !editMode
    }
    
    private func updateDoneButtonState() {
        doneButton.isEnabled = viewEdited || contactAssignmentChanges.count > 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        if let mailingListDTO = self.mailingListDTO {
            // Set up view if editing an existing mailingList.
            nameTextField.text = mailingListDTO.name
            defaultAssignmentSwitch.isOn = mailingListDTO.assignAsDefault
            recipientAsBccSwitch.isOn = mailingListDTO.recipientAsBcc
            
            title = "Verteiler"
            updateDoneButtonState()
        }
        
        defaultAssignmentSwitch.addTarget(self, action: #selector(switchChanged), for: UIControlEvents.valueChanged)
        recipientAsBccSwitch.addTarget(self, action: #selector(switchChanged), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isAddMode() {
            // Only in add mode directly put the focus inside the name field.
            nameTextField.becomeFirstResponder()
        }
    }
    
    @objc func switchChanged(mySwitch: UISwitch) {
        viewEdited = true
    }
    
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            nameTextField.becomeFirstResponder()
        }
    }
    
    // Do not allow cell selection
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 2 {
            // Section 2 should be selectable to navigate to the contact details.
            return indexPath
        } else {
            return nil
        }
    }
    
    // MARK: - Navigation and Actions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMailingListContacts",
            let destinationVC = segue.destination as? MailingListContactsTableViewController
        {
            guard let container = container else {
                return
            }
            
            destinationVC.container = container
            destinationVC.delegate = self
            
            // Init assignedContacts list and pass as a reference to the sub view
            // This list is modified by the sub view when new contacts a are assigned or contacts are removed.
            if !assignedContacts.isInit() {
                // Init list of assigned contacts
                if let objectId = mailingListDTO?.objectId {
                    assignedContacts.initWithContactList(MailingList.getAssignedContacts(objectId: objectId, in: container.viewContext))
                } else {
                    assignedContacts.initWithEmptyList()
                }
            }
            destinationVC.assignedContacts = assignedContacts
        }
    }
    
    /**
     Fills the values from UI fields into the MailingListDTO.
     */
    private func fillMailingListDTO() {
        let name = nameTextField.text ?? ""
        let recipientBcc = recipientAsBccSwitch.isOn
        let defaultAssign = defaultAssignmentSwitch.isOn
        
        // Fill up values
        if mailingListDTO == nil {
            // Create new MailingListDTO object
            mailingListDTO = MailingListDTO()
        }
        mailingListDTO?.name = name
        mailingListDTO?.recipientAsBcc = recipientBcc
        mailingListDTO?.assignAsDefault = defaultAssign
    }
    
    @IBAction func cancel(_ sender: Any) {
       delegate?.mailingListDetailViewControllerDidCancel(self)
    }
    
    @IBAction func doneEditing(_ sender: Any) {
        fillMailingListDTO()
        
        if isAddMode() {
            delegate?.mailingListDetailViewController(self, didFinishAdding: mailingListDTO!, assignmentChanges: contactAssignmentChanges)
        } else {
            delegate?.mailingListDetailViewController(self, didFinishEditing: mailingListDTO!, assignmentChanges: contactAssignmentChanges)
        }
    }
    
    // MARK:- UITextField Delegates
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        let oldText = textField.text!
        let stringRange = Range(range, in:oldText)!
        let newText = oldText.replacingCharacters(in: stringRange, with: string)
        viewEdited = !newText.isEmpty
        return true
    }
    
    // MARK:- MailingListContactsTableViewController Delegates
    
    /**
     Called after changing contact assignment in sub view.
     Takes the changes into the contactAssignmentChanges list.
     */
    func mailingListContactsTableViewController(_ controller: MailingListContactsTableViewController, didChangeContacts contactAssignmentChanges: [ContactAssignmentChange]) {
        
        for i in 0 ..< contactAssignmentChanges.count {
            let contactAssignmentChange = contactAssignmentChanges[i]
            let contactAlreadyChanged = self.contactAssignmentChanges.contains {$0.objectId == contactAssignmentChange.objectId}
            if !contactAlreadyChanged {
                // no entry with the objectId exists in the change list -> add it
                self.contactAssignmentChanges.append(contactAssignmentChange)
            } else {
                // A change entry for this contact already exists in the change list.
                if let existing = self.contactAssignmentChanges.first(where: { $0.objectId == contactAssignmentChange.objectId }) {
                    
                    if existing.action != contactAssignmentChange.action {
                        // The entry has a different action -> remove it from the change list.
                        if let index = self.contactAssignmentChanges.index(where: { $0.objectId == existing.objectId } ) {
                            self.contactAssignmentChanges.remove(at: index)
                        }
                    }
                }
            }
        }
        
        updateDoneButtonState()
    }
}
