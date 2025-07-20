import AppCore
import ComposableArchitecture
import SwiftUI

#if os(iOS)
    import AIKOiOS
#elseif os(macOS)
    import AIKOmacOS
#endif

// MARK: - Blur Effect System

struct BlurEffect: ViewModifier {
    let radius: CGFloat
    let opaque: Bool

    func body(content: Content) -> some View {
        content
            .blur(radius: radius, opaque: opaque)
    }
}

struct VariableBlur: View {
    let startRadius: CGFloat
    let endRadius: CGFloat
    let direction: Axis

    @State private var gradientMask = LinearGradient(
        colors: [.clear, .black],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0 ..< 10) { index in
                    blurSegment(index: index, geometry: geometry)
                }
            }
        }
    }

    @ViewBuilder
    private func blurSegment(index: Int, geometry: GeometryProxy) -> some View {
        let segmentWidth = direction == .horizontal ? geometry.size.width / 10 : geometry.size.width
        let segmentHeight = direction == .vertical ? geometry.size.height / 10 : geometry.size.height
        let xOffset = direction == .horizontal ? CGFloat(index) * geometry.size.width / 10 : 0
        let yOffset = direction == .vertical ? CGFloat(index) * geometry.size.height / 10 : 0

        Rectangle()
            .fill(Color.clear)
            .background(BlurredBackground(radius: radius(for: index)))
            .mask(
                Rectangle()
                    .fill(gradientMask)
                    .frame(width: segmentWidth, height: segmentHeight)
                    .offset(x: xOffset, y: yOffset)
            )
    }

    private func radius(for index: Int) -> CGFloat {
        let progress = CGFloat(index) / 9.0
        return startRadius + (endRadius - startRadius) * progress
    }
}

// Cross-platform blur effect
struct BlurredBackground: View {
    let radius: CGFloat
    @Dependency(\.blurEffectService) var blurEffectService

    var body: some View {
        blurEffectService.createBlurredBackground(radius: radius)
    }
}

// MARK: - Glassmorphism View

struct GlassmorphicView<Content: View>: View {
    let content: () -> Content
    var blurRadius: CGFloat = 10
    var opacity: Double = 0.6
    var cornerRadius: CGFloat = Theme.CornerRadius.lg

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background blur
            if #available(iOS 17.0, *) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Material.ultraThin)
            }

            // Content with background
            content()
                .background(
                    LinearGradient(
                        colors: [
                            colorScheme == .dark ?
                                Color.white.opacity(0.05) :
                                Color.black.opacity(0.05),
                            colorScheme == .dark ?
                                Color.white.opacity(0.02) :
                                Color.black.opacity(0.02),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(0.15),
            radius: 20,
            x: 0,
            y: 10
        )
    }
}

// MARK: - Gradient Overlay

struct GradientOverlay: ViewModifier {
    let gradient: Gradient
    let startPoint: UnitPoint
    let endPoint: UnitPoint
    let blendMode: BlendMode

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: gradient,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
                .blendMode(blendMode)
                .allowsHitTesting(false)
            )
    }
}

extension View {
    func gradientOverlay(
        colors: [Color],
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing,
        blendMode: BlendMode = .normal
    ) -> some View {
        modifier(GradientOverlay(
            gradient: Gradient(colors: colors),
            startPoint: startPoint,
            endPoint: endPoint,
            blendMode: blendMode
        ))
    }
}

// MARK: - Neumorphic Style

struct NeumorphicModifier: ViewModifier {
    let isPressed: Bool
    let shape: RoundedRectangle

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if isPressed {
                        shape
                            .fill(backgroundColor)
                            .overlay(
                                shape
                                    .stroke(darkShadow, lineWidth: 4)
                                    .blur(radius: 4)
                                    .offset(x: 2, y: 2)
                                    .mask(shape.fill(LinearGradient(colors: [.clear, .black], startPoint: .topLeading, endPoint: .bottomTrailing)))
                            )
                            .overlay(
                                shape
                                    .stroke(lightShadow, lineWidth: 4)
                                    .blur(radius: 4)
                                    .offset(x: -2, y: -2)
                                    .mask(shape.fill(LinearGradient(colors: [.black, .clear], startPoint: .topLeading, endPoint: .bottomTrailing)))
                            )
                    } else {
                        shape
                            .fill(backgroundColor)
                            .shadow(color: darkShadow, radius: 10, x: 5, y: 5)
                            .shadow(color: lightShadow, radius: 10, x: -5, y: -5)
                    }
                }
            )
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.13) : Color(white: 0.93)
    }

    private var darkShadow: Color {
        colorScheme == .dark ? Color.black : Color.black.opacity(0.2)
    }

    private var lightShadow: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.white
    }
}

