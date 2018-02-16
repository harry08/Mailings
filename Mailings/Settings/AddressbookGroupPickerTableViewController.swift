//
//  AddressbookGroupPickerTableViewController.swift
//  Mailings
//
//  Created on 16.02.18.
//

import UIKit
import Contacts

protocol AddressbookGroupPickerTableViewControllerDelegate: class {
    func groupPicker(_ picker: AddressbookGroupPickerTableViewController,
                           didPick chosenGroup: CNGroup)
}

/**
 Shows a list of addressbook groups to choose from.
 Table is in Singleselection mode.
 After group selection is done the AddressbookGroupPickerTableViewControllerDelegate is called.
 */
class AddressbookGroupPickerTableViewController: UITableViewController {

    /**
     Delegate to call after choosing a group.
     Weak reference to avoid ownership cycles.
     */
    weak var delegate: AddressbookGroupPickerTableViewControllerDelegate?
    
    var groups = [CNGroup]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - TableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell", for: indexPath)
        let group = groups[indexPath.row]
        cell.textLabel?.text = group.name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = groups[indexPath.row]
        delegate?.groupPicker(self, didPick: group)
    }
}
