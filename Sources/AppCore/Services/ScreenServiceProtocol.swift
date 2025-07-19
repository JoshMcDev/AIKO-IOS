import Foundation
import CoreGraphics

/// Protocol for platform-specific screen information
public protocol ScreenServiceProtocol: Sendable {
    /// Get the main screen bounds
    var mainScreenBounds: CGRect { get }
    
    /// Get the main screen width
    var mainScreenWidth: CGFloat { get }
    
    /// Get the main screen height
    var mainScreenHeight: CGFloat { get }
    
    /// Get the screen scale factor
    var screenScale: CGFloat { get }
    
    /// Check if running on a compact device
    var isCompact: Bool { get }
}

// Error types
public enum ScreenServiceError: Error, LocalizedError, Sendable {
    case screenNotAvailable
    
    public var errorDescription: String? {
        switch self {
        case .screenNotAvailable:
            return "Screen information not available"
        }
    }
}