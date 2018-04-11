//
//  CommonInfoViewController.swift
//  Mailings
//
//  Created on 19.12.17.
//

import UIKit
import CoreData

class CommonInfoViewController: UITableViewController {

    var infoElements : ([InfoElement]) = []
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadInfoData()
        tableView.reloadData()
    }
    
    private func loadInfoData() {
        if let context = self.container?.viewContext {
            // All contacts
            let contacts = MailingContact.getNrOfContacts(in: context)
            infoElements.append(InfoElement(title: "Kontakte", info: String(contacts)))
            
            // All mailing lists with nr of assigned contacts
            let mailingLists = MailingList.getAllMailingLists(in: context)
            for mailingList in mailingLists {
                let contacts = MailingList.getAssignedContacts(objectId: mailingList.objectID, in: context)
                let contactCount = contacts.count
                infoElements.append(InfoElement(title: "Kontakte - \(mailingList.name!)", info: String(contactCount)))
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infoElements.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InfoElementCell", for: indexPath)

        let element = infoElements[indexPath.row]
        cell.textLabel?.text = element.title
        cell.detailTextLabel?.text = element.info
        
        return cell
    }
}
