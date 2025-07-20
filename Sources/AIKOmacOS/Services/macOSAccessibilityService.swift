#if os(macOS)
    import AppCore
    import AppKit
    import SwiftUI

    public final class macOSAccessibilityService: AccessibilityServiceProtocol {
        public init() {}

        public func announceNotification(_ message: String, priority: AccessibilityAnnouncementPriority) {
            let announcement = AttributedString(message)

            if #available(macOS 14.0, *) {
                switch priority {
                case .high:
                    AccessibilityNotification.Announcement(announcement).post()
                case .low:
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        AccessibilityNotification.Announcement(announcement).post()
                    }
                }
            } else {
                // Fallback for older macOS versions - just print to console
                print("Accessibility Announcement: \(message)")
            }
        }

        public func supportsAccessibilityNotifications() -> Bool {
            if #available(macOS 14.0, *) {
                true
            } else {
                false
            }
        }

        public func notifyVoiceOverStatusChange() {
            // macOS doesn't have a direct equivalent to UIAccessibility notifications
            // This is here for API consistency
        }

        public func voiceOverStatusChangeNotificationName() -> Notification.Name? {
            // macOS doesn't have an equivalent notification, return nil
            nil
        }

        public func hasVoiceOverStatusNotifications() -> Bool {
            false
        }
    }
#endif
