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
    var files = [AttachedFile]()
    var listIsInit = false
    
    func initWithFileList(_ files: [AttachedFile]) {
        self.files = files
        listIsInit = true
    }
    
    func initWithEmptyList() {
        listIsInit = true
    }
    
    func isInit() -> Bool {
        return listIsInit
    }
}
