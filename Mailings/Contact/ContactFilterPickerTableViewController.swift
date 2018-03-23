//
//  ContactFilterPickerTableViewController.swift
//  Mailings
//
//  Created on 20.03.18.
//

import UIKit
import CoreData

class ContactFilterPickerTableViewController: UITableViewController {
    
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
        }
        
        return cell
    }
}
