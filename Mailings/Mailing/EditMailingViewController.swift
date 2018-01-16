//
//  EditMailingViewController.swift
//  CustomerManager
//
//  Created on 24.11.17.
//

import UIKit
import os.log
import CoreData

class EditMailingViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var mailingTextView: UITextView!
    
    var editMode = false
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    // In case of editing an existing mailing this variable is filled on startup.
    // In case of a new one this will be created in the prepare method.
    var mailingDTO : MailingDTO?
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Handle the text field’s user input through delegate callbacks.
        titleField.delegate = self
        
        // Set up views if editing an existing customer.
        if let mailingDTO = self.mailingDTO {
            navigationItem.title = mailingDTO.title
            titleField.text = mailingDTO.title
            mailingTextView.text = mailingDTO.text
        }
        
        // Enable the Save button only if the text field has a valid name.
        updateSaveButtonState()
    }
    
    private func updateSaveButtonState() {
        // Disable the Save button if the title field is empty.
        let title = titleField.text ?? ""
        saveButton.isEnabled = !title.isEmpty
    }
    
    //MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        saveButton.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
        navigationItem.title = textField.text
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
            // In edit mode the mailing detail scene was pushed onto a navigation stack
            owningNavigationController.popViewController(animated: true)
        } else {
            fatalError("The EditMailingViewController is not inside a navigation controller.")
        }
    }
    
    // Called after save button pressed before navigating to other screen.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        let title = titleField.text ?? ""
        let text = mailingTextView.text ?? ""
        
        // Fill up values
        if mailingDTO == nil {
            // Create new MailingDTO object
            mailingDTO = MailingDTO()
        }
        mailingDTO?.title = title
        mailingDTO?.text = text
    }

}
