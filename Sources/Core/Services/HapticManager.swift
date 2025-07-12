import SwiftUI
import CoreHaptics
import Combine

// MARK: - Haptic Manager

@MainActor
final class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool = false
    
    // User preference for haptics
    @AppStorage("hapticFeedbackEnabled") private var isHapticEnabled = true
    
    private init() {
        prepareHaptics()
    }
    
    // MARK: - Setup
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            supportsHaptics = false
            return
        }
        
        supportsHaptics = true
        
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
    
    // MARK: - Impact Feedback
    
    enum ImpactStyle {
        case light
        case medium
        case heavy
        case soft
        case rigid
        
        #if os(iOS)
        @MainActor
        var generator: UIImpactFeedbackGenerator {
            switch self {
            case .light:
                return UIImpactFeedbackGenerator(style: .light)
            case .medium:
                return UIImpactFeedbackGenerator(style: .medium)
            case .heavy:
                return UIImpactFeedbackGenerator(style: .heavy)
            case .soft:
                return UIImpactFeedbackGenerator(style: .soft)
            case .rigid:
                return UIImpactFeedbackGenerator(style: .rigid)
            }
        }
        #endif
    }
    
    func impact(_ style: ImpactStyle = .medium) {
        guard isHapticEnabled && supportsHaptics else { return }
        
        #if os(iOS)
        let generator = style.generator
        generator.prepare()
        generator.impactOccurred()
        #else
        // For macOS, use CHHapticEngine pattern
        playCustomPattern(.impact(style))
        #endif
    }
    
    // MARK: - Notification Feedback
    
    enum NotificationStyle {
        case success
        case warning
        case error
        
        #if os(iOS)
        var feedbackType: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .success: return .success
            case .warning: return .warning
            case .error: return .error
            }
        }
        #endif
    }
    
    func notification(_ style: NotificationStyle) {
        guard isHapticEnabled && supportsHaptics else { return }
        
        #if os(iOS)
        Task { @MainActor in
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(style.feedbackType)
        }
        #else
        // For macOS, use CHHapticEngine pattern
        switch style {
        case .success:
            playCustomPattern(.success)
        case .warning:
            playCustomPattern(.warning)
        case .error:
            playCustomPattern(.error)
        }
        #endif
    }
    
    // MARK: - Selection Feedback
    
    func selection() {
        guard isHapticEnabled && supportsHaptics else { return }
        
        #if os(iOS)
        Task { @MainActor in
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
        #else
        // For macOS, use CHHapticEngine pattern
        playCustomPattern(.selection)
        #endif
    }
    
    // MARK: - Custom Patterns
    
    func playCustomPattern(_ pattern: HapticPattern) {
        guard isHapticEnabled && supportsHaptics,
              let engine = engine else { return }
        
        do {
            let pattern = try pattern.chPattern()
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
    
    // MARK: - Complex Feedback Patterns
    
    func buttonTap() {
        impact(.light)
    }
    
    func toggleSwitch() {
        impact(.medium)
    }
    
    func successAction() {
        notification(.success)
    }
    
    func errorAction() {
        notification(.error)
    }
    
    func warningAction() {
        notification(.warning)
    }
    
    func dragStarted() {
        impact(.soft)
    }
    
    func dragEnded() {
        impact(.rigid)
    }
    
    func refresh() {
        Task {
            impact(.medium)
            try? await Task.sleep(nanoseconds: 200_000_000)
            impact(.light)
        }
    }
}

// MARK: - Haptic Pattern

struct HapticPattern {
    let events: [HapticEvent]
    
    struct HapticEvent {
        let time: TimeInterval
        let intensity: Float
        let sharpness: Float
        let duration: TimeInterval
    }
    
    func chPattern() throws -> CHHapticPattern {
        let hapticEvents = events.map { event in
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: event.intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: event.sharpness)
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
        HapticEvent(time: 0.15, intensity: 1.0, sharpness: 1.0, duration: 0.1)
    ])
    
    static let bounce = HapticPattern(events: [
        HapticEvent(time: 0, intensity: 1.0, sharpness: 1.0, duration: 0.1),
        HapticEvent(time: 0.2, intensity: 0.6, sharpness: 0.6, duration: 0.1),
        HapticEvent(time: 0.35, intensity: 0.3, sharpness: 0.3, duration: 0.1)
    ])
    
    static let heartbeat = HapticPattern(events: [
        HapticEvent(time: 0, intensity: 0.8, sharpness: 0.4, duration: 0.1),
        HapticEvent(time: 0.1, intensity: 1.0, sharpness: 0.6, duration: 0.1),
        HapticEvent(time: 0.5, intensity: 0.8, sharpness: 0.4, duration: 0.1),
        HapticEvent(time: 0.6, intensity: 1.0, sharpness: 0.6, duration: 0.1)
    ])
    
    static let warning = HapticPattern(events: [
        HapticEvent(time: 0, intensity: 0.8, sharpness: 0.8, duration: 0.2),
        HapticEvent(time: 0.3, intensity: 0.8, sharpness: 0.8, duration: 0.2)
    ])
    
    static let error = HapticPattern(events: [
        HapticEvent(time: 0, intensity: 1.0, sharpness: 1.0, duration: 0.3)
    ])
    
    static let selection = HapticPattern(events: [
        HapticEvent(time: 0, intensity: 0.4, sharpness: 0.6, duration: 0.05)
    ])
    
    // Impact style patterns for macOS
    static func impact(_ style: HapticManager.ImpactStyle) -> HapticPattern {
        switch style {
        case .light:
            return HapticPattern(events: [
                HapticEvent(time: 0, intensity: 0.3, sharpness: 0.5, duration: 0.1)
            ])
        case .medium:
            return HapticPattern(events: [
                HapticEvent(time: 0, intensity: 0.6, sharpness: 0.7, duration: 0.1)
            ])
        case .heavy:
            return HapticPattern(events: [
                HapticEvent(time: 0, intensity: 1.0, sharpness: 0.9, duration: 0.1)
            ])
        case .soft:
            return HapticPattern(events: [
                HapticEvent(time: 0, intensity: 0.4, sharpness: 0.3, duration: 0.15)
            ])
        case .rigid:
            return HapticPattern(events: [
                HapticEvent(time: 0, intensity: 0.8, sharpness: 1.0, duration: 0.08)
            ])
        }
    }
}

// MARK: - View Modifiers

struct HapticFeedbackModifier: ViewModifier {
    let style: HapticManager.ImpactStyle
    let trigger: Bool
    
    func body(content: Content) -> some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            content
                .onChange(of: trigger) { oldValue, newValue in
                    if newValue {
                        HapticManager.shared.impact(style)
                    }
                }
        } else {
            content
                .onReceive(Just(trigger)) { newValue in
                    if newValue {
                        HapticManager.shared.impact(style)
                    }
                }
        }
    }
}

