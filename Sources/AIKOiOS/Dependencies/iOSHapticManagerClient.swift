#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import CoreHaptics
    import UIKit

    /// iOS Haptic Manager Service Client using SimpleServiceTemplate
    public final class iOSHapticManagerClient: SimpleServiceTemplate {
        private let manager = iOSHapticManager()

        override public init() {
            super.init()
        }

        public func impact(_ style: HapticStyle) async {
            await executeMainActorOperation {
                await self.manager.impact(style)
            }
        }

        public func notification(_ type: HapticNotificationType) async {
            await executeMainActorOperation {
                await self.manager.notification(type)
            }
        }

        public func selection() async {
            await executeMainActorOperation {
                await self.manager.selection()
            }
        }

        public func buttonTap() async {
            await executeMainActorOperation {
                await self.manager.buttonTap()
            }
        }

        public func toggleSwitch() async {
            await executeMainActorOperation {
                await self.manager.toggleSwitch()
            }
        }

        public func successAction() async {
            await executeMainActorOperation {
                await self.manager.successAction()
            }
        }

        public func errorAction() async {
            await executeMainActorOperation {
                await self.manager.errorAction()
            }
        }

        public func warningAction() async {
            await executeMainActorOperation {
                await self.manager.warningAction()
            }
        }

        public func dragStarted() async {
            await executeMainActorOperation {
                await self.manager.dragStarted()
            }
        }

        public func dragEnded() async {
            await executeMainActorOperation {
                await self.manager.dragEnded()
            }
        }

        public func refresh() async {
            await executeMainActorOperation {
                await self.manager.refresh()
            }
        }
    }

    // MARK: - iOS Haptic Manager Client

    public extension HapticManagerClient {
        @MainActor
        static var iOSLive: Self {
            let manager = iOSHapticManager()

            return Self(
                impact: { style in
                    Task {
                        await manager.impact(style)
                    }
                },
                notification: { type in
                    Task {
                        await manager.notification(type)
                    }
                },
                selection: {
                    Task {
                        await manager.selection()
                    }
                },
                buttonTap: {
                    Task {
                        await manager.buttonTap()
                    }
                },
                toggleSwitch: {
                    Task {
                        await manager.toggleSwitch()
                    }
                },
                successAction: {
                    Task {
                        await manager.successAction()
                    }
                },
                errorAction: {
                    Task {
                        await manager.errorAction()
                    }
                },
                warningAction: {
                    Task {
                        await manager.warningAction()
                    }
                },
                dragStarted: {
                    Task {
                        await manager.dragStarted()
                    }
                },
                dragEnded: {
                    Task {
                        await manager.dragEnded()
                    }
                },
                refresh: {
                    Task {
                        await manager.refresh()
                    }
                }
            )
        }
    }

    // MARK: - iOS Haptic Manager Implementation

    @MainActor
    private class iOSHapticManager {
        private var engine: CHHapticEngine?
        private let supportsHaptics: Bool

        init() {
            supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
            prepareHaptics()
        }

        private func prepareHaptics() {
            guard supportsHaptics else { return }

            do {
                engine = try CHHapticEngine()
                try engine?.start()

                // Handle engine reset
                engine?.resetHandler = { [weak self] in
                    do {
                        try self?.engine?.start()
                    } catch {
                        print("Failed to restart haptic engine: \(error)")
                    }
                }

                // Handle engine stopped
                engine?.stoppedHandler = { reason in
                    print("Haptic engine stopped: \(reason)")
                }
            } catch {
                print("Failed to create haptic engine: \(error)")
            }
        }

        func impact(_ style: HapticStyle) async {
            guard supportsHaptics else { return }

            let generator = switch style {
            case .light:
                UIImpactFeedbackGenerator(style: .light)
            case .medium:
                UIImpactFeedbackGenerator(style: .medium)
            case .heavy:
                UIImpactFeedbackGenerator(style: .heavy)
            case .soft:
                UIImpactFeedbackGenerator(style: .soft)
            case .rigid:
                UIImpactFeedbackGenerator(style: .rigid)
            }

            generator.prepare()
            generator.impactOccurred()
        }

        func notification(_ type: HapticNotificationType) async {
            guard supportsHaptics else { return }

            let generator = UINotificationFeedbackGenerator()
            generator.prepare()

            let feedbackType: UINotificationFeedbackGenerator.FeedbackType = switch type {
            case .success:
                .success
            case .warning:
                .warning
            case .error:
                .error
            }

            generator.notificationOccurred(feedbackType)
        }

        func selection() async {
            guard supportsHaptics else { return }

            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }

        func buttonTap() async {
            await impact(.light)
        }

        func toggleSwitch() async {
            await impact(.medium)
        }

        func successAction() async {
            await notification(.success)
        }

        func errorAction() async {
            await notification(.error)
        }

        func warningAction() async {
            await notification(.warning)
        }

        func dragStarted() async {
            await impact(.soft)
        }

        func dragEnded() async {
            await impact(.rigid)
        }

        func refresh() async {
            await impact(.medium)
            try? await Task.sleep(nanoseconds: 200_000_000)
            await impact(.light)
        }
    }
#endif
