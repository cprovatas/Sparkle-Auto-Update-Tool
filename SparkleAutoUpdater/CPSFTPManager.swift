//
//  CPFTPManager.swift
//  SparkleAutoUpdater
//
//  Created by Charlton Provatas on 7/3/17.
//  Copyright © 2017 Charlton Provatas. All rights reserved.
//

import Foundation
final class CPSFTPManager {
    
    ///it stopped working here
    /// completion returns bool success or fail
    public static func uploadFile(atFileURL fileURL: URL, toRemoteURL remoteURL: URL, username: String, password: String, host: String) throws {
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw CPSFTPManagerError.fileDoesNotExist
        }
        
        var remoteURLPath = "/var/www/html\(remoteURL.escapingSpaces.path)"
        if remoteURLPath.last == "/" { remoteURLPath = String(remoteURLPath.dropLast()) }
        
        guard let firstCommandSubstring = _getCommandSubstring(username: username, password: password, host: host) else {
            throw CPSFTPManagerError.errorFindingSSHPassFile
        }
        let commandString = firstCommandSubstring + " <<< $'put \(fileURL.escapingSpaces.path) \(remoteURLPath)'"
        guard let output = CPProcessWrapper.launch(withRawInput: commandString),
            output.contains("sftp> put \(fileURL.escapingSpaces.path) \(remoteURLPath)") else {
                throw CPSFTPManagerError.noSuccessOutputFound
        }
    }
    
    /// completion returns url of downloaded file if successful
    /// renames to proper extension
    public static func downloadFile(fromRemoteURL url: URL, username: String, password: String, host: String) throws -> URL {
        let remoteURLPath = "/var/www/html\(url.escapingSpaces.path)"
        guard let firstCommandSubstring = _getCommandSubstring(username: username, password: password, host: host) else {
            throw CPSFTPManagerError.errorFindingSSHPassFile
        }
        let commandString = firstCommandSubstring + " <<< $'get \(remoteURLPath)'"
        
        guard let output = CPProcessWrapper.launch(withRawInput: commandString),
            output.contains("sftp> get \(remoteURLPath)") else {
                throw CPSFTPManagerError.noSuccessOutputFound
        }
        
        return Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent(url.lastPathComponent)
    }
    
    private static func _getCommandSubstring(username: String, password: String, host: String) -> String? {
        guard let sshPassPath = Bundle(for: CPFileManager.self).path(forResource: "sshpass", ofType: nil) else { return nil }
        return "\(sshPassPath) -p \(password) sftp \(username)@\(host)"
    }
}

enum CPSFTPManagerError: String, Error, LocalizedError {
    case appCastNotFound = "App cast file not found at sftp directory specified.  Please upload an appcast file"
    case errorFindingSSHPassFile = "Error finding SSHPass executable.  Check project structure!"
    case fileDoesNotExist = "No such file or directory"
    case noSuccessOutputFound = "No successful output was found"
    var errorDescription: String? {
        return rawValue
    }
}
