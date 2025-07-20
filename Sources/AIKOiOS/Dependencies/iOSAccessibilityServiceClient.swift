#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import SwiftUI

    /// iOS Accessibility Service Client using SimpleServiceTemplate
    public final class iOSAccessibilityServiceClient: SimpleServiceTemplate {
        private let service = iOSAccessibilityService()

        override public init() {
            super.init()
        }

        public func announceNotification(_ message: String, priority: AccessibilityAnnouncementPriority) async {
            await executeMainActorOperation {
                self.service.announceNotification(message, priority: priority)
            }
        }

        public func supportsAccessibilityNotifications() async -> Bool {
            await executeMainActorOperation {
                self.service.supportsAccessibilityNotifications()
            }
        }

        public func notifyVoiceOverStatusChange() async {
            await executeMainActorOperation {
                self.service.notifyVoiceOverStatusChange()
            }
        }

        public func voiceOverStatusChangeNotificationName() async -> Notification.Name? {
            await executeMainActorOperation {
                self.service.voiceOverStatusChangeNotificationName()
            }
        }

        public func hasVoiceOverStatusNotifications() async -> Bool {
            await executeMainActorOperation {
                self.service.hasVoiceOverStatusNotifications()
            }
        }
    }

    public extension AccessibilityServiceClient {
        static let iOS: Self = {
            let client = iOSAccessibilityServiceClient()
            return Self(
                _announceNotification: { message, priority in
                    await client.announceNotification(message, priority: priority)
                },
                _supportsAccessibilityNotifications: {
                    await client.supportsAccessibilityNotifications()
                },
                _notifyVoiceOverStatusChange: {
                    await client.notifyVoiceOverStatusChange()
                },
                _voiceOverStatusChangeNotificationName: {
                    await client.voiceOverStatusChangeNotificationName()
                },
                _hasVoiceOverStatusNotifications: {
                    await client.hasVoiceOverStatusNotifications()
                }
            )
        }()
    }
#endif
