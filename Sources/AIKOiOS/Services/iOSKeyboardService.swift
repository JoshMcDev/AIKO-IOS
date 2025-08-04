#if os(iOS)
import AppCore
import UIKit

/// iOS implementation of keyboard service
public final class IOSKeyboardService: KeyboardServiceProtocol, @unchecked Sendable {
    public typealias KeyboardType = UIKeyboardType

    public var defaultKeyboardType: UIKeyboardType {
        .default
    }

    public var emailKeyboardType: UIKeyboardType {
        .emailAddress
    }

    public var numberKeyboardType: UIKeyboardType {
        .numberPad
    }

    public var phoneKeyboardType: UIKeyboardType {
        .phonePad
    }

    public var urlKeyboardType: UIKeyboardType {
        .URL
    }

    public var supportsKeyboardTypes: Bool {
        true
    }

    public init() {}

    /// Convert platform keyboard type to UIKeyboardType
    public static func keyboardType(from platformType: PlatformKeyboardType) -> UIKeyboardType {
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
}#endif
