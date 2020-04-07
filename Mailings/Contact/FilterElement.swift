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
    
    init(title: String, filterType: FilterType) {
        self.title = title
        self.filterType = filterType
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
        // TODO throw
    }
    
    func getIndexForFilterType(_ filterType: FilterType) -> Int {
        return -1
        // TODO
    }
    
    func addFilter(_ filter: FilterElement, isSelected: Bool) {
        filters.append(filter)
        if isSelected {
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
