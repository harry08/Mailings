//
//  ShowMailingListViewController.swift
//  Mailings
//
//  Created on 18.01.18.
//

import UIKit
import CoreData

class ShowMailingListViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var defaultAssignmentLabel: UILabel!
    @IBOutlet weak var recipientsAsBccLabel: UILabel!
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        navigationItem.largeTitleDisplayMode = .never
    }
    
    var mailingListDTO : MailingListDTO? {
        didSet {
            loadViewIfNeeded()
            updateUI()
        }
    }
    
    private func updateUI() {
        if let mailingListDTO = self.mailingListDTO {
            nameLabel.text = mailingListDTO.name
            if mailingListDTO.recipientAsBcc == true {
                recipientsAsBccLabel.text = "Empfänger als Blindkopie"
            } else {
                recipientsAsBccLabel.text = "Empfänger als Kopie"
            }
            
            if mailingListDTO.assignAsDefault == true {
               defaultAssignmentLabel.text = "Neue Kontakte automatisch zuordnen"
            } else {
               defaultAssignmentLabel.text = "Neue Kontakte nicht zuordnen"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Navigation

    // Navigate back from editing mailing. Save data in MailingDTO
    // MailingDTO is already filled
    @IBAction func unwindFromSave(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? EditMailingListViewController,
            let mailingListDTO = sourceViewController.mailingListDTO {
            
            guard let container = container else {
                print("Save not possible. No PersistentContainer.")
                return
            }
            
            do {
                // Update database
                try MailingList.createOrUpdateFromDTO(mailingListDTO, in: container.viewContext)
                
                // Reload mailingDTO. UI is updated automatically
                self.mailingListDTO = try MailingList.loadMailingList(objectId: mailingListDTO.objectId!, in: container.viewContext)
            } catch let error as NSError {
                // TODO show Alert
            }
        }
    }
    
    // Prepare for navigate to editing the mailingList data
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editMailingList",
            let destinationVC = segue.destination as? EditMailingListViewController
        {
            // Edit mailingList
            destinationVC.container = container
            destinationVC.mailingListDTO = mailingListDTO
            destinationVC.editMode = true
        }
    }
}
