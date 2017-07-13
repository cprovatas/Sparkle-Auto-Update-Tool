//
//  CPFTPManager.swift
//  SparkleAutoUpdater
//
//  Created by Charlton Provatas on 7/3/17.
//  Copyright © 2017 Charlton Provatas. All rights reserved.
//

import Foundation
import rebekka
typealias CPFTPManagerResult = (Any?, Error?) -> Void
final class CPFTPManager {
    
    public static let shared : CPFTPManager = .init()
    public var firstXMLFileName : String! = ""
    private var _session : Session!
    private var _ftpURL : URL!
    
    
    /// completion contains bool that connection was successful
    /// otherwise error
    public func startConnection(withURL url: URL, username: String, password: String, _ completion: @escaping CPFTPManagerResult) {
        var config = SessionConfiguration()
        config.host = url.absoluteString
        config.username = username
        config.password = password
        _ftpURL = url
        _session = Session(configuration: config)
        _session.list("/") { (items, error) in
            if error != nil {
                completion(items != nil, error)
            }else if let items = items {
                if let firstXMLFileName = self.firstXMLFile(items) {
                    self.firstXMLFileName = firstXMLFileName
                    completion(true, nil)
                }else {
                    completion(nil, CPFTPManagerError.appCastNotFound)
                }
            }
        }
    }
    ///it stopped working here
    /// completion returns bool success or fail
    public func uploadFile(atURL url: URL, _ completion: @escaping CPFTPManagerResult) {
        
        _session.upload(url, path: url.lastPathComponent) { (result, error) in
            completion(result, error)
        }
    }
    
    /// completion returns url of downloaded file if successful
    /// renames to proper extension
    public func downloadAppCastFile(_ completion: @escaping CPFTPManagerResult) {
        _session.download(firstXMLFileName) { (url, error) in
            if let url = url {
                do {
                    let newURL = try CPFileManager.rename(fileAtURL: url, toFileName: "sampleAppCast\(arc4random_uniform(100000000)).xml")
                    completion(newURL, nil)
                }catch let error {
                    completion(nil, error)
                }
            }else {
                completion(nil, error)
            }
        }
    }
    
    /// returns name of first xml file in directory
    private func firstXMLFile(_ files: [ResourceItem]) -> String? {
        for file in files {
            if (file.path as NSString).pathExtension.lowercased() == "xml"  {
                return (file.path as NSString).lastPathComponent
            }
        }
        return nil
    }
}

enum CPFTPManagerError : String, Error, LocalizedError {
    case appCastNotFound = "App cast file not found at ftp directory specified.  Please upload an appcast file"
    var errorDescription: String? {
        return rawValue
    }
}

