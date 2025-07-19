import SwiftUI
import AppCore
import ComposableArchitecture

// MARK: - Accessibility Extensions

extension View {
    /// Adds comprehensive accessibility support to any view
    func accessibilityElement(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        value: String? = nil,
        identifier: String? = nil
    ) -> some View {
        accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityValue(value ?? "")
            .accessibilityIdentifier(identifier ?? "")
    }

    /// Adds button accessibility with haptic feedback
    func accessibleButton(
        label: String,
        hint: String? = nil,
        identifier: String? = nil
    ) -> some View {
        accessibilityElement(
            label: label,
            hint: hint,
            traits: .isButton,
            identifier: identifier
        )
    }

    /// Adds header accessibility
    func accessibleHeader(
        label: String,
        level: HeaderLevel = .h1
    ) -> some View {
        accessibilityElement(
            label: label,
            traits: [.isHeader, level.trait]
        )
    }

    /// Dynamic type support with limits
    func dynamicTypeSizeLimit(_ range: ClosedRange<DynamicTypeSize> = .xSmall ... DynamicTypeSize.accessibility3) -> some View {
        dynamicTypeSize(range)
    }
}

// MARK: - Header Level

enum HeaderLevel {
    case h1, h2, h3, h4, h5, h6

    var trait: AccessibilityTraits {
        .isHeader
    }
}

// MARK: - Accessibility Announcements

enum AccessibilityAnnouncement {
    @Dependency(\.accessibilityService) private static var accessibilityService
    
    static func announce(_ message: String, priority: AnnouncementPriority = .high) {
        let servicePriority: AccessibilityAnnouncementPriority = priority == .high ? .high : .low
        accessibilityService.announceNotification(message, priority: servicePriority)
    }

    enum AnnouncementPriority {
        case high, low
    }
}

// MARK: - Reduced Motion Support

struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let reducedAnimation: Animation

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? reducedAnimation : animation, value: UUID())
    }
}

extension View {
    func adaptiveAnimation(
        _ animation: Animation = .easeInOut,
        reduced: Animation = .linear(duration: 0.1)
    ) -> some View {
        modifier(ReducedMotionModifier(animation: animation, reducedAnimation: reduced))
    }
}

// MARK: - Focus Management

struct AccessibilityFocusState<Value: Hashable> {
    @FocusState private var focusedField: Value?

    var wrappedValue: Value? {
        get { focusedField }
        nonmutating set { focusedField = newValue }
    }
}

// MARK: - Semantic Colors for Accessibility

extension Color {
    static let semanticSuccess = Color.green
    static let semanticWarning = Color.orange
    static let semanticError = Color.red
    static let semanticInfo = Color.blue

    /// High contrast variants
    static var highContrastPrimary: Color {
        Color.primary.opacity(1.0)
    }

    static var highContrastSecondary: Color {
        Color.secondary.opacity(0.8)
    }
}

// MARK: - Accessibility Actions

struct AccessibilityActionModifier: ViewModifier {
    let actions: [AccessibilityAction]

    struct AccessibilityAction {
        let name: String
        let action: () -> Void
    }

    func body(content: Content) -> some View {
        content
            .accessibilityActions {
                ForEach(actions, id: \.name) { action in
                    Button(action.name) {
                        action.action()
                    }
                }
            }
    }
}

extension View {
    func accessibilityCustomActions(_ actions: [AccessibilityActionModifier.AccessibilityAction]) -> some View {
        modifier(AccessibilityActionModifier(actions: actions))
    }
}

// MARK: - VoiceOver Detection

struct VoiceOverDetector: ViewModifier {
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Dependency(\.accessibilityService) var accessibilityService
    let onVoiceOverChange: (Bool) -> Void

    func body(content: Content) -> some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            content
                .onChange(of: voiceOverEnabled) { _, newValue in
                    onVoiceOverChange(newValue)
                    accessibilityService.notifyVoiceOverStatusChange()
                }
                .onAppear {
                    onVoiceOverChange(voiceOverEnabled)
                }
        } else {
            // Fallback for older versions
            content
                .onAppear {
                    onVoiceOverChange(voiceOverEnabled)
                }
                .onReceive(voiceOverNotificationPublisher()) { _ in
                    onVoiceOverChange(voiceOverEnabled)
                    accessibilityService.notifyVoiceOverStatusChange()
                }
        }
    }
    
    private func voiceOverNotificationPublisher() -> NotificationCenter.Publisher {
        if accessibilityService.hasVoiceOverStatusNotifications() {
            return NotificationCenter.default.publisher(for: accessibilityService.voiceOverStatusChangeNotificationName())
        } else {
            // Platform doesn't have VoiceOver notifications, return a never-publishing publisher
            return NotificationCenter.default.publisher(for: Notification.Name("com.aiko.never"))
        }
    }
}

extension View {
    func onVoiceOverStatusChanged(perform action: @escaping (Bool) -> Void) -> some View {
        modifier(VoiceOverDetector(onVoiceOverChange: action))
    }
}

// MARK: - Accessibility Container

struct AccessibilityContainer<Content: View>: View {
    let label: String
    let hint: String?
    let content: Content

    init(
        label: String,
        hint: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.hint = hint
        self.content = content()
    }

    var body: some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
}

// MARK: - Loading State Accessibility

struct AccessibleLoadingView: View {
    let message: String
    @State private var loadingProgress = 0.0

    var body: some View {
        ProgressView(value: loadingProgress)
            .accessibilityLabel(message)
            .accessibilityValue("\(Int(loadingProgress * 100))% complete")
            .onAppear {
                // Announce loading state
                AccessibilityAnnouncement.announce(message)
            }
    }
}

// MARK: - Accessibility Testing Helpers

#if DEBUG
    struct AccessibilityInspector: ViewModifier {
        @State private var showingAccessibilityInfo = false

        func body(content: Content) -> some View {
            content
                .overlay(alignment: .topTrailing) {
                    if showingAccessibilityInfo {
                        VStack {
                            Text("Accessibility Mode")
                                .font(.caption)
                                .padding(4)
                                .background(Color.yellow)
                                .cornerRadius(4)
                        }
                        .padding()
                    }
                }
                .onAppear {
                    #if DEBUG
                        showingAccessibilityInfo = ProcessInfo.processInfo.arguments.contains("-UIAccessibilityTesting")
                    #endif
                }
        }
    }

    extension View {
        func accessibilityInspector() -> some View {
            modifier(AccessibilityInspector())
        }
    }
#endif
