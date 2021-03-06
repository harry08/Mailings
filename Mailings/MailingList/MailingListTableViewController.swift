//
//  MailingListTableViewController.swift
//  Mailings
//
//  Created on 18.01.18.
//

import UIKit
import CoreData


class MailingListTableViewController: FetchedResultsTableViewController {

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
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
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
    
    // MARK: - Navigation and Actions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMailingList",
            let destinationVC = segue.destination as? MailingListDetailViewController
        {
            // Navigate to existing mailinglist
            if let indexPath = tableView.indexPathForSelectedRow,
                let selectedMailingList = fetchedResultsController?.object(at: indexPath)
            {
                let mailingListDTO = MailingListMapper.mapToDTO(mailingList: selectedMailingList)
                destinationVC.container = container
                destinationVC.mailingListDTO = mailingListDTO
                destinationVC.editType = true
            }
        } else if segue.identifier == "addNewMailingList",
            let destinationVC = segue.destination as? MailingListDetailViewController {
            
            destinationVC.container = container
        }
    }
}

// MARK: extension UITableViewDataSource

extension MailingListTableViewController {
    
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
