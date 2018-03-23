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
    
    var currentFilterSection: FilterSection?
    var currentFilterIndex: Int?
    
    var filters = [FilterSection: [FilterElement]]()
    
    func addFilter(_ filter: FilterElement, to section: FilterSection) {
        var filterList = filters[section]
        if filterList == nil {
            filterList = [FilterElement]()
        }
        filterList!.append(filter)
        
        filters[section] = filterList
    }
    
    func getFilterList(forSection section: FilterSection) -> [FilterElement]? {
        let filterList = filters[section]
        
        return filterList
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
    
    func setFilter(_ filterIndex: Int, filterSection: FilterSection) {
        if isValidIndex(filterIndex, section: filterSection) {
            currentFilterSection = filterSection
            currentFilterIndex = filterIndex
        } else {
            print("filterIndex not valid")
            // TODO Errorhandling. Should throw erro
        }
    }
    
    func clearFilter() {
        currentFilterIndex = nil
        currentFilterSection = nil
    }
    
    func isFiltered() -> Bool {
        return currentFilterIndex != nil && currentFilterSection != nil
    }
    
    func getCurrentFilter() -> FilterElement? {
        if let index = currentFilterIndex,
            let section = currentFilterSection,
            let filterList = getFilterList(forSection: section) {
            
            return filterList[index]
        }
        
        return nil
    }
    
    func isValidIndex(_ index: Int, section: FilterSection) -> Bool {
        if let filterList = getFilterList(forSection: section) {
            if index >= filterList.count {
                return false
            }
            if index < 0 {
                return false
            }
            return true
        } else {
            return false
        }
    }
}
