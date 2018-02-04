//
//  ContactPickerTableViewController.swift
//  Mailings
//
//  Created on 01.02.18.
//

import UIKit
import CoreData

protocol ContactPickerTableViewControllerDelegate: class {
    func contactPicker(_ picker: ContactPickerTableViewController,
                    didPick chosenContacts: [MailingContactDTO])
}

/**
 Shows a list of contacts to choose from.
 Table is in Multiselection mode.
 After contact selection is done the ContactPickerTableViewControllerDelegate is called.
 */
class ContactPickerTableViewController: UITableViewController {

    @IBOutlet weak var btnDone: UIBarButtonItem!
    
    weak var delegate: ContactPickerTableViewControllerDelegate?
    
    /**
     Contacts to choose from
     */
    var contacts = [MailingContactDTO]()
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer {
        didSet {
            loadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
   
    /**
     Loads all available contacts and displays them in the table.
     */
    private func loadData() {
        if let context = container?.viewContext {
            let request : NSFetchRequest<MailingContact> = MailingContact.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(
                key: "lastname",
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
                )]
            
            do {
                let fetchedContacts = try context.fetch(request)
                
                contacts = [MailingContactDTO]()
                contacts.reserveCapacity(fetchedContacts.count)
                for case let fetchedContact in fetchedContacts {
                    let contactDTO = MailingContactMapper.mapToDTO(contact: fetchedContact)
                    contacts.append(contactDTO)
                }                
            } catch {
                
            }
            
            tableView.reloadData()
        }
    }
    
    private func updateDoneButtonState() {
        if let _ = tableView.indexPathForSelectedRow {
            btnDone.isEnabled = true
        } else {
            btnDone.isEnabled = false
        }
    }
    
    // MARK: - Actions and Navigation
    
    /**
     Called after contacts are chosen and done button is pressed.
     The delegate is called with the list of chosen contacts
     */
    @IBAction func pickContacts(_ sender: Any) {
        var pickedContacts = [MailingContactDTO]()
        
        if let selectedRows = tableView.indexPathsForSelectedRows {
            for i in 0 ..< selectedRows.count {
                let indexPath = selectedRows[i]
                let contact = contacts[indexPath.row]
                pickedContacts.append(contact)
            }
        }
        
        delegate?.contactPicker(self, didPick: pickedContacts)
    }
    
    // MARK: - TableView
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PickerContactCell", for: indexPath)
        let contact = contacts[indexPath.row]
        cell.textLabel?.text = contact.lastname!
        cell.detailTextLabel?.text = contact.firstname!
        
        cell.accessoryType = cell.isSelected ? .checkmark : .none
        cell.selectionStyle = .none // to prevent cells from being "highlighted"
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.selectionStyle = .none
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        updateDoneButtonState()
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
        
        updateDoneButtonState()
    }
}
