//
//  ContactCsvReaderTest.swift
//  MailingsTests
//
//  Created on 30.04.20.
//

import XCTest

@testable import Mailings

let inputStringWithOneRecord = """
Vorname,Name,Notizen,Email
Peter,Neumeyer,Notiz,pm@test.de
"""

let simpleInputString = """
Vorname,Name,Notizen,Email
Peter,Neumeyer,Notiz,pm@test.de
Hans,Huber,,hanshuber@test.de
Petra,Huber,Notizen,phuber@test.de
"""

let inputStringWithWordDelimiter = """
Vorname,Name,Notizen,Email
Petra,Huber,"Notiz mit Komma,",phuber@test.de
Peter,Neumeyer,Notiz,pm@test.de
"""

let noteWithKomma = "Notiz mit Komma,"

let inputStringWithRecordDelimiter = """
Vorname,Name,Notizen,Email
Renate,Meyer,"Notiz mit Zeilenumbruch
hier geht es weiter in Zeile 2",rm@test.de
Peter,Neumeyer,Notiz,pm@test.de
"""

let noteWithLinebreak = """
Notiz mit Zeilenumbruch
hier geht es weiter in Zeile 2
"""

let inputStringWithMultipleRecordDelimiters = """
Vorname,Name,Notizen,Email
Renate,Meyer,"Notiz mit mehreren Zeilen
Zeile 2
Auf Zeile 3 geht es weiter
und jetzt die 4. und letzte Zeile",rm@test.de
Peter,Neumeyer,Notiz,pm@test.de
"""

let noteWithMultipleLinebreaks = """
Notiz mit mehreren Zeilen
Zeile 2
Auf Zeile 3 geht es weiter
und jetzt die 4. und letzte Zeile
"""

let inputStringWithWordAndRecordDelimiter = """
Vorname,Name,Notizen,Email
Renate,Meyer,"Notiz mit mehreren Zeilen
und einem Komma,",rm@test.de
Peter,Neumeyer,Notiz,pm@test.de
"""

let noteWithLinebreakAndWordDelimiter = """
Notiz mit mehreren Zeilen
und einem Komma,
"""

let simpleInputStringWithSemicolon = """
Vorname;Name;Notizen;Email
Peter;Neumeyer;Notiz;pm@test.de
Hans;Huber;;hanshuber@test.de
Petra;Huber;Notizen;phuber@test.de
"""

let inputStringWithHeaderOnly = "Vorname;Name;Notizen;Email"

// The 2nd record has a line break in the notes field without quotes.
// The import mechanism recognizes accepts this line but recognizes a 3rd line with only two solumns
let inputStringWithLineBreak = """
Vorname;Name;Notizen;Email
Petra;Huber;Notizen;phuber@test.de
Hans;Huber;Text mit Zeilenumbruch\nohne Quotes;hanshuber@test.de
"""

// The 2nd record has a word delimiter in the notes field without quotes.
// Hence the import mechanism recognizes more columns than allowed
let inputStringWithDelimiter = """
Vorname,Name,Notizen,Email
Petra,Huber,Notizen,phuber@test.de
Hans,Huber,Text mit Word Delimiter,ohne Quotes,hanshuber@test.de
"""

let inputStringWithEmptyEmail = """
Vorname;Name;Notizen;Email
Petra;Huber;Notizen;
"""

let inputStringWithAllColumns = """
Vorname;Name;Notizen;Email;Erstellt am; Geändert am
Brigitte;Skrabania;Notiz für Kontakt 1;bskrabania@test.de;20181024214400;20181024214400
Linda;Hack;;lindahack@test.de;20181024214400;20181024214400
"""

class ContactCsvReaderTest: XCTestCase {
    
    var sut: ContactCsvReader!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testReadSimpleStringWithOneRecord() {
        let inputString = inputStringWithOneRecord
        
        do {
            sut = ContactCsvReader()
            let contacts = try sut.readFileContent(inputString)
            
            XCTAssertEqual(contacts.count, 1, "One record should be imported")
            let previewcontact = contacts.first!
            let contact = previewcontact.contact
            XCTAssertEqual(contact.firstname, "Peter")
            XCTAssertEqual(contact.lastname, "Neumeyer")
            XCTAssertEqual(contact.notes, "Notiz")
            XCTAssertEqual(contact.email, "pm@test.de")
        } catch {
            XCTFail("Exception occured: \(error)")
        }
    }
    
    func testReadSimpleStringWithLimitedReader() {
        let inputString = simpleInputString
        
        do {
            sut = ContactCsvReader(readLimit: 2, wordDelimiterChar: ",")
            let contacts = try sut.readFileContent(inputString)
            
            XCTAssertEqual(contacts.count, 2, "Two records should be imported")
        } catch {
            XCTFail("Exception occured: \(error)")
        }
    }
    
    func testReadStringWithWordDelimiter() {
        let inputString = inputStringWithWordDelimiter
        
        do {
            sut = ContactCsvReader()
            let contacts = try sut.readFileContent(inputString)
            
            XCTAssertEqual(contacts.count, 2, "Two records should be imported")
            let previewcontact = contacts.first!
            let contact = previewcontact.contact
            XCTAssertEqual(contact.notes, noteWithKomma, "The notes field should contain the delimiter")
        } catch {
            XCTFail("Exception occured: \(error)")
        }
    }
    
