//
//  MailingContact.swift
//  Mailings
//
//  Created by Harry Huebner on 28.12.17.
//  Copyright © 2017 Huebner. All rights reserved.
//

import Foundation
import CoreData

class MailingContact: NSManagedObject {

    // MARK: -  class functions

    // MARK: - Statistic functions
    
    class func getNrOfContacts(in context: NSManagedObjectContext) -> Int {
        var count = 0
        
        let request : NSFetchRequest<MailingContact> = MailingContact.fetchRequest()
        request.predicate = NSPredicate(format: "retired = false")
        do {
            let matches = try context.fetch(request)
            count = matches.count
        } catch let error as NSError {
            print("Could not count contacts. \(error), \(error.userInfo)")
        }
        
        return count
    }
}
