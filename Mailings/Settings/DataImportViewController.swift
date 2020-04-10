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
 
 Handling of UI updating within a long running task with usage of
 - PrivateManagedObjectContext
 - DispatchQueue.main.async
 - ManagedObjectContext as private queue.
 
 For details see
 https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/Concurrency.html
 */
class DataImportViewController: UIViewController, UIDocumentPickerDelegate, CsvContactReaderDelegate {
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    var numberOfRecords : Int = 0
    
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIHelper.isDarkMode(traitCollection: traitCollection) {
            view.backgroundColor = UIColor.black
        }
        
        infoLabel.isHidden = true
        progressView.isHidden = true
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
    
    /**
     Opens the selected file and starts the import via CsvContactReader.
     */
    func readDataFromFile(at url: URL) throws {
        let content = try String(contentsOf: url)
        if let context = self.container?.viewContext {
            
            let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            privateMOC.parent = context
            
            privateMOC.perform {
                let reader = CsvContactReader(csvContent: content, context: privateMOC)
                reader.delegate = self
                do {
                    try reader.importContacts()
                } catch let e as CsvReaderError {
                    print("CsvReaderError: \(e.kind)")
                    self.showImportError(e)
                } catch {
                    print("General Error. Failed to import contacts from file")
                }
            
                do {
                    try privateMOC.save()
                    context.performAndWait {
                        do {
                            try context.save()
                        } catch {
                            print("Failure to save context: \(error)")
                        }
                    }
                } catch {
                    print("Failure to save context: \(error)")
                }
            }
        }
    }
    
    private func showImportError(_ error: CsvReaderError) {
        var imporResultMessage = "Fehler beim Import."
        if error.kind == .invalidColumns {
            imporResultMessage.append(" Fehlerhaftes Dateiformat")
        }
        
        DispatchQueue.main.async {
            self.progressView.isHidden = true
            
            self.infoLabel.text = imporResultMessage
            self.infoLabel.isHidden = false
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
        
        DispatchQueue.main.async {
            self.infoLabel.text = imporResultMessage
            self.infoLabel.isHidden = false
        }
    }
    
    // MARK: - CsvContactReader Delegate
    func csvContactReaderInitialized(_ reader: CsvContactReader, numberOfRecords: Int) {
        self.numberOfRecords = numberOfRecords
        let progressValue = 0.0
        DispatchQueue.main.async {
            self.progressView.progress = Float(progressValue)
            self.progressView.isHidden = false
            
            self.infoLabel.text = "Importiere Kontakte..."
            self.infoLabel.isHidden = false
        }
    }
    
    func csvContactReaderProgress(_ reader: CsvContactReader, recordNumber: Int) {
        let progressValue =  1.0 / Float(numberOfRecords) * Float(recordNumber)
        print("Progress \(progressValue)")
        DispatchQueue.main.async {
            print("Progress in DispatchQueue\(progressValue)")
            self.progressView.progress = progressValue
            self.progressView.isHidden = false
        }
    }
    
    func csvContactReaderFinished(_ reader: CsvContactReader, importedContacts: [MailingContactDTO]) {
        let progressValue = 1.0
        DispatchQueue.main.async {
            self.progressView.progress = Float(progressValue)
        }
        
        showImportResult(importedContacts: importedContacts.count)
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
