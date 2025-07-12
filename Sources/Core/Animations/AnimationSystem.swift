import Combine
import SwiftUI

// MARK: - Animation System

enum AnimationSystem {
    // MARK: - Spring Animations

    enum Spring {
        static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let gentle = Animation.spring(response: 0.6, dampingFraction: 0.9)
    }

    // MARK: - Timing Curves

    enum Curve {
        static let easeInOutQuart = Animation.timingCurve(0.77, 0, 0.175, 1, duration: 0.5)
        static let easeOutBack = Animation.timingCurve(0.34, 1.56, 0.64, 1, duration: 0.4)
        static let easeInOutExpo = Animation.timingCurve(0.87, 0, 0.13, 1, duration: 0.6)
        static let materialEase = Animation.timingCurve(0.4, 0.0, 0.2, 1, duration: 0.3)
    }

    // MARK: - Micro Interactions

    static let microBounce = Animation.spring(response: 0.2, dampingFraction: 0.5)
    static let microFade = Animation.easeOut(duration: 0.15)
    static let microScale = Animation.easeInOut(duration: 0.1)
}

// MARK: - Animated Button

struct AnimatedButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label

    @State private var isPressed = false
    @State private var showRipple = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: {
            // Trigger ripple effect
            withAnimation(.easeOut(duration: 0.6)) {
                showRipple = true
            }

            // Reset ripple
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showRipple = false
            }

            action()
        }) {
            label()
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .opacity(isPressed ? 0.8 : 1.0)
                .overlay(
                    GeometryReader { geometry in
                        if showRipple {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: geometry.size.width * 2)
                                .scaleEffect(showRipple ? 1 : 0)
                                .opacity(showRipple ? 0 : 1)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                                .allowsHitTesting(false)
                        }
                    }
                    .clipped()
                )
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) {} onPressingChanged: { pressing in
            withAnimation(AnimationSystem.microScale) {
                isPressed = pressing
            }
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    let bounce: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                    .mask(content)
                    .allowsHitTesting(false)
                }
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration)
                        .repeatForever(autoreverses: bounce)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer(duration: Double = 2.0, bounce: Bool = false) -> some View {
        modifier(ShimmerModifier(duration: duration, bounce: bounce))
    }
}

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let duration: Double
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulse(duration: Double = 1.5, scale: CGFloat = 1.05) -> some View {
        modifier(PulseModifier(duration: duration, scale: scale))
    }
}

// MARK: - Bounce Animation

struct BounceModifier: ViewModifier {
    @State private var bounceOffset: CGFloat = 0
    let trigger: Bool
    let distance: CGFloat

    func body(content: Content) -> some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            content
                .offset(y: bounceOffset)
                .onChange(of: trigger) { _, newValue in
                    if newValue {
                        performBounce()
                    }
                }
        } else {
            content
                .offset(y: bounceOffset)
                .onReceive(Just(trigger)) { newValue in
                    if newValue, bounceOffset == 0 {
                        performBounce()
                    }
                }
        }
    }

    private func performBounce() {
        withAnimation(AnimationSystem.Spring.bouncy) {
            bounceOffset = -distance
        }

        withAnimation(AnimationSystem.Spring.bouncy.delay(0.1)) {
            bounceOffset = 0
        }
    }
}

extension View {
    func bounce(trigger: Bool, distance: CGFloat = 10) -> some View {
        modifier(BounceModifier(trigger: trigger, distance: distance))
    }
}

// MARK: - Shake Animation

struct ShakeModifier: ViewModifier {
    @State private var shakeOffset: CGFloat = 0
    let trigger: Bool
    let intensity: CGFloat

    func body(content: Content) -> some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            content
                .offset(x: shakeOffset)
                .onChange(of: trigger) { _, newValue in
                    if newValue {
                        performShake()
                    }
                }
        } else {
            content
                .offset(x: shakeOffset)
                .onReceive(Just(trigger)) { newValue in
                    if newValue, shakeOffset == 0 {
                        performShake()
                    }
                }
        }
    }

    private func performShake() {
        let animation = Animation.linear(duration: 0.05)

        for i in 0 ..< 6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(animation) {
                    shakeOffset = (i % 2 == 0) ? intensity : -intensity
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(animation) {
                shakeOffset = 0
            }
        }
    }
}

