#if os(macOS)
    import AppCore
    import ComposableArchitecture
    import Foundation

    extension TextFieldServiceClient {
        private static let textFieldService = macOSTextFieldService()

        public static let macOSLive = Self(
            supportsAutocapitalization: {
                textFieldService.supportsAutocapitalization
            },
            supportsKeyboardTypes: {
                textFieldService.supportsKeyboardTypes
            }
        )
    }

    // Convenience static accessor
    public enum macOSTextFieldServiceClient {
        public static let live = TextFieldServiceClient.macOSLive
    }#endif
