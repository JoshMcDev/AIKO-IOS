#if os(macOS)
    import AppCore
    import Foundation

    /// macOS implementation of text field service
    public struct macOSTextFieldService: TextFieldServiceProtocol {
        public init() {}

        public var supportsAutocapitalization: Bool { false }
        public var supportsKeyboardTypes: Bool { false }
    }#endif
