//
//  ContactFilter.swift
//  Mailings
//
//  Created on 22.03.18.
//

import Foundation

/**
 Available sections in filter overview
 */
enum FilterSection: Int {
    case general, mailingList, reset
}

/**
 Manages a list of filters to apply on the Contact list.
 This class contains information about the current applied filter.
 */
class ContactFilter {
    
    var filters = [FilterSection: SectionInfo]()
    
    /**
     Adds a filterElement to a section.
     Set isSelected to true if this filter should be the one which is selected in this section.
     */
    func addFilter(_ filter: FilterElement, to section: FilterSection, isSelected : Bool = false) {
        var sectionInfo = filters[section]
        if sectionInfo == nil {
            sectionInfo = SectionInfo()
        }
        sectionInfo!.addFilter(filter, isSelected: isSelected)
        
        filters[section] = sectionInfo
    }
    
    func getFilterList(forSection section: FilterSection) -> [FilterElement]? {
        if let sectionInfo = filters[section] {
            return sectionInfo.filters
        }
        
        return nil
    }
    
    func getFilterElement(forSection section: FilterSection, index: Int) -> FilterElement? {
        if let filterList = getFilterList(forSection: section) {
            return filterList[index]
        }
        
        return nil
    }
    
    func getCount(forSection section: FilterSection) -> Int {
        if let filterList = getFilterList(forSection: section) {
            return filterList.count
        }
        
        return 0
    }
    
    func getCountSections() -> Int {
        return filters.count
    }
    
    func isSelectedIndex(_ index: Int, forSection section: FilterSection) -> Bool {
        if let sectionInfo = filters[section] {
            if sectionInfo.hasSelection() {
                if sectionInfo.selectionIndex! == index {
                    return true
                }
            }
        }
        
        return false
    }
    
    func setSelectedIndex(_ index: Int, forSection section: FilterSection) {
        if let sectionInfo = filters[section] {
            sectionInfo.setSelectionIndex(index)
        }
    }
}
