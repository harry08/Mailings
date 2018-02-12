//
//  MailingPickerTableViewController
//  Mailings
//
//  Created on 09.01.18.
//

import UIKit
import CoreData

// TODO: Use Delegate to provide chosen Mailing to caller. See ContactPickerTableViewController

/**
 Shows a a ist of mailings to choose from.
 Implements UIPopoverPresentationControllerDelegate to display tbe view in a navigation controller on compact width-devices.
 */
class MailingPickerTableViewController: FetchedResultsTableViewController, UIPopoverPresentationControllerDelegate {

    var btnChoose: UIBarButtonItem?
    
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
    
    public func getSelectedMailing() -> MailingDTO? {
        if let indexPath = tableView.indexPathForSelectedRow,
            let mailing = fetchedResultsController?.object(at: indexPath) {
            return MailingMapper.mapToDTO(mailing: mailing)
        }
        
        return nil
    }
    
    private func updateChooseButtonState() {
        if let btnChoose = self.btnChoose {
            if let _ = tableView.indexPathForSelectedRow {
                btnChoose.isEnabled = true
            } else {
                btnChoose.isEnabled = false
            }
        }
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .fullScreen
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        let navigationController = UINavigationController(rootViewController: controller.presentedViewController)
        
        let btnCancel = UIBarButtonItem(title: "Abbrechen", style: .done, target: self, action: #selector(cancel))
        navigationController.topViewController?.navigationItem.leftBarButtonItem = btnCancel
        btnChoose = UIBarButtonItem(title: "Wählen", style: .done, target: self, action: #selector(mailingSelected))
        btnChoose?.isEnabled = false
        navigationController.topViewController?.navigationItem.rightBarButtonItem = btnChoose
        
        return navigationController
    }
    
    @objc func cancel(sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func mailingSelected(sender: UIButton) {
        self.performSegue(withIdentifier: "unwindFromChoooseMailing", sender: self)
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
