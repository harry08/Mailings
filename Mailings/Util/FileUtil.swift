//
//  FileUtil.swift
//  Mailings
//
//  Created by Harry Huebner on 07.05.20.
//

import Foundation

struct FileAttributes {
    var size: UInt64?
    var modificationDate: NSDate?
}

class FileUtil {
    
    class func getFileAttributes(fileUrl: URL) -> FileAttributes {
        let filemgr = FileManager.default
        
        var attributes = FileAttributes()
        
        do {
            let attr = try filemgr.attributesOfItem(atPath: fileUrl.path)
            attributes.size = attr[FileAttributeKey.size] as? UInt64
            attributes.modificationDate = attr[FileAttributeKey.modificationDate] as? NSDate
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
        
        return attributes
    }
}
