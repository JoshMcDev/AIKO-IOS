#if os(macOS)
import AppCore
import Foundation

extension TextFieldServiceClient {
    private static let textFieldService = MacOSTextFieldService()

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
public enum MacOSTextFieldServiceClient {
    public static let live = TextFieldServiceClient.macOSLive
}#endif
