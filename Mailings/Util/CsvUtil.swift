//
//  CsvUtil.swift
//  Mailings
//
//  Created on 15.05.20.
//

import Foundation

class CsvUtil {
    let wordDelimiterChar : Character
    let recordDelimiterChar : Character = "\n"
    let quoteChar : Character = "\""
    
    init () {
        self.wordDelimiterChar = ";"
    }
    
    init (wordDelimiterChar: Character) {
        self.wordDelimiterChar = wordDelimiterChar
    }
    
    public func csvString(_ values: [String], appendRecordDelimter : Bool = false) -> String {
        var result = ""
        for (index, value) in values.enumerated() {
            var textToAppend = value
            if textToAppend.contains(wordDelimiterChar) || textToAppend.contains(recordDelimiterChar) {
                textToAppend = "\(quoteChar)\(textToAppend)\(quoteChar)"
            }
            result.append(textToAppend)
            if index < values.count - 1 {
                result.append(self.wordDelimiterChar)
            }
        }
        
        if appendRecordDelimter {
            result.append(self.recordDelimiterChar)
        }
        
        return result
    }
}
