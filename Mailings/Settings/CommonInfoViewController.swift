//
//  CommonInfoViewController.swift
//  CustomerManager
//
//  Created by Harry Huebner on 19.12.17.
//  Copyright © 2017 Huebner. All rights reserved.
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
            let contacts = MailingContact.getNrOfContacts(in: context)
            infoElements.append(InfoElement(title: "Kontakte", info: String(contacts)))
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
