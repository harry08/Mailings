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

class ImportContactsViewController: UIViewController {
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Loads all contacts which are assigned to a group from the device.
    private func loadContacts() {
        AppDelegate.getAppDelegate().requestForAccess { (accessGranted) -> Void in
            if accessGranted,
                let context = self.container?.viewContext {
                print("Loading contacts...")
                let contactsStore = AppDelegate.getAppDelegate().contactStore
                
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactBirthdayKey, CNContactImageDataKey]
                var contacts = [CNContact]()
                do {
                    var contactCounter : Int = 0
                    
                    // Selecting all groups
                    let groups = try contactsStore.groups(matching: nil)
                    for i in 0 ..< groups.count {
                        let group = groups[i]
                        print("Group: \(group.identifier): \(group.name). Fetching contacts for this group...")
                        
                        let predicate = CNContact.predicateForContactsInGroup(withIdentifier: group.identifier)
                        
                        contacts = try contactsStore.unifiedContacts(matching: predicate, keysToFetch: keys as [CNKeyDescriptor])
                        if contacts.count == 0 {
                            print("No contacts were found for group \(group.name)")
                        } else {
                            print("# of contacts for group \(group.name): \(contacts.count)")
                            for x in 0 ..< contacts.count {
                                let contact = contacts[x]
                                print("Contact: \(contact.givenName) \(contact.familyName). Adding to database...")
                                
                                // TDDO Import
                            }
                        }
                    }
                    
                    // Loading done. Save data.
                    try? context.save()
                    var message : String
                    if contactCounter > 1 {
                        message = "\(contactCounter) Kontakte importiert"
                    } else if contactCounter == 1 {
                        message = "Ein Kontakt importiert"
                    } else {
                        message = "Keine Kontakte importiert"
                    }
                    print(message)
                    
                    let alertController = UIAlertController(title: "Kontaktimport abeschlossen", message: message, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                catch {
                    print("Unable to fetch contacts")
                }
                
                print("Loading contacts done")
            }
        }
    }
    
    private func selectGroups() -> [CNGroup]{
        var selectedGroups : [CNGroup] = [CNGroup]()
        
        AppDelegate.getAppDelegate().requestForAccess { (accessGranted) -> Void in
            if accessGranted,
                let context = self.container?.viewContext {
                
                let contactsStore = AppDelegate.getAppDelegate().contactStore
                
                do {
                    let groups = try contactsStore.groups(matching: nil)
                    for i in 0 ..< groups.count {
                        let group = groups[i]
                        selectedGroups.append(group)
                        print("Group: \(group.identifier): \(group.name).")
                    }
                }
                catch let error as NSError {
                    os_log("Could not fetch addressbook groups: %s, %s", log: OSLog.default, type: .error, error, error.userInfo)
                }
            }
        }
        
        return selectedGroups
    }

    @IBAction func importSelectedContacts(_ sender: Any) {
        print("importSelectedContacts called")
        selectGroups()
    }
    
    @IBAction func importContactsFromGroup(_ sender: Any) {
        print("importContactsFromGroup called")
    }
    
}
