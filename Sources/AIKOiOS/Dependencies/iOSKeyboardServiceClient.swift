import AppCore
import ComposableArchitecture
import Foundation

extension KeyboardServiceClient {
    private static let keyboardService = iOSKeyboardService()
    
    public static let iOSLive = Self(
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
public enum iOSKeyboardServiceClient {
    public static let live = KeyboardServiceClient.iOSLive
}