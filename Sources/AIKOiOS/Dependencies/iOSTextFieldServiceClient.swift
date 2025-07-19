import AppCore
import ComposableArchitecture
import Foundation

extension TextFieldServiceClient {
    private static let textFieldService = iOSTextFieldService()
    
    public static let iOSLive = Self(
        supportsAutocapitalization: {
            textFieldService.supportsAutocapitalization
        },
        supportsKeyboardTypes: {
            textFieldService.supportsKeyboardTypes
        }
    )
}

// Convenience static accessor
public enum iOSTextFieldServiceClient {
    public static let live = TextFieldServiceClient.iOSLive
}