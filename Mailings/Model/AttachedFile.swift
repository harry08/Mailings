//
//  AttachedFile.swift
//  Mailings
//
//  Created on 04.06.18.
//

import Foundation

class AttachedFile {
    var name: String?
    var url: URL
    
    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}
