#if os(macOS)
    import AppCore
    import ComposableArchitecture
    import Foundation

    extension KeyboardServiceClient {
        private static let keyboardService = MacOSKeyboardService()

        public static let macOSLive = Self(
            defaultKeyboardType: {
                .default
            },
            emailKeyboardType: {
                .email
            },
            numberKeyboardType: {
                .number
            },
            phoneKeyboardType: {
                .phone
            },
            urlKeyboardType: {
                .url
            },
            supportsKeyboardTypes: {
                keyboardService.supportsKeyboardTypes
            }
        )
    }

    // Convenience static accessor
    public enum MacOSKeyboardServiceClient {
        public static let live = KeyboardServiceClient.macOSLive
    }#endif