struct HapticTapModifier: ViewModifier {
    let style: HapticManager.ImpactStyle
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                HapticManager.shared.impact(style)
            }
    }
}

extension View {
    func hapticFeedback(_ style: HapticManager.ImpactStyle = .medium, trigger: Bool) -> some View {
        modifier(HapticFeedbackModifier(style: style, trigger: trigger))
    }
    
    func hapticTap(_ style: HapticManager.ImpactStyle = .light) -> some View {
        modifier(HapticTapModifier(style: style))
    }
    
    func hapticNotification(_ style: HapticManager.NotificationStyle, trigger: Bool) -> some View {
        Group {
            if #available(macOS 14.0, iOS 17.0, *) {
                self.onChange(of: trigger) { oldValue, newValue in
                    if newValue {
                        HapticManager.shared.notification(style)
                    }
                }
            } else {
                self.onReceive(Just(trigger)) { newValue in
                    if newValue {
                        HapticManager.shared.notification(style)
                    }
                }
            }
        }
    }
}

// MARK: - Haptic Button Style

struct HapticButtonStyle: ButtonStyle {
    let hapticStyle: HapticManager.ImpactStyle
    
    func makeBody(configuration: Configuration) -> some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .onChange(of: configuration.isPressed) { oldValue, newValue in
                    if newValue {
                        HapticManager.shared.impact(hapticStyle)
                    }
                }
        } else {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .onReceive(Just(configuration.isPressed)) { isPressed in
                    if isPressed {
                        HapticManager.shared.impact(hapticStyle)
                    }
                }
        }
    }
}

extension ButtonStyle where Self == HapticButtonStyle {
    static var haptic: HapticButtonStyle {
        HapticButtonStyle(hapticStyle: .light)
    }
    
    static func haptic(_ style: HapticManager.ImpactStyle) -> HapticButtonStyle {
        HapticButtonStyle(hapticStyle: style)
    }
}

// MARK: - Haptic Toggle Style

struct HapticToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
            HapticManager.shared.toggleSwitch()
        } label: {
            HStack {
                configuration.label
                Spacer()
                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(configuration.isOn ? .accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}