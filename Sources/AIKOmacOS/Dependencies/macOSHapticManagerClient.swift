#if os(macOS)
    import AppCore
    import AppKit
    import CoreHaptics

    // MARK: - macOS Haptic Manager Client

    public extension HapticManagerClient {
        @MainActor
        static var macOSLive: Self {
            let manager = MacOSHapticManager()

            return Self(
                impact: { style in
                    Task { @MainActor in
                        await manager.impact(style)
                    }
                },
                notification: { type in
                    Task { @MainActor in
                        await manager.notification(type)
                    }
                },
                selection: {
                    Task { @MainActor in
                        await manager.selection()
                    }
                },
                buttonTap: {
                    Task { @MainActor in
                        await manager.buttonTap()
                    }
                },
                toggleSwitch: {
                    Task { @MainActor in
                        await manager.toggleSwitch()
                    }
                },
                successAction: {
                    Task { @MainActor in
                        await manager.successAction()
                    }
                },
                errorAction: {
                    Task { @MainActor in
                        await manager.errorAction()
                    }
                },
                warningAction: {
                    Task { @MainActor in
                        await manager.warningAction()
                    }
                },
                dragStarted: {
                    Task { @MainActor in
                        await manager.dragStarted()
                    }
                },
                dragEnded: {
                    Task { @MainActor in
                        await manager.dragEnded()
                    }
                },
                refresh: {
                    Task { @MainActor in
                        await manager.refresh()
                    }
                }
            )
        }
    }

    // MARK: - macOS Haptic Manager Implementation

    @MainActor
    private class MacOSHapticManager {
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
            await playPattern(HapticPattern.impact(style))
        }

        func notification(_ type: HapticNotificationType) async {
            switch type {
            case .success:
                await playPattern(.success)
            case .warning:
                await playPattern(.warning)
            case .error:
                await playPattern(.error)
            }
        }

        func selection() async {
            await playPattern(.selection)
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

        private func playPattern(_ pattern: HapticPattern) async {
            guard supportsHaptics, let engine else { return }

            do {
                let chPattern = try pattern.toCHPattern()
                let player = try engine.makePlayer(with: chPattern)
                try player.start(atTime: CHHapticTimeImmediate)
            } catch {
                print("Failed to play haptic pattern: \(error)")
            }
        }
    }

    // MARK: - Haptic Pattern

    private struct HapticPattern {
        let events: [HapticEvent]

        struct HapticEvent {
            let time: TimeInterval
            let intensity: Float
            let sharpness: Float
            let duration: TimeInterval
        }

        func toCHPattern() throws -> CHHapticPattern {
            let hapticEvents = events.map { event in
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: event.intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: event.sharpness),
                    ],
                    relativeTime: event.time,
                    duration: event.duration
                )
            }

            return try CHHapticPattern(events: hapticEvents, parameters: [])
        }

        // Predefined patterns
        static let success = HapticPattern(events: [
            HapticEvent(time: 0, intensity: 0.6, sharpness: 0.8, duration: 0.1),
            HapticEvent(time: 0.15, intensity: 1.0, sharpness: 1.0, duration: 0.1),
        ])

        static let warning = HapticPattern(events: [
            HapticEvent(time: 0, intensity: 0.8, sharpness: 0.8, duration: 0.2),
            HapticEvent(time: 0.3, intensity: 0.8, sharpness: 0.8, duration: 0.2),
        ])

        static let error = HapticPattern(events: [
            HapticEvent(time: 0, intensity: 1.0, sharpness: 1.0, duration: 0.3),
        ])

        static let selection = HapticPattern(events: [
            HapticEvent(time: 0, intensity: 0.4, sharpness: 0.6, duration: 0.05),
        ])

        // Impact style patterns
        static func impact(_ style: HapticStyle) -> HapticPattern {
            switch style {
            case .light:
                HapticPattern(events: [
                    HapticEvent(time: 0, intensity: 0.3, sharpness: 0.5, duration: 0.1),
                ])
            case .medium:
                HapticPattern(events: [
                    HapticEvent(time: 0, intensity: 0.6, sharpness: 0.7, duration: 0.1),
                ])
            case .heavy:
                HapticPattern(events: [
                    HapticEvent(time: 0, intensity: 1.0, sharpness: 0.9, duration: 0.1),
                ])
            case .soft:
                HapticPattern(events: [
                    HapticEvent(time: 0, intensity: 0.4, sharpness: 0.3, duration: 0.15),
                ])
            case .rigid:
                HapticPattern(events: [
                    HapticEvent(time: 0, intensity: 0.8, sharpness: 1.0, duration: 0.08),
                ])
            }
        }
    }
#endif
