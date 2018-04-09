//
//  MailingListPickerTableViewController.swift
//  Mailings
//
//  Created on 12.02.18.
//

import UIKit
import CoreData

protocol MailingListPickerTableViewControllerDelegate: class {
    func mailingListPicker(_ picker: MailingListPickerTableViewController,
                       didPick chosenMailingList: MailingListDTO)
    func mailingListPicker(_ picker: MailingListPickerTableViewController,
                           didPickList chosenMailingLists: [MailingListDTO])
}

/**
 Shows a list of mailing lists to choose from.
 Table is in Singleselection mode.
 After mailinglist selection is done the MailingListPickerTableViewControllerDelegate is called.
 */
class MailingListPickerTableViewController: FetchedResultsTableViewController {
    
    @IBOutlet weak var btnDone: UIBarButtonItem!
    
    var selectionType = "single"  // single or multiple
    
    /**
     Delegate to call after choosing a mailing list.
     Weak reference to avoid ownership cycles.
     */
    weak var delegate: MailingListPickerTableViewControllerDelegate?
    
    /**
     MailingLists to choose from
     */
    var mailingLists = [MailingListDTO]()
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer {
        didSet {
            loadData()
        }
    }
    
    /**
     MailingLists which should not be shown in the picker
     */
    var excludedMailingLists = [MailingListDTO]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /**
     Loads all available contacts and displays them in the table.
     */
    private func loadData() {
        if let context = container?.viewContext {
            let request : NSFetchRequest<MailingList> = MailingList.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(
                key: "name",
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
                )]
            
            do {
                let fetchedMailingLists = try context.fetch(request)
                
                mailingLists = [MailingListDTO]()
                mailingLists.reserveCapacity(fetchedMailingLists.count)
                for case let fetchedMailingList in fetchedMailingLists {
                    let mailingListDTO = MailingListMapper.mapToDTO(mailingList: fetchedMailingList)
                    if !shouldExcludeMailingList(mailingListDTO) {
                        mailingLists.append(mailingListDTO)
                    }
                }
            } catch let error as NSError {
                print("Error retrieving mailing lists: \(error)")
            }
            
            tableView.reloadData()
        }
    }
    
    private func shouldExcludeMailingList(_ mailingList: MailingListDTO) -> Bool {
        if excludedMailingLists.count > 0 {
            for case let mailingListToExclude in excludedMailingLists {
                if mailingList.objectId == mailingListToExclude.objectId {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func updateDoneButtonState() {
        if selectionType == "single" {
            btnDone.isEnabled = false  // TODO Hide
        } else {
            if let _ = tableView.indexPathForSelectedRow {
                btnDone.isEnabled = true
            } else {
                btnDone.isEnabled = false
            }
        }
    }
    
    // MARK: - Actions and Navigation
    
    /**
     Called after mailiong lists are chosen and done button is pressed.
     The delegate is called with the list of chosen mailing lists
     */
    @IBAction func pickMailingLists(_ sender: Any) {
        var pickedMailingLists = [MailingListDTO]()
        
        if let selectedRows = tableView.indexPathsForSelectedRows {
            for i in 0 ..< selectedRows.count {
                let indexPath = selectedRows[i]
                let mailingList = mailingLists[indexPath.row]
                pickedMailingLists.append(mailingList)
            }
        }
        
        delegate?.mailingListPicker(self, didPickList: pickedMailingLists)
    }
    
    
    // MARK: - TableView
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PickerMailingListCell", for: indexPath)
        let mailingList = mailingLists[indexPath.row]
        cell.textLabel?.text = mailingList.name!
        
        cell.accessoryType = cell.isSelected ? .checkmark : .none
        cell.selectionStyle = .none // to prevent cells from being "highlighted"
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mailingLists.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectionType == "single" {
            let mailingListDTO = mailingLists[indexPath.row]
            delegate?.mailingListPicker(self, didPick: mailingListDTO)
        } else {
            tableView.cellForRow(at: indexPath)?.selectionStyle = .none
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            
            updateDoneButtonState()
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if selectionType == "multiple" {
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
            
            updateDoneButtonState()
        }
    }
}

