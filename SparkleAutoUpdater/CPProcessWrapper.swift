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

final private class _OutputReader: NSObject {
    public var output: String?
    
    @objc func readOutput(_ notification: Notification) {
        
        guard let fileHandle = notification.object as? FileHandle else { return }
        
        if let result = String(data: fileHandle.availableData, encoding: .utf8) {
            if output == nil { output = "" }
            output! += result.replacingOccurrences(of: "\n", with: "")
        }
    }
}

final class CPProcessWrapper: Process {
    
    /// returns output if exists
    static func launch(withLaunchPath launchPath: String, arguments: [String], currentDirectoryPath path: String? = nil) -> String? {
        
        let task = Process()
        let pipe = Pipe()
        let outputReader = _OutputReader()
        
        task.standardOutput = pipe
        
        NotificationCenter.default.addObserver(outputReader, selector: #selector(outputReader.readOutput(_:)), name: .NSFileHandleDataAvailable, object: pipe.fileHandleForReading)
        pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        task.terminationHandler = { process in
            dispatchGroup.leave()
        }
        task.launch(withArguments: arguments, currentDirectoryPath: path, launchPath: launchPath)
        _ = dispatchGroup.wait(timeout: .distantFuture)
        return outputReader.output
    }
    
    /// returns string output if it exists
    public static func launch(withRawInput input: String) -> String? {
        return CPProcessWrapper.launch(withLaunchPath: "/bin/sh", arguments: ["-c", input])
    }
}
