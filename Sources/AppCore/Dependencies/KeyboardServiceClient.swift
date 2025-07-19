import ComposableArchitecture
import Foundation

/// Dependency client for keyboard configuration
@DependencyClient
public struct KeyboardServiceClient: Sendable {
    public var defaultKeyboardType: @Sendable () -> PlatformKeyboardType = { .default }
    public var emailKeyboardType: @Sendable () -> PlatformKeyboardType = { .email }
    public var numberKeyboardType: @Sendable () -> PlatformKeyboardType = { .number }
    public var phoneKeyboardType: @Sendable () -> PlatformKeyboardType = { .phone }
    public var urlKeyboardType: @Sendable () -> PlatformKeyboardType = { .url }
    public var supportsKeyboardTypes: @Sendable () -> Bool = { false }
}

extension KeyboardServiceClient: DependencyKey {
    public static var liveValue: Self = Self()
}

extension DependencyValues {
    public var keyboardService: KeyboardServiceClient {
        get { self[KeyboardServiceClient.self] }
        set { self[KeyboardServiceClient.self] = newValue }
    }
}