//
//  MailingPickerTableViewController
//  Mailings
//
//  Created on 09.01.18.
//

import UIKit
import CoreData

protocol MailingPickerTableViewControllerDelegate: class {
    func mailingPicker(_ picker: MailingPickerTableViewController,
                           didPick chosenMailing: MailingDTO)
}

/**
 Shows a a ist of mailings to choose from.
 Implements UIPopoverPresentationControllerDelegate to display tbe view in a navigation controller on compact width-devices.
 */
class MailingPickerTableViewController: FetchedResultsTableViewController {

    var btnChoose: UIBarButtonItem?
    
    /**
     Delegate to call after choosing a mailing.
     Weak reference to avoid ownership cycles.
     */
    weak var delegate: MailingPickerTableViewControllerDelegate?
    
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
            tableView.reloadData()
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
        if let mailing = fetchedResultsController?.object(at: indexPath) {
            let mailingDTO = MailingMapper.mapToDTO(mailing: mailing)
            delegate?.mailingPicker(self, didPick: mailingDTO)
        }
    }
    
    // MARK: - Navigation and Actions
    
}

// MARK: extension UITableViewDataSource

extension MailingPickerTableViewController {
    
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
