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
    func mailingListDetailViewController(_ controller: MailingListDetailViewController, didFinishDeleting mailingList: MailingListDTO)
}

class MailingListDetailViewController: UITableViewController, UITextFieldDelegate, MailingListContactsTableViewControllerDelegate, MailingListDetailViewControllerDelegate {
    
    /**
     Flag indicates whether a new mailing is shown or an existing one.
     */
    var editType = false
    
    /**
     Flag indicates whether the view is in readonly mode or edit mode.
     */
    var editMode = false
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var defaultAssignmentSwitch: UISwitch!
    @IBOutlet weak var recipientAsBccSwitch: UISwitch!
    
    @IBOutlet weak var mailingListDeleteCell: UITableViewCell!
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
            configureBarButtonItems()
        }
    }
    
    private func isEditType() -> Bool {
        return editType
    }
    
    private func isAddType() -> Bool {
        return !editType
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        // Put this class as delegate to receive events
        delegate = self
        
        if isEditType() {
            fillControls()
            
            title = "Verteiler"
        } else {
            editMode = true
        }
        configureBarButtonItems()
        configureControls()
        
        defaultAssignmentSwitch.addTarget(self, action: #selector(switchChanged), for: UIControlEvents.valueChanged)
        recipientAsBccSwitch.addTarget(self, action: #selector(switchChanged), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isAddType() {
            // Only in add mode directly put the focus inside the title field.
            nameTextField.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.isToolbarHidden = true
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
    
    /**
     Fills the values from the DTO to the controls.
     */
    private func fillControls() {
        if let mailingListDTO = self.mailingListDTO {
            // Set up view if editing an existing mailingList.
            nameTextField.text = mailingListDTO.name
            defaultAssignmentSwitch.isOn = mailingListDTO.assignAsDefault
            recipientAsBccSwitch.isOn = mailingListDTO.recipientAsBcc
        }
    }
    
    private func configureControls() {
        nameTextField.isEnabled = editMode
        defaultAssignmentSwitch.isEnabled = editMode
        recipientAsBccSwitch.isEnabled = editMode
    }
    
    
    // MARK: - Action and Navigation
    
    private func configureBarButtonItems() {
        if isAddType() {
            // View displays a new mailing
            // Editing of this new mailing can be finished with done and cancel.
            let leftItem1 = UIBarButtonItem(title: "Abbrechen", style: .plain, target: self, action: #selector(cancelAction))
            let leftItems = [leftItem1]
            navigationItem.setLeftBarButtonItems(leftItems, animated: false)
            
            var rightItems = [UIBarButtonItem]()
            if viewEdited {
                let rightItem1 = UIBarButtonItem(title: "Fertig", style: .plain, target: self, action: #selector(doneAction))
                rightItems.append(rightItem1)
            }
            navigationItem.setRightBarButtonItems(rightItems, animated: false)
        } else if isEditType() {
            // View displays an existing mailing.
            // The mailing can be edited with an Edit button. This mode can be ended with done and cancel.
            var leftItems = [UIBarButtonItem]()
            if editMode {
                let leftItem1 = UIBarButtonItem(title: "Abbrechen", style: .plain, target: self, action: #selector(cancelAction))
                leftItems.append(leftItem1)
            }
            navigationItem.setLeftBarButtonItems(leftItems, animated: false)
            
            var rightItems = [UIBarButtonItem]()
            if editMode {
                let rightItem1 = UIBarButtonItem(title: "Fertig", style: .plain, target: self, action: #selector(doneAction))
                if !viewEdited {
                    rightItem1.isEnabled = false
                }
                rightItems.append(rightItem1)
            } else {
                let rightItem1 = UIBarButtonItem(title: "Bearbeiten", style: .plain, target: self, action: #selector(editAction))
                rightItems.append(rightItem1)
            }
            
            navigationItem.setRightBarButtonItems(rightItems, animated: false)
        }
    }
    
    @objc func switchChanged(mySwitch: UISwitch) {
        viewEdited = true
    }
    
    @objc func cancelAction(sender: UIBarButtonItem) {
        if isEditType(){
            delegate?.mailingListDetailViewControllerDidCancel(self)
        } else if isAddType() {
            delegate?.mailingListDetailViewControllerDidCancel(self)
        }
    }
    
    @objc func doneAction(sender: UIBarButtonItem) {
        if isEditType(){
            fillMailingListDTO()
            delegate?.mailingListDetailViewController(self, didFinishEditing: mailingListDTO!, assignmentChanges: contactAssignmentChanges)
        } else if isAddType() {
            fillMailingListDTO()
            delegate?.mailingListDetailViewController(self, didFinishAdding: mailingListDTO!, assignmentChanges: contactAssignmentChanges)
        }
    }
    
    @objc func editAction(sender: UIBarButtonItem) {
        editMode = true
        viewEdited = false
        configureBarButtonItems()
        configureControls()
        tableView.reloadData()
    }
    
    /**
     Deletes the mailing list
     */
    func deleteAction() {
        delegate?.mailingListDetailViewController(self, didFinishDeleting: mailingListDTO!)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMailingListContacts",
            let destinationVC = segue.destination as? MailingListContactsTableViewController
        {
            guard let container = container else {
                return
            }
            
            destinationVC.container = container
            destinationVC.editMode = editMode
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
    
    // MARK: - TableView Delegate
    
    // Do not allow cell selection except for contactlist
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 2 {
            // Section 2 should be selectable to navigate to the contact assignments
            return indexPath
        } else if indexPath.section == 3 {
            // Section 3 should be selectable to delete the mailing list.
            return indexPath
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 3 {
            // Section for delete button.
            if editMode && isEditType() {
                // Only visible if view is in editMode for an existing mailing
                return super.tableView(tableView, heightForRowAt: indexPath)
            } else {
                return 0
            }
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            nameTextField.becomeFirstResponder()
        } else if indexPath.section == 3 {
            // Delete mailinglist
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Verteiler löschen", style: .default) { _ in
                self.tableView.deselectRow(at: indexPath, animated: true)
                self.deleteAction()
            })
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel) { _ in
                // Do nothing
            })
            // The following 2 lines are needed for iPad.
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = self.mailingListDeleteCell.frame
            
            present(alert, animated: true)
        }
    }
    
    // MARK:- MailingListDetailViewController Delegate
    
    /**
     Protocol function. Called after canceled the detail view
     Removes the edit view.
     */
    func mailingListDetailViewControllerDidCancel(_ controller: MailingListDetailViewController) {
        editMode = false
        viewEdited = false
        
        if isEditType() {
            configureBarButtonItems()
            fillControls()
            configureControls()
            tableView.reloadData()
        } else {
            navigationController?.popViewController(animated:true)
        }
    }
    
    /**
     Protocol function. Called after finish adding a new MailingList
     Saves data to database and removes the edit view.
     */
    func mailingListDetailViewController(_ controller: MailingListDetailViewController, didFinishAdding mailingList: MailingListDTO, assignmentChanges: [ContactAssignmentChange]) {
        
        guard let container = container else {
            print("Save not possible. No PersistentContainer.")
            return
        }
        
        // try MailingList.createOrUpdateFromDTO(mailingList, assignmentChanges: assignmentChanges, in: container.viewContext)
        
        // Update database
        do {
            if contactAssignmentChanges.count > 0 {
                try MailingList.createOrUpdateFromDTO(mailingList, assignmentChanges: assignmentChanges, in: container.viewContext)
            } else {
                // No assignments done in this view. Create contact with default assignments.
                try MailingList.createOrUpdateFromDTO(mailingList, in: container.viewContext)
            }
            editMode = false
            viewEdited = false
            contactAssignmentChanges = [ContactAssignmentChange]()
        } catch {
            // TODO show Alert
        }
        
        navigationController?.popViewController(animated:true)
    }
    
    /**
     Protocol function. Called after finish editing an existing MailingList
     Saves data to database and removes the edit view.
     */
    func mailingListDetailViewController(_ controller: MailingListDetailViewController, didFinishEditing mailingList: MailingListDTO, assignmentChanges: [ContactAssignmentChange]) {
        
        guard let container = container else {
            print("Save not possible. No PersistentContainer.")
            return
        }
        
        // Update database
        do {
            try MailingList.createOrUpdateFromDTO(mailingList, assignmentChanges: assignmentChanges, in: container.viewContext)
            editMode = false
            viewEdited = false
            contactAssignmentChanges = [ContactAssignmentChange]()
        } catch {
            // TODO show Alert
        }
        configureBarButtonItems()
        fillControls()
        configureControls()
        tableView.reloadData()
    }
    
    func mailingListDetailViewController(_ controller: MailingListDetailViewController, didFinishDeleting mailingList: MailingListDTO) {
        
        guard let container = container else {
            print("Delete not possible. No PersistentContainer.")
            return
        }
        
        // Update database
        do {
            try MailingList.deleteMailingList(mailingList, in: container.viewContext)
            editMode = false
            viewEdited = false
            // dataChanged = true
        } catch {
            // TODO show Alert
        }
        
        navigationController?.popViewController(animated:true)
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
        
        viewEdited = true
    }
}
