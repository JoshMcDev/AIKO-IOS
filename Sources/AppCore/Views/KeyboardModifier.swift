import SwiftUI

/// View modifier for platform-specific keyboard configuration
public struct KeyboardModifier: ViewModifier {
    let keyboardType: PlatformKeyboardType
    let supportsKeyboardTypes: Bool
    
    public init(keyboardType: PlatformKeyboardType, supportsKeyboardTypes: Bool) {
        self.keyboardType = keyboardType
        self.supportsKeyboardTypes = supportsKeyboardTypes
    }
    
    public func body(content: Content) -> some View {
        #if os(iOS)
        if supportsKeyboardTypes {
            content
                .keyboardType(iOSKeyboardType(from: keyboardType))
                .autocapitalization(keyboardType == .email ? .none : .sentences)
                .disableAutocorrection(keyboardType == .email)
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
            return .default
        case .email:
            return .emailAddress
        case .number:
            return .numberPad
        case .phone:
            return .phonePad
        case .url:
            return .URL
        case .decimal:
            return .decimalPad
        }
    }
    #endif
}

public extension View {
    /// Apply platform-specific keyboard configuration
    func keyboardConfiguration(_ type: PlatformKeyboardType, supportsTypes: Bool) -> some View {
        self.modifier(KeyboardModifier(keyboardType: type, supportsKeyboardTypes: supportsTypes))
    }
}