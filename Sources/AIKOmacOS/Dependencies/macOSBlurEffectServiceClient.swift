#if os(macOS)
import SwiftUI
import AppCore
import ComposableArchitecture

extension BlurEffectServiceClient {
    public static let macOS: Self = {
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