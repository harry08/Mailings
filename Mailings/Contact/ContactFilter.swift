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
    
    func clearFilter() {
        filters.removeAll()
    }
    
    func isEmpty() -> Bool {
        return filters.isEmpty
    }
    
    func getSelectedFilters() -> [FilterElement] {
        var filterElements = [FilterElement]()
        
        for sectionIndex in 0 ... 1 {
            if let section = FilterSection(rawValue: sectionIndex),
                let sectionInfo = filters[section] {
                if sectionInfo.hasSelection() {
                    let filterElement = sectionInfo.getSelection()
                    filterElements.append(filterElement!)
                }
            }
        }
        
        return filterElements
    }
    
    /**
     Returns true, if at least one filter is set.
     */
    func isFiltered() -> Bool {
        let filterElements = getSelectedFilters()
        if filterElements.count == 0 {
            return false
        } else if filterElements.count == 1 {
            if case.all = filterElements[0].filterType {
                return false
            }
        }
        
        return true
    }
}
