import ComposableArchitecture
@preconcurrency import SwiftUI

// MARK: - Sendable Wrapper Types for Swift 6 Concurrency

/// Sendable wrapper for SwiftUI Font.TextStyle
public struct SendableTextStyle: Sendable {
    public let rawValue: String

    public init(_ textStyle: Font.TextStyle) {
        switch textStyle {
        case .largeTitle: rawValue = "largeTitle"
        case .title: rawValue = "title"
        case .title2: rawValue = "title2"
        case .title3: rawValue = "title3"
        case .headline: rawValue = "headline"
        case .subheadline: rawValue = "subheadline"
        case .body: rawValue = "body"
        case .callout: rawValue = "callout"
        case .footnote: rawValue = "footnote"
        case .caption: rawValue = "caption"
        case .caption2: rawValue = "caption2"
        @unknown default: rawValue = "body"
        }
    }

    public var textStyle: Font.TextStyle {
        switch rawValue {
        case "largeTitle": .largeTitle
        case "title": .title
        case "title2": .title2
        case "title3": .title3
        case "headline": .headline
        case "subheadline": .subheadline
        case "body": .body
        case "callout": .callout
        case "footnote": .footnote
        case "caption": .caption
        case "caption2": .caption2
        default: .body
        }
    }
}

/// Sendable wrapper for SwiftUI ContentSizeCategory
public struct SendableContentSizeCategory: Sendable {
    public let rawValue: String

    public init(_ sizeCategory: ContentSizeCategory) {
        switch sizeCategory {
        case .extraSmall: rawValue = "extraSmall"
        case .small: rawValue = "small"
        case .medium: rawValue = "medium"
        case .large: rawValue = "large"
        case .extraLarge: rawValue = "extraLarge"
        case .extraExtraLarge: rawValue = "extraExtraLarge"
        case .extraExtraExtraLarge: rawValue = "extraExtraExtraLarge"
        case .accessibilityMedium: rawValue = "accessibilityMedium"
        case .accessibilityLarge: rawValue = "accessibilityLarge"
        case .accessibilityExtraLarge: rawValue = "accessibilityExtraLarge"
        case .accessibilityExtraExtraLarge: rawValue = "accessibilityExtraExtraLarge"
        case .accessibilityExtraExtraExtraLarge: rawValue = "accessibilityExtraExtraExtraLarge"
        @unknown default: rawValue = "large"
        }
    }

    public var sizeCategory: ContentSizeCategory {
        switch rawValue {
        case "extraSmall": .extraSmall
        case "small": .small
        case "medium": .medium
        case "large": .large
        case "extraLarge": .extraLarge
        case "extraExtraLarge": .extraExtraLarge
        case "extraExtraExtraLarge": .extraExtraExtraLarge
        case "accessibilityMedium": .accessibilityMedium
        case "accessibilityLarge": .accessibilityLarge
        case "accessibilityExtraLarge": .accessibilityExtraLarge
        case "accessibilityExtraExtraLarge": .accessibilityExtraExtraLarge
        case "accessibilityExtraExtraExtraLarge": .accessibilityExtraExtraExtraLarge
        default: .large
        }
    }
}

/// Platform-agnostic font scaling service for Dynamic Type support
public protocol FontScalingServiceProtocol: Sendable {
    func scaledFontSize(for baseSize: CGFloat, textStyle: Font.TextStyle, sizeCategory: ContentSizeCategory) -> CGFloat
    func supportsUIFontMetrics() -> Bool
}

@DependencyClient
public struct FontScalingServiceClient: Sendable {
    public var _scaledFontSize: @Sendable (CGFloat, SendableTextStyle, SendableContentSizeCategory) -> CGFloat = { baseSize, _, sizeCategory in
        baseSize * sizeCategory.sizeCategory.scaleFactor
    }

    public var _supportsUIFontMetrics: @Sendable () -> Bool = { false }
}

// Protocol conformance
extension FontScalingServiceClient: FontScalingServiceProtocol {
    public func scaledFontSize(for baseSize: CGFloat, textStyle: Font.TextStyle, sizeCategory: ContentSizeCategory) -> CGFloat {
        _scaledFontSize(baseSize, SendableTextStyle(textStyle), SendableContentSizeCategory(sizeCategory))
    }

    public func supportsUIFontMetrics() -> Bool {
        _supportsUIFontMetrics()
    }
}

// MARK: - ContentSizeCategory Extensions

public extension ContentSizeCategory {
    var scaleFactor: CGFloat {
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.85
        case .medium: return 0.9
        case .large: return 1.0
        case .extraLarge: return 1.1
        case .extraExtraLarge: return 1.2
        case .extraExtraExtraLarge: return 1.3
        case .accessibilityMedium: return 1.4
        case .accessibilityLarge: return 1.6
        case .accessibilityExtraLarge: return 1.8
        case .accessibilityExtraExtraLarge: return 2.0
        case .accessibilityExtraExtraExtraLarge: return 2.4
        @unknown default: return 1.0
        }
    }
}

// MARK: - Dependency

private enum FontScalingServiceKey: DependencyKey {
    static let liveValue: FontScalingServiceProtocol = FontScalingServiceClient()
}

public extension DependencyValues {
    var fontScalingService: FontScalingServiceProtocol {
        get { self[FontScalingServiceKey.self] }
        set { self[FontScalingServiceKey.self] = newValue }
    }
}
