//
//  FilterElement.swift
//  Mailings
//
//  Created 20.03.18.
//

import Foundation

enum FilterType {
    case all
    case mostRecentAdded
    case mostRecentEdited
    
    case notAssignedToMailingList
    case assignedToMailingList (mailingList: String)
    
    case resetFilter
}

struct FilterElement {
    
    let title: String
    let filterType: FilterType
    
    init(title: String, filterType: FilterType) {
        self.title = title
        self.filterType = filterType
    }
}
