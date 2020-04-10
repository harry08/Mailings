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
    case sorting, filter, reset
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
    func addFilter(_ filter: FilterElement, to section: FilterSection) {
        var sectionInfo = filters[section]
        if sectionInfo == nil {
            sectionInfo = SectionInfo()
        }
        sectionInfo!.addFilter(filter)
        
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
                if let filterElement = getSelectedFilterForSection(sectionInfo) {
                    filterElements.append(filterElement)
                }
            }
        }
        
        return filterElements
    }
    
    func getSelectedFilterForSection(_ sectionInfo: SectionInfo) -> FilterElement? {
        if sectionInfo.hasSelection() {
            let filterElement = sectionInfo.getSelection()
            return filterElement!
        }
        
        return nil
    }
    
    /**
     Returns true, if at least one filter is set which is not a default filter.
     */
    func isFiltered() -> Bool {
        let filterElements = getSelectedFilters()
        let hasFiltes = filterElements.contains { element in
            return !element.defaultFilter
        }
        
        return hasFiltes
    }
    
    /**
    Returns true, if a filter is set that shrinks the list.
    */
    func hasFilterAppliedInSectionFilter() -> Bool {
        if let sectionInfo = filters[FilterSection.filter],
            let filterElement = getSelectedFilterForSection(sectionInfo) {
            return !filterElement.defaultFilter
        }
        
        return false
    }
}
