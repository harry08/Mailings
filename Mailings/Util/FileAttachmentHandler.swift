//
//  FileAttachmentHandler.swift
//  Mailings
//
//  Created on 13.06.18.
//

import Foundation

class FileAttachmentHandler {
    
    /**
     Create the attachements subdirectory in the app documents directory if not yet exists.
     */
    class func createAttachementsDirectory() {
        let attachementDir = getAttachementsUrl().path
        
        let filemgr = FileManager.default
        if !filemgr.fileExists(atPath: attachementDir) {
            do {
                try filemgr.createDirectory(atPath: attachementDir, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Copies the given file to the attachments directory so that it is locally available.
     */
    class func copyFileToAttachementsDir(urlToCopy: URL) {
        createAttachementsDirectory()
        
        let filemgr = FileManager.default
        if filemgr.fileExists(atPath: urlToCopy.path) {
            let attachementURL = getAttachementsUrl()
            let destinationFile = attachementURL.appendingPathComponent(urlToCopy.lastPathComponent, isDirectory: false)
            
            do {
                try filemgr.copyItem(atPath: urlToCopy.path, toPath: destinationFile.path)
                print("Successfully copied file to \(destinationFile.path)")
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
            }
        } else {
            print("Error. No file found to copy at location \(urlToCopy.path)")
        }
    }
    
    /**
     Returns the url for the directory to store attachement files.
     */
    class func getAttachementsUrl() -> URL {
        let filemgr = FileManager.default
        
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        let docsURL = dirPaths[0]
        
        let attachementDir = docsURL.appendingPathComponent("attachements")
        
        return attachementDir
    }
    
    /**
     Returns the url for the given file.
     */
    class func getUrlForFile(fileName: String) -> URL {
        let attachementUrl = getAttachementsUrl()
        
        let destinationFile = attachementUrl.appendingPathComponent(fileName, isDirectory: false)
        return destinationFile
    }
}
