//
//  GroupedTableViewController.swift
//  Mailings
//
//  Created by Harry Huebner on 17.04.20.
//

import UIKit
import Foundation

struct CellData {
    var title = String()
    var sectionData = [String]()
}

struct SectionCells {
    var title : String
    var tableCells = [UITableViewCell]()
}

/**
 Programmatically created TableView to display the data set in the attribute tableViewData.
 This data can be set from outside. e.g.  Contact extended data.
 */
class GenericTableViewController : UITableViewController {
       
    /**
     Data fto display in the TableView.
     Set from the caller of this class
     */
    var tableViewData = [CellData]() {
        didSet {
            updateUI()
        }
    }
    
    var viewTitle: String = "" {
        didSet {
            navigationItem.title = self.viewTitle
        }
    }
    
    /**
     Array of TableViewCells created out of tableViewData
     */
    var sectionCells = [SectionCells]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    /**
     Creates for each entriy in tableViewData a data cell
     The cell is already filled with the given text.
     */
    private func updateUI() {
        var sectionCellsArray : Array<SectionCells> = Array()
        
        tableViewData.forEach {cellData in
            var cells : Array<UITableViewCell> = Array()
            cellData.sectionData.forEach {sectionData in
                let dataCell = UITableViewCell()
                
                let dataLabel = UILabel()
                dataLabel.translatesAutoresizingMaskIntoConstraints = false
                dataLabel.text = sectionData
                
                dataCell.addSubview(dataLabel)
                dataLabel.leadingAnchor.constraint(equalTo: dataCell.leadingAnchor, constant: 20).isActive = true
                dataLabel.centerYAnchor.constraint(equalTo: dataCell.centerYAnchor).isActive = true
                
                cells.append(dataCell)
                view.addSubview(dataCell)
            }
            
            sectionCellsArray.append(SectionCells(title: cellData.title, tableCells: cells))
        }
        
        sectionCells = sectionCellsArray
        
        tableView.reloadData()
    }
    
    // MARK: - TableView Delegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionCells.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionCells[section].tableCells.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = sectionCells[indexPath.section].tableCells[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionCells[section].title
    }
}
