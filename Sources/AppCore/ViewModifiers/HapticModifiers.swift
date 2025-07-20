import Combine
import ComposableArchitecture
import SwiftUI

// MARK: - Haptic Feedback Modifier

public struct HapticFeedbackModifier: ViewModifier {
    let style: HapticStyle
    let trigger: Bool
    @Dependency(\.hapticManager) var hapticManager

    public func body(content: Content) -> some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            content
                .onChange(of: trigger) { _, newValue in
                    if newValue {
                        Task { @MainActor in
                            hapticManager.impact(style)
                        }
                    }
                }
        } else {
            content
                .onReceive(Just(trigger)) { newValue in
                    if newValue {
                        Task { @MainActor in
                            hapticManager.impact(style)
                        }
                    }
                }
        }
    }
}

// MARK: - Haptic Tap Modifier

public struct HapticTapModifier: ViewModifier {
    let style: HapticStyle
    @Dependency(\.hapticManager) var hapticManager

    public func body(content: Content) -> some View {
        content
            .onTapGesture {
                Task { @MainActor in
                    hapticManager.impact(style)
                }
            }
    }
}

// MARK: - Haptic Notification Modifier

public struct HapticNotificationModifier: ViewModifier {
    let type: HapticNotificationType
    let trigger: Bool
    @Dependency(\.hapticManager) var hapticManager

    public func body(content: Content) -> some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            content
                .onChange(of: trigger) { _, newValue in
                    if newValue {
                        Task { @MainActor in
                            hapticManager.notification(type)
                        }
                    }
                }
        } else {
            content
                .onReceive(Just(trigger)) { newValue in
                    if newValue {
                        Task { @MainActor in
                            hapticManager.notification(type)
                        }
                    }
                }
        }
    }
}

// MARK: - View Extensions

public extension View {
    func hapticFeedback(_ style: HapticStyle = .medium, trigger: Bool) -> some View {
        modifier(HapticFeedbackModifier(style: style, trigger: trigger))
    }

    func hapticTap(_ style: HapticStyle = .light) -> some View {
        modifier(HapticTapModifier(style: style))
    }

    func hapticNotification(_ type: HapticNotificationType, trigger: Bool) -> some View {
        modifier(HapticNotificationModifier(type: type, trigger: trigger))
    }
}

// MARK: - Haptic Button Style

public struct HapticButtonStyle: ButtonStyle {
    let hapticStyle: HapticStyle
    @Dependency(\.hapticManager) var hapticManager

    public init(hapticStyle: HapticStyle = .light) {
        self.hapticStyle = hapticStyle
    }

    public func makeBody(configuration: Configuration) -> some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .onChange(of: configuration.isPressed) { _, newValue in
                    if newValue {
                        Task { @MainActor in
                            hapticManager.impact(hapticStyle)
                        }
                    }
                }
        } else {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .onReceive(Just(configuration.isPressed)) { isPressed in
                    if isPressed {
                        Task { @MainActor in
                            hapticManager.impact(hapticStyle)
                        }
                    }
                }
        }
    }
}

public extension ButtonStyle where Self == HapticButtonStyle {
    static var haptic: HapticButtonStyle {
        HapticButtonStyle(hapticStyle: .light)
    }

    static func haptic(_ style: HapticStyle) -> HapticButtonStyle {
        HapticButtonStyle(hapticStyle: style)
    }
}

// MARK: - Haptic Toggle Style

public struct HapticToggleStyle: ToggleStyle {
    @Dependency(\.hapticManager) var hapticManager

    public func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
            Task { @MainActor in
                hapticManager.toggleSwitch()
            }
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
