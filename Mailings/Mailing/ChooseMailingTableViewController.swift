//
//  ChooseMailingTableViewController.swift
//  Mailings
//
//  Created on 09.01.18.
//

import UIKit
import CoreData

/**
 Shows a a ist of mailings to choose from.
 */
class ChooseMailingTableViewController: FetchedResultsTableViewController {

    @IBOutlet weak var chooseButton: UIBarButtonItem!
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer {
        didSet {
            updateUI()
        }
    }
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<Mailing>?
    
    private func updateUI() {
        performFetch()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        updateUI()
        
        // Enable the Save button only if the text field has a valid name.
        updateChooseButtonState()
    }
    
    // Performs the fetch on the database and reloads the tableView.
    private func performFetch() {
        // Display TableView
        if let context = container?.viewContext {
            let request : NSFetchRequest<Mailing> = Mailing.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(
                key: "createTime",
                ascending: false,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
                )]
            
            fetchedResultsController = NSFetchedResultsController<Mailing>(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            fetchedResultsController?.delegate = self
            try? fetchedResultsController?.performFetch()
            if let objects = fetchedResultsController?.fetchedObjects {
                print("Mailings found: \(objects.count)")
            }
            tableView.reloadData()
        }
    }
    
    public func getSelectedMailing() -> MailingDTO? {
        if let indexPath = tableView.indexPathForSelectedRow,
            let mailing = fetchedResultsController?.object(at: indexPath) {
            return MailingMapper.mapToDTO(mailing: mailing)
        }
        
        return nil
    }
    
    private func updateChooseButtonState() {
        if let _ = tableView.indexPathForSelectedRow {
            chooseButton.isEnabled = true
        } else {
            chooseButton.isEnabled = false
        }
    }
    
    // MARK: - TableView
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MailingCell", for: indexPath)
        if let mailing = fetchedResultsController?.object(at: indexPath) {
            cell.textLabel?.text = mailing.title
            // TODO Formatting of date. Beispieltext: Erstellt am 01.11.2017
            cell.detailTextLabel?.text = mailing.text
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        updateChooseButtonState()
    }
    
    // MARK: - Navigation and Actions
    
    @IBAction func cancel(_ sender: Any) {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else if let owningNavigationController = navigationController{
            // In edit mode the detail scene was pushed onto a navigation stack
            owningNavigationController.popViewController(animated: true)
        } else {
            fatalError("The ChooseMailingTableViewController is not inside a navigation controller.")
        }
    }
}

// MARK: extension UITableViewDataSource

extension ChooseMailingTableViewController {
    
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
