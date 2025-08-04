#if os(macOS)
import AppCore
import SwiftUI

public extension AccessibilityServiceClient {
    static let macOS: Self = {
        let service = MacOSAccessibilityService()
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
