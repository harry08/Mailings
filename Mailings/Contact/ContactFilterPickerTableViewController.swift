//
//  ContactFilterPickerTableViewController.swift
//  Mailings
//
//  Created on 20.03.18.
//

import UIKit
import CoreData

protocol ContactFilterPickerTableViewControllerDelegate: class {
    func contactFilterPicker(_ picker: ContactFilterPickerTableViewController,
                       didPick chosenFilter: [FilterElement])
}

/**
 Shows a list of filters to filter the contact tableView.
 The list contains static filters like "least recent added" and dynamic filters like added to mailinglist xy.
 Once a filter is chosen the delegate ContactFilterPickerTableViewControllerDelegate is called.
 */
class ContactFilterPickerTableViewController: UITableViewController {
    
    weak var delegate: ContactFilterPickerTableViewControllerDelegate?
    
    var contactFilter: ContactFilter? {
        didSet {
            tableView.reloadData()
        }
    }
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let contactFilter = contactFilter {
            return contactFilter.getCountSections()
        }
        
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Get the FilterSection enum value out of the integer value of the section
        if let contactFilter = contactFilter,
            let filterSection = FilterSection(rawValue: section) {
            return contactFilter.getCount(forSection: filterSection)
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        if let filterSection = FilterSection(rawValue: section) {
            
            var title : String
            switch filterSection {
            case .general:
                title = "Allgemein"
            case .mailingList:
                title = "Verteilerliste"
            case .reset:
                title = ""
            }
            return title
        }
        
        return ""
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilterCell", for: indexPath)
        
        if let contactFilter = contactFilter,
            let filterSection = FilterSection(rawValue: indexPath.section),
            let filter = contactFilter.getFilterElement(forSection: filterSection, index: indexPath.row) {
            
            cell.textLabel?.text = filter.title
            
            cell.accessoryType = contactFilter.isSelectedIndex(indexPath.row, forSection: filterSection) ? .checkmark : .none
            
            if case .reset = filterSection {
                // The row with the reset entry should be normally selectable
                cell.selectionStyle = .default
            } else {
                // The others should not be selectable, i.e. not being "highlighted"
                cell.selectionStyle = .none
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let contactFilter = contactFilter,
            let filterSection = FilterSection(rawValue: indexPath.section) {
            
            let nrOfItemsInSection = contactFilter.getCount(forSection: filterSection)
            
            if case .general = filterSection {
                contactFilter.setSelectedIndex(indexPath.row, forSection: filterSection)
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                removeCheckmarksFromSection(indexPath.section, except: indexPath.row, count: nrOfItemsInSection)
            } else if case .mailingList = filterSection {
                contactFilter.setSelectedIndex(indexPath.row, forSection: filterSection)
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                removeCheckmarksFromSection(indexPath.section, except: indexPath.row, count: nrOfItemsInSection)
            } else if case .reset = filterSection {
                contactFilter.clearFilter()
            }
            
            delegate?.contactFilterPicker(self, didPick: contactFilter.getSelectedFilters())
        }
    }
    
    func removeCheckmarksFromSection(_ section: Int, except index: Int, count: Int) {
        for i in 0 ..< count {
            if i != index {
                tableView.cellForRow(at: IndexPath(item: i, section: section))?.accessoryType = .none
            }
        }
    }
}
