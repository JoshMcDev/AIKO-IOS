import AppCore
import ComposableArchitecture
import SwiftUI

// MARK: - Enhanced Card View

struct EnhancedCard<Content: View>: View {
    let content: () -> Content
    var style: CardStyle = .elevated
    var isInteractive: Bool = false
    var onTap: (() -> Void)?

    @State private var isPressed = false
    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Dependency(\.hapticManager) var hapticManager

    enum CardStyle {
        case flat
        case elevated
        case outlined
        case gradient
        case glassmorphism

        var shadowRadius: CGFloat {
            switch self {
            case .flat: 0
            case .elevated: 8
            case .outlined: 2
            case .gradient: 12
            case .glassmorphism: 16
            }
        }

        var shadowOpacity: Double {
            switch self {
            case .flat: 0
            case .elevated: 0.1
            case .outlined: 0.05
            case .gradient: 0.15
            case .glassmorphism: 0.2
            }
        }
    }

    var body: some View {
        content()
            .background(cardBackground)
            .overlay(cardOverlay)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            .shadow(
                color: shadowColor,
                radius: isPressed ? style.shadowRadius / 2 : style.shadowRadius,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.02 : 1.0))
            .animation(
                reduceMotion ? .linear(duration: 0.1) : AnimationSystem.Spring.smooth,
                value: isPressed
            )
            .animation(
                reduceMotion ? .linear(duration: 0.1) : AnimationSystem.Spring.gentle,
                value: isHovered
            )
            .onTapGesture {
                if isInteractive, let onTap {
                    hapticManager.impact(.light)
                    onTap()
                }
            }
            .onLongPressGesture(minimumDuration: .infinity) {} onPressingChanged: { pressing in
                if isInteractive {
                    isPressed = pressing
                }
            }
            .onHover { hovering in
                if isInteractive {
                    isHovered = hovering
                }
            }
            .accessibilityAddTraits(isInteractive ? .isButton : [])
    }

    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .flat:
            Color.gray.opacity(0.1)

        case .elevated:
            LinearGradient(
                colors: [
                    Color.gray.opacity(0.1),
                    Color.gray.opacity(0.1).opacity(0.95),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .outlined:
            Color.gray.opacity(0.1)

        case .gradient:
            LinearGradient(
                colors: [
                    colorScheme == .dark ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1),
                    colorScheme == .dark ? Color.purple.opacity(0.2) : Color.purple.opacity(0.1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .glassmorphism:
            ZStack {
                // Base color with transparency
                Color.gray.opacity(0.1).opacity(0.6)

                // Blur effect
                if #available(iOS 17.0, *) {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                } else {
                    Rectangle()
                        .fill(Material.ultraThin)
                }

                // Subtle gradient overlay
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    @ViewBuilder
    private var cardOverlay: some View {
        switch style {
        case .outlined:
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.3),
                            Color.blue.opacity(0.1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

        case .glassmorphism:
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
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

        default:
            EmptyView()
        }
    }

    private var shadowColor: Color {
        switch style {
        case .gradient:
            Color.blue.opacity(style.shadowOpacity)
        case .glassmorphism:
            Color.black.opacity(style.shadowOpacity)
        default:
            Color.black.opacity(style.shadowOpacity)
        }
    }
}

// MARK: - Card Grid Layout

struct CardGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let content: (Item) -> Content

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        items: [Item],
        columns: Int = 2,
        spacing: CGFloat = Theme.Spacing.medium,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }

    private var adaptiveColumns: [GridItem] {
        let columnCount = dynamicTypeSize.isAccessibilitySize ? 1 : columns
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }

    var body: some View {
        LazyVGrid(columns: adaptiveColumns, spacing: spacing) {
            ForEach(items) { item in
                content(item)
                    .transition(
                        .asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        )
                    )
            }
        }
        .animation(AnimationSystem.Spring.smooth, value: items.count)
    }
}

// MARK: - Skeleton Card

struct SkeletonCard: View {
    @State private var isAnimating = false

    var body: some View {
        EnhancedCard(
            content: {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    // Title skeleton
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 20)
                        .frame(maxWidth: .infinity)
                        .shimmer(duration: 1.5)

                    // Subtitle skeleton
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                        .frame(width: 200)
                        .shimmer(duration: 1.5)

                    Spacer()
                        .frame(height: Theme.Spacing.medium)

                    // Content skeleton
                    ForEach(0 ..< 3) { _ in
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 14)
                            .shimmer(duration: 1.5)
                    }
                }
                .padding()
            }, style: .flat
        )
        .accessibilityLabel("Loading content")
        .accessibilityHint("Please wait while content loads")
    }
}

// MARK: - Interactive Card Example

struct InteractiveDocumentCard: View {
    let document: DocumentType
    let isSelected: Bool
    let action: () -> Void

    @State private var showingDetails = false

    var body: some View {
        EnhancedCard(
            content: {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    HStack {
                        Image(systemName: document.icon)
                            .font(.title2)
                            .foregroundColor(Color.blue)
                            .rotationEffect(.degrees(showingDetails ? 360 : 0))
                            .animation(AnimationSystem.Spring.bouncy, value: showingDetails)

                        Spacer()

                        if isSelected {
                            AnimatedCheckmark(size: 24, color: Color.blue)
                        }
                    }

                    ResponsiveText(
                        content: document.shortName,
                        style: .headline
                    )

                    ResponsiveText(
                        content: document.description,
                        style: .footnote
                    )
                    .lineLimit(showingDetails ? nil : 2)

                    if showingDetails {
                        Divider()
                            .padding(.vertical, Theme.Spacing.extraSmall)

                        VStack(alignment: .leading, spacing: Theme.Spacing.extraSmall) {
                            // Example fields - replace with actual document fields
                            ForEach(["Field 1", "Field 2", "Field 3"], id: \.self) { field in
                                HStack(spacing: Theme.Spacing.extraSmall) {
                                    Circle()
                                        .fill(Color.blue.opacity(0.3))
                                        .frame(width: 6, height: 6)

                                    ResponsiveText(
                                        content: field,
                                        style: .caption
                                    )
                                }
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding()
            },
            style: isSelected ? .gradient : .elevated,
            isInteractive: true,
            onTap: action
        )
        .onTapGesture {
            withAnimation(AnimationSystem.Spring.smooth) {
                showingDetails.toggle()
            }
        }
        .accessibilityElement(
            label: "\(document.shortName). \(document.description)",
            hint: isSelected ? "Selected. Tap to deselect" : "Tap to select",
            traits: [.isButton, isSelected ? .isSelected : []].reduce([]) { $0.union($1) }
        )
    }
}
