#if os(macOS)
import AppCore
import Foundation

/// macOS implementation of text field service
public struct MacOSTextFieldService: TextFieldServiceProtocol {
    public init() {}

    public var supportsAutocapitalization: Bool { false }
    public var supportsKeyboardTypes: Bool { false }
}#endif