extension View {
    func neumorphic(isPressed: Bool = false, cornerRadius: CGFloat = Theme.CornerRadius.md) -> some View {
        modifier(NeumorphicModifier(
            isPressed: isPressed,
            shape: RoundedRectangle(cornerRadius: cornerRadius)
        ))
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var style: FABStyle = .primary

    @State private var isPressed = false
    @State private var isAnimating = false
    @Dependency(\.hapticManager) var hapticManager

    enum FABStyle {
        case primary
        case secondary
        case destructive

        var backgroundColor: Color {
            switch self {
            case .primary: .blue
            case .secondary: .gray
            case .destructive: .red
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary, .destructive: .white
            case .secondary: .blue
            }
        }
    }

    var body: some View {
        Button(action: {
            hapticManager.impact(.medium)
            withAnimation(AnimationSystem.Spring.bouncy) {
                isAnimating = true
            }
            action()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        }) {
            ZStack {
                // Shadow layer
                Circle()
                    .fill(style.backgroundColor.opacity(0.3))
                    .frame(width: 56, height: 56)
                    .blur(radius: isPressed ? 5 : 10)
                    .offset(y: isPressed ? 2 : 5)

                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                style.backgroundColor,
                                style.backgroundColor.opacity(0.8),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(style.foregroundColor)
                    .rotationEffect(.degrees(isAnimating ? 45 : 0))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity) {} onPressingChanged: { pressing in
            withAnimation(AnimationSystem.microScale) {
                isPressed = pressing
            }
        }
        .accessibilityLabel("Action button")
        .accessibilityHint("Tap to perform action")
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @State private var iconRotation = 0.0
    @State private var iconScale = 1.0

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.1),
                                Color.blue.opacity(0.05),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Image(systemName: icon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(iconRotation))
                    .scaleEffect(iconScale)
                    .onAppear {
                        withAnimation(
                            Animation.easeInOut(duration: 3)
                                .repeatForever(autoreverses: true)
                        ) {
                            iconRotation = 10
                            iconScale = 1.1
                        }
                    }
            }
            .frame(height: 150)

            // Title
            ResponsiveText(content: title, style: .title2)
                .multilineTextAlignment(.center)

            // Message
            ResponsiveText(content: message, style: .body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 300)

            // Action button
            if let actionTitle, let action {
                AnimatedButton(action: action) {
                    HStack {
                        Text(actionTitle)
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                }
                .padding(.top, Theme.Spacing.md)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
        .accessibilityHint(actionTitle != nil ? "Action available: \(actionTitle!)" : "")
    }
}

// MARK: - Progress Indicator

struct CustomProgressIndicator: View {
    let progress: Double
    let style: ProgressStyle

    @State private var isAnimating = false

    enum ProgressStyle {
        case linear
        case circular
        case wave
    }

    var body: some View {
        switch style {
        case .linear:
            LinearProgressIndicator(progress: progress)
        case .circular:
            CircularProgressView(progress: progress)
        case .wave:
            LinearProgressIndicator(progress: progress) // Wave not implemented yet
        }
    }
}

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
        }
        .frame(width: 50, height: 50)
    }
}

struct LinearProgressIndicator: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                // Progress
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(AnimationSystem.Spring.smooth, value: progress)

                // Shimmer effect
                if progress > 0, progress < 1 {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 30, height: 8)
                        .offset(x: geometry.size.width * progress - 15)
                        .shimmer(duration: 1.5, bounce: true)
                }
            }
        }
        .frame(height: 8)
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
}
