#if os(iOS)
import SwiftUI
import AppCore
import ComposableArchitecture

extension AccessibilityServiceClient {
    public static let iOS: Self = {
        let service = iOSAccessibilityService()
        return Self(
            _announceNotification: { message, priority in
                service.announceNotification(message, priority: priority)
            },
            _supportsAccessibilityNotifications: { service.supportsAccessibilityNotifications() },
            _notifyVoiceOverStatusChange: { service.notifyVoiceOverStatusChange() },
            _voiceOverStatusChangeNotificationName: { service.voiceOverStatusChangeNotificationName() },
            _hasVoiceOverStatusNotifications: { service.hasVoiceOverStatusNotifications() }
        )
    }()
}
#endif