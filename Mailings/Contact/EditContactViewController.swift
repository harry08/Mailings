//
//  EditContactViewController.swift
//  Mailings
//
//  Created by Harry Huebner on 08.01.18.
//  Copyright © 2018 Huebner. All rights reserved.
//

import UIKit
import CoreData
import os.log

/**
 Handles creation of a new contact and editing an existing contact.
 */
class EditContactViewController: UIViewController {
    
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var emaiField: UITextField!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var editMode = false
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    // In case of editing an existing contact this variable is filled on startup.
    // In case of a new one this will be created in the prepare method.
    var contactDTO : MailingContactDTO?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up views if editing an existing contact.
        if let contactDTO = self.contactDTO {
            navigationItem.title = contactDTO.lastname
            firstNameField.text = contactDTO.firstname
            lastNameField.text = contactDTO.lastname
            emaiField.text = contactDTO.email
        }
    }
    
    //MARK: Navigation
    
    /**
     Depending on edit mode
     this view controller needs to be dismissed in two different ways.
     */
    @IBAction func cancel(_ sender: Any) {
        if editMode == false {
            // In add mode the detail scence Was called as popup
            dismiss(animated: true, completion: nil)
        } else if let owningNavigationController = navigationController{
            // In edit mode the detail scene was pushed onto a navigation stack
            owningNavigationController.popViewController(animated: true)            
        } else {
            fatalError("The EditContactViewController is not inside a navigation controller.")
        }
    }
    
    // Called after save button pressed before navigating to other screen.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        let lastname = lastNameField.text ?? ""
        let firstname = firstNameField.text ?? ""
        let email = emaiField.text ?? ""
        
        // Fill up values
        if contactDTO == nil {
            // Create new ContactDTO object
            contactDTO = MailingContactDTO()
        }
        contactDTO?.lastname = lastname
        contactDTO?.firstname = firstname
        contactDTO?.email = email
    }
}
