//
//  AttachedFiles.swift
//  Mailings
//
//  Created on 04.06.18.
//

import Foundation

/**
 Container for attached files of a mailing
 Designed as a class to be passed as a reference.‚
 */
class MailingAttachements {
    var subfolderName : String? // TODO not optional
    var files = [AttachedFile]()
    var listIsInit = false
    
    func initWithFileList(_ files: [AttachedFile], subfolderName: String) {
        self.subfolderName = subfolderName
        self.files = files
        listIsInit = true
    }
    
    func initWithEmptyList(subfolderName: String) {
        self.subfolderName = subfolderName
        listIsInit = true
    }
    
    func isInit() -> Bool {
        return listIsInit
    }
}
