//
//  MailingDetailTableViewController.swift
//  Mailings
//
//  Created on 20.02.18.
//

import UIKit
import CoreData
import MessageUI

/**
 Sections of static table inside MailingDetailView
 */
enum MailingDetailViewSection: Int {
    case title = 0, content, attachement, action
}

/**
 Delegate that is called after closing the DetailController.
 Database update can be done in the implementing classes.
 */
protocol MailingDetailViewControllerDelegate: class {
    func mailingDetailViewControllerDidCancel(_ controller: MailingDetailViewController)
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishAdding mailing: MailingDTO, attachementChanges: [MailingAttachmentChange])
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishEditing mailing: MailingDTO, attachementChanges: [MailingAttachmentChange])
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishDeleting mailing: MailingDTO)
}

/**
 Detail View for mailings.
 This View uses a dynamic tableView layout since it is needed for dynamic row heights.
 The row height of the content cell is dependent on the text.
 */
class MailingDetailViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate,  MailingDetailViewControllerDelegate, MailingListPickerTableViewControllerDelegate, MailingAttachementsTableViewControllerDelegate, MailingTextViewControllerDelegate, MFMailComposeViewControllerDelegate {
    
    /**
     Flag indicates whether a new mailing is shown or an existing one.
     */
    var editType = false
    
    /**
     Flag indicates whether the view is in readonly mode or edit mode.
     */
    var editMode = false
    
    /**
     Delegate to call after finish editing
     Weak reference to avoid ownership cycles.
     The detailView has only a weak reference back to the owning tableView.
     */
    weak var delegate: MailingDetailViewControllerDelegate?
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    // In case of editing an existing mailing this variable is filled on startup.
    // In case of a new one this will be created in the prepare method.
    var mailingDTO : MailingDTO?
    
    var changedMailingTitle : String?
    var changedMailingText : String?
    
    /**
     List of attached files
     */
    var attachments : MailingAttachments?
    
    /**
     List of changes of attachements of this mailing
     */
    var mailingAttachementChanges = [MailingAttachmentChange]()
    
    /**
     Controls the doneButton
     */
    var viewEdited = false {
        didSet {
            configureBarButtonItems()
        }
    }
    
    var mailsToSend = [MailDTO]()
    
    private func isEditType() -> Bool {
        return editType
    }
    
    private func isAddType() -> Bool {
        return !editType
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        
        navigationItem.largeTitleDisplayMode = .never
        
        // Put this class as delegate to receive events
        delegate = self
        
        if isEditType() {
           title = "Mailing"
        } else {
            // Add mode. Create new empty MailingDTO object
            mailingDTO = MailingDTO()
            editMode = true
        }
        configureBarButtonItems()
        configureToolbar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isAddType() {
            // Only in add mode directly put the focus inside the title field.
            // The event didSelectRow needs to be called programmatically.
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            self.tableView.delegate?.tableView!(self.tableView, didSelectRowAt: indexPath)
        }
        configureToolbar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.isToolbarHidden = true
    }
    
    /**
     Returns the text of the mailing. If the mailing has changes the changed text is returned.
     Otherwise the saved one.
     */
    private func getMailingText() -> String {
        if let changedMailingText = changedMailingText {
            return changedMailingText
        } else {
            if let mailingDTO = mailingDTO,
                let text = mailingDTO.text {
                    return text
            } else {
                return ""
            }
        }
    }
    
    /**
     Fills the changed values into the MailingListDTO.
     */
    private func fillMailingDTO() {
        if let mailingTitle = changedMailingTitle {
            mailingDTO?.title = mailingTitle
        }
        
        if let mailingText = changedMailingText {
            mailingDTO?.text = mailingText
        }
    }
    
    // MARK: - Action and Navigation
    
