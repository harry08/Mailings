//
//  MailingAttachementsTableViewController.swift
//  Mailings
//
//  Created on 18.05.18.
//

import UIKit
import CoreData
import MobileCoreServices
import QuickLook

/**
 Delegate that is called after adding a new file to the mailing or removing a file from the mailing..
 */
protocol MailingAttachementsTableViewControllerDelegate: class {
    func mailingFilesTableViewControllerDelegate(_ controller: MailingAttachementsTableViewController, didChangeAttachements attachedChanges: [MailingAttachmentChange])
}

/**
 Shows the attached files of a mailing in a TableView.
 Allows attaching new files and removing existing attachments.
 */
class MailingAttachementsTableViewController: UITableViewController, UIDocumentMenuDelegate, UIDocumentPickerDelegate, UINavigationControllerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    var mailingDTO : MailingDTO?
    
    /**
     List of attached files
     */
    var attachments : MailingAttachments? {
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
        if let attachedFiles = self.attachments {
            return attachedFiles.files.count
        } else {
            return 0
        }
    }
    
    /**
     Reloads data of the file with the given fileName
     The objectId of the file entry needs to be filled.
     */
    private func reloadAttachment(fileName: String) {
        if !parentEditMode {
            guard let container = container else {
                return
            }
            
            if let attachments = self.attachments,
                let mailingDTO = mailingDTO {
                if let file = attachments.files.first(where: { $0.name == fileName }) {
                    if let loadedFile = Mailing.getAttachedFile(objectId: mailingDTO.objectId!, fileName: fileName, in: container.viewContext) {
                        file.objectId = loadedFile.objectId
                    }
                }
            }
        }
    }
    
    /**
     Shows the menu to open a DocumentPicker to choose a file to add to the mailing.
     */
    @IBAction func addNewFile(_ sender: Any) {
        let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypePDF), String(kUTTypeText),  String(kUTTypeImage), String(kUTTypeCompositeContent)], in: .import)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        self.present(importMenu, animated: true, completion: nil)
    }

    // MARK: - Table view
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttachementCell", for: indexPath)
        
        let attachedFile = attachments!.files[indexPath.row]
        cell.textLabel?.text = attachedFile.name
        
        let fileAttributes = FileAttachmentHandler.getFileAttributes(fileName: attachedFile.name, folderName: attachments!.subfolderName)
        
        var detailLabelText = ""
        if let modDate = fileAttributes.modificationDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            let formattedDate = dateFormatter.string(from: modDate as Date)
            
            detailLabelText = formattedDate
        }
        
        if let fileSize = fileAttributes.size {
            let sizeText = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: ByteCountFormatter.CountStyle.file)
            
            detailLabelText = detailLabelText + " - " + sizeText
        }
        
        cell.detailTextLabel?.text = detailLabelText
        
        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getNrOfAttachedFiles()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let attachedFiles = attachments else {
            return
        }
        
        // Prepare Urls for QuickLook dataSource
        var filerUrls:[URL] = []
        filerUrls = attachedFiles.files.map { file in
            let fileUrl = FileAttachmentHandler.getUrlForFile(fileName: file.name, folderName: attachedFiles.subfolderName)
            
            let mimetpe = FileAttachmentHandler.mimeTypeForUrl(fileUrl)
            print(mimetpe)
            
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
        
        guard let attachments = attachments else {
            return
        }
        
        let removedFile = attachments.files[indexPath.row]
        var mailingAttachmentChange : MailingAttachmentChange
        if let objectId = removedFile.objectId {
            mailingAttachmentChange = MailingAttachmentChange(objectId: objectId, fileName: removedFile.name, folderName: attachments.subfolderName, action: .removed)
        } else {
            mailingAttachmentChange = MailingAttachmentChange(fileName: removedFile.name, folderName: attachments.subfolderName, action: .removed)
        }
        
        attachments.files.remove(at: indexPath.row)
        
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
        
        guard let attachedFiles = attachments else {
            return
        }
        
        if urls.count >= 1 {
            let url = urls[0]
            let filemgr = FileManager.default
            
            if filemgr.fileExists(atPath: url.path) {
                if FileAttachmentHandler.fileExistsInAttachmentsDir(url: url, folderName: attachedFiles.subfolderName) {
                    let alertController = UIAlertController(title: "Datei mit diesem Namen bereits vorhanden", message: "Bitte wählen Sie eine andere Datei aus.", preferredStyle: .alert)
                    
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    
                    present(alertController, animated: true, completion: nil)
                    
                } else {
                    FileAttachmentHandler.copyFileToAttachementsDir(urlToCopy: url, folderName: attachedFiles.subfolderName)
                    
                    let fileName = url.lastPathComponent
                    var mailingAttachementChanges = [MailingAttachmentChange]()
                    
                    let attachementAlreadyAdded = attachedFiles.files.contains {$0.name == fileName}
                    if !attachementAlreadyAdded {
                        let attachedFile = AttachedFile(name: fileName)
                        attachedFiles.files.append(attachedFile)
                        
                        mailingAttachementChanges.append(MailingAttachmentChange(fileName: fileName, folderName: attachedFiles.subfolderName, action: .added))
                    }
                    
                    if mailingAttachementChanges.count > 0 {
                        delegate?.mailingFilesTableViewControllerDelegate(self, didChangeAttachements: mailingAttachementChanges)
                        reloadAttachment(fileName: fileName)
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
