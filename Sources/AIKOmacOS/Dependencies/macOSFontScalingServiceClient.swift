#if os(macOS)
    import AppCore
    import ComposableArchitecture
    import SwiftUI

    public extension FontScalingServiceClient {
        static let macOS: Self = {
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
