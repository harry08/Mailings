//
//  SettingsViewController.swift
//  Mailings
//
//  Created on 10.11.17.
//

import UIKit
import CoreData

/**
 The SettingsViewController has no functionality on its own. It is Just a tableView
 with static cells to navigate to further settings screens.
 */
class SettingsViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = false
    }
}
