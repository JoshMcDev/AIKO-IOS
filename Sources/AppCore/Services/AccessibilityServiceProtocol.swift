import ComposableArchitecture
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

@DependencyClient
public struct AccessibilityServiceClient: Sendable {
    public var _announceNotification: @Sendable (String, AccessibilityAnnouncementPriority) -> Void = { _, _ in }
    public var _supportsAccessibilityNotifications: @Sendable () -> Bool = { false }
    public var _notifyVoiceOverStatusChange: @Sendable () -> Void = {}
    public var _voiceOverStatusChangeNotificationName: @Sendable () -> Notification.Name? = { nil }
    public var _hasVoiceOverStatusNotifications: @Sendable () -> Bool = { false }
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

private enum AccessibilityServiceKey: DependencyKey {
    static let liveValue: AccessibilityServiceProtocol = AccessibilityServiceClient()
}

public extension DependencyValues {
    var accessibilityService: AccessibilityServiceProtocol {
        get { self[AccessibilityServiceKey.self] }
        set { self[AccessibilityServiceKey.self] = newValue }
    }
}
