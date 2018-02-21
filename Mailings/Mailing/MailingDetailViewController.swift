//
//  MailingDetailTableViewController.swift
//  Mailings
//
//  Created on 20.02.18.
//

import UIKit
import CoreData

/**
 Delegate that is called after closing the DetailController.
 Database update can be done in the implementing classes.
 */
protocol MailingDetailViewControllerDelegate: class {
    func mailingDetailViewControllerDidCancel(_ controller: MailingDetailViewController)
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishAdding mailing: MailingDTO)
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishEditing mailing: MailingDTO)
}

class MailingDetailViewController: UITableViewController, UITextFieldDelegate {

    var editMode = false
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentTextView: UITextView!

    @IBOutlet weak var doneButton: UIBarButtonItem!
    
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
        doneButton.isEnabled = viewEdited
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        if let mailingDTO = self.mailingDTO {
            // Set up view if editing an existing mailingList.
            titleTextField.text = mailingDTO.title
            contentTextView.text = mailingDTO.text
            
            title = "Mailing"
            updateDoneButtonState()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isAddMode() {
            // Only in add mode directly put the focus inside the title field.
           titleTextField.becomeFirstResponder()
        }
    }
    
    /**
     Fills the values from UI fields into the MailingListDTO.
     */
    private func fillMailingDTO() {
        let title = titleTextField.text ?? ""
        let content = contentTextView.text ?? ""
        
        // Fill up values
        if mailingDTO == nil {
            // Create new MailingListDTO object
            mailingDTO = MailingDTO()
        }
        mailingDTO?.title = title
        mailingDTO?.text = content
    }
    
    // MARK: - Action and Navigation
    
    @IBAction func cancelAction(_ sender: Any) {
        delegate?.mailingDetailViewControllerDidCancel(self)
    }
    
    @IBAction func doneAction(_ sender: Any) {
        fillMailingDTO()
        
        if isAddMode() {
            delegate?.mailingDetailViewController(self, didFinishAdding: mailingDTO!)
        } else {
            delegate?.mailingDetailViewController(self, didFinishEditing: mailingDTO!)
        }
    }
    
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            titleTextField.becomeFirstResponder()
        } else if indexPath.section == 1 {
            contentTextView.becomeFirstResponder()
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
}
