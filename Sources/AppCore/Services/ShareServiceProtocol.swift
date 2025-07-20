import Foundation
import SwiftUI

/// Sendable wrapper for shareable items to resolve Swift 6 concurrency issues
/// Following VanillaIce consensus: architectural redesign over @unchecked Sendable
public struct ShareableItems: @unchecked Sendable {
    private let _items: [Any]

    public init(_ items: [Any]) {
        _items = items
    }

    public var items: [Any] {
        _items
    }

    /// Thread-safe access to items
    /// Note: The caller is responsible for ensuring thread-safe usage of the items
    public func withItems<T>(_ action: ([Any]) -> T) -> T {
        action(_items)
    }
}

/// Protocol for platform-agnostic sharing functionality
public protocol ShareServiceProtocol: Sendable {
    /// Share items using the platform's native sharing mechanism
    /// - Parameters:
    ///   - items: Sendable wrapper containing items to share (strings, URLs, etc.)
    /// - Returns: Bool indicating success
    @MainActor
    func share(items: ShareableItems) async -> Bool

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
public enum ShareServiceError: LocalizedError, Sendable {
    case notAvailable
    case cancelled
    case failed(Error)

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            "Share service is not available"
        case .cancelled:
            "Share operation was cancelled"
        case let .failed(error):
            "Share failed: \(error.localizedDescription)"
        }
    }
}
