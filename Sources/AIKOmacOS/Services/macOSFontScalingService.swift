#if os(macOS)
    import AppCore
    import SwiftUI

    public final class macOSFontScalingService: FontScalingServiceProtocol {
        public init() {}

        public func scaledFontSize(for baseSize: CGFloat, textStyle _: Font.TextStyle, sizeCategory: ContentSizeCategory) -> CGFloat {
            // macOS uses a simpler scaling approach
            baseSize * sizeCategory.scaleFactor
        }

        public func supportsUIFontMetrics() -> Bool {
            false
        }
    }
#endif
