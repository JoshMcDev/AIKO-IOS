import Foundation
import SwiftUI

/// Protocol for platform-agnostic sharing functionality
public protocol ShareServiceProtocol: Sendable {
    /// Share items using the platform's native sharing mechanism
    /// - Parameters:
    ///   - items: Array of items to share (strings, URLs, etc.)
    ///   - completion: Optional completion handler
    func share(items: [Any], completion: ((Bool) -> Void)?)
    
    /// Creates a shareable file from text content
    /// - Parameters:
    ///   - text: The text content to save
    ///   - fileName: The desired file name
    /// - Returns: URL of the created file if successful
    func createShareableFile(from text: String, fileName: String) throws -> URL
}

// Default implementation for file creation
public extension ShareServiceProtocol {
    func createShareableFile(from text: String, fileName: String) throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try text.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
}

/// Share service errors
public enum ShareServiceError: LocalizedError {
    case notAvailable
    case cancelled
    case failed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Share service is not available"
        case .cancelled:
            return "Share operation was cancelled"
        case .failed(let error):
            return "Share failed: \(error.localizedDescription)"
        }
    }
}