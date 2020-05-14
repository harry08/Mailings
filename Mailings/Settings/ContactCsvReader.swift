//
//  ContactCsvReader.swift
//  Mailings
//
//  Created by Harry Huebner on 29.04.20.
//

import Foundation

struct FileMetaData {
    var delimiter: Character
    var nrOfColumns: Int
}

struct PreviewContact {
    var contact: MailingContactDTO
    var mailingLists = [String]()
}

enum ContactCsvReaderError: Error {
    case invalidColumns
    case invalidRecord(recordNumber: Int)
    case invalidFileFormat
    case noContent
}

extension ContactCsvReaderError: Equatable {
  static func == (lhs: ContactCsvReaderError, rhs: ContactCsvReaderError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidColumns, .invalidColumns):
        return true
    case (.invalidFileFormat, .invalidFileFormat):
        return true
    case (.noContent, .noContent):
        return true
    case (.invalidRecord(let a), .invalidRecord(let b)):
        return a == b
    default:
        return false
    }
  }
}

struct HeaderCol {
    var title: String
    var mandatory: Bool = true
}

/**
 Parses a CSV Stirng into contact objects
 The string should have a header with the column names.
 Expected format of the String:
 Vorname,Name,Email,Notizen,Erstellt am, Geändert am,Info Mail,Neue Liste\n
 Martina,Müller,mm@online.de,,20180124061137,20180124061137,1,1\n
 
 The columns after "Geändert am" represent the assigned mailing list. If they are omitted,
 the imported contacts are assigned to the default mailing lists.
 */
class ContactCsvReader {
    static let headerCols = [HeaderCol(title: "Vorname"), HeaderCol(title: "Name"), HeaderCol(title: "Email"), HeaderCol(title: "Erstellt am", mandatory: false), HeaderCol(title: "Geändert am", mandatory: false)]
    
    static let quoteChar : Character = "\""
    static let quoteDelimiter = CharacterSet(charactersIn: quoteChar.description)
    
    let recordDelimiter = CharacterSet.newlines
    let recordDelimiterChar : Character = "\n"
    
    let wordDelimiter : CharacterSet
    let wordDelimiterChar : Character
    
    var headerElements = [String]()
    
    let readLimit : Int
    
    init (readLimit: Int, wordDelimiterChar: Character) {
        self.readLimit = readLimit
        self.wordDelimiterChar = wordDelimiterChar
        
        wordDelimiter = CharacterSet(charactersIn: self.wordDelimiterChar.description)
    }
    
    init () {
        self.readLimit = -1
        wordDelimiterChar = ","
        
        wordDelimiter = CharacterSet(charactersIn: wordDelimiterChar.description)
    }
    
    /**
     Parses the given content String into contacts
     */
    func readFileContent(_ content: String) throws -> [PreviewContact]{
        var parsedContacts = [PreviewContact]()
        
        let lineScanner = Scanner(string: content)
        
        var index = 0
        while !lineScanner.isAtEnd && canReadMore(readContacts: parsedContacts.count) {
            let lineContent = getNextLine(lineScanner: lineScanner)
            if let lineContent = lineContent {
                if index == 0 {
                    processHeader(lineContent)
                } else {
                    if let contact = try processLine(lineContent, lineIndex: index) {
                        parsedContacts.append(contact)
                    }
                }
                
                if !lineScanner.isAtEnd {
                    // Skip the recorddelimiter if available
                    if content[lineScanner.currentIndex] == recordDelimiterChar {
                        lineScanner.currentIndex = content.index(after: lineScanner.currentIndex)
                    }
                }
            }
            
            index += 1
        }
        
        return parsedContacts
    }
    
    private func canReadMore(readContacts: Int) -> Bool {
        if readLimit > -1 {
            return readContacts < readLimit
        }
            
        return true
    }
    
    /**
     Processes one line of the CSV String.
     */
    private func processLine(_ line : String, lineIndex : Int) throws -> PreviewContact? {
        var previewContact = PreviewContact(contact: MailingContactDTO())
        var columnIndex = 0
        
        let contactScanner = Scanner(string: line)
        while !contactScanner.isAtEnd {
            let firstChar = line[contactScanner.currentIndex]
            let quotedContent = firstChar == ContactCsvReader.quoteChar
            
            var column : String?
            if quotedContent {
                // Move one char forward
                contactScanner.currentIndex = line.index(after: contactScanner.currentIndex)
                column = getNextColumn(contactScanner: contactScanner, delimiter: ContactCsvReader.quoteDelimiter)
                
                // Move one char forward to skip the word delimiter
                contactScanner.currentIndex = line.index(after: contactScanner.currentIndex)
            } else {
                column = getNextColumn(contactScanner: contactScanner, delimiter: wordDelimiter)
            }
            
            guard columnIndex < self.headerElements.count else {
                // To much columns
                throw ContactCsvReaderError.invalidRecord(recordNumber: lineIndex)
            }
            
            if let column = column {
                previewContact = try updateContact(previewContact, value: column, columnIndex: columnIndex, lineIndex: lineIndex)
            }
            
            if !contactScanner.isAtEnd {
                // Manually move forward because delimiter is not skipped.
                // Otherwise empty fields are not readable
                contactScanner.currentIndex = line.index(after: contactScanner.currentIndex)
            }
            
            columnIndex += 1
        }
        
        guard columnIndex == self.headerElements.count - 1 || columnIndex == self.headerElements.count else {
            // After processing the contact
            // the columnIndex should be at the end or one step before in case the last column is not filled.
            throw ContactCsvReaderError.invalidRecord(recordNumber: lineIndex)
        }
        
        return previewContact
    }
    
