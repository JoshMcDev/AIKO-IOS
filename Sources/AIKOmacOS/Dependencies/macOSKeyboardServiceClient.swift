#if os(macOS)
import AppCore
import ComposableArchitecture
import Foundation

extension KeyboardServiceClient {
    private static let keyboardService = macOSKeyboardService()
    
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
public enum macOSKeyboardServiceClient {
    public static let live = KeyboardServiceClient.macOSLive
}#endif
