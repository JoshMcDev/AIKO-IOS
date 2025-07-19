import SwiftUI
import AppCore
import ComposableArchitecture

// MARK: - Dynamic Type System

/// Scalable font system that supports Dynamic Type
struct ScalableFont: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    @Dependency(\.fontScalingService) var fontScalingService

    let textStyle: Font.TextStyle
    let baseSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        content
            .font(scaledFont)
    }

    private var scaledFont: Font {
        let scaledSize = fontScalingService.scaledFontSize(
            for: baseSize,
            textStyle: textStyle,
            sizeCategory: sizeCategory
        )
        return Font.system(size: scaledSize, weight: weight, design: design)
    }
}

// MARK: - Typography Extension

extension View {
    /// Apply scalable typography with Dynamic Type support
    func scalableFont(
        _ textStyle: Font.TextStyle,
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        modifier(ScalableFont(
            textStyle: textStyle,
            baseSize: size,
            weight: weight,
            design: design
        ))
    }
}

// MARK: - Theme Typography with Dynamic Type

extension Theme {
    enum DynamicTypography {
        // Large Title
        static func largeTitle(_ text: Text) -> some View {
            text
                .font(.largeTitle)
                .fontWeight(.bold)
                .dynamicTypeSize(.xSmall ... DynamicTypeSize.accessibility3)
        }

        // Title 1
        static func title(_ text: Text) -> some View {
            text
                .font(.title)
                .fontWeight(.semibold)
                .dynamicTypeSize(.xSmall ... DynamicTypeSize.accessibility3)
        }

        // Title 2
        static func title2(_ text: Text) -> some View {
            text
                .font(.title2)
                .fontWeight(.medium)
                .dynamicTypeSize(.xSmall ... DynamicTypeSize.accessibility3)
        }

        // Title 3
        static func title3(_ text: Text) -> some View {
            text
                .font(.title3)
                .fontWeight(.medium)
                .dynamicTypeSize(.xSmall ... DynamicTypeSize.accessibility3)
        }

        // Headline
        static func headline(_ text: Text) -> some View {
            text
                .font(.headline)
                .fontWeight(.semibold)
                .dynamicTypeSize(.xSmall ... DynamicTypeSize.accessibility3)
        }

        // Body
        static func body(_ text: Text) -> some View {
            text
                .font(.body)
                .dynamicTypeSize(.xSmall ... DynamicTypeSize.accessibility3)
        }

        // Callout
        static func callout(_ text: Text) -> some View {
            text
                .font(.callout)
                .dynamicTypeSize(.xSmall ... DynamicTypeSize.accessibility3)
        }

        // Subheadline
        static func subheadline(_ text: Text) -> some View {
            text
                .font(.subheadline)
                .foregroundColor(.secondary)
                .dynamicTypeSize(.xSmall ... DynamicTypeSize.accessibility3)
        }

        // Footnote
        static func footnote(_ text: Text) -> some View {
            text
                .font(.footnote)
                .foregroundColor(.secondary)
                .dynamicTypeSize(.xSmall ... DynamicTypeSize.accessibility3)
        }

        // Caption
        static func caption(_ text: Text) -> some View {
            text
                .font(.caption)
                .foregroundColor(.secondary)
                .dynamicTypeSize(.xSmall ... DynamicTypeSize.accessibility3)
        }

        // Caption 2
        static func caption2(_ text: Text) -> some View {
            text
                .font(.caption2)
                .foregroundColor(.secondary)
                .dynamicTypeSize(.xSmall ... DynamicTypeSize.accessibility3)
        }
    }
}

// MARK: - Responsive Text Container

struct ResponsiveText: View {
    let content: String
    let style: TextStyle

    @Environment(\.sizeCategory) private var sizeCategory

    enum TextStyle {
        case largeTitle
        case title
        case title2
        case title3
        case headline
        case body
        case callout
        case subheadline
        case footnote
        case caption
        case caption2

        var maxLines: Int? {
            switch self {
            case .largeTitle, .title: 2
            case .title2, .title3, .headline: 3
            case .body: nil
            case .callout, .subheadline: 4
            case .footnote, .caption, .caption2: 2
            }
        }
    }

    var body: some View {
        Group {
            switch style {
            case .largeTitle:
                Theme.DynamicTypography.largeTitle(Text(content))
            case .title:
                Theme.DynamicTypography.title(Text(content))
            case .title2:
                Theme.DynamicTypography.title2(Text(content))
            case .title3:
                Theme.DynamicTypography.title3(Text(content))
            case .headline:
                Theme.DynamicTypography.headline(Text(content))
            case .body:
                Theme.DynamicTypography.body(Text(content))
            case .callout:
                Theme.DynamicTypography.callout(Text(content))
            case .subheadline:
                Theme.DynamicTypography.subheadline(Text(content))
            case .footnote:
                Theme.DynamicTypography.footnote(Text(content))
            case .caption:
                Theme.DynamicTypography.caption(Text(content))
            case .caption2:
                Theme.DynamicTypography.caption2(Text(content))
            }
        }
        .lineLimit(style.maxLines)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Size Category Extensions

extension ContentSizeCategory {
    var isAccessibilityCategory: Bool {
        self >= .accessibilityMedium
    }
}

// MARK: - Dynamic Layout Adjustments

struct DynamicStack<Content: View>: View {
    @Environment(\.sizeCategory) private var sizeCategory
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if sizeCategory.isAccessibilityCategory {
            // Use vertical stack for accessibility sizes
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                content
            }
        } else {
            // Use horizontal stack for regular sizes
            HStack(spacing: Theme.Spacing.md) {
                content
            }
        }
    }
}

// MARK: - Line Height Modifier

struct LineHeightModifier: ViewModifier {
    @Environment(\.sizeCategory) private var sizeCategory
    let multiplier: CGFloat

    func body(content: Content) -> some View {
        content
            .lineSpacing(lineSpacing)
    }

    private var lineSpacing: CGFloat {
        let baseSpacing: CGFloat = 4
        // Use the scale factor from AppCore's ContentSizeCategory extension
        return baseSpacing * multiplier * sizeCategory.scaleFactor
    }
}

extension View {
    func dynamicLineSpacing(_ multiplier: CGFloat = 1.0) -> some View {
        modifier(LineHeightModifier(multiplier: multiplier))
    }
}