    private func configureBarButtonItems() {
        if isAddType() {
            // View displays a new mailing
            // Editing of this new mailing can be finished with done and cancel.
            let leftItem1 = UIBarButtonItem(title: "Abbrechen", style: .plain, target: self, action: #selector(cancelAction))
            let leftItems = [leftItem1]
            navigationItem.setLeftBarButtonItems(leftItems, animated: false)
            
            var rightItems = [UIBarButtonItem]()
            if viewEdited {
                let rightItem1 = UIBarButtonItem(title: "Fertig", style: .plain, target: self, action: #selector(doneAction))
                rightItems.append(rightItem1)
            }
            navigationItem.setRightBarButtonItems(rightItems, animated: false)
        } else if isEditType() {
            // View displays an existing mailing.
            // The mailing can be edited with an Edit button. This mode can be ended with done and cancel.
            var leftItems = [UIBarButtonItem]()
            if editMode {
                let leftItem1 = UIBarButtonItem(title: "Abbrechen", style: .plain, target: self, action: #selector(cancelAction))
                leftItems.append(leftItem1)
            }
            navigationItem.setLeftBarButtonItems(leftItems, animated: false)
            
            var rightItems = [UIBarButtonItem]()
            if editMode {
                let rightItem1 = UIBarButtonItem(title: "Fertig", style: .plain, target: self, action: #selector(doneAction))
                if !viewEdited {
                    rightItem1.isEnabled = false
                }
                rightItems.append(rightItem1)
            } else {
                let rightItem1 = UIBarButtonItem(title: "Bearbeiten", style: .plain, target: self, action: #selector(editAction))
                rightItems.append(rightItem1)
            }
           
            navigationItem.setRightBarButtonItems(rightItems, animated: false)
        }
    }
    
    private func configureToolbar() {
        if editMode {
            self.navigationController?.isToolbarHidden = true
            
        } else {
            self.navigationController?.isToolbarHidden = false
            self.navigationController?.toolbar.barStyle = .default
            self.navigationController?.toolbar.isTranslucent = true
            self.navigationController?.toolbar.barTintColor = UIColor.white
            
            var items = [UIBarButtonItem]()
            items.append(
                UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareMailingContentAction))
            )
            
            if HtmlUtil.isHtml(getMailingText()) {
                let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
                spacer.width = 5
                items.append(spacer)
                items.append(
                    UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(previewHtmlAction))
                )
            }
            
            self.toolbarItems = items
        }
    }
    
    @objc func cancelAction(sender: UIBarButtonItem) {
        if isEditType(){
            delegate?.mailingDetailViewControllerDidCancel(self)
        } else if isAddType() {
            delegate?.mailingDetailViewControllerDidCancel(self)
        }
    }
    
    @objc func doneAction(sender: UIBarButtonItem) {
        if isEditType(){
            fillMailingDTO()
            delegate?.mailingDetailViewController(self, didFinishEditing: mailingDTO!, attachementChanges: mailingAttachementChanges)
        } else if isAddType() {
            fillMailingDTO()
            delegate?.mailingDetailViewController(self, didFinishAdding: mailingDTO!, attachementChanges: mailingAttachementChanges)
        }
    }
    
    @objc func editAction(sender: UIBarButtonItem) {
        editMode = true
        viewEdited = false
        configureBarButtonItems()
        configureToolbar()
        tableView.reloadData()
    }
    
    /**
     Deletes the mailing
     */
    func deleteAction() {
        delegate?.mailingDetailViewController(self, didFinishDeleting: mailingDTO!)
    }
    
    /**
     Shares the content of this mailing.
     Text and files.
     */
    @objc func shareMailingContentAction(sender: UIBarButtonItem) {
        guard let mailingDTO = mailingDTO else {
            return
        }
        
        let containsText = mailingDTO.text != nil
        let containsAttachments = attachments != nil && attachments!.files.count > 0
        
        if containsText && containsAttachments {
            showSharingContentMenu(sender: sender)
        } else if containsText && !containsAttachments{
            shareMailingContent(shareText: true, shareFiles: false, sender: sender)
        } else if !containsText && containsAttachments{
            shareMailingContent(shareText: false, shareFiles: true, sender: sender)
        }
    }

    func showSharingContentMenu(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Nur Text teilen...", style: .default) { _ in
            self.shareMailingContent(shareText: true, shareFiles: false, sender: sender)
        })
        alert.addAction(UIAlertAction(title: "Nur Dateien teilen...", style: .default) { _ in
            self.shareMailingContent(shareText: false, shareFiles: true, sender: sender)
        })
        alert.addAction(UIAlertAction(title: "Text und Dateien teilen...", style: .default) { _ in
            self.shareMailingContent(shareText: true, shareFiles: true, sender: sender)
        })
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel) { _ in
            // Do nothing
        })
        
        // Set barbuttonItem for iPad.
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        
        self.present(alert, animated: true)
    }
    
    func shareMailingContent(shareText: Bool, shareFiles: Bool, sender: UIBarButtonItem) {
        guard let mailingDTO = mailingDTO else {
            return
        }
        
        var activityItems = [Any]()
        
        if shareText {
            if let mailingText = mailingDTO.text {
                activityItems.append(mailingText as NSString)
            }
        }
        
        if shareFiles {
            if let attachments = attachments {
                for i in 0 ..< attachments.files.count {
                    let file = attachments.files[i]
                    let url = FileAttachmentHandler.getUrlForFile(fileName: file.name, folderName: attachments.subfolderName)
                    activityItems.append(url)
                }
            }
        }
        
        if activityItems.count > 0 {
            let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            
            // Relevant for iPad to adhere the popover to the share button.
            activityViewController.popoverPresentationController?.sourceView = view
            activityViewController.popoverPresentationController?.barButtonItem = sender
            
            self.present(activityViewController, animated: true, completion: {})
        }
    }

    @objc func previewHtmlAction(sender: UIBarButtonItem) {
        if let mailingDTO = mailingDTO,
            let text = mailingDTO.text {
            if HtmlUtil.isHtml(text) {
                performSegue(withIdentifier: "showHtmlPreview", sender: nil)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pickMailingList",
            let destinationVC = segue.destination as? MailingListPickerTableViewController
        {
            // Choose mailing list to send mailing to.
            destinationVC.container = container
            destinationVC.delegate = self
        } else if segue.identifier == "showEmailsToSend",
            let destinationVC = segue.destination as? MailsToSendTableViewController
        {
            destinationVC.mailsToSend = mailsToSend
        } else if segue.identifier == "editMailContent",
            let destinationVC = segue.destination as? MailingTextViewController
        {
            destinationVC.parentEditMode = self.editMode
            destinationVC.mailingTextViewControllerDelegate = self
            
            if let mailingDTO = mailingDTO {
                var editMailingDTO = MailingDTO(objectId: mailingDTO.objectId, title: mailingDTO.title, text: mailingDTO.text, folder: mailingDTO.folder)
                if let changedMailingText = changedMailingText {
                    editMailingDTO.text = changedMailingText
                }
                destinationVC.mailing = editMailingDTO
            }
        } else if segue.identifier == "showMailingAttachements",
            let destinationVC = segue.destination as? MailingAttachementsTableViewController
        {
            destinationVC.container = container
            destinationVC.delegate = self
            destinationVC.mailingDTO = self.mailingDTO
            destinationVC.parentEditMode = self.editMode
            
            if attachments == nil {
                initAttachedFiles()
            }
            destinationVC.attachments = attachments
        } else if segue.identifier == "showHtmlPreview",
            let destinationVC = segue.destination as? HtmlPreviewViewController {
        
            let text = getMailingText()
            destinationVC.htmlText = text
        }
    }
    
    private func initAttachedFiles() {
        guard let container = container else {
            return
        }
        guard var mailingDTO = mailingDTO else {
            return
        }
        
        if mailingDTO.folder == nil {
            let subfolderName = Mailing.generateSubFolderName()
            mailingDTO.folder = subfolderName
            self.mailingDTO!.folder = subfolderName
        }
        
        if let objectId = mailingDTO.objectId {
            // Init with list of attached files
            attachments = MailingAttachments(files: Mailing.getAttachedFiles(objectId: objectId, in: container.viewContext), subFolderName: mailingDTO.folder!)
        } else {
            // Init with empty list of attachements
            attachments = MailingAttachments(subFolderName: mailingDTO.folder!)
        }
    }
    
    // MARK: - TableView Delegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let section = MailingDetailViewSection(rawValue: section) {
            switch section {
            case .action:
                return 2
            default:
                return 1
            }
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let section = MailingDetailViewSection(rawValue: indexPath.section) {
            switch section {
            case .content:
                var containsText = false
                
                if let mailingDTO = mailingDTO,
                    let text = mailingDTO.text {
                    containsText = text.count > 0
                }
                
                if !containsText {
                    return 176
                }
            case .action:
                // Section for send and delete button.
                if indexPath.row == 0 {
                    // Delete button
                    if editMode && isEditType() {
                        // Only visible if view is in editMode for an existing mailing
                        return super.tableView(tableView, heightForRowAt: indexPath)
                    } else {
                        return 0
                    }
                } else if indexPath.row == 1 {
                    // Send button
                    if !editMode {
                        // Only visible if view is in readonly mode
                        return super.tableView(tableView, heightForRowAt: indexPath)
                    } else {
                        return 0
                    }
                }
            default:
                return super.tableView(tableView, heightForRowAt: indexPath)
            }
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let section = MailingDetailViewSection(rawValue: section) {
            switch section {
            case .title:
                return "Titel"
            case .content:
                return "Inhalt"
            default:
                return ""
            }
        }
        
        return ""
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == MailingDetailViewSection.title.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCell", for: indexPath) as! MailingTitleTableViewCell
            
            if let changedMailingTitle = changedMailingTitle {
                cell.mailingTitleTextField.text = changedMailingTitle
            } else {
                if let mailingDTO = mailingDTO {
                    cell.mailingTitleTextField.text = mailingDTO.title
                }
            }
            
            cell.mailingTitleTextField.isEnabled = editMode
            cell.mailingTitleTextField.delegate = self
            
            return cell
        } else if indexPath.section == MailingDetailViewSection.content.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContentCell", for: indexPath) as! MailingContentTableViewCell
            
            cell.contentLabel.text = getMailingText()
            cell.contentLabel.textColor = UIColor(white: 114/255, alpha: 1)
            cell.contentLabel.font = UIFont.preferredFont(forTextStyle: .body)
            
            return cell
        } else if indexPath.section == MailingDetailViewSection.attachement.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionFilesCell", for: indexPath)
            
            var detailText = ""
            if attachments == nil {
                initAttachedFiles()
            }
            
            if let attachments = attachments {
                let count = attachments.files.count
                if count > 0 {
                    detailText = String(count)
                }
            }
            cell.detailTextLabel?.text = detailText
            
            return cell
        } else if indexPath.section == MailingDetailViewSection.action.rawValue && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionDeleteCell", for: indexPath)
            
            return cell
        } else {
            // Section action, row 1
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionSendCell", for: indexPath)
            
            return cell
        }
    }
    
    /**
     Only allow selection for a few cells
     */
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let section = MailingDetailViewSection(rawValue: indexPath.section) {
            switch section {
            case .content:
                // Should be selectable to edit the mailing text
                return indexPath
            case .attachement:
                // Should be selectable to attach files
                return indexPath
            case .action:
                // Should be selectable to delete a mailing or send a mailing
                return indexPath
            default:
                return nil
            }
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let section = MailingDetailViewSection(rawValue: indexPath.section) {
            switch section {
            case .title:
                if editMode {
                    let cell = tableView.cellForRow(at: indexPath) as! MailingTitleTableViewCell
                    cell.mailingTitleTextField.becomeFirstResponder()
                }
            case .content:
                // Opens the edit view fot the mailing content
                performSegue(withIdentifier: "editMailContent", sender: nil)
            case .attachement:
                // Show attached files in separate view
                performSegue(withIdentifier: "showMailingAttachements", sender: nil)
            case .action:
                if indexPath.row == 0 {
                    // Delete mailing
                    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: "Mailing löschen", style: .default) { _ in
                        self.tableView.deselectRow(at: indexPath, animated: true)
                        self.deleteAction()
                    })
                    alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel) { _ in
                        // Do nothing
                    })
                    // The following 2 lines are needed for iPad.
                    alert.popoverPresentationController?.sourceView = view
                    if let cell = tableView.cellForRow(at: indexPath) {
                        alert.popoverPresentationController?.sourceRect = cell.frame
                    }
                    
                    present(alert, animated: true)
                } else if indexPath.row == 1 {
                    // Triggers sending this mailing as mail. First the mailing list has to be chosen.
                    performSegue(withIdentifier: "pickMailingList", sender: nil)
                }
            }
        }
    }
    
    // MARK:- UITextField Delegates
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        let oldText = textField.text!
        let stringRange = Range(range, in:oldText)!
        let newText = oldText.replacingCharacters(in: stringRange, with: string)
        viewEdited = !newText.isEmpty
        
        if textField.tag == 1 {
            changedMailingTitle = newText
        }
        
        return true
    }
    
    // MARK:- UITextView Delegates
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        viewEdited = true
        
        return true
    }
    
    // MARK: - MailingDetailViewController Delegate
    
    /**
     Protocol function. Called after canceled editing of an existing mailing.
     */
    func mailingDetailViewControllerDidCancel(_ controller: MailingDetailViewController) {
        editMode = false
        viewEdited = false
        
        changedMailingTitle = nil
        changedMailingText = nil
        attachments = nil
        cancelAttachmentChanges()
        
        if isEditType() {
            configureBarButtonItems()
            configureToolbar()
            tableView.reloadData()
        } else {
            navigationController?.popViewController(animated:true)
        }        
    }
    
    /**
     Protocol function. Called after finish editing a new Mailing
     Saves data to database and navigates back to caller view.
     */
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishAdding mailing: MailingDTO, attachementChanges: [MailingAttachmentChange]) {
        guard let container = container else {
            print("Save not possible. No PersistentContainer.")
            return
        }
        
        // Update database
        do {
            try Mailing.createOrUpdateFromDTO(mailingDTO: mailing, attachmentChanges: attachementChanges, in: container.viewContext)
            editMode = false
            viewEdited = false
            changedMailingText = nil
            changedMailingTitle = nil
            self.mailingAttachementChanges.removeAll()
        } catch {
            // TODO show Alert
        }
        
        navigationController?.popViewController(animated:true)
    }
    
    /**
     Protocol function. Called after finish editing an existing Mailing
     Saves data to database and stays in this view.
     */
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishEditing mailing: MailingDTO, attachementChanges: [MailingAttachmentChange]) {
        guard let container = container else {
            print("Save not possible. No PersistentContainer.")
            return
        }
        
        // Update database
        do {
            try Mailing.createOrUpdateFromDTO(mailingDTO: mailing, attachmentChanges: attachementChanges, in: container.viewContext)
            editMode = false
            viewEdited = false
            changedMailingText = nil
            changedMailingTitle = nil
            self.mailingAttachementChanges.removeAll()
        } catch {
            // TODO show Alert
        }
        configureBarButtonItems()
        configureToolbar()
        tableView.reloadData()
    }
    
    func mailingDetailViewController(_ controller: MailingDetailViewController, didFinishDeleting mailing: MailingDTO) {
    
        guard let container = container else {
            print("Delete not possible. No PersistentContainer.")
            return
        }
        
        // Update database
        do {
            try Mailing.deleteMailing(mailingDTO: mailing, in: container.viewContext)
            editMode = false
            viewEdited = false
            changedMailingText = nil
            changedMailingTitle = nil
        } catch {
            // TODO show Alert
        }
        
        navigationController?.popViewController(animated:true)
    }
    
    // MARK: - MailingListPickerTableViewController Delegate
    
    func mailingListPicker(_ picker: MailingListPickerTableViewController, didPickList chosenMailingLists: [MailingListDTO]) {
        // no implementation Only single
    }
    
    /**
     Called after mailing list was chosen. Send the selected mailing to the chosen mailing list.
     */
    func mailingListPicker(_ picker: MailingListPickerTableViewController, didPick chosenMailingList: MailingListDTO) {
        // Return from view
        navigationController?.popViewController(animated:true)
        
        // Get email addresses of mailing list
        guard let container = container else {
            return
        }
        
        let emailAddresses = MailingList.getEmailAddressesForMailingList(objectId: chosenMailingList.objectId!, in: container.viewContext)
        
        // Prepare mails to send
        if let mailingDTO = mailingDTO {
            if attachments == nil {
                initAttachedFiles()
            }
            
            let mailComposer = MailComposer(mailingDTO: mailingDTO, files: attachments!.files)
            mailsToSend = mailComposer.composeMailsToSend(emailAddresses: emailAddresses)
            if mailsToSend.count == 1 {
                // Show Mail view directly
                composeMail(mailsToSend[0])
            } else if mailsToSend.count > 1 {
                // The mailing needs to be send in more than one mail.
                // Display tableview to show the different mails.
                performSegue(withIdentifier: "showEmailsToSend", sender: nil)
            }
        }
    }
    
    // MARK: - MailingAttachementsTableViewController Delegate
    /**
     Called after changing file attachements in sub view.
     Takes the changes into the fileAttachementChanges list.
     If view is not in edit mode changes aaved directly.
     */
    func mailingFilesTableViewControllerDelegate(_ controller: MailingAttachementsTableViewController, didChangeAttachements attachedChanges: [MailingAttachmentChange]) {
        
        for i in 0 ..< attachedChanges.count {
            let mailingAttachementChange = attachedChanges[i]
            let mailingAttachementAlreadyChanged = self.mailingAttachementChanges.contains {$0.fileName == mailingAttachementChange.fileName}
            
            if !mailingAttachementAlreadyChanged {
                // no entry with the fileName exists in the change list -> add it
                self.mailingAttachementChanges.append(mailingAttachementChange)
            } else {
                // A change entry for this fileName already exists in the change list.
                if let existing = self.mailingAttachementChanges.first(where: { $0.fileName == mailingAttachementChange.fileName }) {
                    
                    if existing.action != mailingAttachementChange.action {
                        // The entry has a different action -> remove it from the change list.
                        if let index = self.mailingAttachementChanges.index(where: { $0.fileName == existing.fileName } ) {
                            self.mailingAttachementChanges.remove(at: index)
                            
                            if let attachments = attachments {
                                FileAttachmentHandler.removeFile(fileName: mailingAttachementChange.fileName, folderName: attachments.subfolderName)
                            }
                        }
                    }
                }
            }
        }
        
        if editMode {
            viewEdited = true
        } else {
            // View was not in edit mode. Save changes directly
            delegate?.mailingDetailViewController(self, didFinishEditing: mailingDTO!, attachementChanges: mailingAttachementChanges)
            initAttachedFiles()
        }
    }
    
    /**
     Removes all attachment changes.
     Also deletes files which are already copied to the mailing diretory.
     For newly created mailings the subfolder is also removed.
     */
    func cancelAttachmentChanges() {
        var subfolderName : String?
        
        for i in 0 ..< mailingAttachementChanges.count {
            let attachmentChange = mailingAttachementChanges[i]
            if attachmentChange.action == .added {
                FileAttachmentHandler.removeFile(fileName: attachmentChange.fileName, folderName: attachmentChange.folderName)
                subfolderName = attachmentChange.folderName
            }
        }
        
        mailingAttachementChanges.removeAll()
        
        if isAddType() {
            if let subfolderName = subfolderName {
                FileAttachmentHandler.removeFolder(folderName: subfolderName)
            }
        }
    }
    
    // MARK: - MailingTextViewController Delegate
    /**
     Called after finishing editing the mailing text
     */
    func mailingTextViewController(_ controller: MailingTextViewController, didFinishEditing mailing: MailingDTO) {
        if editMode {
            // This view is in edit mode. Take value and stay in edit mode
            self.changedMailingText = mailing.text
            viewEdited = true            
        } else {
            // This view is not in edit mode. Take value and save directly
            self.mailingDTO?.text = mailing.text
            
            guard let container = container else {
                print("Save not possible. No PersistentContainer.")
                return
            }
            
            // Update database
            do {
                try Mailing.createOrUpdateFromDTO(mailingDTO: mailing, in: container.viewContext)
                editMode = false
                viewEdited = false
                changedMailingText = nil
                changedMailingTitle = nil
            } catch {
                // TODO show Alert
            }
        }
        tableView.reloadData()
        configureToolbar()
    }
    
    // MARK: - Send mail
    
    func composeMail(_ mailDTO: MailDTO) {
        if MessageComposer.canSendText() {
            let mailComposeViewController = configuredMailComposeViewController(mailDTO: mailDTO)
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController(mailDTO: MailDTO) -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Set the mailComposeDelegate property to self
        
        MessageComposer.updateMailComposeViewController(mailComposerVC, mailDTO: mailDTO)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let alertController = UIAlertController(title: "Mail kann nicht gesendet werden", message: "Bitte E-Mail Einstellungen überprüfen und erneut versuchen.", preferredStyle: .alert)
        
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        controller.dismiss(animated: true, completion: nil)
    }
}
