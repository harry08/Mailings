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
class DataImportViewController: UIViewController, UIDocumentPickerDelegate, FileImportPreviewTableViewControllerDelegate {
    
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
    
    func getFileContent(at url: URL) throws -> String {
        let content = try String(contentsOf: url)
        
        return content
    }
    
    // MARK: - Show import progress and result
    
    private func initProgress(nrOfRecords: Int) {
        self.numberOfRecords = nrOfRecords
        let progressValue = 0.0
        DispatchQueue.main.async {
            self.progressView.progress = Float(progressValue)
            self.progressView.isHidden = false
            
            self.infoLabel.text = "Importiere Kontakte..."
            self.infoLabel.isHidden = false
        }
    }
    
    private func incProgress(recordNumber: Int) {
        let progressValue =  1.0 / Float(self.numberOfRecords) * Float(recordNumber)
        DispatchQueue.main.async {
            print("Progress in DispatchQueue\(progressValue)")
            self.progressView.progress = progressValue
            self.progressView.isHidden = false
        }
    }
    
    private func finishProgress(nrOfImportedRecords: Int) {
        let progressValue = 1.0
        DispatchQueue.main.async {
            self.progressView.progress = Float(progressValue)
            self.progressView.isHidden = true
        }
        
        showImportResult(importedContacts: nrOfImportedRecords)
    }
    
    private func showImportError(_ error: String, prefix: String) {
        let imporResultMessage = "\(prefix). \(error)"
        
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
        let imporResultMessage = "Kontaktimport abgeschlossen\n\(message)"
        
        DispatchQueue.main.async {
            self.progressView.isHidden = true
            
            self.infoLabel.text = imporResultMessage
            self.infoLabel.isHidden = false
        }
    }
    
    // MARK: - FileImportPreviewTableViewController Delegate
    func doImport(_ controller: FileImportPreviewTableViewController, contacts: [PreviewContact]) {
        if let context = self.container?.viewContext {
            let mailingLists = MailingList.getAllMailingListsAsDTO(in: context)
            
            let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            var importedContacts = 0
            privateMOC.parent = context
            
            privateMOC.perform {
                // Update database with contacts
                do {
                    self.initProgress(nrOfRecords: contacts.count)
                    for previewContact in contacts {
                        print("Info: Persisting contact \(previewContact.contact)...")
                        var firstname = previewContact.contact.firstname
                        if firstname == nil {
                            firstname = ""
                        }
                        var lastname = previewContact.contact.lastname
                        if lastname == nil {
                            lastname = ""
                        }
                        
                        if try !MailingContact.contactExists(firstname: firstname!, lastname: lastname!, in: context) {
                            if previewContact.mailingLists.count > 0 {
                                // Import with mailing lists. Then no default mailing lists are assigned
                                var assignmentChanges = [MailingListAssignmentChange]()
                                for mailingListName in previewContact.mailingLists {
                                    if let mailingList = MailingList.getMailingListByName(mailingListName, mailingLists: mailingLists) {
                                         let assignmentChange = MailingListAssignmentChange(objectId: mailingList.objectId!, action: "A")
                                         assignmentChanges.append(assignmentChange)
                                    } else {
                                        print("Warning: Mailinglist \(mailingListName) not found for assignemnt")
                                    }
                                }
                                try MailingContact.createOrUpdateFromDTO(contactDTO: previewContact.contact, assignmentChanges: assignmentChanges, in: context)
                            } else {
                                // Import without mailing lists. Default mailing lists are assigned
                                try MailingContact.createOrUpdateFromDTO(contactDTO: previewContact.contact, in: context)
                            }
                        }
                        
                        importedContacts += 1
                        self.incProgress(recordNumber: importedContacts)
                    }
                } catch let error as NSError {
                    print("Error: Failed to persist contact: \(error), \(error.userInfo)")
                    self.showImportError("Kontakte konnten nicht gespeicher werden", prefix: "Fehler beim Import")
                }
                
                // Save context
                do {
                    try privateMOC.save()
                    context.performAndWait {
                        do {
                            try context.save()
                        } catch {
                            print("Error: Failed to save context: \(error)")
                            self.showImportError("Kontakte konnten nicht gespeicher werden", prefix: "Fehler beim Import")
                        }
                    }
                    
                    self.finishProgress(nrOfImportedRecords: importedContacts)
                } catch {
                    print("Error: Failed to save context: \(error)")
                    self.showImportError("Kontakte konnten nicht gespeicher werden", prefix: "Fehler beim Import")
                }
            }
        }
    }
    
    // MARK: - Document Picker
    /**
     Document picked.
     Shows a preview view with details of the file and the contacts to import.
     */
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        if urls.count == 1 {
            let url = urls[0]
            let filemgr = FileManager.default
            
            if filemgr.fileExists(atPath: url.path) {
                print("Importing contacts from file \(url.path)...")
                do {
                    let fileContent = try getFileContent(at: url)
                    
                    var previewError = ""
                    do {
                        let metaData = try ContactCsvReader.analyzeFileContent(fileContent)
                        let contactCsvReader = ContactCsvReader(readLimit: -1, wordDelimiterChar: metaData.delimiter)
                        if let previewContacts = try? contactCsvReader.readFileContent(fileContent) {
                            let importPreviewView = FileImportPreviewTableViewController(style: .grouped)
                            importPreviewView.delegate = self
                            importPreviewView.fileName = url.lastPathComponent
                            importPreviewView.lastChanged = getFileLastChangedString(url: url)
                            importPreviewView.fileContent = fileContent
                            importPreviewView.previewContacts = previewContacts
                            self.navigationController?.pushViewController(importPreviewView, animated: true)
                        }
                    } catch ContactCsvReaderError.noContent {
                        previewError = "Datei hat keinen Inhalt"
                    } catch ContactCsvReaderError.invalidColumns {
                        previewError = "Fehlerhafte Spalten"
                    } catch ContactCsvReaderError.invalidFileFormat {
                        previewError = "Dateiformat nicht erkannt"
                    } catch ContactCsvReaderError.invalidRecord(let recordNumber) {
                        previewError = "Fehler bei Datensatz \(recordNumber)"
                    } catch {
                        previewError = "Unbestimmter Fehler"
                    }
                    
                    if previewError.count > 0 {
                        self.showImportError(previewError, prefix: "Fehler beim Lesen der Datei")
                    }
                } catch let error as NSError {
                    // Errorhandling for fileopen
                    print("Error: Failed to read file \(error)")
                    self.showImportError("Datei konnte nicht geöffnet werden", prefix: "Fehler beim Lesen der Datei")
                }
            } else {
                print("Error: File not found at path \(url.path)")
                self.showImportError("Datei konnte nicht geöffnet werden", prefix: "Fehler beim Lesen der Datei")
            }
        }
    }
    
    private func getFileLastChangedString(url: URL) -> String {
        let fileAttributes = FileUtil.getFileAttributes(fileUrl: url)
        
        var lastChangedString = ""
        if let modDate = fileAttributes.modificationDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            let formattedDate = dateFormatter.string(from: modDate as Date)
            
            lastChangedString = formattedDate
        }
        
        if let fileSize = fileAttributes.size {
            let sizeText = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: ByteCountFormatter.CountStyle.file)
            
            lastChangedString = lastChangedString + " - " + sizeText
        }
        
        return lastChangedString
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
