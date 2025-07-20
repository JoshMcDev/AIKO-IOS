import Foundation

/// Protocol for platform-agnostic keyboard configuration
public protocol KeyboardServiceProtocol: Sendable {
    /// Keyboard type enumeration
    associatedtype KeyboardType

    /// Default keyboard type
    var defaultKeyboardType: KeyboardType { get }

    /// Email keyboard type
    var emailKeyboardType: KeyboardType { get }

    /// Number keyboard type
    var numberKeyboardType: KeyboardType { get }

    /// Phone keyboard type
    var phoneKeyboardType: KeyboardType { get }

    /// URL keyboard type
    var urlKeyboardType: KeyboardType { get }

    /// Whether the platform supports keyboard type configuration
    var supportsKeyboardTypes: Bool { get }
}

/// Platform-agnostic keyboard type representation
public enum PlatformKeyboardType: String, Sendable, CaseIterable {
    case `default`
    case email
    case emailAddress
    case number
    case numberPad
    case phone
    case url
    case decimal
}
