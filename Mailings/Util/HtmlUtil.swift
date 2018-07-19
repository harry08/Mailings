//
//  HtmlUtil.swift
//  Mailings
//
//  Created on 18.07.18.
//

import Foundation

class HtmlUtil {
    
    class func isHtml(_ text: String) -> Bool {
        let containsHtmlTags = text.contains("<html") && text.contains("<body")
        
        return containsHtmlTags
    }
}
