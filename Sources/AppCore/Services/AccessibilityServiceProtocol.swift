import SwiftUI

/// Platform-agnostic accessibility service
public protocol AccessibilityServiceProtocol: Sendable {
    func announceNotification(_ message: String, priority: AccessibilityAnnouncementPriority)
    func supportsAccessibilityNotifications() -> Bool
    func notifyVoiceOverStatusChange()
    func voiceOverStatusChangeNotificationName() -> Notification.Name?
    func hasVoiceOverStatusNotifications() -> Bool
}

public enum AccessibilityAnnouncementPriority: Sendable {
    case high
    case low
}

public struct AccessibilityServiceClient: Sendable {
    public var _announceNotification: @Sendable (String, AccessibilityAnnouncementPriority) -> Void = { _, _ in }
    public var _supportsAccessibilityNotifications: @Sendable () -> Bool = { false }
    public var _notifyVoiceOverStatusChange: @Sendable () -> Void = {}
    public var _voiceOverStatusChangeNotificationName: @Sendable () -> Notification.Name? = { nil }
    public var _hasVoiceOverStatusNotifications: @Sendable () -> Bool = { false }

    public init(
        _announceNotification: @escaping @Sendable (String, AccessibilityAnnouncementPriority) -> Void = { _, _ in },
        _supportsAccessibilityNotifications: @escaping @Sendable () -> Bool = { false },
        _notifyVoiceOverStatusChange: @escaping @Sendable () -> Void = {},
        _voiceOverStatusChangeNotificationName: @escaping @Sendable () -> Notification.Name? = { nil },
        _hasVoiceOverStatusNotifications: @escaping @Sendable () -> Bool = { false }
    ) {
        self._announceNotification = _announceNotification
        self._supportsAccessibilityNotifications = _supportsAccessibilityNotifications
        self._notifyVoiceOverStatusChange = _notifyVoiceOverStatusChange
        self._voiceOverStatusChangeNotificationName = _voiceOverStatusChangeNotificationName
        self._hasVoiceOverStatusNotifications = _hasVoiceOverStatusNotifications
    }
}

// Protocol conformance
extension AccessibilityServiceClient: AccessibilityServiceProtocol {
    public func announceNotification(_ message: String, priority: AccessibilityAnnouncementPriority) {
        _announceNotification(message, priority)
    }

    public func supportsAccessibilityNotifications() -> Bool {
        _supportsAccessibilityNotifications()
    }

    public func notifyVoiceOverStatusChange() {
        _notifyVoiceOverStatusChange()
    }

    public func voiceOverStatusChangeNotificationName() -> Notification.Name? {
        _voiceOverStatusChangeNotificationName()
    }

    public func hasVoiceOverStatusNotifications() -> Bool {
        _hasVoiceOverStatusNotifications()
    }
}

// MARK: - Dependency

private enum AccessibilityServiceKey {
    static let liveValue: AccessibilityServiceProtocol = AccessibilityServiceClient()
}

// MARK: - Environment Extension

public extension EnvironmentValues {
    var accessibilityService: AccessibilityServiceClient {
        get { self[AccessibilityServiceEnvironmentKey.self] }
        set { self[AccessibilityServiceEnvironmentKey.self] = newValue }
    }
}

private struct AccessibilityServiceEnvironmentKey: EnvironmentKey {
    static let defaultValue: AccessibilityServiceClient = AccessibilityServiceClient()
}
