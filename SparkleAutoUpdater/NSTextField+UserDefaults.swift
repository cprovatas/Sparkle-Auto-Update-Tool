//
//  NSTextField+UserDefaults.swift
//  SparkleAutoUpdater
//
//  Created by Charlton Provatas on 7/2/17.
//  Copyright © 2017 Charlton Provatas. All rights reserved.
//

import Foundation
import Cocoa

/** Summary:
     Allows persistent storage to default preference values to NSTextField, NSSecureTextField, and NSTextView
 */

class CPCodingTextField : NSTextField {
    
    override var stringValue: String {        
        didSet {
            UserDefaults.standard.set(stringValue, forKey: key)
        }
    }                    
    
    @objc private var key: String! {
        didSet {
            stringValue = UserDefaults.standard.value(forKey: key) as? String ?? ""
        }
    }
    
    override func textDidChange(_ notification: Notification) {
        UserDefaults.standard.set(stringValue, forKey: key)
    }
    
}

class CPCodingSecureTextField : NSSecureTextField {
    
    override var stringValue: String {
        didSet {
            UserDefaults.standard.set(stringValue, forKey: key)
        }
    }
    
    @objc private var key : String! {
        didSet {
            stringValue = UserDefaults.standard.value(forKey: key) as? String ?? ""
        }
    }
    
    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        UserDefaults.standard.set(stringValue, forKey: key)
    }
}

class CPCodingTextView : NSTextView {
    
    override var string: String {
        didSet {
            UserDefaults.standard.set(string, forKey: key)
        }
    }
    
    @objc private var key : String! {
        didSet {
            string = UserDefaults.standard.value(forKey: key) as? String ?? ""
        }
    }
    
    override func didChangeText() {
        super.didChangeText()
        UserDefaults.standard.set(string, forKey: key)
    }
}
