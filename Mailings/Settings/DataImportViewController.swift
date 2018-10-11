//
//  DataImportViewController.swift
//  Mailings
//
//  Created on 04.10.18.
//

import UIKit
import MobileCoreServices
import CoreData

/**
 View to controll importing contacts from a csv file
 */
class DataImportViewController: UIViewController, UIDocumentPickerDelegate {
    
    @IBOutlet weak var infoLabel: UILabel!
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer

    override func viewDidLoad() {
        super.viewDidLoad()
        
        infoLabel.isHidden = true
    }
    
    /**
     Shows the menu to open a DocumentPicker to choose a file to import.
     */
    @IBAction func importContactsFromFile(_ sender: Any) {
        let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypeCommaSeparatedText)], in: .import)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        self.present(importMenu, animated: true, completion: nil)
    }
    
    func readDataFromFile(at url: URL) throws {
        let content = try String(contentsOf: url)
        
        if let context = self.container?.viewContext {
            let reader = CsvContactReader(csvContent: content, context: context)
            do {
                let importedContacts = try reader.importContacts()
                print("Nr of imported contacts: \(importedContacts.count)")
                
                showImportResult(importedContacts: importedContacts.count)
            } catch {
                print("Error. Failed to import contacts from file")
            }
        }
    }
    
    private func showImportResult(importedContacts: Int) {
        var message : String
        if importedContacts > 1 {
            message = "\(importedContacts) Kontakte importiert"
        } else if importedContacts == 1 {
            message = "Ein Kontakt importiert"
        } else {
            message = "Keine Kontakte importiert"
        }
        print(message)
        
        let imporResultMessage = "Kontaktimport abgeschlossen\n\(message)"
        infoLabel.text = imporResultMessage
        infoLabel.isHidden = false
    }
    
    // MARK: - Document Picker
    /**
     Document picked.
     Imports the data from the selected file.
     */
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        if urls.count == 1 {
            let url = urls[0]
            let filemgr = FileManager.default
            
            if filemgr.fileExists(atPath: url.path) {
                print("Importing contacts from file \(url.path)...")
                do {
                    try readDataFromFile(at: url)
                    
                    // TODO Show message with number of imported contacts
                } catch let error as NSError {
                    print("Error reading file \(error)")
                }
            } else {
                print("Error. Imported file not found at path \(url.path)")
            }
        }
    }
    
    /**
     The user has selected a document picker from the menu.
     The document picker is then shown.
     */
    public func documentMenu(_ documentMenu: UIDocumentMenuViewController,
                             didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
}
