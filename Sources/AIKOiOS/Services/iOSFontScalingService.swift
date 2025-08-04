#if os(iOS)
import AppCore
@preconcurrency import SwiftUI
import UIKit

public final class IOSFontScalingService: FontScalingServiceProtocol {
    public init() {}

    public func scaledFontSize(for baseSize: CGFloat, textStyle: Font.TextStyle, sizeCategory _: ContentSizeCategory) -> CGFloat {
        let uiTextStyle = convertToUITextStyle(textStyle)
        return UIFontMetrics(forTextStyle: uiTextStyle).scaledValue(for: baseSize)
    }

    public func supportsUIFontMetrics() -> Bool {
        true
    }

    private func convertToUITextStyle(_ textStyle: Font.TextStyle) -> UIFont.TextStyle {
        switch textStyle {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}
#endif
