//
//  ImportContactsViewController.swift
//  Mailings
//
//  Created on 10.11.17.
//

import UIKit
import os.log
import CoreData
import Contacts
import ContactsUI

class ImportContactsViewController: UIViewController, CNContactPickerDelegate, AddressbookGroupPickerTableViewControllerDelegate {
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer

    @IBOutlet weak var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIHelper.isDarkMode(traitCollection: traitCollection) {
            view.backgroundColor = UIColor.black
        }
        
        infoLabel.isHidden = true
    }
    
    /**
     Loads all contacts from the given addressbook group
     */
    private func importContactsOfGroup(_ group: CNGroup) -> Int {
        var contactCounter : Int = 0
        
        AppDelegate.getAppDelegate().requestForAccess { (accessGranted) -> Void in
            if accessGranted,
                let context = self.container?.viewContext {
                let contactsStore = AppDelegate.getAppDelegate().contactStore
                
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactBirthdayKey, CNContactImageDataKey]
                var contacts = [CNContact]()
                do {
                    let predicate = CNContact.predicateForContactsInGroup(withIdentifier: group.identifier)
                        
                    contacts = try contactsStore.unifiedContacts(matching: predicate, keysToFetch: keys as [CNKeyDescriptor])
                    
                    for i in 0 ..< contacts.count {
                        let contact = contacts[i]
                        if try !MailingContact.contactExists(contact: contact, in: context) {
                            try MailingContact.createContact(contact: contact, in: context)
                            contactCounter += 1
                        } else {
                            print("Contact \(contact.givenName) \(contact.familyName) not imported.")
                        }
                    }
                    
                    
                    // Loading done. Save data.
                    try? context.save()
                }
                catch {
                    print("Unable to fetch contacts")
                }
            }
        }
        
        return contactCounter
    }
    
    private func showImportResult(importedContacts: Int) {
        var message : String
        if importedContacts > 1 {
            message = "\(importedContacts) Kontakte importiert"
        } else if importedContacts == 1 {
            message = "Ein Kontakt importiert"
        } else {
            message = "Keine Kontakte importiert"
        }
        print(message)
        
        let imporResultMessage = "Kontaktimport abgeschlossen\n\(message)"
        infoLabel.text = imporResultMessage
        infoLabel.isHidden = false
    }
    
    private func getAddressbookGroups() -> [ContactGroupDTO]{
        var selectedGroups : [ContactGroupDTO] = [ContactGroupDTO]()
        
        AppDelegate.getAppDelegate().requestForAccess { (accessGranted) -> Void in
            if accessGranted {
                let contactsStore = AppDelegate.getAppDelegate().contactStore
                
                do {
                    let groups = try contactsStore.groups(matching: nil)
                    for i in 0 ..< groups.count {
                        let group = groups[i]
                        
                        let keys = [CNContactIdentifierKey]
                        var contacts = [CNContact]()
                        let predicate = CNContact.predicateForContactsInGroup(withIdentifier: group.identifier)
                        contacts = try contactsStore.unifiedContacts(matching: predicate, keysToFetch: keys as [CNKeyDescriptor])
                        let contactCount = contacts.count
                        let contactGroup = ContactGroupDTO(group: group, nrOfContacts: contactCount)
                        
                        selectedGroups.append(contactGroup)
                    }
                }
                catch let error as NSError {
                    os_log("Could not fetch addressbook groups: %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
                }
            }
        }
        
        return selectedGroups
    }
    
    // MARK: - Navigation and Actions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pickGroup",
            let destinationVC = segue.destination as? AddressbookGroupPickerTableViewController
        {
            destinationVC.delegate = self
            destinationVC.groups = getAddressbookGroups()
        }
    }

    /**
     Action that calls the ContactPicker View.
     */
    @IBAction func importSelectedContacts(_ sender: Any) {
        let contactPickerViewController = CNContactPickerViewController()
        contactPickerViewController.delegate = self
        present(contactPickerViewController, animated: true, completion: nil)
    }
    
    // MARK: - ContactPicker Delegate
    
    /**
     ContactPicker Delegate method. Called after contacts where picked.
     Imports the chosen contacts
     */
    public func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        var contactCounter : Int = 0
        
        guard let container = container else {
            return
        }
        
        do {
            for i in 0 ..< contacts.count {
                let contact = contacts[i]
                if try !MailingContact.contactExists(contact: contact, in: container.viewContext) {
                    try MailingContact.createContact(contact: contact, in: container.viewContext)
                    contactCounter += 1
                }
            }
            
            try container.viewContext.save()
            
            showImportResult(importedContacts: contactCounter)
            
        } catch let error as NSError {
            print("Could not save addressbook contact: \(error), \(error.userInfo)")
        }
    }
    
    // MARK: - AddressbookGroupPicker Delegate
    
    /**
     Addressbook group picker Delegate method. Called after group was picked.
     Imports all contacts of the selected group
     */
    func groupPicker(_ picker: AddressbookGroupPickerTableViewController, didPick chosenGroup: ContactGroupDTO) {
        navigationController?.popViewController(animated:true)
        
        let importedContacts = importContactsOfGroup(chosenGroup.group)
        showImportResult(importedContacts: importedContacts)
    }
}
