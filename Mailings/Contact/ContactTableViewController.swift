//
//  ContactTableViewController.swift
//  Mailings
//
//  Created on 08.01.18.
//

import UIKit

import UIKit
import CoreData
import MessageUI

class ContactTableViewController: FetchedResultsTableViewController, ContactDetailViewControllerInfoDelegate {
    
    let messageComposer = MessageComposer()
    
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer {
        didSet {
            updateUI()
        }
    }
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<MailingContact>?
    
    private func updateUI() {
        performFetch()
        
        updateControls()
    }
    
    private func updateControls() {
        updateTableFooter()
    }
    
    private func configureRightBarButtonItems() {
        // Display add button
        let item1 = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAction))
        let items = [item1]
        navigationItem.setRightBarButtonItems(items, animated: true)
    }
    
    // Setup the Search Controller
    private func configureSearchbar() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Kontakte durchsuchen"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func updateTableFooter() {
        footerView.isHidden = !shouldDisplayFooter()
        
        if !footerView.isHidden {
            let count = getNrOfContacts()
            footerLabel.text = "\(count) Kontakte"
        } else {
            footerLabel.text = ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        updateUI()
        configureRightBarButtonItems()
        configureSearchbar()
    }
    
    // Performs the fetch on the database and reloads the tableView.
    private func performFetch() {
        // Display TableView
        if let context = container?.viewContext {
            let request : NSFetchRequest<MailingContact> = MailingContact.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(
                key: "lastname",
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
                )]
            
            if !searchBarIsEmpty() {
                let searchString = searchController.searchBar.text!
                let predicate = NSPredicate(format: "lastname contains[c] %@ or firstname contains[c] %@", searchString, searchString)
                request.predicate = predicate
            }
            
            fetchedResultsController = NSFetchedResultsController<MailingContact>(
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
    
    private func getNrOfContacts() -> Int {
        if let sections = fetchedResultsController?.sections, sections.count > 0 {
            return sections[0].numberOfObjects
        }
        
        return 0
    }
    
    // MARK: - TableView
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        if let contact = fetchedResultsController?.object(at: indexPath) {
            cell.textLabel?.text = contact.lastname
            cell.detailTextLabel?.text = contact.firstname
        }
        
        return cell
    }
    
    /**
     Display a TableView footer with info about contacts when there are at least 15 contacts.
     */
    private func shouldDisplayFooter() -> Bool {
        if getNrOfContacts() >= 12 {
            return true
        }
        
        return false
    }
    
    // MARK: - Navigation and Actions
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showContact",
            let destinationVC = segue.destination as? ContactDetailViewController
        {
            // Navigate to existing contact
            if let indexPath = tableView.indexPathForSelectedRow,
                let selectedContact = fetchedResultsController?.object(at: indexPath)
            {
                let contactDTO = MailingContactMapper.mapToDTO(contact: selectedContact)
                destinationVC.container = container
                destinationVC.mailingContactDTO = contactDTO
                destinationVC.editType = true
                destinationVC.infoDelegate = self
            }
        } else if segue.identifier == "addNewContact",
            let destinationVC = segue.destination as? ContactDetailViewController
        {
            destinationVC.container = container
            destinationVC.infoDelegate = self
        } else if segue.identifier == "pickContactFilter",
            let destinationVC = segue.destination as? ContactFilterPickerTableViewController
        {
            // destinationVC.filter = ...
        }
    }
   
    /**
     Opens the ContactDetailController to add a new contact
     */
    @objc func addAction(sender: UIButton) {
        self.performSegue(withIdentifier: "addNewContact", sender: self)
    }
    
    @IBAction func filterAction(_ sender: Any) {
        self.performSegue(withIdentifier: "pickContactFilter", sender: self)
    }
    
    // MARK: - Searching
    
    // Returns true if the text is empty or nil
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        performFetch()
        updateControls()
    }
    
    // MARK: ContactDetailViewControllerInfo Delegate
    
    /**
     Called after data has been changed inside the detailview.
     Update relevent parts of the UI like table footer.
     */
    func contactDetailViewControllerDidChangeData(_ controller: ContactDetailViewController) {
        updateControls()
    }
}

// MARK: extension UITableViewDataSource

extension ContactTableViewController {
    
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

// MARK: extension UISearchResultsUpdating Delegate

extension ContactTableViewController: UISearchResultsUpdating {
    
    // Called after the user enters text in the search field
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
