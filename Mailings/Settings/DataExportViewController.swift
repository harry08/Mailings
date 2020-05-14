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
    
    let wordDelimiterChar : Character = ";"
    let recordDelimiterChar : Character = "\n"
    let quoteChar : Character = "\""
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIHelper.isDarkMode(traitCollection: traitCollection) {
            view.backgroundColor = UIColor.black
        }
    }
    
    @IBAction func exportMailingLists(_ sender: Any) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        
        let fileName = "mailinglists".appending(dateFormatter.string(from: Date())).appending(".csv")
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        if let path = path,
            let context = self.container?.viewContext {
            
            // Header
            var csvText = "Name"
            csvText.append(self.wordDelimiterChar)
            csvText.append("Default")
            csvText.append(self.wordDelimiterChar)
            csvText.append("Empfänger als bcc")
            csvText.append(self.wordDelimiterChar)
            csvText.append("Erstellt am")
            csvText.append(self.wordDelimiterChar)
            csvText.append("Geändert am")
            csvText.append(self.recordDelimiterChar)
            
            // Mailinglista
            let mailingLists = MailingList.getAllMailingLists(in: context)
            mailingLists.forEach { mailingList in
                csvText.append(getDataFromMailingList(mailingList))
            }
            
            csvText.append(self.recordDelimiterChar)
            
            writeToFile(csvText, path: path, sender: sender)
        }
    }
    
    /**
     Creates a csv file with all contacts.
     Besides the normal contact data like name a record also containts the assigned mailinglists of this contact.
     For each available mailing list a column is added to the export record.
     */
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
                csvText.append(getDataFromContact(contact, mailingLists: mailingLists))
            }
            
            writeToFile(csvText, path: path, sender: sender)
        }
    }
    
    private func getContactHeader(mailingLists: [MailingList]) -> String {
        //var header = "Vorname,Name,Email,Notizen,Erstellt am, Geändert am"
        var header = "Vorname"
        header.append(self.wordDelimiterChar)
        header.append("Name")
        header.append(self.wordDelimiterChar)
        header.append("Email")
        header.append(self.wordDelimiterChar)
        header.append("Notizen")
        header.append(self.wordDelimiterChar)
        header.append("Erstellt am")
        header.append(self.wordDelimiterChar)
        header.append("Geändert am")
        
        // Add each mailingList as a column to the header
        for mailingList in mailingLists {
            var name = ""
            if mailingList.name != nil {
                name = mailingList.name!
            }
            header.append(self.wordDelimiterChar)
            header.append("\(name)")
        }
        
        header.append(self.recordDelimiterChar)
        
        return header
    }
    
    /**
     Returns a comma separated string for the given contact entity.
     */
    private func getDataFromContact(_ contact: MailingContact, mailingLists: [MailingList]) -> String {
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
        
        var contactRecord = "\(firstName)"
        contactRecord.append(self.wordDelimiterChar)
        contactRecord.append("\(lastName)")
        contactRecord.append(self.wordDelimiterChar)
        contactRecord.append("\(email)")
        contactRecord.append(self.wordDelimiterChar)
        if notes.count > 0 {
            if notes.contains(wordDelimiterChar) || notes.contains(recordDelimiterChar) {
                notes = "\(quoteChar)\(notes)\(quoteChar)"
            }
        }
        contactRecord.append("\(notes)")
        contactRecord.append(self.wordDelimiterChar)
        contactRecord.append("\(created)")
        contactRecord.append(self.wordDelimiterChar)
        contactRecord.append("\(updated)")
        
        // Fill each mailinglist column with 1 if contact is assigned to this mailinglist. Otherwise 0.
        for mailingList in mailingLists {
            var assigned = 0
            
            if let contactMailingLists = contact.lists {
                for case let contactMailingList as MailingList in contactMailingLists {
                    if contactMailingList.objectID == mailingList.objectID {
                        assigned = 1
                    }
                }
            }
            contactRecord.append(self.wordDelimiterChar)
            contactRecord.append("\(assigned)")
        }
    
        contactRecord.append(self.recordDelimiterChar)
        
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
        
        var mailingListRecord = "\(name)"
        mailingListRecord.append(self.wordDelimiterChar)
        mailingListRecord.append("\(defaultAssignment)")
        mailingListRecord.append(self.wordDelimiterChar)
        mailingListRecord.append("\(bcc)")
        mailingListRecord.append(self.wordDelimiterChar)
        mailingListRecord.append("\(created)")
        mailingListRecord.append(self.wordDelimiterChar)
        mailingListRecord.append("\(updated)")
        mailingListRecord.append(self.recordDelimiterChar)
        
        return mailingListRecord
    }
    
    private func writeToFile(_ text: String, path: URL, sender: Any) {
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
            activityViewController.popoverPresentationController?.sourceRect = (sender as! UIButton).frame
            
            self.present(activityViewController, animated: true, completion: {})
            
        } catch {
            print("Failed to create file")
        }
    }
}
