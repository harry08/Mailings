//
//  MailingDetailTableViewController.swift
//  Mailings
//
//  Created on 20.02.18.
//

import UIKit
import CoreData
import MessageUI

/**
 Delegate that is called after closing the DetailController.
 Database update can be done in the implementing classes.
 */
protocol MailingDetailViewControllerDelegate: class {
    func mailingDetailViewControllerDidCancel(_ controller: MailingDetailViewController)
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishAdding mailing: MailingDTO)
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishEditing mailing: MailingDTO)
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishDeleting mailing: MailingDTO)
}

class MailingDetailViewController: UITableViewController, UITextFieldDelegate, MailingDetailViewControllerDelegate, MailingListPickerTableViewControllerDelegate, MFMailComposeViewControllerDelegate {

    /**
     Flag indicates whether a new mailing is shown or an existing one.
     */
    var editType = false
    
    /**
     Flag indicates whether the view is in readonly mode or edit mode.
     */
    var editMode = false
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentTextView: UITextView!
    
    @IBOutlet weak var mailingDeleteCell: UITableViewCell!
    /**
     Delegate to call after finish editing
     Weak reference to avoid ownership cycles.
     The detailView has only a weak reference back to the owning tableView.
     */
    weak var delegate: MailingDetailViewControllerDelegate?
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    // In case of editing an existing mailing this variable is filled on startup.
    // In case of a new one this will be created in the prepare method.
    var mailingDTO : MailingDTO?
    
    /**
     Controls the doneButton
     */
    var viewEdited = false {
        didSet {
            configureBarButtonItems()
        }
    }
    
    var mailsToSend = [MailDTO]()
    
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
            
            title = "Mailing"
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
           titleTextField.becomeFirstResponder()
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
        let title = titleTextField.text ?? ""
        let content = contentTextView.text ?? ""
        
