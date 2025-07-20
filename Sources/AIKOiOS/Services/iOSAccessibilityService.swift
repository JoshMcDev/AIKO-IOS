#if os(iOS)
    import AppCore
    import SwiftUI
    import UIKit

    public final class iOSAccessibilityService: AccessibilityServiceProtocol {
        public init() {}

        @MainActor
        public func announceNotification(_ message: String, priority: AccessibilityAnnouncementPriority) {
            let announcement = AttributedString(message)

            if #available(iOS 17.0, *) {
                switch priority {
                case .high:
                    AccessibilityNotification.Announcement(announcement).post()
                case .low:
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        AccessibilityNotification.Announcement(announcement).post()
                    }
                }
            } else {
                // Fallback for iOS 16.0 - use UIAccessibility
                UIAccessibility.post(notification: .announcement, argument: message)
            }
        }

        public func supportsAccessibilityNotifications() -> Bool {
            true
        }

        public func notifyVoiceOverStatusChange() {
            // iOS handles this automatically through NotificationCenter
            // This is here for API consistency
        }

        public func voiceOverStatusChangeNotificationName() -> Notification.Name? {
            UIAccessibility.voiceOverStatusDidChangeNotification
        }

        public func hasVoiceOverStatusNotifications() -> Bool {
            true
        }
    }
#endif
