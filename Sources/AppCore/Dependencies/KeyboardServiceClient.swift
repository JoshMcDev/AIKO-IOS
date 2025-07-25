import Foundation

/// Dependency client for keyboard configuration
public struct KeyboardServiceClient: Sendable {
    public var defaultKeyboardType: @Sendable () -> PlatformKeyboardType = { .default }
    public var emailKeyboardType: @Sendable () -> PlatformKeyboardType = { .email }
    public var numberKeyboardType: @Sendable () -> PlatformKeyboardType = { .number }
    public var phoneKeyboardType: @Sendable () -> PlatformKeyboardType = { .phone }
    public var urlKeyboardType: @Sendable () -> PlatformKeyboardType = { .url }
    public var supportsKeyboardTypes: @Sendable () -> Bool = { false }

    public init(
        defaultKeyboardType: @escaping @Sendable () -> PlatformKeyboardType = { .default },
        emailKeyboardType: @escaping @Sendable () -> PlatformKeyboardType = { .email },
        numberKeyboardType: @escaping @Sendable () -> PlatformKeyboardType = { .number },
        phoneKeyboardType: @escaping @Sendable () -> PlatformKeyboardType = { .phone },
        urlKeyboardType: @escaping @Sendable () -> PlatformKeyboardType = { .url },
        supportsKeyboardTypes: @escaping @Sendable () -> Bool = { false }
    ) {
        self.defaultKeyboardType = defaultKeyboardType
        self.emailKeyboardType = emailKeyboardType
        self.numberKeyboardType = numberKeyboardType
        self.phoneKeyboardType = phoneKeyboardType
        self.urlKeyboardType = urlKeyboardType
        self.supportsKeyboardTypes = supportsKeyboardTypes
    }
}

public extension KeyboardServiceClient {
    static let liveValue: Self = .init()
}
