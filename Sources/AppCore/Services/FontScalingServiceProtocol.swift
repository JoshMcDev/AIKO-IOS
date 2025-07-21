import ComposableArchitecture
@preconcurrency import SwiftUI

// MARK: - Sendable Wrapper Types for Swift 6 Concurrency

/// Sendable wrapper for SwiftUI Font.TextStyle
public struct SendableTextStyle: Sendable {
    public let rawValue: String
    
    public init(_ textStyle: Font.TextStyle) {
        switch textStyle {
        case .largeTitle: self.rawValue = "largeTitle"
        case .title: self.rawValue = "title"
        case .title2: self.rawValue = "title2"
        case .title3: self.rawValue = "title3"
        case .headline: self.rawValue = "headline"
        case .subheadline: self.rawValue = "subheadline"
        case .body: self.rawValue = "body"
        case .callout: self.rawValue = "callout"
        case .footnote: self.rawValue = "footnote"
        case .caption: self.rawValue = "caption"
        case .caption2: self.rawValue = "caption2"
        @unknown default: self.rawValue = "body"
        }
    }
    
    public var textStyle: Font.TextStyle {
        switch rawValue {
        case "largeTitle": return .largeTitle
        case "title": return .title
        case "title2": return .title2
        case "title3": return .title3
        case "headline": return .headline
        case "subheadline": return .subheadline
        case "body": return .body
        case "callout": return .callout
        case "footnote": return .footnote
        case "caption": return .caption
        case "caption2": return .caption2
        default: return .body
        }
    }
}

/// Sendable wrapper for SwiftUI ContentSizeCategory
public struct SendableContentSizeCategory: Sendable {
    public let rawValue: String
    
    public init(_ sizeCategory: ContentSizeCategory) {
        switch sizeCategory {
        case .extraSmall: self.rawValue = "extraSmall"
        case .small: self.rawValue = "small"
        case .medium: self.rawValue = "medium"
        case .large: self.rawValue = "large"
        case .extraLarge: self.rawValue = "extraLarge"
        case .extraExtraLarge: self.rawValue = "extraExtraLarge"
        case .extraExtraExtraLarge: self.rawValue = "extraExtraExtraLarge"
        case .accessibilityMedium: self.rawValue = "accessibilityMedium"
        case .accessibilityLarge: self.rawValue = "accessibilityLarge"
        case .accessibilityExtraLarge: self.rawValue = "accessibilityExtraLarge"
        case .accessibilityExtraExtraLarge: self.rawValue = "accessibilityExtraExtraLarge"
        case .accessibilityExtraExtraExtraLarge: self.rawValue = "accessibilityExtraExtraExtraLarge"
        @unknown default: self.rawValue = "large"
        }
    }
    
    public var sizeCategory: ContentSizeCategory {
        switch rawValue {
        case "extraSmall": return .extraSmall
        case "small": return .small
        case "medium": return .medium
        case "large": return .large
        case "extraLarge": return .extraLarge
        case "extraExtraLarge": return .extraExtraLarge
        case "extraExtraExtraLarge": return .extraExtraExtraLarge
        case "accessibilityMedium": return .accessibilityMedium
        case "accessibilityLarge": return .accessibilityLarge
        case "accessibilityExtraLarge": return .accessibilityExtraLarge
        case "accessibilityExtraExtraLarge": return .accessibilityExtraExtraLarge
        case "accessibilityExtraExtraExtraLarge": return .accessibilityExtraExtraExtraLarge
        default: return .large
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
