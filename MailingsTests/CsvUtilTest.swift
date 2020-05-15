//
//  CsvUtilTest.swift
//  MailingsTests
//
//  Created on 15.05.20.
//

import XCTest

@testable import Mailings

class CsvUtilTest: XCTestCase {

    var sut: CsvUtil!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testSimpleString() {
        sut = CsvUtil()
        
        let values = ["One", "Two", "Three"]
        
        let result = sut.csvString(values)
        XCTAssertEqual(result, "One;Two;Three")
    }
    
    func testSimpleStringWithCustomDelimiter() {
        sut = CsvUtil(wordDelimiterChar: ",")
        
        let values = ["One", "Two", "Three"]
        
        let result = sut.csvString(values)
        XCTAssertEqual(result, "One,Two,Three")
    }
    
    func testSimpleStringWithRecordDelimiter() {
        sut = CsvUtil()
        
        let values = ["One", "Two", "Three"]
        
        let result = sut.csvString(values, appendRecordDelimter: true)
        XCTAssertEqual(result, "One;Two;Three\n")
    }
    
    func testStringWithIncludingWordDelimiter() {
        sut = CsvUtil()
        
        let values = ["One;Two", "Three", "Four"]
        let result = sut.csvString(values)
        XCTAssertEqual(result, "\"One;Two\";Three;Four")
    }
    
    func testStringWithIncludingRecordDelimiter() {
        sut = CsvUtil()
        
        let values = ["One\nTwo", "Three", "Four"]
        let result = sut.csvString(values)
        XCTAssertEqual(result, "\"One\nTwo\";Three;Four")
    }
}
