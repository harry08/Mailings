//
//  MailingTableViewController.swift
//  CustomerManager
//
//  Created on 22.11.17.
//

import UIKit
import CoreData

class MailingTableViewController: FetchedResultsTableViewController {
    
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
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        updateUI()
    }
    
    // Performs the fetch on the database and reloads the tableView.
    private func performFetch() {
        // Display TableView
        if let context = container?.viewContext {
            let request : NSFetchRequest<Mailing> = Mailing.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "createtime", ascending: false)
            request.sortDescriptors = [sortDescriptor]
            
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

    // MARK: - TableView
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MailingCell", for: indexPath)
        if let mailing = fetchedResultsController?.object(at: indexPath) {
            cell.textLabel?.text = mailing.title
            cell.detailTextLabel?.text = mailing.text
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let duplicateAction = UITableViewRowAction(style: .default, title: "Duplizieren", handler:{action, indexpath in
            self.duplicateMailing(indexPath: indexPath)
        });
        duplicateAction.backgroundColor = UIColor.lightGray
        
        return [duplicateAction];
    }
    
    // MARK: - Navigation and Actions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMailing",
            let destinationVC = segue.destination as? MailingDetailViewController
        {
            // Navigate to existing mailing
            if let indexPath = tableView.indexPathForSelectedRow,
                let selectedMailing = fetchedResultsController?.object(at: indexPath)
            {
                let mailingDTO = MailingMapper.mapToDTO(mailing: selectedMailing)
                destinationVC.container = container
                destinationVC.mailingDTO = mailingDTO
                destinationVC.editType = true
            }
        } else if segue.identifier == "addNewMailing",
            let destinationVC = segue.destination as? MailingDetailViewController
        {
            destinationVC.container = container
        }
    }
    
    func duplicateMailing(indexPath: IndexPath) {
        guard let container = container else {
            print("Duplicate not possible. No PersistentContainer.")
            return
        }
        
        if let mailingToDuplicate = fetchedResultsController?.object(at: indexPath) {
            var newMailing = MailingDTO()
            if let title = mailingToDuplicate.title {
                newMailing.title = title + " Kopie"
            } else {
                newMailing.title = "Duplikat"
            }
            
            if let text = mailingToDuplicate.text {
                newMailing.text = text
            }
            
            do {
                try Mailing.createOrUpdateFromDTO(mailingDTO: newMailing, in: container.viewContext)
            } catch {
                // TODO show Alert
            }
        }
        
        /* TODO - Create name for duplicate
         Get all mailings with a title starting with the mailing to duplicate (with added suffix Kopie)
         if no mailing exist name the new mailing "oldtitle Kopie"
         if at least one mailing exist name the new mailing "oldtitle Kopie 1".
         If multiple exists take the next free number.
        */
    }
}

// MARK: extension UITableViewDataSource

extension MailingTableViewController {
    
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
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController?.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return fetchedResultsController?.section(forSectionIndexTitle: title, at: index) ?? 0
    }
}
