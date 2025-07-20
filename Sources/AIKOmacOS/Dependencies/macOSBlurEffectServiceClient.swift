#if os(macOS)
    import AppCore
    import ComposableArchitecture
    import SwiftUI

    public extension BlurEffectServiceClient {
        static let macOS: Self = {
            let service = macOSBlurEffectService()
            return Self(
                _createBlurredBackground: { radius in
                    service.createBlurredBackground(radius: radius)
                },
                _supportsNativeBlur: { service.supportsNativeBlur() },
                _recommendedBlurStyle: { service.recommendedBlurStyle() }
            )
        }()
    }
#endif
