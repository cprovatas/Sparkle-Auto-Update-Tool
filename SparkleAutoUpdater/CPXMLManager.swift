//
//  CPXMLManager.swift
//  SparkleAutoUpdater
//
//  Created by Charlton Provatas on 7/5/17.
//  Copyright © 2017 Charlton Provatas. All rights reserved.
//

import Foundation
import SwiftyXML

final class CPXMLManager {
    
    /// adds an item to app cast file and removes the last item if it exists
    public class func editUpdateNotes(forXMLFileatURL url: URL, versionSet: CPFileManagerVersionSet, publicZipURL: URL, dsaSignature: String, updateNotes: String) throws {
        do {
            
            guard let contents = XML(url: url), contents.children.first != nil else {
                throw CPXMLManagerError.parseError
            }
            guard let lastItemIndex = indexOfLastXMLAppcastItem(inParentElementsChildren: contents.children.first!.children) else {
                throw CPXMLManagerError.noItemsFound
            }
            
            let newItem = contents.children.first!.children.remove(at: lastItemIndex).copied()
            
            newItem.children[0].value = "Version \(versionSet.0)"
            newItem.children[1].value = nil
            newItem.children[1].value = htmlFormattedUpdateNotes(updateNotes)
            newItem.children[3].attributes["sparkle:dsaSignature"] = dsaSignature
            newItem.children[3].attributes["sparkle:version"] = versionSet.1
            newItem.children[3].attributes["sparkle:shortVersionString"] = versionSet.0
            newItem.children[3].attributes["url"] = publicZipURL.absoluteString
            contents.children.first!.children.insert(newItem, at: 0)
            
            try contents.toXMLString().write(to: url, atomically: true, encoding: .ascii)
            
        }catch let error {
            throw error
        }
    }
    
    private class func indexOfLastXMLAppcastItem(inParentElementsChildren children: [XML]) -> Int? {
        for i in 0..<children.count {
            if children[i].children.count < 1, i > 0 {
                return i - 1
            }
        }
        return nil
    }
    
    private class func htmlFormattedUpdateNotes(_ updateNotes: String) -> String {
        let htmlFormattedUpdates = updateNotes.components(separatedBy: "\n").map({ "<li>\($0)</li>" }).joined()
        return "<![CDATA[ <h3>Update</h3><p>Contains:</p><ul>\(htmlFormattedUpdates)</ul>]]>"
    }
    
}

enum CPXMLManagerError : String, Error, LocalizedError {
    case parseError = "Error parsing appcast file.  There must be at least one item already (we can add support for this later)"
    case noItemsFound = "No items found in appcast file.  At least one item must be present"
    var errorDescription: String? {
        return rawValue
    }
}