        if mailingDTO == nil {
            // Create new MailingDTO object
            mailingDTO = MailingDTO()
        }
        mailingDTO?.title = title
        mailingDTO?.text = content
    }
    
    /**
     Fills the values from the DTO to the controls.
     */
    private func fillControls() {
        if let mailingDTO = self.mailingDTO {
            titleTextField.text = mailingDTO.title
            contentTextView.text = mailingDTO.text
        }
    }
    
    private func configureControls() {
        titleTextField.isEnabled = editMode
        contentTextView.isEditable = editMode
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
            
            var items = [UIBarButtonItem]()
            items.append(
                UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(sendMailingAction))
            )
            self.toolbarItems = items
        }
    }
    
    @objc func cancelAction(sender: UIBarButtonItem) {
        if isEditType(){
            delegate?.mailingDetailViewControllerDidCancel(self)
        } else if isAddType() {
            delegate?.mailingDetailViewControllerDidCancel(self)
        }
    }
    
    @objc func doneAction(sender: UIBarButtonItem) {
        if isEditType(){
            fillMailingDTO()
            delegate?.mailingDetailViewController(self, didFinishEditing: mailingDTO!)
        } else if isAddType() {
            fillMailingDTO()
            delegate?.mailingDetailViewController(self, didFinishAdding: mailingDTO!)
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
     Deletes the mailing
     */
    func deleteAction() {
        delegate?.mailingDetailViewController(self, didFinishDeleting: mailingDTO!)
    }
    
    /**
     Triggers sending this mailing as mail. First the mailing list has to be chosen.
     */
    @objc func sendMailingAction(sender: UIBarButtonItem) {
        performSegue(withIdentifier: "pickMailingList", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pickMailingList",
            let destinationVC = segue.destination as? MailingListPickerTableViewController
        {
            // Choose mailing list to send mailing to.
            destinationVC.container = container
            destinationVC.delegate = self
        } else if segue.identifier == "showEmailsToSend",
            let destinationVC = segue.destination as? MailsToSendTableViewController
        {
            destinationVC.mailsToSend = mailsToSend
        }
    }
    
    // MARK: - TableView Delegate
    
    // Do not allow cell selection except for mailing deletion
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 2 {
            // Section 2 should be selectable to delete a mailing.
            return indexPath
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 {
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
            titleTextField.becomeFirstResponder()
        } else if indexPath.section == 1 {
            contentTextView.becomeFirstResponder()
        } else if indexPath.section == 2 {
            // Delete mailing
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Mailing löschen", style: .default) { _ in
                self.tableView.deselectRow(at: indexPath, animated: true)
                self.deleteAction()
            })
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel) { _ in
                // Do nothing
            })
            // The following 2 lines are needed for iPad.
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = self.mailingDeleteCell.frame
            
            present(alert, animated: true)
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
    
    // TODO Set viewEdited when textview was edited.
    
    // MARK: MailingDetailViewController Delegate
    
    /**
     Protocol function. Called after canceled editing of an existing mailing.
     */
    func mailingDetailViewControllerDidCancel(_ controller: MailingDetailViewController) {
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
     Protocol function. Called after finish editing a new Mailing
     Saves data to database and navigates back to caller view.
     */
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishAdding mailing: MailingDTO) {
        guard let container = container else {
            print("Save not possible. No PersistentContainer.")
            return
        }
        
        // Update database
        do {
            try Mailing.createOrUpdateFromDTO(mailingDTO: mailing, in: container.viewContext)
            editMode = false
            viewEdited = false
        } catch {
            // TODO show Alert
        }
        
        navigationController?.popViewController(animated:true)
    }
    
    /**
     Protocol function. Called after finish editing an existing Mailing
     Saves data to database and stays in this view.
     */
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishEditing mailing: MailingDTO) {
        guard let container = container else {
            print("Save not possible. No PersistentContainer.")
            return
        }
        
        // Update database
        do {
            try Mailing.createOrUpdateFromDTO(mailingDTO: mailing, in: container.viewContext)
            editMode = false
            viewEdited = false
        } catch {
            // TODO show Alert
        }
        configureBarButtonItems()
        fillControls()
        configureControls()
        configureToolbar()
        tableView.reloadData()
    }
    
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishDeleting mailing: MailingDTO) {
    
        guard let container = container else {
            print("Delete not possible. No PersistentContainer.")
            return
        }
        
        // Update database
        do {
            try Mailing.deleteMailing(mailingDTO: mailing, in: container.viewContext)
            editMode = false
            viewEdited = false
           // dataChanged = true
        } catch {
            // TODO show Alert
        }
        
        navigationController?.popViewController(animated:true)
    }
    
    // MARK: - MailingListPickerTableViewController Delegate
    
    func mailingListPicker(_ picker: MailingListPickerTableViewController, didPickList chosenMailingLists: [MailingListDTO]) {
        // no implementation Only single
    }
    
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
        if let mailingDTO = mailingDTO {
            let mailComposer = MailComposer(mailingDTO: mailingDTO)
            mailsToSend = mailComposer.composeMailsToSend(emailAddresses: emailAddresses)
            if mailsToSend.count == 1 {
                // Show Mail view directly
                composeMail(mailsToSend[0])
            } else if mailsToSend.count > 1 {
                // The mailing needs to be send in more than one mail.
                // Display tableview to show the different mails.
                performSegue(withIdentifier: "showEmailsToSend", sender: nil)
            }
        }
    }
    
    // MARK: - Send mail
    
    func composeMail(_ mailDTO: MailDTO) {
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
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func configuredMailComposeViewController(mailDTO: MailDTO) -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Set the mailComposeDelegate property to self
        
        mailComposerVC.setBccRecipients(mailDTO.emailAddresses)
        mailComposerVC.setSubject(mailDTO.mailingDTO.title!)
        mailComposerVC.setMessageBody(mailDTO.mailingDTO.text!, isHTML: false)
        
        return mailComposerVC
    }
}
