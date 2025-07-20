import ComposableArchitecture
import SwiftUI

/// Platform-agnostic font scaling service for Dynamic Type support
public protocol FontScalingServiceProtocol: Sendable {
    func scaledFontSize(for baseSize: CGFloat, textStyle: Font.TextStyle, sizeCategory: ContentSizeCategory) -> CGFloat
    func supportsUIFontMetrics() -> Bool
}

@DependencyClient
public struct FontScalingServiceClient: Sendable {
    public var _scaledFontSize: @Sendable (CGFloat, Font.TextStyle, ContentSizeCategory) -> CGFloat = { baseSize, _, sizeCategory in
        baseSize * sizeCategory.scaleFactor
    }

    public var _supportsUIFontMetrics: @Sendable () -> Bool = { false }
}

// Protocol conformance
extension FontScalingServiceClient: FontScalingServiceProtocol {
    public func scaledFontSize(for baseSize: CGFloat, textStyle: Font.TextStyle, sizeCategory: ContentSizeCategory) -> CGFloat {
        _scaledFontSize(baseSize, textStyle, sizeCategory)
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
