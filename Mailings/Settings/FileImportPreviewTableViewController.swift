//
//  FileImportPreviewTableViewController.swift
//  Mailings
//
//  Created on 22.04.20.
//

import Foundation
import UIKit

enum FileImportPreviewSection: Int {
    case fileinfos = 0, preview
}

protocol FileImportPreviewTableViewControllerDelegate: class {
    func doImport(_ controller: FileImportPreviewTableViewController, contacts: [PreviewContact])
}
    
/**
 Shows a preview ot the file to import.
 In the first section general infos of the file with the number of found contacts in the file.
 In the second section a preview of some contacts.
 Always 4 preview cells are shown. If the file contains less contacts some cells are empty.
 */
class FileImportPreviewTableViewController : UITableViewController {
    
    weak var delegate: FileImportPreviewTableViewControllerDelegate?
    
    var previewContacts = [PreviewContact]()
    
    var previewError = ""
    
    var previewCells = [UITableViewCell]()
    
    let filenameCell : UITableViewCell = {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        return cell
    }()
    
    let lastChangedCell : UITableViewCell = {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        return cell
    }()
    
    let nrOfRecordsCell : UITableViewCell = {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        return cell
    }()
    
    var fileName : String?
    var lastChanged : String?
    var fileContent : String?
    
    let filenameLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let lastChangedLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let nrOfRecordsLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = false
        self.title = "Vorschau"
        configureBarButtonItems()
        
        setupLayout()
    }
    
    private func configureBarButtonItems() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Importieren",
        style: .plain,
        target: self,
        action: #selector(importAction))
    }
    
    func setupLayout() {
        if let fileName = fileName {
            filenameLabel.text = fileName
        }
        filenameCell.addSubview(filenameLabel)
        filenameLabel.leadingAnchor.constraint(equalTo: filenameCell.leadingAnchor, constant: 20).isActive = true
        filenameLabel.centerYAnchor.constraint(equalTo: filenameCell.centerYAnchor).isActive = true
        
        if let lastChanged = lastChanged {
            lastChangedLabel.text = lastChanged
        }
        lastChangedCell.addSubview(lastChangedLabel)
        lastChangedLabel.leadingAnchor.constraint(equalTo: lastChangedCell.leadingAnchor, constant: 20).isActive = true
        lastChangedLabel.centerYAnchor.constraint(equalTo: lastChangedCell.centerYAnchor).isActive = true
        
        nrOfRecordsLabel.text = "Gefundene Datensätze: \(self.previewContacts.count)"
        nrOfRecordsCell.addSubview(nrOfRecordsLabel)
        nrOfRecordsLabel.leadingAnchor.constraint(equalTo: nrOfRecordsCell.leadingAnchor, constant: 20).isActive = true
        nrOfRecordsLabel.centerYAnchor.constraint(equalTo: nrOfRecordsCell.centerYAnchor).isActive = true
        
        initPreviewCells()
    }
    
    /**
     Maximum 4 preview cells are displayed
     */
    private func initPreviewCells() {
        for i in 0...3 {
            let previewCell = UITableViewCell()
            previewCell.selectionStyle = .none
            
            let previewLabel = UILabel()
            previewLabel.tag = i
            previewLabel.numberOfLines = 4
            previewLabel.translatesAutoresizingMaskIntoConstraints = false
            previewLabel.textColor = UIColor(white: 114/255, alpha: 1)
            previewLabel.font = UIFont.preferredFont(forTextStyle: .body)
            
            previewCell.addSubview(previewLabel)
            previewLabel.leadingAnchor.constraint(equalTo: previewCell.leadingAnchor, constant: 20).isActive = true
            previewLabel.centerYAnchor.constraint(equalTo: previewCell.centerYAnchor).isActive = true
            
            previewCells.append(previewCell)
            view.addSubview(previewCell)
        }
        
        tableView.reloadData()
    }
    
    @objc
    func importAction() {
        navigationController?.popViewController(animated:true)
        delegate?.doImport(self, contacts: self.previewContacts)
    }
    
    // MARK: - TableView Delegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let section = FileImportPreviewSection(rawValue: section) {
            switch section {
            case .preview:
                return previewCells.count
            default:
                // File metadata
                return 3
            }
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let section = FileImportPreviewSection(rawValue: indexPath.section) {
            switch section {
            case .preview:
                return 110
            default:
                return super.tableView(tableView, heightForRowAt: indexPath)
            }
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let section = FileImportPreviewSection(rawValue: section) {
            switch section {
            case .fileinfos:
                return "Datei"
            case .preview:
                return "Vorschau der zu importierenden Daten"
            }
        }
        
        return ""
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let section = FileImportPreviewSection(rawValue: indexPath.section) {
            switch section {
            case .fileinfos:
                if indexPath.row == 0 {
                    return filenameCell
                } else if indexPath.row == 1 {
                    return lastChangedCell
                } else if indexPath.row == 2 {
                    return nrOfRecordsCell
                }
            case .preview:
                let cell = previewCells[indexPath.row]
                if let label = getLabelWithTag(indexPath.row, cell: cell) {
                    if indexPath.row < previewContacts.count {
                        let previewContact = previewContacts[indexPath.row]
                        let contact = previewContact.contact
                        let firstname = contact.firstname ?? ""
                        let lastname = contact.lastname ?? ""
                        let email = contact.email ?? ""
                        let notes = contact.notes ?? ""
                        label.text = "Vorname: \(firstname) \nNachname: \(lastname) \nEmail: \(email) \nNotizen: \(notes)"
                    } else {
                        label.text = ""
                    }
                }
                
                return cell
            }
        }
        
        fatalError("table section not found")
    }
    
    private func getLabelWithTag(_ tag : Int, cell : UITableViewCell) -> UILabel? {
        let labels = cell.subviews.compactMap { $0 as? UILabel }
        for label in labels {
            if label.tag == tag {
                return label
            }
        }
        
        return nil
    }
}