    private func getNextColumn(contactScanner : Scanner, delimiter: CharacterSet) -> String? {
        let content = contactScanner.scanUpToCharacters(from: delimiter)
        return content
    }
    
    /**
     Updates the given contact with the String in value.
     */
    private func updateContact(_ previewContact : PreviewContact, value : String, columnIndex : Int, lineIndex : Int) throws -> PreviewContact {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        
        var updatedPreviewContact = previewContact
        
        let columnName = headerElements[columnIndex]
        switch columnName {
        case "Vorname":
            updatedPreviewContact.contact.firstname = value
        case "Name":
            updatedPreviewContact.contact.lastname = value
        case "Email":
            updatedPreviewContact.contact.email = value
        case "Notizen":
            updatedPreviewContact.contact.notes = value
        case "Erstellt am":
            updatedPreviewContact.contact.createtime = dateFormatter.date(from: value)
            if updatedPreviewContact.contact.createtime == nil {
                throw ContactCsvReaderError.invalidRecord(recordNumber: lineIndex)
            }
        case "Geändert am":
            updatedPreviewContact.contact.updatetime = dateFormatter.date(from: value)
            if updatedPreviewContact.contact.updatetime == nil {
                throw ContactCsvReaderError.invalidRecord(recordNumber: lineIndex)
            }
        default:
            if value == "1" {
                // Consider the column as a mailinglist assignment when filled with 1
                // The column title is the name of the mailinglist.
                updatedPreviewContact.mailingLists.append(columnName)
            }
        }
        
        return updatedPreviewContact
    }
    
    private func processHeader(_ header: String) {
        print("Header: \(header)")
        
        headerElements = [String]()
        
        let columns = header.split(separator: wordDelimiterChar, omittingEmptySubsequences: false)
        for column in columns {
            let colName = String(describing: column).trimmingCharacters(in: .whitespaces)
            headerElements.append(colName)
        }
    }
    
    /**
     Returns the next line of the given lineScanner
     If the line delimiter is inside quoted text this position is skipped.
     */
    private func getNextLine(lineScanner : Scanner) -> String? {
        let lineContent = lineScanner.scanUpToCharacters(from: recordDelimiter)
        if var lineContent = lineContent {
            if lineContent.contains(ContactCsvReader.quoteChar.description) {
                // If the line has a record delimiter inside the quoted text
                // this delimiter belongs to the record
                print("Linecontent contains quotes: \(lineContent)")
                var count = lineContent.filter {$0 == ContactCsvReader.quoteChar}.count
                while count % 2 != 0 {
                    // Quote not closed. Append delimiter and read further
                    lineContent.append(recordDelimiterChar)
                    let nextString = lineScanner.scanUpToCharacters(from: recordDelimiter)
                    if let nextString = nextString {
                        lineContent += nextString
                    }
                    
                    count = lineContent.filter {$0 == ContactCsvReader.quoteChar}.count
                }
            }
            
            return lineContent
        }
        
        return nil
    }
    
    /**
     Analyzes the given content and tries to determine the record delimiter.
     The header line should contain at least name, vorname und email
     */
    public static func analyzeFileContent(_ content: String) throws -> FileMetaData {
        // Analyze header and try to determine delimiter
        let lineScanner = Scanner(string: content)
        lineScanner.charactersToBeSkipped = CharacterSet.newlines
        if let firstLine = lineScanner.scanUpToCharacters(from: CharacterSet.newlines) {
            let mandatoryCols = headerCols.filter({ $0.mandatory == true })
            
            let delimiters = [Character(","), Character(";")]
            for delimiter in delimiters {
                let columns = firstLine.split(separator: delimiter, omittingEmptySubsequences: false)
                
                if (columns.count > 1) {
                    // Delimter found. Ckeck if all mandatory columns are filled.
                    for mandatoryCol in mandatoryCols {
                        var mandatoryColFound = false
                        for col in columns {
                            if String(col) == mandatoryCol.title {
                                mandatoryColFound = true
                            }
                        }
                        
                        if (!mandatoryColFound) {
                            throw ContactCsvReaderError.invalidColumns
                        }
                    }
                    
                    return FileMetaData(delimiter: delimiter, nrOfColumns: columns.count)
                }
            }
            
            throw ContactCsvReaderError.invalidFileFormat
        } else {
            throw ContactCsvReaderError.noContent
        }
    }
}
