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
}

/**
 Shows a list of mailing lists to choose from.
 Table is in Singleselection mode.
 After mailinglist selection is done the MailingListPickerTableViewControllerDelegate is called.
 */
class MailingListPickerTableViewController: FetchedResultsTableViewController {

    /**
     Delegate to call after choosing a mailing list.
     Weak reference to avoid ownership cycles.
     */
    weak var delegate: MailingListPickerTableViewControllerDelegate?
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer {
        didSet {
            updateUI()
        }
    }
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<MailingList>?
    
    private func updateUI() {
        performFetch()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUI()
    }
    
    // Performs the fetch on the database and reloads the tableView.
    private func performFetch() {
        // Display TableView
        if let context = container?.viewContext {
            let request : NSFetchRequest<MailingList> = MailingList.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(
                key: "name",
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
                )]
            
            fetchedResultsController = NSFetchedResultsController<MailingList>(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            fetchedResultsController?.delegate = self
            try? fetchedResultsController?.performFetch()
            tableView.reloadData()
        }
    }
    
    // MARK: - TableView
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MailingListCell", for: indexPath)
        if let mailingList = fetchedResultsController?.object(at: indexPath) {
            cell.textLabel?.text = mailingList.name
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("MailingList selected")
        if let mailingList = fetchedResultsController?.object(at: indexPath) {
            let mailingListDTO = MailingListMapper.mapToDTO(mailingList: mailingList)
            delegate?.mailingListPicker(self, didPick: mailingListDTO)
        }
    }
}

// MARK: extension UITableViewDataSource

extension MailingListPickerTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections, sections.count > 0 {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController?.sections, sections.count > 0 {
            return sections[section].name
        } else {
            return nil
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]?
    {
        return fetchedResultsController?.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int
    {
        return fetchedResultsController?.section(forSectionIndexTitle: title, at: index) ?? 0
    }
}
