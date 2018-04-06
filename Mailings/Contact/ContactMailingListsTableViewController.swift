//
//  ContactMailingListsTableViewController.swift
//  Mailings
//
//  Created on 06.03.18.
//

import UIKit
import CoreData

/**
 Delegate that is called after assigning new mailingLists to the contact or removing mailingLists from the list.
 */
protocol ContactMailingListsTableViewControllerDelegate: class {
    func contactMailingListsTableViewController(_ controller: ContactMailingListsTableViewController, didChangeMailingLists mailingListAssignmentChanges: [MailingListAssignmentChange])
}

/**
 Assigned Mailing Lists of a contact
 */
class ContactMailingListsTableViewController: UITableViewController, MailingListPickerTableViewControllerDelegate {
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    /**
     Flag indicates whether the view is in readonly mode or edit mode.
     */
    var editMode = false {
        didSet {
            configureControls()
        }
    }
   
    /**
     Delegate to call after adding or removing mailingLists
     */
    weak var delegate: ContactMailingListsTableViewControllerDelegate?
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer {
        didSet {
            updateUI()
        }
    }
    
    /**
     List of mailing Lists to display
     */
    var assignedMailingLists : AssigndMailingLists? {
        didSet {
            updateUI()
        }
    }
    
    private func getNrOfAssignedMailingLists() -> Int {
        if let assignedMailingLists = self.assignedMailingLists {
            return assignedMailingLists.mailingLists.count
        } else {
            return 0
        }
    }
    
    private func getAssignedMailingLists() -> [MailingListDTO] {
        var mailingLists =  [MailingListDTO]()
        
        if let assignedMailingLists = self.assignedMailingLists {
            if assignedMailingLists.mailingLists.count > 0 {
                for case let assignedMailingList in assignedMailingLists.mailingLists {
                    var mailingList = MailingListDTO()
                    mailingList.objectId = assignedMailingList.objectId
                    mailingList.name = assignedMailingList.name
                    mailingLists.append(mailingList)
                }
            }
        }
        return mailingLists
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        configureControls()
        updateUI()
    }
    
    private func updateUI() {
        tableView.reloadData()
    }
    
    private func configureControls() {
        addButton.isEnabled = editMode
    }
    
    // MARK: - Navigation and Actions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pickMailingList",
            let destinationVC = segue.destination as? MailingListPickerTableViewController
        {
            destinationVC.delegate = self
            destinationVC.selectionType = "multiple"
            destinationVC.excludedMailingLists = getAssignedMailingLists()
            destinationVC.container = container
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactMailingListCell", for: indexPath)
        
        let assignedMailingList = assignedMailingLists!.mailingLists[indexPath.row]
        cell.textLabel?.text = assignedMailingList.name!
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getNrOfAssignedMailingLists()
    }
    
    /**
     Delete mailing list assignment.
     When the commitEditingStyle method is present inside the view controller, the table view will automatically enable swipe-to-delete.
     */
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        let removedMailingList = assignedMailingLists!.mailingLists[indexPath.row]
        let mailingListAssignmentChange = MailingListAssignmentChange(objectId: removedMailingList.objectId, action: "R")
        
        assignedMailingLists!.mailingLists.remove(at: indexPath.row)
        
        let indexPaths = [indexPath]
        tableView.deleteRows(at: indexPaths, with: .automatic)
        
        delegate?.contactMailingListsTableViewController(self, didChangeMailingLists: [mailingListAssignmentChange])
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    
        if editMode == true {
            return .delete
        } else {
            return .none
        }
    }
    
    // MARK: - MailingListPickerTableViewControllerDelegate
    
    func mailingListPicker(_ picker: MailingListPickerTableViewController,
                           didPick chosenMailingList: MailingListDTO) {
        // No implementation. Only multiselection
    }
    
    /**
     Called when MailingListPickerTableViewController returns with a list of chosen mailing lists.
     Assign them to the contact
     */
    func mailingListPicker(_ picker: MailingListPickerTableViewController,
                           didPickList chosenMailingLists: [MailingListDTO]) {
        // Add chosen mailingLists
        var mailingListAssignmentChanges = [MailingListAssignmentChange]()
        for i in 0 ..< chosenMailingLists.count {
            let chosenMailingList = chosenMailingLists[i]
            let mailingListAlreadyAdded = assignedMailingLists!.mailingLists.contains {$0.objectId == chosenMailingList.objectId}
            if !mailingListAlreadyAdded {
                let assignedMailingList = AssignedMailingList(objectId: chosenMailingList.objectId!, name: chosenMailingList.name!)
                assignedMailingLists?.mailingLists.append(assignedMailingList)
                
                mailingListAssignmentChanges.append(MailingListAssignmentChange(objectId: chosenMailingList.objectId!, action: "A"))
            }
        }
        
        if mailingListAssignmentChanges.count > 0 {
            delegate?.contactMailingListsTableViewController(self, didChangeMailingLists: mailingListAssignmentChanges)
        }
        
        navigationController?.popViewController(animated:true)
        
        updateUI()
    }
}
