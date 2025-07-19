#if os(macOS)
import SwiftUI
import AppCore

public final class macOSFontScalingService: FontScalingServiceProtocol {
    public init() {}
    
    public func scaledFontSize(for baseSize: CGFloat, textStyle: Font.TextStyle, sizeCategory: ContentSizeCategory) -> CGFloat {
        // macOS uses a simpler scaling approach
        baseSize * sizeCategory.scaleFactor
    }
    
    public func supportsUIFontMetrics() -> Bool {
        false
    }
}
#endif