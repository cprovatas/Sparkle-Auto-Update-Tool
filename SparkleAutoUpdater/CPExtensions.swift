//
//  CPExtensions.swift
//  SparkleAutoUpdater
//
//  Created by Charlton Provatas on 7/2/17.
//  Copyright © 2017 Charlton Provatas. All rights reserved.
//

import Foundation
import Cocoa

public extension NSView {
    public func presentAlert(_ message: String? = nil, retryButtonText: String? = nil, retryHandler: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self._presentAlert(message, retryButtonText: retryButtonText, retryHandler: retryHandler)
        }
    }
    
    private func _presentAlert(_ message: String? = nil, retryButtonText: String? = nil, retryHandler: (() -> Void)? = nil) {
        if window == nil {
            Swift.print("\(self.self) Error Function '\(#function)' Line: \(#line) No window found.")
            return
        }
        
        let alert = NSAlert()
        alert.messageText = message ?? ""
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Cancel")
        if retryHandler != nil {
            alert.addButton(withTitle: retryButtonText ?? "Retry")
        }
        if window == nil { return }
        alert.beginSheetModal(for: window ?? NSWindow()) { (response) in
            
            if response != .alertFirstButtonReturn {
                retryHandler?()
                if self.window != nil {
                    self.window!.endSheet(self.window!)
                }
            }
            
            NSApp.stopModal() /// this may have fixed some sporadic crashes we were getting w/ nsalert
        }
    }
}

public extension Process {
    public func launch(withArguments args: [String], currentDirectoryPath: String, launchPath: String) {
        arguments = args
        self.currentDirectoryPath = currentDirectoryPath
        self.launchPath = launchPath
        launch()
        waitUntilExit()
    }
}

