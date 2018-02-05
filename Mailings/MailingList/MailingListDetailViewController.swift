//
//  MailingListDetailViewController.swift
//  Mailings
//
//  Created on 26.01.18.
//

import UIKit
import os.log
import CoreData

protocol MailingListDetailViewControllerDelegate: class {
    func mailingListDetailViewControllerDidCancel(_ controller: MailingListDetailViewController)
    func mailingListDetailViewController(_ controller: MailingListDetailViewController, didFinishAdding mailingList: MailingListDTO)
    func mailingListDetailViewController(_ controller: MailingListDetailViewController, didFinishEditing mailingList: MailingListDTO)
}

class MailingListDetailViewController: UITableViewController, UITextFieldDelegate {

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
    
    // In case of editing an existing mailing this variable is filled on startup.
    // In case of a new one this will be created in the prepare method.
    var mailingListDTO : MailingListDTO?
    
    var viewEdited = false {
        didSet {
            doneButton.isEnabled = viewEdited
        }
    }
    
    private func isEditMode() -> Bool {
        return editMode
    }
    
    private func isAddMode() -> Bool {
        return !editMode
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
            doneButton.isEnabled = false
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
            destinationVC.container = container
            destinationVC.mailingListDTO = mailingListDTO
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
            delegate?.mailingListDetailViewController(self, didFinishAdding: mailingListDTO!)
        } else {
            delegate?.mailingListDetailViewController(self, didFinishEditing: mailingListDTO!)
        }
        
    }
    
    // MARK:- UITextField Delegates
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        let oldText = textField.text!
        let stringRange = Range(range, in:oldText)!
        let newText = oldText.replacingCharacters(in: stringRange, with: string)
        //doneButton.isEnabled = !newText.isEmpty
        viewEdited = !newText.isEmpty
        return true
    }
}
