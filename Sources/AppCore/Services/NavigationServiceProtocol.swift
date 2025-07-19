import Foundation
import SwiftUI

/// Protocol for platform-specific navigation services
public protocol NavigationServiceProtocol: Sendable {
    /// Whether the platform supports NavigationStack (iOS 16+)
    var supportsNavigationStack: Bool { get }
    
    /// Default navigation style for the platform
    var defaultNavigationStyle: NavigationStyle { get }
    
    /// Whether the platform supports navigation bar display mode
    var supportsNavigationBarDisplayMode: Bool { get }
}

public enum NavigationStyle: Sendable {
    case stack
    case column
    case automatic
}

// Error types
public enum NavigationServiceError: Error, LocalizedError, Sendable {
    case notSupported
    
    public var errorDescription: String? {
        switch self {
        case .notSupported:
            return "Navigation style not supported on this platform"
        }
    }
}