//
//  CsvContactReader.swift
//  Mailings
//
//  Created on 09.10.18.
//

import Foundation
import CoreData

/**
 Delegate to get informed with the progress information during importing
 */
protocol CsvContactReaderDelegate: class {
    func csvContactReaderInitialized(_ reader: CsvContactReader, numberOfRecords: Int)
    func csvContactReaderProgress(_ reader: CsvContactReader, recordNumber: Int)
    func csvContactReaderFinished(_ reader: CsvContactReader, importedContacts: [MailingContactDTO])
}

/**
 Imports contacts from csv Strings.
 The string should have a header with the column names.
 Expected format of the String:
 Vorname,Name,Email,Notizen,Erstellt am, Geändert am,Info Mail,Neue Liste\n
 Martina,Müller,mm@online.de,,20180124061137,20180124061137,1,1\n
 
 The columns after Geändert am represent the assigned mailing list. If they are omitted,
 the imported contacts are assigned to the default mailing lists.
 */
class CsvContactReader {

    var content : String
    var context : NSManagedObjectContext
    
    let contactHeaderFields = ["Vorname", "Name", "Email", "Notizen", "Erstellt am", "Geändert am"]
    
    var headerElements = [String]()
    var headerContainsMailingLists = false
    
    /**
     Delegate to call after each status change
     Weak reference to avoid ownership cycles.
     */
    weak var delegate: CsvContactReaderDelegate?
    
    init(csvContent: String, context: NSManagedObjectContext) {
        self.content = csvContent
        self.context = context
    }
    
    public func importContacts() throws { // -> [MailingContactDTO] {
        var importedContacts = [MailingContactDTO]()
        
        let lines = content.split(separator: "\n")
        delegate?.csvContactReaderInitialized(self, numberOfRecords: lines.count)
        
        for (index, line) in lines.enumerated() {
            if index == 0 {
                try processHeader(line)
            } else {
                do {
                    if let importContact = try processLine(line) {
                        importedContacts.append(importContact)
                    }
                } catch {
                    print("Could not import contact from line: \(line)")
                }
            }
            delegate?.csvContactReaderProgress(self, recordNumber: index)
        }
        
        delegate?.csvContactReaderFinished(self, importedContacts: importedContacts)
        
       // return importedContacts
    }
    
    func processLine(_ line: String.SubSequence) throws -> MailingContactDTO? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        
        var contact = MailingContactDTO()
        var assignmentChanges = [MailingListAssignmentChange]()
        
        let columns = line.split(separator: ",", omittingEmptySubsequences: false)
        for (index, column) in columns.enumerated() {
            let content = String(describing: column).trimmingCharacters(in: .whitespaces)
            
            let columnName = headerElements[index]
            switch columnName {
            case "Vorname":
                contact.firstname = content
            case "Name":
                contact.lastname = content
            case "Email":
                contact.email = content
            case "Notizen":
                contact.notes = content
            case "Erstellt am":
                contact.createtime = dateFormatter.date(from: content)
            case "Geändert am":
                contact.updatetime = dateFormatter.date(from: content)
            default:
                // mailinglist assignments
                if content == "1" {
                    // Mailing list is assigned
                    do {
                        if let mailingList = try MailingList.loadMailingListByBame(columnName, in : context) {
                            let assignmentChange = MailingListAssignmentChange(objectId: mailingList.objectId!, action: "A")
                            assignmentChanges.append(assignmentChange)
                        }
                    } catch {
                        print("Error. Mailinglist to assign with name \(columnName) not found")
                    }
                }
            }
        }
        
        do {
            print("Persisting contact \(contact)...")
            var firstname = contact.firstname
            if firstname == nil {
                firstname = ""
            }
            var lastname = contact.lastname
            if lastname == nil {
                lastname = ""
            }
            
            if try !MailingContact.contactExists(firstname: firstname!, lastname: lastname!, in: context) {
                if headerContainsMailingLists {
                    // Import with mailing lists. Then no default mailing lists are assigned
                    try MailingContact.createOrUpdateFromDTO(contactDTO: contact, assignmentChanges: assignmentChanges, in: context)
                } else {
                    // Import without mailing lists. Default mailing lists are assigned
                    try MailingContact.createOrUpdateFromDTO(contactDTO: contact, in: context)
                }
                
                
                return contact
            }
        } catch let error as NSError {
            print("Error persisting contact: \(error), \(error.userInfo)")
            throw error
        }
        
        return nil
    }
    
    func processHeader(_ header: String.SubSequence) throws {
        print("Header: \(header)")
        
        headerElements = [String]()
        
        let columns = header.split(separator: ",", omittingEmptySubsequences: false)
        for column in columns {
            let colName = String(describing: column).trimmingCharacters(in: .whitespaces)
            headerElements.append(colName)
        }
        
        for header in headerElements {
            if !contactHeaderFields.contains(header) {
                // Field not available in contact headers. It is asssumed to be a mailing list
                headerContainsMailingLists = true
            }
        }
    }
}
