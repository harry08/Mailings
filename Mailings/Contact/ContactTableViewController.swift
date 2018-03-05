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

class ContactTableViewController: FetchedResultsTableViewController, MailingPickerTableViewControllerDelegate {
    
    var multiSelection = false
    
    let messageComposer = MessageComposer()
    
    @IBOutlet weak var multiSelectButton: UIButton!
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
    
    @IBAction func changeMultiSelection(_ sender: Any) {
        multiSelection = !multiSelection
        updateMultiSelection()
        
        configureRightBarButtonItems()
    }
    
    private func updateUI() {
        performFetch()
        
        updateControls()
    }
    
    private func updateControls() {
        updateMultiSelection()
        updateTableFooter()
    }
    
    private func configureRightBarButtonItems() {
        if self.multiSelection {
            // Display action button
            let item1 = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(multiSelectShareAction))
            let items = [item1]
            navigationItem.setRightBarButtonItems(items, animated: true)
        } else {
            // Display add button
            let item1 = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAction))
            let items = [item1]
            navigationItem.setRightBarButtonItems(items, animated: true)
        }
    }
    
    // Setup the Search Controller
    private func configureSearchbar() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Kontakte durchsuchen"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func updateMultiSelection() {
        if !multiSelection {
            multiSelectButton.setTitle("Auswählen", for: .normal)
        } else {
            multiSelectButton.setTitle("Abbrechen", for: .normal)
        }
        tableView.allowsMultipleSelection = multiSelection
        tableView.reloadData()
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
        
        if multiSelection {
            cell.accessoryType = cell.isSelected ? .checkmark : .none
            cell.selectionStyle = .none // to prevent cells from being "highlighted"
        } else {
            cell.accessoryType = .none
            cell.selectionStyle = .default
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if multiSelection {
            tableView.cellForRow(at: indexPath)?.selectionStyle = .none
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        } else {
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if multiSelection {
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
        }
    }
    
    /**
     Display a TableView footer with info about contacts when there are at least 15 contacts.
     */
    private func shouldDisplayFooter() -> Bool {
        if getNrOfContacts() >= 15 {
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
            }
        } else if segue.identifier == "pickMailing",
            let destinationVC = segue.destination as? MailingPickerTableViewController
        {
            destinationVC.container = container
            destinationVC.delegate = self
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showContact",
            self.multiSelection {
            // Prohibit selecting the row when in multiselect mode.
            return false
        }
        
        return true
    }
   
    /**
     Opens the ContactDetailController to add a new contact
     */
    @objc func addAction(sender: UIButton) {
        self.performSegue(withIdentifier: "addNewContact", sender: self)
    }
    
    /**
     Displays a menu to choose several actions for the selected contacts.
     */
    @objc func multiSelectShareAction(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Sende Email", style: .default) { _ in
            print("Action Sende Email called")
            self.composeMail(emailAddresses: self.getSelectedEmailAddresses())
        })
        alert.addAction(UIAlertAction(title: "Sende Mailing...", style: .default) { _ in
            print("Action Sende Mailing")
            self.performSegue(withIdentifier: "pickMailing", sender: self)
        })
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel) { _ in
            print("Cancel called")
        })
        // The following 2 lines are needed for iPad.
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.barButtonItem = sender
        present(alert, animated: true)
    }
    
    // MARK: - Send Email
    
    @IBAction func sendEmail(_ sender: Any) {
        self.composeMail(emailAddresses: getSelectedEmailAddresses())
    }
    
    /**
     Presents the iOS screen to write an email to the given email addresses
     */
    func composeMail(emailAddresses: [String]) {
        if messageComposer.canSendText() {
            let messageComposeVc = messageComposer.configuredMailComposeViewController(emailAddresses: emailAddresses)
            self.present(messageComposeVc, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "Mail kann nicht gesendet werden", message: "Bitte E-Mail Einstellungen überprüfen und erneut versuchen.", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    /**
     Presents the iOS screen to write an email with the contents of the provided mailing to the given email addresses
     */
    func composeMailForMailing(_ mailingDTO: MailingDTO, emailAddresses: [String]) {
        if messageComposer.canSendText() {
            let messageComposeVc = messageComposer.configuredMailComposeViewController(mailing: mailingDTO, emailAddresses: emailAddresses)
            self.present(messageComposeVc, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "Mail kann nicht gesendet werden", message: "Bitte E-Mail Einstellungen überprüfen und erneut versuchen.", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func getSelectedEmailAddresses() -> [String] {
        var emailAddresses = [String]()
        if let selectedRows = tableView.indexPathsForSelectedRows {
            print("Nr of selections: \(selectedRows.count)")
            for i in 0 ..< selectedRows.count {
                let indexPath = selectedRows[i]
                if let contact = fetchedResultsController?.object(at: indexPath),
                    let email = contact.email {
                    emailAddresses.append(email)
                }
            }
        }
        
        return emailAddresses
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
    
    // MARK: - MailPicker Delegate
    
    /**
     Called after mailing was chosen. Send mailing to selected email addresses.
     */
    func mailingPicker(_ picker: MailingPickerTableViewController, didPick chosenMailing: MailingDTO) {
        navigationController?.popViewController(animated:true)
        
        let emailAddresses = getSelectedEmailAddresses()
        
        self.multiSelection = false
        updateMultiSelection()
        updateUI()
        
        // Wait for 2 seconds in order to wait for the other
        // view to be finished before displaying the mail view.
        let when = DispatchTime.now() + 2 // wait 2 seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.composeMailForMailing(chosenMailing, emailAddresses: emailAddresses)
        }
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
