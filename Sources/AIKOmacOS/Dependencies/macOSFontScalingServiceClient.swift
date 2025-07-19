#if os(macOS)
import SwiftUI
import AppCore
import ComposableArchitecture

extension FontScalingServiceClient {
    public static let macOS: Self = {
        let service = macOSFontScalingService()
        return Self(
            _scaledFontSize: { baseSize, textStyle, sizeCategory in
                service.scaledFontSize(for: baseSize, textStyle: textStyle, sizeCategory: sizeCategory)
            },
            _supportsUIFontMetrics: { service.supportsUIFontMetrics() }
        )
    }()
}
#endif