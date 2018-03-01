//
//  CommonSettingsViewController.swift
//  Mailings
//
//  Created on 26.02.18.
//

import UIKit

class CommonSettingsViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var splitReceiverSwitch: UISwitch!
    @IBOutlet weak var maxReceiverPerMail: UITextField!
    
    var pickerDataSource = ["1", "2", "3", "4", "5"];
    var resultString = ""
    
    var settingsController : CommonSettingsController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        maxReceiverPerMail.inputView = pickerView
        
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
    
    // MARK: - Actions
    
    @IBAction func splitReceiverSwitchChanged(_ sender: Any) {
        let splitReceiver = splitReceiverSwitch.isOn
        settingsController!.setSplitReceivers(splitReceiver)
    }
    
    // MARK: - Picker Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        let nrOfReceiver = row + 1
        settingsController!.setMaxReveiver(nrOfReceiver)
        maxReceiverPerMail.text = String(settingsController!.getMaxReceiver())
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}
