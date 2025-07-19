import UIKit
import CoreHaptics
import ComposableArchitecture
import AppCore

// MARK: - iOS Haptic Manager Client

extension HapticManagerClient {
    @MainActor
    public static var iOSLive: Self {
        let manager = iOSHapticManager()
        
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
        
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light:
            generator = UIImpactFeedbackGenerator(style: .light)
        case .medium:
            generator = UIImpactFeedbackGenerator(style: .medium)
        case .heavy:
            generator = UIImpactFeedbackGenerator(style: .heavy)
        case .soft:
            generator = UIImpactFeedbackGenerator(style: .soft)
        case .rigid:
            generator = UIImpactFeedbackGenerator(style: .rigid)
        }
        
        generator.prepare()
        generator.impactOccurred()
    }
    
    func notification(_ type: HapticNotificationType) async {
        guard supportsHaptics else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        
        let feedbackType: UINotificationFeedbackGenerator.FeedbackType
        switch type {
        case .success:
            feedbackType = .success
        case .warning:
            feedbackType = .warning
        case .error:
            feedbackType = .error
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