import Foundation

/// Protocol for platform-specific text field configuration
public protocol TextFieldServiceProtocol: Sendable {
    /// Whether the platform supports autocapitalization
    var supportsAutocapitalization: Bool { get }

    /// Whether the platform supports keyboard types beyond default
    var supportsKeyboardTypes: Bool { get }
}
