//
//  CPFileManager.swift
//  SparkleAutoUpdater
//
//  Created by Charlton Provatas on 7/2/17.
//  Copyright © 2017 Charlton Provatas. All rights reserved.
//

import Foundation
import Security

public enum CPFileManagerError : String, Error, LocalizedError {
    
    case fileNotFound = "Info.plist or a subdirectory of it was not found. Check app path directory"
    case plistInInvalidFormat = "Info.plist was not in a readable format."
    case bundleVersionNotFound = "Bundle Version was not found in Info.plist. Please create those keys in Xcode"
    case failureZippingFile = "Unknown Failure zipping File"
    case dsaKeyFileNotFound = "Couldn't find DSA Key File"
    case codeResourcesNotFound = "Failed to locate code resources file"
    case codeResourcesInvalidFormat = "Code resources is in an invalid format"
    case errorFindingExecutable = "Error locating path of executable"
    
    public var errorDescription: String? {
        return rawValue
    }
}

/// tuple representing build version and display version
public typealias CPFileManagerVersionSet = (String, String)
final class CPFileManager {
    
    private static let fm : FileManager = .default
    
    public class func updateVersionNumber(forAppAtPath path: String) throws -> CPFileManagerVersionSet {
        
        let url = URL(fileURLWithPath: path)
        let infoPlistURL = url.appendingPathComponent("Contents").appendingPathComponent("Info.plist")
        
        guard fm.fileExists(atPath: infoPlistURL.path) else {
            throw CPFileManagerError.fileNotFound
        }
        
        do {
            
            let aPlist = try plist(forURL: infoPlistURL)
            guard let bundleBuildVersionString = (aPlist.value(forKey: "CFBundleShortVersionString") as? NSString)?.floatValue,
                  let bundleVersionString = (aPlist.value(forKey: "CFBundleVersion") as? NSString)?.floatValue else {
                throw CPFileManagerError.bundleVersionNotFound
            }
            
            let newDisplayVersionString = "\(bundleBuildVersionString + 0.1)"
            let newBundleVersionString = "\(bundleVersionString + 0.1)"
            
            let task = Process()
            task.launch(withArguments: ["write", infoPlistURL.deletingPathExtension().lastPathComponent, "CFBundleVersion", newBundleVersionString],
                        currentDirectoryPath: infoPlistURL.deletingLastPathComponent().path,
                        launchPath: "/usr/bin/defaults")
            let task2 = Process()
            task2.launch(withArguments: ["write", infoPlistURL.deletingPathExtension().lastPathComponent, "CFBundleShortVersionString", newDisplayVersionString],
                        currentDirectoryPath: infoPlistURL.deletingLastPathComponent().path,
                        launchPath: "/usr/bin/defaults")
            
            return (newDisplayVersionString, newBundleVersionString)
        }catch let error {
            throw error
        }                
    }
    
    /// returns url of new zip file
    public class func zip(folderAtPath path: String, displayVersion: String) throws -> URL {
        
        let zippedURL = URL(fileURLWithPath: "\(path)\(displayVersion)").appendingPathExtension("zip")
        
        let task = Process()
        task.launch(withArguments: ["-r", "-q", zippedURL.lastPathComponent, (path as NSString).lastPathComponent],
                    currentDirectoryPath: URL(fileURLWithPath: path).deletingLastPathComponent().path,
                    launchPath: "/usr/bin/zip")
        
        guard fm.fileExists(atPath: zippedURL.path) else {
            throw CPFileManagerError.failureZippingFile
        }
        
        return zippedURL
    }
    
    /// returns new url
    public class func rename(fileAtURL url: URL, toFileName name: String) throws -> URL {
        let lastComponent = (name as NSString).lastPathComponent
        let newURL = url.deletingLastPathComponent().appendingPathComponent(lastComponent)
        do {
            if fm.fileExists(atPath: newURL.path) {
                Swift.print("\(self.self) Note Function: '\(#function)' Line \(#line).  file: \(newURL.lastPathComponent) already exists. deleting..")
                try fm.removeItem(atPath: newURL.path)
            }
            try fm.moveItem(at: url, to: newURL)
            return newURL
        }catch let error {
            throw error
        }
    }
    
    public class func getSignature(forZipAtURL url: URL, pathOfDSAKeyFile path: String, _ completion: @escaping CPProcessWrapperResult) {
        
        guard let binaryPath = Bundle.main.path(forResource: "sign_update", ofType: nil) else {
            return completion(nil, CPFileManagerError.errorFindingExecutable)
        }
        guard fm.fileExists(atPath: path) else {
            return completion(nil, CPFileManagerError.dsaKeyFileNotFound)
        }
        
        CPProcessWrapper.launch(withLaunchPath: binaryPath, arguments: [url.lastPathComponent, path], currentDirectoryPath: url.deletingLastPathComponent().path, completion)
    }
    
    private class func plist(forURL url: URL) throws -> NSMutableDictionary {
        do {
            let data = try Data(contentsOf: url)
            guard let plist = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? NSMutableDictionary else {
                throw CPFileManagerError.plistInInvalidFormat
            }
            return plist
        }catch let error {
            throw error
        }
    }
}
