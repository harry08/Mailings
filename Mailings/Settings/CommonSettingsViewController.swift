//
//  CommonSettingsViewController.swift
//  Mailings
//
//  Created on 26.02.18.
//

import UIKit

class CommonSettingsViewController: UITableViewController {

    @IBOutlet weak var splitReceiverSwitch: UISwitch!
    @IBOutlet weak var maxReceiverPerMail: UILabel!
    
    var settingsController : CommonSettingsController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsController = CommonSettingsController.sharedInstance
        fillControls()
    }

    /**
     Fills the values from the DTO to the controls.
     */
    private func fillControls() {
        splitReceiverSwitch.isOn = settingsController!.getSplitReceivers()
        maxReceiverPerMail.text = String(settingsController!.getMaxReceiver())
    }
    
    @IBAction func splitReceiverSwitchChanged(_ sender: Any) {
        let splitReceiver = splitReceiverSwitch.isOn
        settingsController!.setSplitReceivers(splitReceiver)
    }
}
