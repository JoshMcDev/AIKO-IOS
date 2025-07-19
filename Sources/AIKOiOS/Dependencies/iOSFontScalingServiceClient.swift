#if os(iOS)
import SwiftUI
import AppCore
import ComposableArchitecture

extension FontScalingServiceClient {
    public static let iOS: Self = {
        let service = iOSFontScalingService()
        return Self(
            _scaledFontSize: { baseSize, textStyle, sizeCategory in
                service.scaledFontSize(for: baseSize, textStyle: textStyle, sizeCategory: sizeCategory)
            },
            _supportsUIFontMetrics: { service.supportsUIFontMetrics() }
        )
    }()
}
#endif