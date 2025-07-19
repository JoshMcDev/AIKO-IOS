#if os(macOS)
import SwiftUI
import AppCore
import ComposableArchitecture

extension AccessibilityServiceClient {
    public static let macOS: Self = {
        let service = macOSAccessibilityService()
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