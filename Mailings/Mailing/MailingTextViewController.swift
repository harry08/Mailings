//
//  MailingTextViewController.swift
//  Mailings
//
//  Created on 17.04.18.
//

import UIKit

protocol MailingTextViewControllerDelegate: class {
    func mailingTextViewController(_ controller: MailingTextViewController, didFinishEditing mailing: MailingDTO)
}

class MailingTextViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var textView: UITextView!
    
    /**
     Delegate to call after finish editing the mailing text.
     */
    weak var mailingTextViewControllerDelegate: MailingTextViewControllerDelegate?
    
    var mailing: MailingDTO?
    
    /**
     Controls the doneButton
     */
    var viewEdited = false {
        didSet {
            configureBarButtonItems()
        }
    }
    
    private func configureBarButtonItems() {
       // doneButton.isEnabled = viewEdited
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: Notification.Name.UIKeyboardWillHide, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
    }

    @objc func adjustForKeyboard(notification: Notification) {
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == Notification.Name.UIKeyboardWillHide {
            textView.contentInset = UIEdgeInsets.zero
        } else {
            textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }
        
        textView.scrollIndicatorInsets = textView.contentInset
        
        let selectedRange = textView.selectedRange
        textView.scrollRangeToVisible(selectedRange)
    }
    
    // TODO Richtige Action
    func doneEditingAction() {
        if let mailing = mailing {
            mailingTextViewControllerDelegate?.mailingTextViewController(self, didFinishEditing: mailing)
            
            navigationController?.popViewController(animated:true)
        }
    }
    
    // MARK:- UITextView Delegates
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        viewEdited = true
        
        return true
    }
}
