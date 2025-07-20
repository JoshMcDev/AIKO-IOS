import SwiftUI

/// View modifier for platform-specific text field configuration
public struct TextFieldModifier: ViewModifier {
    let disableAutocapitalization: Bool
    let keyboardType: PlatformKeyboardType?
    let supportsAutocapitalization: Bool
    let supportsKeyboardTypes: Bool

    public init(
        disableAutocapitalization: Bool = false,
        keyboardType: PlatformKeyboardType? = nil,
        supportsAutocapitalization: Bool,
        supportsKeyboardTypes: Bool
    ) {
        self.disableAutocapitalization = disableAutocapitalization
        self.keyboardType = keyboardType
        self.supportsAutocapitalization = supportsAutocapitalization
        self.supportsKeyboardTypes = supportsKeyboardTypes
    }

    public func body(content: Content) -> some View {
        #if os(iOS)
            if supportsAutocapitalization || supportsKeyboardTypes {
                content
                    .autocapitalization(disableAutocapitalization ? .none : .sentences)
                    .keyboardType(keyboardType.map(iOSKeyboardType) ?? .default)
            } else {
                content
            }
        #else
            content
        #endif
    }

    #if os(iOS)
        private func iOSKeyboardType(from platformType: PlatformKeyboardType) -> UIKeyboardType {
            switch platformType {
            case .default:
                .default
            case .email:
                .emailAddress
            case .emailAddress:
                .emailAddress
            case .number:
                .numberPad
            case .numberPad:
                .numberPad
            case .phone:
                .phonePad
            case .url:
                .URL
            case .decimal:
                .decimalPad
            }
        }
    #endif
}

public extension View {
    /// Apply platform-specific text field configuration
    func textFieldConfiguration(
        disableAutocapitalization: Bool = false,
        keyboardType: PlatformKeyboardType? = nil,
        supportsAutocapitalization: Bool,
        supportsKeyboardTypes: Bool
    ) -> some View {
        modifier(TextFieldModifier(
            disableAutocapitalization: disableAutocapitalization,
            keyboardType: keyboardType,
            supportsAutocapitalization: supportsAutocapitalization,
            supportsKeyboardTypes: supportsKeyboardTypes
        ))
    }
}
