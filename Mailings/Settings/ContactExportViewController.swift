//
//  ContactExportViewController.swift
//  Mailings
//
//  Created on 27.09.18.
//

import UIKit
import CoreData

/**
 View to controll exporting contacts to a file
 */
class ContactExportViewController: UIViewController {
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func exportContacts(_ sender: Any) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        
        let fileName = "contacts".appending(dateFormatter.string(from: Date())).appending(".csv")
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        var csvText = "Vorname,Name,Email,Notizen,Erstellt am, Geändert am,Verteilerliste\n"
        
        if let path = path,
            let context = self.container?.viewContext {
            
            let contacts = MailingContact.getAllContacts(in: context)
            contacts.forEach { contact in
                csvText.append(getDataFromContact(contact))
            }
            
            do {
                try csvText.write(to: path, atomically: true, encoding: String.Encoding.utf8)
                
                let activityViewController = UIActivityViewController(activityItems: [path], applicationActivities: [])
                activityViewController.excludedActivityTypes = [
                    UIActivityType.assignToContact,
                    UIActivityType.saveToCameraRoll,
                    UIActivityType.postToFlickr,
                    UIActivityType.postToVimeo,
                    UIActivityType.postToTencentWeibo,
                    UIActivityType.postToTwitter,
                    UIActivityType.postToFacebook,
                    UIActivityType.openInIBooks
                ]
                
                // Relevant for iPad to adhere the popover to the share button.
                activityViewController.popoverPresentationController?.sourceView = view
                
                self.present(activityViewController, animated: true, completion: {})
                
            } catch {
                print("Failed to create file")
            }
        }
    }
    
    /**
     Returns a comma separated string for the given contact entity.
     */
    private func getDataFromContact(_ contact: MailingContact) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        
        var firstName = ""
        if contact.firstname != nil {
            firstName = contact.firstname!
        }
        var lastName = ""
        if contact.lastname != nil {
            lastName = contact.lastname!
        }
        var email = ""
        if contact.email != nil {
            email = contact.email!
        }
        var notes = ""
        if contact.notes != nil {
            notes = contact.notes!
        }
        var created = ""
        if let createtime = contact.createtime {
            created = dateFormatter.string(from: createtime)
        }
        var updated = ""
        if let updatetime = contact.updatetime {
            updated = dateFormatter.string(from: updatetime)
        }
        
        var contactRecord = "\(firstName),\(lastName),\(email),\(notes),\(created),\(updated)"
        
        if let mailingLists = contact.lists {
            for case let mailingList as MailingList in mailingLists {
                if let mailingListName = mailingList.name {
                    contactRecord.append(",\(mailingListName)")
                }
            }
        }
        
        contactRecord.append("\n")
        
        return contactRecord
    }
}
