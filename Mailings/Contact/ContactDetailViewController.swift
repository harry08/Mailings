//
//  ContactDetailViewController.swift
//  Mailings
//
//  Created on 22.02.18.
//

import UIKit
import CoreData
import MessageUI

/**
 Delegate that is called after the main actions of the DetailController
 i.e. Editing canceled, Contact added, Contact changed.
 Used to update the database.
 */
protocol ContactDetailViewControllerDelegate: class {
    func contactDetailViewControllerDidCancel(_ controller: ContactDetailViewController)
    func contactDetailViewController(_ controller: ContactDetailViewController, didFinishAdding contact: MailingContactDTO)
    func contactDetailViewController(_ controller: ContactDetailViewController, didFinishEditing contact: MailingContactDTO)
    func contactDetailViewController(_ controller: ContactDetailViewController, didFinishDeleting contact: MailingContactDTO)
}

/**
 Delegate that is called after data has changed in the DetailController
 */
protocol ContactDetailViewControllerInfoDelegate: class {
    func contactDetailViewControllerDidChangeData(_ controller: ContactDetailViewController)
}

class ContactDetailViewController: UITableViewController, ContactDetailViewControllerDelegate, ContactMailingListsTableViewControllerDelegate, MailingPickerTableViewControllerDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var firstnameTextField: UITextField!
    @IBOutlet weak var lastnameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    
    @IBOutlet weak var contactDeleteCell: UITableViewCell!
    let messageComposer = MessageComposer()
    
    /**
     Flag indicates whether a new mailing is shown or an existing one.
     */
    var editType = false
    
    /**
     Flag indicates whether the view is in readonly mode or edit mode.
     */
    var editMode = false
    
    /**
     Flag indicates if data has been changed through this view
     */
    var dataChanged = false {
        didSet {
            if dataChanged {
                infoDelegate?.contactDetailViewControllerDidChangeData(self)
            }
        }
    }
    
    /**
     Delegate to call after finish editing
     Weak reference to avoid ownership cycles.
     The detailView has only a weak reference back to the owning tableView.
     */
    weak var delegate: ContactDetailViewControllerDelegate?
    
    weak var infoDelegate: ContactDetailViewControllerInfoDelegate?
    
    /**
     List of mailing lists assinged to this contact.
     Used for displaying assignments in the sub view.‚
     */
    var assignedMailingLists = AssigndMailingLists()
    
    /**
     List of changes of mailing list assignments for this contact.
     */
    var mailingListAssignmentChanges = [MailingListAssignmentChange]()
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    // In case of editing an existing contact this variable is filled on startup.
    // In case of a new one this will be created in the prepare method.
    var mailingContactDTO : MailingContactDTO?
    
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
            
            title = "Kontakt"
        } else {
            editMode = true
        }
        configureBarButtonItems()
        configureControls()
        configureToolbar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isAddType() {
            // Only in add mode directly put the focus inside the title field.
            firstnameTextField.becomeFirstResponder()
        }
        configureToolbar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.isToolbarHidden = true
    }
    
    /**
     Fills the values from UI fields into the MailingListDTO.
     */
    private func fillMailingDTO() {
        let firstname = firstnameTextField.text ?? ""
        let lastname = lastnameTextField.text ?? ""
        let email = emailTextField.text ?? ""
        let notes = notesTextView.text ?? ""
        
        if mailingContactDTO == nil {
            // Create new MailingContactDTO object
            mailingContactDTO = MailingContactDTO()
        }
        mailingContactDTO?.firstname = firstname
        mailingContactDTO?.lastname = lastname
        mailingContactDTO?.email = email
        mailingContactDTO?.notes = notes
    }
    
    /**
     Fills the values from the DTO to the controls.
     */
    private func fillControls() {
        if let mailingContactDTO = self.mailingContactDTO {
            firstnameTextField.text = mailingContactDTO.firstname
            lastnameTextField.text = mailingContactDTO.lastname
            emailTextField.text = mailingContactDTO.email
            notesTextView.text = mailingContactDTO.notes
        }
    }
    
    private func configureControls() {
        firstnameTextField.isEnabled = editMode
        lastnameTextField.isEnabled = editMode
        emailTextField.isEnabled = editMode
        notesTextView.isEditable = editMode
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
    
    private func configureToolbar() {
        if editMode {
            self.navigationController?.isToolbarHidden = true
            
        } else {
            self.navigationController?.isToolbarHidden = false
            self.navigationController?.toolbar.barStyle = .default
            self.navigationController?.toolbar.isTranslucent = true
            self.navigationController?.toolbar.barTintColor = UIColor.white
            
            let msgImage = UIImage(named: "message.png")
            var items = [UIBarButtonItem]()
            items.append(
                UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(sendEmailAction))
            )
            items.append(
                UIBarButtonItem(image: msgImage, style: .plain, target: self, action: #selector(sendMailingAction))
            )
            self.toolbarItems = items
        }
    }
    
    @objc func cancelAction(sender: UIBarButtonItem) {
        if isEditType(){
            delegate?.contactDetailViewControllerDidCancel(self)
        } else if isAddType() {
            delegate?.contactDetailViewControllerDidCancel(self)
        }
    }
    
    @objc func doneAction(sender: UIBarButtonItem) {
        if isEditType(){
            fillMailingDTO()
            delegate?.contactDetailViewController(self, didFinishEditing: mailingContactDTO!)
        } else if isAddType() {
            fillMailingDTO()
            delegate?.contactDetailViewController(self, didFinishAdding: mailingContactDTO!)
        }
    }
    
    @objc func editAction(sender: UIBarButtonItem) {
        editMode = true
        viewEdited = false
        configureBarButtonItems()
        configureControls()
        configureToolbar()
        tableView.reloadData()
    }
    
    /**
     Deletes the contact
     */
    func deleteAction() {
        delegate?.contactDetailViewController(self, didFinishDeleting: mailingContactDTO!)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showContactMailingLists",
            let destinationVC = segue.destination as? ContactMailingListsTableViewController
        {
            guard let container = container else {
                return
            }
            
            destinationVC.container = container
            destinationVC.editMode = self.editMode
            destinationVC.delegate = self
            
            // Init assignedMailingLists list and pass as a reference to the sub view
            // This list is modified by the sub view when new mailing lists a are assigned or mailing lists are removed.
            if isAddType() {
                // Preinit mailing lists with default assignable lists
                let defaultMailingLists = MailingList.getDefaultMailingListsAsDTO(in: container.viewContext)
                assignedMailingLists.initWithMailingList(defaultMailingLists)
                for assignedMailingList in assignedMailingLists.mailingLists {
                    let assignmentChange = MailingListAssignmentChange(objectId: assignedMailingList.objectId, action: "A")
                    mailingListAssignmentChanges.append(assignmentChange)
                }
            } else {
                if !assignedMailingLists.isInit() {
                    // Init list of assigned mailing lists
                    if let objectId = mailingContactDTO?.objectId {
                    assignedMailingLists.initWithMailingList(MailingContact.getAssignedMailingLists(objectId: objectId, in: container.viewContext))
                    } else {
                        assignedMailingLists.initWithEmptyList()
                    }
                }
            }
            destinationVC.assignedMailingLists = assignedMailingLists
        } else if segue.identifier == "pickMailing",
            let destinationVC = segue.destination as? MailingPickerTableViewController
        {
            destinationVC.container = container
            destinationVC.delegate = self
        }
    }
    
    /**
     Sends an email to this contact
     */
    @objc func sendEmailAction(sender: UIBarButtonItem) {
        if let email = mailingContactDTO?.email {
            composeMail(emailAddress: email)
        }
    }
    
    @objc func sendMailingAction(sender: UIBarButtonItem) {
        if let _ = mailingContactDTO?.email {
            self.performSegue(withIdentifier: "pickMailing", sender: self)
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
    
    /**
     Presents the iOS screen to write an email with the contents of the provided mailing to the given email address
     */
    func composeMailForMailing(_ mailingDTO: MailingDTO, emailAddress: String) {
        if messageComposer.canSendText() {
            let messageComposeVc = messageComposer.configuredMailComposeViewController(mailing: mailingDTO, emailAddress: emailAddress)
            self.present(messageComposeVc, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "Mail kann nicht gesendet werden", message: "Bitte E-Mail Einstellungen überprüfen und erneut versuchen.", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - TableView Delegate
    
    // Do not allow cell selection except for mailinglist details
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 2 {
            // Section 2 should be selectable to navigate to the mailinglist details.
            return indexPath
        } else if indexPath.section == 4 {
            // Section 4 should be selectable to delete a contact.
            return indexPath
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 4 {
            // Section for delete button.
            if editMode && isEditType() {
                // Only visible if view is in editMode for an existing contact
                return super.tableView(tableView, heightForRowAt: indexPath)
            } else {
                return 0
            }
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 4 {
            // Delete contact
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Kontakt löschen", style: .default) { _ in
                self.tableView.deselectRow(at: indexPath, animated: true)
                self.deleteAction()
            })
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel) { _ in
                // Do nothing
            })
            // The following 2 lines are needed for iPad.
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = self.contactDeleteCell.frame
            
            present(alert, animated: true)
        }
    }
    
    // MARK: - ContactDetailViewController Delegate
    
    func contactDetailViewControllerDidCancel(_ controller: ContactDetailViewController) {
        editMode = false
        viewEdited = false
        
        if isEditType() {
            configureBarButtonItems()
            fillControls()
            configureControls()
            configureToolbar()
            tableView.reloadData()
        } else {
            navigationController?.popViewController(animated:true)
        }   
    }
    
    /**
     Protocol function. Called after finish editing a new MailingContact
     Saves data to database and navigates back to caller view.
     */
    func contactDetailViewController(_ controller: ContactDetailViewController, didFinishAdding contact: MailingContactDTO) {
        guard let container = container else {
            print("Save not possible. No PersistentContainer.")
            return
        }
        
        // Update database
        do {
            if mailingListAssignmentChanges.count > 0 {
                try MailingContact.createOrUpdateFromDTO(contactDTO: contact, assignmentChanges: mailingListAssignmentChanges, in: container.viewContext)
            } else {
                // No assignments done in this view. Create contact with default assignments.
                try MailingContact.createOrUpdateFromDTO(contactDTO: contact, in: container.viewContext)
            }
            editMode = false
            viewEdited = false
            dataChanged = true
            mailingListAssignmentChanges = [MailingListAssignmentChange]()
        } catch {
            // TODO show Alert
        }
        
        navigationController?.popViewController(animated:true)
    }
    
    /**
     Protocol function. Called after finish editing an existing MailingContact
     Saves data to database and stays in this view.
     */
    func contactDetailViewController(_ controller: ContactDetailViewController, didFinishEditing contact: MailingContactDTO) {
        guard let container = container else {
            print("Save not possible. No PersistentContainer.")
            return
        }
        
        // Update database
        do {
            try MailingContact.createOrUpdateFromDTO(contactDTO: contact, assignmentChanges: mailingListAssignmentChanges, in: container.viewContext)
            editMode = false
            viewEdited = false
            dataChanged = true
            mailingListAssignmentChanges = [MailingListAssignmentChange]()
        } catch {
            // TODO show Alert
        }
        configureBarButtonItems()
        fillControls()
        configureControls()
        configureToolbar()
        tableView.reloadData()
    }
    
    /**
     Protocol function. Called to delete an existing MailingContact
     Saves data to database and navigates back to caller view.
     */
    func contactDetailViewController(_ controller: ContactDetailViewController, didFinishDeleting contact: MailingContactDTO) {
        guard let container = container else {
            print("Delete not possible. No PersistentContainer.")
            return
        }
        
        // Update database
        do {
            try MailingContact.deleteContact(contactDTO: contact, in: container.viewContext)
            editMode = false
            viewEdited = false
            dataChanged = true
        } catch {
            // TODO show Alert
        }
        
        navigationController?.popViewController(animated:true)
    }
    
    // MARK: ContactMailingListsTableViewController Delegate
    
    /**
     Called after changing mailing list assignment in sub view.
     Takes the changes into the mailingListAssignmentChanges list.
     */
    func contactMailingListsTableViewController(_ controller: ContactMailingListsTableViewController, didChangeMailingLists mailingListAssignmentChanges: [MailingListAssignmentChange]) {
    
        for i in 0 ..< mailingListAssignmentChanges.count {
            let mailingListAssignmentChange = mailingListAssignmentChanges[i]
            let mailingListAlreadyChanged = self.mailingListAssignmentChanges.contains {$0.objectId == mailingListAssignmentChange.objectId}
            if !mailingListAlreadyChanged {
                // no entry with the objectId exists in the change list -> add it
                self.mailingListAssignmentChanges.append(mailingListAssignmentChange)
            } else {
                // A change entry for this contact already exists in the change list.
                if let existing = self.mailingListAssignmentChanges.first(where: { $0.objectId == mailingListAssignmentChange.objectId }) {
                    
                    if existing.action != mailingListAssignmentChange.action {
                        // The entry has a different action -> remove it from the change list.
                        if let index = self.mailingListAssignmentChanges.index(where: { $0.objectId == existing.objectId } ) {
                            self.mailingListAssignmentChanges.remove(at: index)
                        }
                    }
                }
            }
        }
        
        viewEdited = true
    }
    
    // MARK:- MailingPickerTableViewController Delegates
    
    /**
     Called after mailing was chosen. Send mailing to email address of contact.
     */
    func mailingPicker(_ picker: MailingPickerTableViewController, didPick chosenMailing: MailingDTO) {
        navigationController?.popViewController(animated:true)
        
        let emailAddress = mailingContactDTO?.email
        
        // Wait for 2 seconds in order to wait for the other
        // view to be finished before displaying the mail view.
        let when = DispatchTime.now() + 1 // wait 1 second
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.composeMailForMailing(chosenMailing, emailAddress: emailAddress!)
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
    
    // MARK:- UITextView Delegates
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        viewEdited = true
        
        return true
    }
}
