//
//  ContactExportViewController.swift
//  Mailings
//
//  Created on 27.09.18.
//

import UIKit
import CoreData

/**
 View to controll exporting contacts and mailing lists to a file
 */
class DataExportViewController: UIViewController {
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func exportMailingLists(_ sender: Any) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        
        let fileName = "mailinglists".appending(dateFormatter.string(from: Date())).appending(".csv")
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        if let path = path,
            let context = self.container?.viewContext {
            
            var csvText = "Name,Default,Empfänger als bcc,Erstellt am, Geändert am\n"
            
            let mailingLists = MailingList.getAllMailingLists(in: context)
            mailingLists.forEach { mailingList in
                csvText.append(getDataFromMailingList(mailingList))
            }
            
            writeToFile(csvText, path: path)
        }
    }
    
    @IBAction func exportContacts(_ sender: Any) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        
        let fileName = "contacts".appending(dateFormatter.string(from: Date())).appending(".csv")
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        if let path = path,
            let context = self.container?.viewContext {
            
            let mailingLists = MailingList.getAllMailingLists(in: context)
            var csvText = getContactHeader(mailingLists: mailingLists)
            
            let contacts = MailingContact.getAllContacts(in: context)
            contacts.forEach { contact in
                csvText.append(getDataFromContact(contact, nrOfMailingLists: mailingLists.count))
            }
            
            writeToFile(csvText, path: path)
        }
    }
    
    private func getContactHeader(mailingLists: [MailingList]) -> String {
        var header = "Vorname,Name,Email,Notizen,Erstellt am, Geändert am"
        
        var count = mailingLists.count
        if count == 0 {
            count = 1
        }
        for _ in 0 ..< count {
            header.append(",Verteilerliste")
        }
        
        header.append("\n")
        
        return header
    }
    
    /**
     Returns a comma separated string for the given contact entity.
     */
    private func getDataFromContact(_ contact: MailingContact, nrOfMailingLists: Int) -> String {
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
        
        var count = 0
        if let mailingLists = contact.lists {
            for case let mailingList as MailingList in mailingLists {
                if let mailingListName = mailingList.name {
                    contactRecord.append(",\(mailingListName)")
                    count += 1
                }
            }
        }
        
        for _ in count ..< nrOfMailingLists {
            contactRecord.append(",")
        }
        
        contactRecord.append("\n")
        
        return contactRecord
    }
    
    /**
     Returns a comma separated string for the given mailinglist entity.
     */
    private func getDataFromMailingList(_ mailingList: MailingList) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        
        var name = ""
        if mailingList.name != nil {
            name = mailingList.name!
        }
        var defaultAssignment = "0"
        if mailingList.assignasdefault {
            defaultAssignment = "1"
        }
        var bcc = "0"
        if mailingList.recipientasbcc {
            bcc = "1"
        }
        var created = ""
        if let createtime = mailingList.createtime {
            created = dateFormatter.string(from: createtime)
        }
        var updated = ""
        if let updatetime = mailingList.updatetime {
            updated = dateFormatter.string(from: updatetime)
        }
        
        let mailingListRecord = "\(name),\(defaultAssignment),\(bcc),\(created),\(updated)\n"
        
        return mailingListRecord
    }
    
    private func writeToFile(_ text: String, path: URL) {
        do {
            try text.write(to: path, atomically: true, encoding: String.Encoding.utf8)
            
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
