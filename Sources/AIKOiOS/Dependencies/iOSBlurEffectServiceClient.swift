#if os(iOS)
import SwiftUI
import AppCore
import ComposableArchitecture

extension BlurEffectServiceClient {
    public static let iOS: Self = {
        let service = iOSBlurEffectService()
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