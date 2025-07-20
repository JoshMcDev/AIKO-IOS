import ComposableArchitecture
import SwiftUI

@DependencyClient
public struct BlurEffectServiceClient: Sendable {
    public var _createBlurredBackground: @Sendable (CGFloat) -> AnyView = { _ in
        AnyView(Rectangle().fill(Material.ultraThin))
    }

    public var _supportsNativeBlur: @Sendable () -> Bool = { false }
    public var _recommendedBlurStyle: @Sendable () -> Material = { .ultraThin }
}

extension BlurEffectServiceClient: BlurEffectServiceProtocol {
    public func createBlurredBackground(radius: CGFloat) -> AnyView {
        _createBlurredBackground(radius)
    }

    public func supportsNativeBlur() -> Bool {
        _supportsNativeBlur()
    }

    public func recommendedBlurStyle() -> Material {
        _recommendedBlurStyle()
    }
}

extension BlurEffectServiceClient: DependencyKey {
    public static let liveValue: Self = .init()
}

public extension DependencyValues {
    var blurEffectService: BlurEffectServiceClient {
        get { self[BlurEffectServiceClient.self] }
        set { self[BlurEffectServiceClient.self] = newValue }
    }
}
