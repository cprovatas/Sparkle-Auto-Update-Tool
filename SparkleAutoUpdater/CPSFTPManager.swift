//
//  CPFTPManager.swift
//  SparkleAutoUpdater
//
//  Created by Charlton Provatas on 7/3/17.
//  Copyright © 2017 Charlton Provatas. All rights reserved.
//

import Foundation

typealias CPSFTPManagerResult = (Any?, Error?) -> Void
final class CPSFTPManager {
    
    ///it stopped working here
    /// completion returns bool success or fail
    public static func uploadFile(atFileURL fileURL: URL, toRemoteURL remoteURL: URL, username: String, password: String, host: String, _ completion: @escaping CPSFTPManagerResult) {
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return completion(nil, CPSFTPManagerError.fileDoesNotExist)
        }
        
        do {
            let firstCommandSubstring = try _getCommandSubstring(username: username, password: password, host: host)
            let commandString = firstCommandSubstring + " <<< $'put '\(fileURL.escapingSpaces.path)' '\(remoteURL.escapingSpaces.path)''"
            
            CPProcessWrapper.launch(withRawInput: commandString) { (output, error) in
                let isSuccess = (output ?? "").contains("Uploading \(fileURL.path) to \(remoteURL.path)")
                completion(isSuccess, error)
            }
        } catch let error {
            return completion(nil, error)
        }
    }
    
    /// completion returns url of downloaded file if successful
    /// renames to proper extension
    public static func downloadAppCastFile(_ completion: @escaping CPSFTPManagerResult) {
        
    }
    
    private static func _getCommandSubstring(username: String, password: String, host: String) throws -> String {
        guard let sshPassPath = Bundle.main.path(forResource: "sshpass", ofType: nil) else {
            throw CPSFTPManagerError.errorFindingSSHPassFile
        }
        
        return "\(sshPassPath) -p \(password) sftp \(username)@\(host)"
    }
}

enum CPSFTPManagerError: String, Error, LocalizedError {
    case appCastNotFound = "App cast file not found at sftp directory specified.  Please upload an appcast file"
    case errorFindingSSHPassFile = "Error finding SSHPass executable.  Check project structure!"
    case fileDoesNotExist = "No such file or directory"
    var errorDescription: String? {
        return rawValue
    }
}
