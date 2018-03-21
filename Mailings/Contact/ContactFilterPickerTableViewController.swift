//
//  ContactFilterPickerTableViewController.swift
//  Mailings
//
//  Created on 20.03.18.
//

import UIKit

class ContactFilterPickerTableViewController: UITableViewController {
    
    var filterList = [FilterElement]()
    
    var filter: FilterElement? {
        didSet {
            print("Filter was set")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        initFilterList()
        tableView.reloadData()
    }
    
    private func initFilterList() {
        filterList.append(FilterElement(title: "Zuletzt hinzugefügte Kontakte"))
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return filterList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilterCell", for: indexPath)
        
        let filter = filterList[indexPath.row]
        cell.textLabel?.text = filter.title

        return cell
    }
}