    func testReadStringWithRecordDelimiter() {
        let inputString = inputStringWithRecordDelimiter
        
        do {
            sut = ContactCsvReader()
            let contacts = try sut.readFileContent(inputString)
            
            XCTAssertEqual(contacts.count, 2, "Two records should be imported")
            let previewcontact = contacts.first!
            let contact = previewcontact.contact
            XCTAssertEqual(contact.notes, noteWithLinebreak, "The notes field should contain the delimiter")
        } catch {
            XCTFail("Exception occured: \(error)")
        }
    }
    
    func testReadStringMultipleRecordDelimiters() {
        let inputString = inputStringWithMultipleRecordDelimiters
        
        do {
            sut = ContactCsvReader()
            let contacts = try sut.readFileContent(inputString)
            
            XCTAssertEqual(contacts.count, 2, "Two records should be imported")
            let previewcontact = contacts.first!
            let contact = previewcontact.contact
            XCTAssertEqual(contact.notes, noteWithMultipleLinebreaks, "The notes field should contain the delimiter")
        } catch {
            XCTFail("Exception occured: \(error)")
        }
    }
    
    func testReadStringRecordAndWordDelimiters() {
        let inputString = inputStringWithWordAndRecordDelimiter
        
        do {
            sut = ContactCsvReader()
            let contacts = try sut.readFileContent(inputString)
            
            XCTAssertEqual(contacts.count, 2, "Two records should be imported")
            let previewcontact = contacts.first!
            let contact = previewcontact.contact
            XCTAssertEqual(contact.notes, noteWithLinebreakAndWordDelimiter, "The notes field should contain the delimiter")
        } catch {
            XCTFail("Exception occured: \(error)")
        }
    }
    
    func testReadStringWithDifferentDelimiors() {
        let inputString = simpleInputStringWithSemicolon
        
        do {
            let metaData = try ContactCsvReader.analyzeFileContent(inputString)
            sut = ContactCsvReader(readLimit: -1, wordDelimiterChar: metaData.delimiter)
            let contacts = try sut.readFileContent(inputString)
            
            XCTAssertEqual(contacts.count, 3, "Three records should be imported")
        } catch {
            XCTFail("No exception expected: \(error)")
        }
    }
    
    func testWithEmptyString() {
        let inputString = ""
        
        do {
            sut = ContactCsvReader()
            let contacts = try sut.readFileContent(inputString)
            
            XCTAssertEqual(contacts.count, 0, "No records should be imported")
        } catch {
            XCTFail("No exception expected: \(error)")
        }
    }
    
    func testWithHeaderOnlyString() {
        let inputString = inputStringWithHeaderOnly
        
        do {
            sut = ContactCsvReader()
            let contacts = try sut.readFileContent(inputString)
            
            XCTAssertEqual(contacts.count, 0, "No records should be imported")
        } catch {
            XCTFail("No exception expected: \(error)")
        }
    }
    
    func testWithInvalidLineString() {
        let inputString = inputStringWithLineBreak
        
        do {
            let metaData = try ContactCsvReader.analyzeFileContent(inputString)
            sut = ContactCsvReader(readLimit: -1, wordDelimiterChar: metaData.delimiter)
            let _ = try sut.readFileContent(inputString)
            
            XCTFail("Exception expected")
        } catch ContactCsvReaderError.invalidRecord(let recordNumber) {
            // Expected exception
            // The input string has only 2 records. Since the 2nd one ends to early
            // a 3rd one is being parsed. But this one has only 2 columns
            XCTAssertEqual(recordNumber, 3, "Record at position 3 should have a failure")
        } catch {
            XCTFail("invalidRecord exception expected: \(error)")
        }
    }
    
    func testWithInvalidLineStringWithWordDelimiter() {
        let inputString = inputStringWithDelimiter
        
        do {
            let metaData = try ContactCsvReader.analyzeFileContent(inputString)
            sut = ContactCsvReader(readLimit: -1, wordDelimiterChar: metaData.delimiter)
            let _ = try sut.readFileContent(inputString)
            
            XCTFail("Exception expected")
        } catch ContactCsvReaderError.invalidRecord(let recordNumber) {
            // Expected exception
            XCTAssertEqual(recordNumber, 2, "Record at position 2 should have a failure")
        } catch {
            XCTFail("invalidRecord exception expected: \(error)")
        }
    }
    
    func testWithEmptyEmail() {
        let inputString = inputStringWithEmptyEmail
        
        do {
            let metaData = try ContactCsvReader.analyzeFileContent(inputString)
            sut = ContactCsvReader(readLimit: -1, wordDelimiterChar: metaData.delimiter)
            let contacts = try sut.readFileContent(inputString)
            
            XCTAssertEqual(contacts.count, 1, "One contact should be imported")
        } catch {
            XCTFail("No exception expected: \(error)")
        }
    }
    
    func testWithAllColumns() {
        let inputString = inputStringWithAllColumns
        
        do {
            let metaData = try ContactCsvReader.analyzeFileContent(inputString)
            sut = ContactCsvReader(readLimit: -1, wordDelimiterChar: metaData.delimiter)
            let contacts = try sut.readFileContent(inputString)
            
            XCTAssertEqual(contacts.count, 2, "Two contacts should be imported")
            // TODO check date
        } catch {
            XCTFail("No exception expected: \(error)")
        }
    }
}
