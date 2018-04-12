//
//  AssignedMailingLists.swift
//  Mailings
//
//  Created on 06.03.18.
//

import Foundation

/**
 Container for MailingList assignments
 Designed as a class to be passed as a reference.‚
 */
class AssigndMailingLists {
    var mailingLists = [AssignedMailingList]()
    var mailingListInit = false
    
    func initWithMailingList(_ mailingLists: [AssignedMailingList]) {
        self.mailingLists = mailingLists
        mailingListInit = true
    }
    
    func initWithMailingList(_ mailingLists: [MailingListDTO]) {
        for mailingList in mailingLists {
            let assignedMailingList = AssignedMailingList(objectId: mailingList.objectId!, name: mailingList.name!)
            self.mailingLists.append(assignedMailingList)
        }
    }
    
    func initWithEmptyList() {
        mailingListInit = true
    }
    
    func isInit() -> Bool {
        return mailingListInit
    }
}
