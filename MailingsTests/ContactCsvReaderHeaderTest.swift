//
//  ContactCsvReaderHeaderTest.swift
//  MailingsTests
//
//  Created in 09.05.20.
//

import XCTest

@testable import Mailings

let inputStringWithMissingHeaderColumns = """
Vorname,Name
Peter,Tester
"""

let inputStringWithNoHeaderLine = """
Peter,Tester
"""

let inputStringWithDifferentDelimiter = """
Vorname&Name
Peter&Tester
"""

let inputStringWithSemicolon = """
Vorname;Name;Notizen;Email
Peter;Tester;;email@test.de
"""

class ContactCsvReaderHeaderTest: XCTestCase {

    var sut: ContactCsvReader!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testAnalyzeWithMissingMandatoryHeaderColumn() {
        let inputString = inputStringWithMissingHeaderColumns
        
        do {
            try _ = ContactCsvReader.analyzeFileContent(inputString)
            XCTFail("Exception expected")
        } catch ContactCsvReaderError.invalidColumns {
            // Exception Expected
        } catch {
            XCTFail("Unexpected Exceptiontype: \(error)")
        }
    }
    
    func testAnalyzeWithNoHeaderLine() {
        let inputString = inputStringWithNoHeaderLine
        
        XCTAssertThrowsError(try ContactCsvReader.analyzeFileContent(inputString)) { error in
            XCTAssertEqual(error as! ContactCsvReaderError, ContactCsvReaderError.invalidColumns)
        }
    }
    
    func testAnalyzeWithEmptyContent() {
        let inputString = ""
        
        XCTAssertThrowsError(try ContactCsvReader.analyzeFileContent(inputString)) { error in
            XCTAssertEqual(error as! ContactCsvReaderError, ContactCsvReaderError.noContent)
        }
    }
    
    func testAnalyzeWithUnknownDelimiter() {
        let inputString = inputStringWithDifferentDelimiter
        
        XCTAssertThrowsError(try ContactCsvReader.analyzeFileContent(inputString)) { error in
            XCTAssertEqual(error as! ContactCsvReaderError, ContactCsvReaderError.invalidFileFormat)
        }
    }
    
    func testAnalyzeWithKnownDelimiter() {
        let inputString = inputStringWithSemicolon
        
        do {
            let metadata = try ContactCsvReader.analyzeFileContent(inputString)
            XCTAssertEqual(metadata.delimiter, ";", "Semicolon should be found as delimiter")
        } catch {
            XCTFail("Unexpected Exceptiontype: \(error)")
        }
    }

}
