#if os(iOS)
    import AppCore
    import Foundation

    public extension TextFieldServiceClient {
        static let iOS = Self(
            supportsAutocapitalization: {
                // iOS supports text field autocapitalization
                true
            },
            supportsKeyboardTypes: {
                // iOS supports different keyboard types
                true
            }
        )
    }

    public enum IOSTextFieldServiceClient {
        public static let live = TextFieldServiceClient.iOS
    }
#endif
