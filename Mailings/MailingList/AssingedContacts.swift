//
//  AssingedContacts.swift
//  Mailings
//
//  Created on 06.02.18.
//

import Foundation

/**
 Container for Contact assignments
 */
class AssigndContacts {
    var contacts = [AssignedContact]()
    var contactsInit = false
    
    func initWithContactList(_ contacts: [AssignedContact]) {
        self.contacts = contacts
        contactsInit = true
    }
    
    func initWithEmptyList() {
        contactsInit = true
    }
    
    func isInit() -> Bool {
        return contactsInit
    }
}
