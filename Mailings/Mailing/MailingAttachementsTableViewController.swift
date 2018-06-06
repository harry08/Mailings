//
//  MailingFilesTableViewController.swift
//  Mailings
//
//  Created on 18.05.18.
//

import UIKit
import MobileCoreServices

/**
 Delegate that is called after adding a new file to the mailing or removing a file from the mailing..
 */
protocol MailingAttachementsTableViewControllerDelegate: class {
    func mailingFilesTableViewControllerDelegate(_ controller: MailingAttachementsTableViewControllerDelegate, didChangeAttachements attachedChanges: [MailingAttachementChange])
}

/**
 Shows the attached files of a mailing in a TableView.
 */
class MailingAttachementsTableViewController: UITableViewController, UIDocumentMenuDelegate, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    
    /**
     List of attached files
     */
    var attachedFiles : MailingAttachements? {
        didSet {
            updateUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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

    // MARK: - Table view

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getNrOfAttachedFiles()
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
    
    // MARK: - Document Picker
    /**
     Document picked.
     Copies it to local directory and attaches it to the mailing.
     */
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        print("import result : \(urls.count)")
        if urls.count >= 1 {
            print("import result : \(urls[0].absoluteURL)")
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
