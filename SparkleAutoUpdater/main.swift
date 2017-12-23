//
//  ViewController.swift
//  SparkleAutoUpdater
//
//  Created by Charlton Provatas on 7/2/17.
//  Copyright © 2017 Charlton Provatas. All rights reserved.
//

import Cocoa

public func run() {
    do {
        try _SparkleAutoUpdater().executeProcess()
    } catch let error {
        _SparkleAutoUpdater.updateStatus(error.localizedDescription)
    }
}

private struct _Config: Decodable {
    let appBundlePath: String
    let dsaPrivPath: String
    let httpUpdatesFolderPath: String
    let appcastFileName: String
    let sftpUsername: String
    let sftpPassword: String
    let updateNotes: String
}

final private class _SparkleAutoUpdater: Decodable {
    /// TODO: spaces don't work
    /// TODO: see if you can add comments into json
    private let config: _Config
    private let publicPathURL: URL
    private let host: String
    
    init() {
        do {
            let bundle = Bundle(for: _SparkleAutoUpdater.self)
            guard let configPath = bundle.path(forResource: "config", ofType: "json") else {
                fatalError("config.json not found!, check framework bundle!")                
            }
            let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
            config = try JSONDecoder().decode(_Config.self, from: data)
            guard let publicPathURL = URL(string: config.httpUpdatesFolderPath), let host = publicPathURL.host else {
                fatalError("Invalid update path or host")
            }
            self.publicPathURL = publicPathURL
            self.host = host
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    public func executeProcess() throws {
        
        /// Input validation, if fields are empty etc...
        /// open .app and update version
        _SparkleAutoUpdater.updateStatus("Updating version number...")
        let versionSet = try CPFileManager.updateVersionNumber(forAppAtPath: config.appBundlePath)
        /// quarantine app from gatekeeper
        _SparkleAutoUpdater.updateStatus("Quarantining App...")
        CPFileManager.quarantine(appAtPath: config.appBundlePath)
        /// compress .app to zip
        _SparkleAutoUpdater.updateStatus("Zipping and renaming app...")
        let zipURL = try CPFileManager.zip(folderAtPath: config.appBundlePath, displayVersion: versionSet.0)
        /// generate key from .priv file
        _SparkleAutoUpdater.updateStatus("Fetching DSA Key...")
        
        guard let signature = try CPFileManager.getSignature(forZipAtURL: zipURL, pathOfDSAKeyFile: config.dsaPrivPath) else { throw "Unable to fetch signature!" }
        /// upload .zip
        _SparkleAutoUpdater.updateStatus("Uploading Zip...")
        try CPSFTPManager.uploadFile(atFileURL: zipURL, toRemoteURL: publicPathURL, username: config.sftpUsername, password: config.sftpPassword, host: host)
        _SparkleAutoUpdater.updateStatus("Downloading App Cast File...")
        let remoteAppcastURL = publicPathURL.appendingPathComponent(config.appcastFileName)
        /// download .appcast
        let localAppcastURL = try CPSFTPManager.downloadFile(fromRemoteURL: remoteAppcastURL, username: config.sftpUsername, password: config.sftpPassword, host: host)
        ///  edit app cast
        _SparkleAutoUpdater.updateStatus("Updating App Cast File...")
        let aZipURL = publicPathURL.appendingPathComponent(zipURL.lastPathComponent)
        try CPXMLManager.editUpdateNotes(forXMLFileAtURL: localAppcastURL, versionSet: versionSet, publicZipURL: aZipURL, dsaSignature: signature, updateNotes: config.updateNotes)
        _SparkleAutoUpdater.updateStatus("Uploading App Cast File...")
        try CPSFTPManager.uploadFile(atFileURL: localAppcastURL, toRemoteURL: remoteAppcastURL, username: config.sftpUsername, password: config.sftpPassword, host: host)
        /// Clean up
        _SparkleAutoUpdater.updateStatus("Cleaning up...")
        try FileManager.default.removeItem(at: zipURL)
        try FileManager.default.removeItem(at: localAppcastURL)
        _SparkleAutoUpdater.updateStatus("Success! 🎊")
    }
    
    static func updateStatus(_ status: String) {
        print("\(Date().string(withFormat: "YYYY-M-d h:mm:s")) <Notice> [SparkleAutoUpdater] - \(status)")
    }
}
