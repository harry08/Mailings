//
//  ContactDetailViewController.swift
//  Mailings
//
//  Created by Harry Huebner on 22.02.18.
//  Copyright © 2018 Huebner. All rights reserved.
//

import UIKit
import CoreData
import MessageUI

/**
 Delegate that is called after closing the DetailController.
 Database update can be done in the implementing classes.
 */
protocol ContactDetailViewControllerDelegate: class {
    func contactDetailViewControllerDidCancel(_ controller: ContactDetailViewController)
    func contactDetailViewController(_ controller: ContactDetailViewController, didFinishAdding contact: MailingContactDTO)
    func contactDetailViewController(_ controller: ContactDetailViewController, didFinishEditing contact: MailingContactDTO)
}

class ContactDetailViewController: UITableViewController, ContactDetailViewControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var firstnameTextField: UITextField!
    @IBOutlet weak var lastnameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
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
     Delegate to call after finish editing
     Weak reference to avoid ownership cycles.
     The detailView has only a weak reference back to the owning tableView.
     */
    weak var delegate: ContactDetailViewControllerDelegate?
    
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
        
        if mailingContactDTO == nil {
            // Create new MailingContactDTO object
            mailingContactDTO = MailingContactDTO()
        }
        mailingContactDTO?.firstname = firstname
        mailingContactDTO?.lastname = lastname
        mailingContactDTO?.email = email
    }
    
    /**
     Fills the values from the DTO to the controls.
     */
    private func fillControls() {
        if let mailingContactDTO = self.mailingContactDTO {
            firstnameTextField.text = mailingContactDTO.firstname
            lastnameTextField.text = mailingContactDTO.lastname
            emailTextField.text = mailingContactDTO.email
        }
    }
    
    private func configureControls() {
        firstnameTextField.isEnabled = editMode
        lastnameTextField.isEnabled = editMode
        emailTextField.isEnabled = editMode
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
                UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(sendEmailAction))
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
    }
    
    /**
     Triggers sending this mailing as mail. First the mailing list has to be chosen.
     */
    @objc func sendEmailAction(sender: UIBarButtonItem) {
        if let email = mailingContactDTO?.email {
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
    
    // MARK: ContactDetailViewController Delegate
    
    func contactDetailViewControllerDidCancel(_ controller: ContactDetailViewController) {
        editMode = false
        viewEdited = false
        
        if isEditType() {
            configureBarButtonItems()
            fillControls()
            configureControls()
            configureToolbar()
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
            try MailingContact.createOrUpdateFromDTO(contactDTO: contact, in: container.viewContext)
            editMode = false
            viewEdited = false
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
            try MailingContact.createOrUpdateFromDTO(contactDTO: contact, in: container.viewContext)
            editMode = false
            viewEdited = false
        } catch {
            // TODO show Alert
        }
        configureBarButtonItems()
        fillControls()
        configureControls()
        configureToolbar()
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
}
