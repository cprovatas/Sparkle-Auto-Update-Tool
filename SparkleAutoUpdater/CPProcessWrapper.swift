//
//  CPProcessWrapper.swift
//  SparkleAutoUpdater
//
//  Created by Charlton Provatas on 12/15/17.
//  Copyright © 2017 Charlton Provatas. All rights reserved.
//

import Foundation

enum CPProcessWrapperError: String, Error, LocalizedError {
    case errorParsingResult = "Error parsing string result"
    var errorDescription: String? {
        return rawValue
    }
}

public typealias CPProcessWrapperResult = (String?, Error?) -> Void
final class CPProcessWrapper {
    
    static var stdOutputCompletion: CPProcessWrapperResult?
    
    public class func launch(withLaunchPath launchPath: String, arguments: [String], currentDirectoryPath path: String? = nil, _ completion: @escaping CPProcessWrapperResult) {
                        
        stdOutputCompletion = completion
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        NotificationCenter.default.addObserver(self, selector: #selector(readOutput(_:)), name: .NSFileHandleDataAvailable, object: pipe.fileHandleForReading)
        pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        task.launch(withArguments: arguments, currentDirectoryPath: path, launchPath: launchPath)
    }
    
    public class func launch(withRawInput input: String, _ completion: @escaping CPProcessWrapperResult) {
        launch(withLaunchPath: "/bin/sh", arguments: ["-c", input], completion)
    }
    
    @objc private class func readOutput(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self, name: .NSFileHandleDataAvailable, object: nil)
        guard let fileHandle = notification.object as? FileHandle else { return }
        
        if let result = String(data: fileHandle.availableData, encoding: .utf8) {
            stdOutputCompletion?(result.replacingOccurrences(of: "\n", with: ""), nil)
        } else {
            stdOutputCompletion?(nil, CPProcessWrapperError.errorParsingResult)
        }
    }
}
