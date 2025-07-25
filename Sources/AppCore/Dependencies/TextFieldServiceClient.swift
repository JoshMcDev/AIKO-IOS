import Foundation

/// Dependency client for text field configuration
public struct TextFieldServiceClient: Sendable {
    public var supportsAutocapitalization: @Sendable () -> Bool = { false }
    public var supportsKeyboardTypes: @Sendable () -> Bool = { false }

    public init(
        supportsAutocapitalization: @escaping @Sendable () -> Bool = { false },
        supportsKeyboardTypes: @escaping @Sendable () -> Bool = { false }
    ) {
        self.supportsAutocapitalization = supportsAutocapitalization
        self.supportsKeyboardTypes = supportsKeyboardTypes
    }
}

extension TextFieldServiceClient {
    public static let testValue = Self()
}
