//
//  MailingAttachementsTableViewController.swift
//  Mailings
//
//  Created on 18.05.18.
//

import UIKit
import MobileCoreServices
import QuickLook

/**
 Delegate that is called after adding a new file to the mailing or removing a file from the mailing..
 */
protocol MailingAttachementsTableViewControllerDelegate: class {
    func mailingFilesTableViewControllerDelegate(_ controller: MailingAttachementsTableViewController, didChangeAttachements attachedChanges: [MailingAttachementChange])
}

/**
 Shows the attached files of a mailing in a TableView.
 */
class MailingAttachementsTableViewController: UITableViewController, UIDocumentMenuDelegate, UIDocumentPickerDelegate, UINavigationControllerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    /**
     List of attached files
     */
    // TODO rename to mailingAttachments
    var attachedFiles : MailingAttachements? {
        didSet {
            updateUI()
        }
    }
    
    /**
     Flag indicates whether the parent view is in readonly mode or edit mode.
     */
    var parentEditMode = false 
    
    let quickLookController = QLPreviewController()
    
    /**
     Urls used as datasource for the QuickLook view.
     Filled when a row in this table gets selected before the QuickLook view is shown.
     */
    var selectedUrls:[URL] = []
    
    /**
     Delegate to call after adding or removing file attachements
     */
    weak var delegate: MailingAttachementsTableViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        quickLookController.dataSource = self
        quickLookController.delegate = self
    }
    
    private func updateUI() {
        tableView.reloadData()
    }
    
    private func getNrOfAttachedFiles() -> Int {
        if let attachedFiles = self.attachedFiles {
            return attachedFiles.files.count
        } else {
            return 0
        }
    }
    
    /**
     Shows the menu to open a DocumentPicker to choose a file to add to the mailing.
     */
    @IBAction func addNewFile(_ sender: Any) {
        let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypePDF), String(kUTTypeText)], in: .import)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        self.present(importMenu, animated: true, completion: nil)
    }

    // MARK: - Table view
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttachementCell", for: indexPath)
        
        let attachedFile = attachedFiles!.files[indexPath.row]
        cell.textLabel?.text = attachedFile.name
        
        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getNrOfAttachedFiles()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let attachedFiles = attachedFiles else {
            return
        }
        
        // Prepare Urls for QuickLook dataSource
        var filerUrls:[URL] = []
        filerUrls = attachedFiles.files.map { file in
            let fileUrl = FileAttachmentHandler.getUrlForFile(fileName: file.name, folderName: attachedFiles.subfolderName!)
            return fileUrl
        }
        self.selectedUrls = filerUrls
        
        if QLPreviewController.canPreview(self.selectedUrls[indexPath.row] as QLPreviewItem) {
            quickLookController.currentPreviewItemIndex = indexPath.row
            self.navigationController?.pushViewController(quickLookController, animated: true)
        }
    }
    
    /**
     Delete file attachment.
     When the commitEditingStyle method is present inside the view controller, the table view will automatically enable swipe-to-delete.
     */
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,        forRowAt indexPath: IndexPath) {
        
        guard let attachedFiles = attachedFiles else {
            return
        }
        
        let removedFile = attachedFiles.files[indexPath.row]
        var mailingAttachmentChange : MailingAttachementChange
        if let objectId = removedFile.objectId {
            mailingAttachmentChange = MailingAttachementChange(objectId: objectId, fileName: removedFile.name, folderName: attachedFiles.subfolderName!, action: .removed)
        } else {
            // File attachment was not saved before. Also directly delete file
            mailingAttachmentChange = MailingAttachementChange(fileName: removedFile.name, folderName: attachedFiles.subfolderName!, action: .removed)
            
            FileAttachmentHandler.removeFile(fileName: removedFile.name, folderName: attachedFiles.subfolderName!)
        }
        
        attachedFiles.files.remove(at: indexPath.row)
        
        let indexPaths = [indexPath]
        tableView.deleteRows(at: indexPaths, with: .automatic)
        
        delegate?.mailingFilesTableViewControllerDelegate(self, didChangeAttachements: [mailingAttachmentChange])
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        return .delete
    }
    
    // MARK: - Document Picker
    /**
     Document picked.
     Copies it to local directory and attaches it to the mailing.
     */
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        guard let attachedFiles = attachedFiles else {
            return
        }
        
        if urls.count >= 1 {
            let url = urls[0]
            let filemgr = FileManager.default
            
            if filemgr.fileExists(atPath: url.path) {
                print("File at path \(url.path) exists")
                
                if FileAttachmentHandler.fileExistsInAttachmentsDir(url: url, folderName: attachedFiles.subfolderName!) {
                    // TODO Show error
                    
                } else {
                    FileAttachmentHandler.copyFileToAttachementsDir(urlToCopy: url, folderName: attachedFiles.subfolderName!)
                    
                    let fileName = url.lastPathComponent
                    var mailingAttachementChanges = [MailingAttachementChange]()
                    
                    let attachementAlreadyAdded = attachedFiles.files.contains {$0.name == fileName}
                    if !attachementAlreadyAdded {
                        let attachedFile = AttachedFile(name: fileName)
                        attachedFiles.files.append(attachedFile)
                        
                        mailingAttachementChanges.append(MailingAttachementChange(fileName: fileName, folderName: attachedFiles.subfolderName!, action: .added))
                    }
                    
                    if mailingAttachementChanges.count > 0 {
                        delegate?.mailingFilesTableViewControllerDelegate(self, didChangeAttachements: mailingAttachementChanges)
                    }
                    
                    updateUI()
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
    
    //MARK: - QuickLook DataSource and Delegate
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.selectedUrls.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return selectedUrls[index] as QLPreviewItem
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
       // self.tableView.deselectRow(at: self.tableView.indexPathForSelectedRow!, animated: true)
    }
    
    /**
     Don´t allow other urls to be called inside the preview view.
     */
    func previewController(_ controller: QLPreviewController, shouldOpen url: URL, for item: QLPreviewItem) -> Bool {
        
        return false
    }
}
