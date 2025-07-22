#if os(iOS)
    import AppCore
    import Foundation

    /// iOS implementation of text field service
    public struct IOSTextFieldService: TextFieldServiceProtocol {
        public init() {}

        public var supportsAutocapitalization: Bool { true }
        public var supportsKeyboardTypes: Bool { true }
    }#endif
