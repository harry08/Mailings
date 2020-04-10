//
//  FilterElement.swift
//  Mailings
//
//  Created 20.03.18.
//

import Foundation

enum FilterType {
    // Sort
    case sortByName
    case sortByAddedDesc
    case sortByEditedDesc
    
    // Filtering by Mailinglists
    case all
    case notAssignedToMailingList
    case assignedToMailingList (mailingList: String)
    
    // Reset
    case resetFilter
}

struct FilterElement {
    let title: String
    let filterType: FilterType
    let defaultFilter: Bool
    
    init(title: String, filterType: FilterType, defaultFilter: Bool) {
        self.title = title
        self.filterType = filterType
        self.defaultFilter = defaultFilter
    }
}

class SectionInfo {
    var selectionIndex: Int?
    var filters = [FilterElement]()
    
    init() {
        selectionIndex = nil
    }
    
    func hasSelection() -> Bool {
        return selectionIndex != nil
    }
    
    func getSelection() -> FilterElement? {
        if hasSelection() {
            return filters[selectionIndex!]
        }
        
        return nil
    }
    
    func clearSelection() {
        selectionIndex = nil
    }
    
    func setSelectionIndex(_ index: Int) {
        if isValidIndex(index) {
            selectionIndex = index
        }
    }
    
    func addFilter(_ filter: FilterElement) {
        filters.append(filter)
        if filter.defaultFilter {
            selectionIndex = filters.count - 1
        }
    }
    
    func isValidIndex(_ index: Int) -> Bool {
        if index >= filters.count {
            return false
        }
        if index < 0 {
            return false
        }
        return true
    }
}
