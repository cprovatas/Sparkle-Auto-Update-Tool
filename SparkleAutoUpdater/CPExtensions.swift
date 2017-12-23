//
//  CPExtensions.swift
//  SparkleAutoUpdater
//
//  Created by Charlton Provatas on 7/2/17.
//  Copyright © 2017 Charlton Provatas. All rights reserved.
//

import Foundation
import Cocoa
import SwiftyXML

private let formatter: DateFormatter = DateFormatter()
public extension Process {
    public func launch(withArguments args: [String], currentDirectoryPath: String? = nil, launchPath: String) {
        arguments = args
        if let currentDirectoryPath = currentDirectoryPath {
            self.currentDirectoryPath = currentDirectoryPath
        }
        self.launchPath = launchPath
        launch()
        waitUntilExit()
    }
}

extension Date {
    func string(withFormat format: String) -> String {
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

extension String: Error, LocalizedError {
    public var errorDescription: String? {
        return self
    }
}

extension URL {
    public var escapingSpaces: URL {
        let aPath = path.replacingOccurrences(of: " ", with: "\\ ")
        return URL(fileURLWithPath: aPath)
    }
}

extension Collection {
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

