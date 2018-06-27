//
//  AttachedFiles.swift
//  Mailings
//
//  Created on 04.06.18.
//

import Foundation

/**
 Container for attached files of a mailing.
 Also contains the fubfolder in the attachments directory where the files are stored.
 Designed as a class to be passed as a reference.
 */
class MailingAttachments {
    let subfolderName : String
    var files = [AttachedFile]()
    
    init(subFolderName: String) {
        self.subfolderName = subFolderName
    }
    
    init(files: [AttachedFile], subFolderName: String) {
        self.files = files
        self.subfolderName = subFolderName
    }
}
