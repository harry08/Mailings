//
//  FileAttachmentHandler.swift
//  Mailings
//
//  Created on 13.06.18.
//

import Foundation
import MobileCoreServices


/**
 When a file is attached to a mailing it is copied to the local storage of the application.
 A reference to this file is saved inside the database with the mailing.
 
 Organisation of attached files per mailing:
 Folder attachments inside the documents directory of the application
 For each mailing a subdirectory is created.
 */
class FileAttachmentHandler {
    
    /**
     Create the attachments subdirectory in the app documents directory if not yet exists.
     */
    class func createAttachementsDirectoryWithSubfolder(_ folderName: String) {
        let subfolderDir = getSubfolderUrl(folderName).path
        
        let filemgr = FileManager.default
        if !filemgr.fileExists(atPath: subfolderDir) {
            do {
                try filemgr.createDirectory(atPath: subfolderDir, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Copies the given file to the attachments directory so that it is locally available.
     */
    class func copyFileToAttachementsDir(urlToCopy: URL, folderName: String) {
        createAttachementsDirectoryWithSubfolder(folderName)
        
        let filemgr = FileManager.default
        if filemgr.fileExists(atPath: urlToCopy.path) {
            let subfolderURL = getSubfolderUrl(folderName)
            let destinationFile = subfolderURL.appendingPathComponent(urlToCopy.lastPathComponent, isDirectory: false)
            
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
     Checks if the given file already exists in the attachments dir.
     Check is done by filename.
     */
    class func fileExistsInAttachmentsDir(url: URL, folderName: String) -> Bool {
        let subfolderUrl = getSubfolderUrl(folderName)
        let fileToCheck = subfolderUrl.appendingPathComponent(url.lastPathComponent, isDirectory: false)
        
        let filemgr = FileManager.default
        if filemgr.fileExists(atPath: fileToCheck.path) {
            return true
        }
        
        return false
    }
    
    /**
     Deletes the given file
     */
    class func removeFile(fileName: String, folderName: String) {
        let subfolderUrl = getSubfolderUrl(folderName)
        let fileToDelete = subfolderUrl.appendingPathComponent(fileName)
        
        let filemgr = FileManager.default
        do {
            if filemgr.fileExists(atPath: fileToDelete.path) {
                try filemgr.removeItem(at: fileToDelete)
                print("Successfully deleted file \(fileName)")
            }
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    class func removeFolder(folderName: String) {
        let subfolderUrl = getSubfolderUrl(folderName)
        let filemgr = FileManager.default
        do {
            if filemgr.fileExists(atPath: subfolderUrl.path) {
                try filemgr.removeItem(at: subfolderUrl)
                print("Successfully deleted folder \(folderName)")
            }
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
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
     Returns the url for a subfolder of the attachement directory.
     */
    class func getSubfolderUrl(_ folderName : String) -> URL {
        let attachmentsUrl = getAttachementsUrl()
        let subfolderDir = attachmentsUrl.appendingPathComponent(folderName)
        
        return subfolderDir
    }
    
    /**
     Returns the url for the given file.
     */
    class func getUrlForFile(fileName: String, folderName: String) -> URL {
        let subfolderDir = getSubfolderUrl(folderName)
        
        let destinationFile = subfolderDir.appendingPathComponent(fileName, isDirectory: false)
        return destinationFile
    }
    
    /**
     Returns the MimeType template String for the given file,
     e.g. returns application/pdf for a pdf file.
     */
    class func mimeTypeForUrl(_ fileUrl: URL) -> String {
        let pathExtension = fileUrl.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        
        // Default = binary file
        return "application/octet-stream"
    }
    
    class func getFileAttributes(fileName: String, folderName: String) -> FileAttributes {
        let subfolderDir = getSubfolderUrl(folderName)
        let file = subfolderDir.appendingPathComponent(fileName, isDirectory: false)
        
        return FileUtil.getFileAttributes(fileUrl: file)
    }
}
