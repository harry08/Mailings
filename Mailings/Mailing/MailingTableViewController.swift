//
//  MailingTableViewController.swift
//  CustomerManager
//
//  Created on 22.11.17.
//

import UIKit
import CoreData

class MailingTableViewController: FetchedResultsTableViewController, MailingDetailViewControllerDelegate {
    
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
    
    // MARK: - Navigation and Actions
    
    // Navigate back from adding a new mailing. Save data from MailingDTO
    // MailingDTO is already filled
    @IBAction func unwindFromSave(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? EditMailingViewController,
            let mailingDTO = sourceViewController.mailingDTO {
            
            guard let container = container else {
                print("Save not possible. No PersistentContainer.")
                return
            }
            
            // Update database
            do {
                try Mailing.createOrUpdateFromDTO(mailingDTO: mailingDTO, in: container.viewContext)
            } catch {
                // TODO show Alert
            }
        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
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
                destinationVC.editMode = true
            }
            
            destinationVC.delegate = self
        } else if segue.identifier == "addNewMailing",
            let destinationVC = segue.destination as? MailingDetailViewController {
            
            destinationVC.delegate = self
        }
    }
    
    // MARK: MailingDetailViewController Delegate
    
    /**
     Protocol function. Called after canceled the detail view
     Removes the edit view.
     */
    func mailingDetailViewControllerDidCancel(_ controller: MailingDetailViewController) {
        navigationController?.popViewController(animated:true)
    }
    
    /**
     Protocol function. Called after finish adding a new Mailing
     Saves data to database and removes the edit view.
     */
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishAdding mailing: MailingDTO) {
        guard let container = container else {
            print("Save not possible. No PersistentContainer.")
            return
        }
        
        // Update database
        do {
            try Mailing.createOrUpdateFromDTO(mailingDTO: mailing, in: container.viewContext)
        } catch {
            // TODO show Alert
        }
        navigationController?.popViewController(animated:true)
    }
    
    /**
     Protocol function. Called after finish editing an existing Mailing
     Saves data to database and removes the edit view.
     */
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishEditing mailing: MailingDTO) {
        guard let container = container else {
            print("Save not possible. No PersistentContainer.")
            return
        }
        
        // Update database
        do {
            try Mailing.createOrUpdateFromDTO(mailingDTO: mailing, in: container.viewContext)
        } catch {
            // TODO show Alert
        }
        navigationController?.popViewController(animated:true)
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
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]?
    {
        return fetchedResultsController?.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int
    {
        return fetchedResultsController?.section(forSectionIndexTitle: title, at: index) ?? 0
    }
}
