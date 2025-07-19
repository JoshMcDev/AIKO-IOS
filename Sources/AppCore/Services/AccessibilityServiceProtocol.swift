import SwiftUI
import ComposableArchitecture

/// Platform-agnostic accessibility service
public protocol AccessibilityServiceProtocol {
    func announceNotification(_ message: String, priority: AccessibilityAnnouncementPriority) -> Void
    func supportsAccessibilityNotifications() -> Bool
    func notifyVoiceOverStatusChange() -> Void
    func voiceOverStatusChangeNotificationName() -> Notification.Name
    func hasVoiceOverStatusNotifications() -> Bool
}

public enum AccessibilityAnnouncementPriority {
    case high
    case low
}

@DependencyClient
public struct AccessibilityServiceClient {
    public var _announceNotification: @Sendable (String, AccessibilityAnnouncementPriority) -> Void = { _, _ in }
    public var _supportsAccessibilityNotifications: @Sendable () -> Bool = { false }
    public var _notifyVoiceOverStatusChange: @Sendable () -> Void = { }
    public var _voiceOverStatusChangeNotificationName: @Sendable () -> Notification.Name = { Notification.Name("com.aiko.never") }
    public var _hasVoiceOverStatusNotifications: @Sendable () -> Bool = { false }
}

// Protocol conformance
extension AccessibilityServiceClient: AccessibilityServiceProtocol {
    public func announceNotification(_ message: String, priority: AccessibilityAnnouncementPriority) -> Void {
        self._announceNotification(message, priority)
    }
    
    public func supportsAccessibilityNotifications() -> Bool {
        self._supportsAccessibilityNotifications()
    }
    
    public func notifyVoiceOverStatusChange() -> Void {
        self._notifyVoiceOverStatusChange()
    }
    
    public func voiceOverStatusChangeNotificationName() -> Notification.Name {
        self._voiceOverStatusChangeNotificationName()
    }
    
    public func hasVoiceOverStatusNotifications() -> Bool {
        self._hasVoiceOverStatusNotifications()
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