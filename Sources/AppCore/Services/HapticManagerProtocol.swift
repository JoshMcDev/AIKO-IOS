import Foundation
import SwiftUI

// MARK: - Haptic Manager Protocol

public protocol HapticManagerProtocol: Sendable {
    func impact(_ style: HapticStyle)
    func notification(_ type: HapticNotificationType)
    func selection()
    func buttonTap()
    func toggleSwitch()
    func successAction()
    func errorAction()
    func warningAction()
    func dragStarted()
    func dragEnded()
    func refresh()
}

// MARK: - Haptic Style

public enum HapticStyle: Sendable {
    case light
    case medium
    case heavy
    case soft
    case rigid
}

// MARK: - Haptic Notification Type

public enum HapticNotificationType: Sendable {
    case success
    case warning
    case error
}

// MARK: - Haptic Manager Client

public struct HapticManagerClient: Sendable {
    public var impact: @MainActor (HapticStyle) -> Void
    public var notification: @MainActor (HapticNotificationType) -> Void
    public var selection: @MainActor () -> Void
    public var buttonTap: @MainActor () -> Void
    public var toggleSwitch: @MainActor () -> Void
    public var successAction: @MainActor () -> Void
    public var errorAction: @MainActor () -> Void
    public var warningAction: @MainActor () -> Void
    public var dragStarted: @MainActor () -> Void
    public var dragEnded: @MainActor () -> Void
    public var refresh: @MainActor () -> Void

    public init(
        impact: @escaping @MainActor (HapticStyle) -> Void,
        notification: @escaping @MainActor (HapticNotificationType) -> Void,
        selection: @escaping @MainActor () -> Void,
        buttonTap: @escaping @MainActor () -> Void,
        toggleSwitch: @escaping @MainActor () -> Void,
        successAction: @escaping @MainActor () -> Void,
        errorAction: @escaping @MainActor () -> Void,
        warningAction: @escaping @MainActor () -> Void,
        dragStarted: @escaping @MainActor () -> Void,
        dragEnded: @escaping @MainActor () -> Void,
        refresh: @escaping @MainActor () -> Void
    ) {
        self.impact = impact
        self.notification = notification
        self.selection = selection
        self.buttonTap = buttonTap
        self.toggleSwitch = toggleSwitch
        self.successAction = successAction
        self.errorAction = errorAction
        self.warningAction = warningAction
        self.dragStarted = dragStarted
        self.dragEnded = dragEnded
        self.refresh = refresh
    }
}

// MARK: - Dependency

private enum HapticManagerKey {
    static let liveValue = HapticManagerClient(
        impact: { _ in },
        notification: { _ in },
        selection: {},
        buttonTap: {},
        toggleSwitch: {},
        successAction: {},
        errorAction: {},
        warningAction: {},
        dragStarted: {},
        dragEnded: {},
        refresh: {}
    )

    static let testValue = liveValue
}

// MARK: - Environment Extension

public extension EnvironmentValues {
    var hapticManager: HapticManagerClient {
        get { self[HapticManagerEnvironmentKey.self] }
        set { self[HapticManagerEnvironmentKey.self] = newValue }
    }
}

private struct HapticManagerEnvironmentKey: EnvironmentKey {
    static let defaultValue: HapticManagerClient = HapticManagerKey.liveValue
}
