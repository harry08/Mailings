//
//  EditMailingListViewController.swift
//  Mailings
//
//  Created on 18.01.18.
//

import UIKit
import os.log
import CoreData

class EditMailingListViewController: UIViewController {

    var editMode = false
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var defaultAssignmentSwitch: UISwitch!
    @IBOutlet weak var recipientBccSwitch: UISwitch!
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    // In case of editing an existing mailing this variable is filled on startup.
    // In case of a new one this will be created in the prepare method.
    var mailingListDTO : MailingListDTO?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Handle the text field’s user input through delegate callbacks.
        // nameField.delegate = self
        
        // Set up views if editing an existing customer.
        if let mailingListDTO = self.mailingListDTO {
            nameField.text = mailingListDTO.name
            defaultAssignmentSwitch.isOn = mailingListDTO.assignAsDefault
            recipientBccSwitch.isOn = mailingListDTO.recipientAsBcc
        }
        
        // Enable the Save button only if the text field has a valid name.
        //updateSaveButtonState()
    }
    
    private func updateSaveButtonState() {
        // Disable the Save button if the title field is empty.
        let name = nameField.text ?? ""
        saveButton.isEnabled = !name.isEmpty
    }

    // MARK: - Navigation
    
    /**
     Depending on edit mode
     this view controller needs to be dismissed in two different ways.
     */
    @IBAction func cancel(_ sender: Any) {
        if editMode == false {
            // In add mode the detail scence Was called as popup
            dismiss(animated: true, completion: nil)
        } else if let owningNavigationController = navigationController{
            // In edit mode the mailing detail scene was pushed onto a navigation stack
            owningNavigationController.popViewController(animated: true)
        } else {
            fatalError("The EditMailingListViewController is not inside a navigation controller.")
        }
    }
    
    // Called after save button pressed before navigating to other screen.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        let name = nameField.text ?? ""
        let recipientBcc = recipientBccSwitch.isOn
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
}