extension View {
    func shake(trigger: Bool, intensity: CGFloat = 5) -> some View {
        modifier(ShakeModifier(trigger: trigger, intensity: intensity))
    }
}

// MARK: - Loading Animation

struct LoadingDotsView: View {
    @State private var animatingDots = [false, false, false]
    let dotSize: CGFloat
    let color: Color

    init(dotSize: CGFloat = 10, color: Color = .accentColor) {
        self.dotSize = dotSize
        self.color = color
    }

    var body: some View {
        HStack(spacing: dotSize / 2) {
            ForEach(0 ..< 3) { index in
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(animatingDots[index] ? 1.3 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animatingDots[index]
                    )
            }
        }
        .onAppear {
            for index in 0 ..< 3 {
                animatingDots[index] = true
            }
        }
    }
}

// MARK: - Success Checkmark Animation

struct AnimatedCheckmark: View {
    @State private var trimEnd: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0

    let size: CGFloat
    let color: Color

    init(size: CGFloat = 50, color: Color = .green) {
        self.size = size
        self.color = color
    }

    var body: some View {
        ZStack {
            // Circle background
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: size, height: size)
                .scaleEffect(scale)

            // Checkmark
            Path { path in
                path.move(to: CGPoint(x: size * 0.25, y: size * 0.5))
                path.addLine(to: CGPoint(x: size * 0.4, y: size * 0.65))
                path.addLine(to: CGPoint(x: size * 0.75, y: size * 0.3))
            }
            .trim(from: 0, to: trimEnd)
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round, lineJoin: .round))
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(AnimationSystem.Spring.bouncy) {
                scale = 1.0
            }

            withAnimation(AnimationSystem.Curve.easeInOutQuart.delay(0.2)) {
                trimEnd = 1.0
                rotation = 360
            }
        }
    }
}

// MARK: - Error Cross Animation

struct AnimatedErrorCross: View {
    @State private var firstLineTrim: CGFloat = 0
    @State private var secondLineTrim: CGFloat = 0
    @State private var scale: CGFloat = 0
    @State private var shake = false

    let size: CGFloat
    let color: Color

    init(size: CGFloat = 50, color: Color = .red) {
        self.size = size
        self.color = color
    }

    var body: some View {
        ZStack {
            // Circle background
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: size, height: size)
                .scaleEffect(scale)

            // First line of X
            Path { path in
                path.move(to: CGPoint(x: size * 0.3, y: size * 0.3))
                path.addLine(to: CGPoint(x: size * 0.7, y: size * 0.7))
            }
            .trim(from: 0, to: firstLineTrim)
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))

            // Second line of X
            Path { path in
                path.move(to: CGPoint(x: size * 0.7, y: size * 0.3))
                path.addLine(to: CGPoint(x: size * 0.3, y: size * 0.7))
            }
            .trim(from: 0, to: secondLineTrim)
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
        }
        .scaleEffect(scale)
        .rotationEffect(.degrees(shake ? 5 : -5))
        .onAppear {
            // Scale in
            withAnimation(AnimationSystem.Spring.bouncy) {
                scale = 1.0
            }

            // Draw first line
            withAnimation(Animation.easeOut(duration: 0.2).delay(0.2)) {
                firstLineTrim = 1.0
            }

            // Draw second line
            withAnimation(Animation.easeOut(duration: 0.2).delay(0.3)) {
                secondLineTrim = 1.0
            }

            // Shake
            withAnimation(
                Animation.easeInOut(duration: 0.1)
                    .repeatCount(3, autoreverses: true)
                    .delay(0.5)
            ) {
                shake = true
            }
        }
    }
}

// MARK: - Page Transition

struct PageTransition: ViewModifier {
    let isActive: Bool
    let edge: Edge

    func body(content: Content) -> some View {
        content
            .transition(
                .asymmetric(
                    insertion: .move(edge: edge).combined(with: .opacity),
                    removal: .move(edge: edge.opposite).combined(with: .opacity)
                )
            )
            .animation(AnimationSystem.Curve.materialEase, value: isActive)
    }
}

extension Edge {
    var opposite: Edge {
        switch self {
        case .top: .bottom
        case .bottom: .top
        case .leading: .trailing
        case .trailing: .leading
        }
    }
}

extension View {
    func pageTransition(isActive: Bool, from edge: Edge = .trailing) -> some View {
        modifier(PageTransition(isActive: isActive, edge: edge))
    }
}
