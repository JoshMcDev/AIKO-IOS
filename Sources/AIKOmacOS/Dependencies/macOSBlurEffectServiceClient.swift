#if os(macOS)
    import AppCore
    import SwiftUI

    public extension BlurEffectServiceClient {
        static let macOS: Self = {
            let service = MacOSBlurEffectService()
            return Self(
                createBlurredBackground: { radius in
                    service.createBlurredBackground(radius: radius)
                },
                supportsNativeBlur: { service.supportsNativeBlur() },
                recommendedBlurStyle: { service.recommendedBlurStyle() }
            )
        }()
    }
#endif
