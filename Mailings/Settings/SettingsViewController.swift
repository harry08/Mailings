//
//  SettingsViewController.swift
//  CustomerManager
//
//  Created on 10.11.17.
//

import UIKit
import CoreData

class SettingsViewController: UITableViewController {
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BasicSettingsCell")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    /*
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Kontaktdaten"
    }*/
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicSettingsCell", for: indexPath)
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Info"
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        } else if indexPath.row == 1 {
            cell.textLabel?.text = "Kontakte importieren"
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }
        
        return cell
    }
    
    // Selecting a table row.
    // Navigate to another screen
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        
        if row == 0 {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let contactImportVc = storyBoard.instantiateViewController(withIdentifier: "CommonInfoVC")
            
            self.navigationController?.pushViewController(contactImportVc, animated: true)
        } else if row == 1 {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let contactImportVc = storyBoard.instantiateViewController(withIdentifier: "ContactImportVC")
            
            self.navigationController?.pushViewController(contactImportVc, animated: true)
        }
    }
}
