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
    
    var pickerDataSource = [String]();
    var pickerChanged = false
    
    var settingsController : CommonSettingsController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for i in 1 ..< 101 {
            pickerDataSource.append(String(i))
        }
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(donePicker))
        
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        maxReceiverPerMail.inputView = pickerView
        maxReceiverPerMail.inputAccessoryView = toolBar
        
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
    
    private func updateMaxReceiver() {
        let maxReceiverText = maxReceiverPerMail.text ?? ""
        if maxReceiverText != "" {
            if let maxReceiver: Int = Int(maxReceiverText) {
                settingsController!.setMaxReveiver(maxReceiver)
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func splitReceiverSwitchChanged(_ sender: Any) {
        let splitReceiver = splitReceiverSwitch.isOn
        settingsController!.setSplitReceivers(splitReceiver)
    }
    
    @objc func donePicker(sender: UIBarButtonItem) {
        maxReceiverPerMail.resignFirstResponder()
        updateMaxReceiver()
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
        maxReceiverPerMail.text = String(nrOfReceiver)
        pickerChanged = true
    }
}
