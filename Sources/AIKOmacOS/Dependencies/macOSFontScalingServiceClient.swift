#if os(macOS)
import AppCore
import SwiftUI

public extension FontScalingServiceClient {
    static let macOS: Self = {
        let service = MacOSFontScalingService()
        return Self(
            _scaledFontSize: { baseSize, sendableTextStyle, sendableSizeCategory in
                service.scaledFontSize(
                    for: baseSize,
                    textStyle: sendableTextStyle.textStyle,
                    sizeCategory: sendableSizeCategory.sizeCategory
                )
            },
            _supportsUIFontMetrics: { service.supportsUIFontMetrics() }
        )
    }()
}
#endif
