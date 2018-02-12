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
class MailingListPickerTableViewController: FetchedResultsTableViewController, MailingListPickerTableViewControllerDelegate {
    
    var mailsToSend = [MailDTO]()
    
    var mailingDTO : MailingDTO?

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
    
    // MARK: - Email address preparation
    
    func composeMailsToSend(emailAddresses: [String]) -> [MailDTO] {
        var mailsToSend = [MailDTO]()
        let chunkSize = 4
        
        if let mailingDTO = mailingDTO {
            var startIndex = 0
            var continueProcessing = true
            while (continueProcessing) {
                var endIndex = startIndex + chunkSize
                if endIndex >= emailAddresses.endIndex {
                    endIndex = emailAddresses.endIndex
                }
                
                let chunk = emailAddresses[startIndex ..< endIndex]
                let ccAddresses = convertToArray(slice: chunk)
                
                print("Sending mails to \(ccAddresses)")
                let mailToSend = MailDTO(mailingDTO: mailingDTO, emailAddresses: ccAddresses)
                mailsToSend.append(mailToSend)
                
                startIndex = endIndex
                if startIndex >= emailAddresses.endIndex {
                    continueProcessing = false
                }
            }
        }
        
        return mailsToSend
    }
    
    func convertToArray(slice: ArraySlice<String>) -> [String] {
        var result = [String]()
        result.reserveCapacity(slice.count)
        slice.forEach{ element in
            result.append(element)
        }
        
        return result
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
    
    // MARK: - Navigation
    
    // Prepare for navigate to editing the Mailing data
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sendMailingToMailingList",
            let destinationVC = segue.destination as? MailsToSendTableViewController
        {
            // Edit mailing
            destinationVC.mailsToSend = mailsToSend
        } 
    }
    
    // MARK: - MailingListPickerTableViewController Delegate
    /**
     Called after mailing list was chosen. Send the selected mailing to the chosen mailing list.
     */
    func mailingListPicker(_ picker: MailingListPickerTableViewController, didPick chosenMailingList: MailingListDTO) {
        
        // Get email addresses of mailing list
        guard let container = container else {
            return
        }
        
        let emailAddresses = MailingList.getEmailAddressesForMailingList(objectId: chosenMailingList.objectId!, in: container.viewContext)
        
        // Prepare mails to send
        mailsToSend = composeMailsToSend(emailAddresses: emailAddresses)
        
        performSegue(withIdentifier: "sendMailingToMailingList", sender: nil)
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
