//
//  ViewController.swift
//  SparkleAutoUpdater
//
//  Created by Charlton Provatas on 7/2/17.
//  Copyright © 2017 Charlton Provatas. All rights reserved.
//

import Cocoa

fileprivate extension Int {
    fileprivate static let appPathTextFieldTag = 0
}

final class CPMainViewController : NSViewController {
    
    @IBOutlet private weak var progressTextField: NSTextField!
    @IBOutlet private weak var progressIndicator: NSProgressIndicator!
    @IBOutlet private weak var appPathTextField: CPCodingTextField!
    @IBOutlet private weak var dsaPrivateKeyTextField: CPCodingTextField!
    @IBOutlet private weak var pathToUpdatesTextField: CPCodingTextField!
    @IBOutlet private weak var publicPathToUpdatesTextField: CPCodingTextField!
    @IBOutlet private weak var sftpUsernameTextField: CPCodingTextField!
    @IBOutlet private weak var sftpPasswordTextField: CPCodingSecureTextField!
    @IBOutlet private var updateNotesTextView: CPCodingTextView!
    /// is set only when it is clicked
    private var updateButton : NSButton? = nil
    
    @IBAction private func plusClicked(_ sender: NSButton) {
        
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.beginSheetModal(for: view.window!) { (response) in
            
            guard response == .OK, let urlString = openPanel.url?.path else {
                return Swift.print("\(self.self) Error Function: '\(#function)' Line \(#line).  Couldn't get url from open panel")
            }
            let textField = sender.tag == .appPathTextFieldTag ? self.appPathTextField : self.dsaPrivateKeyTextField
            textField!.stringValue = urlString
        }
    }
    
    private func fail(_ message: String) {
        view.presentAlert(message)
        updateStatus("")
        DispatchQueue.main.async {
            self.progressIndicator.isHidden = true
            self.updateButton!.isEnabled = true
            self.updateButton!.alphaValue = 1
        }
    }
    
    /// only fires completion on success, wrapper for upload function
    private func uploadFile(atURL url: URL, _ completion: @escaping () -> Void) {
        guard let publicPathURL = URL(string: publicPathToUpdatesTextField.stringValue),
            let host = publicPathURL.host,
            let remoteURL = URL(string: pathToUpdatesTextField.stringValue) else {
                return debugPrint("Unable to get host for url \(url)")
        }
        
        CPSFTPManager.uploadFile(atFileURL: url,
                                 toRemoteURL: remoteURL,
                                 username: sftpUsernameTextField.stringValue,
                                 password: sftpPasswordTextField.stringValue,
                                 host: host) { (success, error) in
            
            if let success = success as? Bool, success {
                return completion()
            }
            if let error = error {
                return self.fail(error.localizedDescription)
            }
            self.fail("File at url '\(url)' failed to upload 😭")
        }
    }
    
    /// only fires completion if successful, wrapper for download function
    private func downloadAppcast(_ completion: @escaping (URL) throws -> Void) {
        CPSFTPManager.downloadAppCastFile({ (url, error) in
            if let url = url as? URL {
                do {
                    try completion(url)
                }catch let error {
                    self.fail(error.localizedDescription)
                }
            }else if let error = error {
                self.fail(error.localizedDescription)
            }
        })
    }
    
    @IBAction private func updateClicked(_ sender: NSButton) {
        updateButton = sender
        sender.isEnabled = false
        sender.alphaValue = 0.5
        DispatchQueue.global(qos: .background).async {
            self.executeProcess()
        }
    }
    
    private func executeProcess() {
        let appPath = appPathTextField.stringValue
        let dsaPath = dsaPrivateKeyTextField.stringValue
        do {

            guard let publicPathURL = URL(string: publicPathToUpdatesTextField.stringValue) else {
                throw CPMainViewControllerError.invalidUpdatePath
            }

            /// 1 - Input validation, if fields are empty etc...
            /// 2 - open .app and update version
            updateStatus("Updating version number...")
            let versionSet = try CPFileManager.updateVersionNumber(forAppAtPath: appPath)
            /// 3 - compress .app to zip
            /// 4 - rename .zip
            updateStatus("Zipping and renaming app...")
            let zipURL = try CPFileManager.zip(folderAtPath: appPath, displayVersion: versionSet.0)
            /// 5 - generate key from .priv file
            updateStatus("Fetching DSA Key...")
            CPFileManager.getSignature(forZipAtURL: zipURL, pathOfDSAKeyFile: dsaPath, { (signature, error) in
                if let error = error {
                   return self.fail(error.localizedDescription)
                }
                if let signature = signature {
                    /// 7 - upload .zip
                    self.updateStatus("Uploading Zip...")
                    self.uploadFile(atURL: zipURL, {
                        self.updateStatus("Downloading App Cast File and renaming...")
                        /// 8 - download .appcast and rename to .xml
                        self.downloadAppcast({ (url) in
                            /// 9 edit app cast
                            self.updateStatus("Updating App Cast File...")
                            let notes = self.updateNotesTextView.string

                            let zipURL = publicPathURL.appendingPathComponent(zipURL.lastPathComponent)
                            try CPXMLManager.editUpdateNotes(forXMLFileatURL: url, versionSet: versionSet, publicZipURL: zipURL, dsaSignature: signature, updateNotes: notes)
                            //let appCastName = CPFTPManager.shared.firstXMLFileName
                            let appCastName = "Testingitout.xml"
                            let renamedURL = try CPFileManager.rename(fileAtURL: url, toFileName: appCastName)

                            self.updateStatus("Uploading App Cast File...")
                            self.uploadFile(atURL: renamedURL, { self.finish() })
                        })
                    })
                }
            })
            
        } catch let error {
            view.presentAlert(error.localizedDescription)
        }
    }
    
    private func finish() {
        updateStatus("Success!")
        DispatchQueue.main.async {
            self.progressIndicator.isHidden = true
            self.updateButton?.isEnabled = true
            self.updateButton?.alphaValue = 1
        }
    }
    
    private func updateStatus(_ str: String) {
        DispatchQueue.main.async {
            if self.progressIndicator.isHidden {
                self.progressIndicator.isHidden = false
                self.progressIndicator.startAnimation(nil)
            }
            self.progressTextField.stringValue = str
        }
    }
}

enum CPMainViewControllerError : String, Error, LocalizedError {
    case invalidUpdatePath = "Invalid update path, Couldn't construct URL"
    var errorDescription: String? {
        return rawValue
    }
}
