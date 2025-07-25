import SwiftUI

public struct BlurEffectServiceClient: Sendable {
    public var _createBlurredBackground: @Sendable (CGFloat) -> AnyView = { _ in
        AnyView(Rectangle().fill(Material.ultraThin))
    }

    public var _supportsNativeBlur: @Sendable () -> Bool = { false }
    public var _recommendedBlurStyle: @Sendable () -> Material = { .ultraThin }

    public init(
        createBlurredBackground: @escaping @Sendable (CGFloat) -> AnyView = { _ in
            AnyView(Rectangle().fill(Material.ultraThin))
        },
        supportsNativeBlur: @escaping @Sendable () -> Bool = { false },
        recommendedBlurStyle: @escaping @Sendable () -> Material = { .ultraThin }
    ) {
        _createBlurredBackground = createBlurredBackground
        _supportsNativeBlur = supportsNativeBlur
        _recommendedBlurStyle = recommendedBlurStyle
    }
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

public extension BlurEffectServiceClient {
    static let liveValue: Self = .init()
}

// MARK: - Environment Extension

public extension EnvironmentValues {
    var blurEffectService: BlurEffectServiceClient {
        get { self[BlurEffectServiceEnvironmentKey.self] }
        set { self[BlurEffectServiceEnvironmentKey.self] = newValue }
    }
}

private struct BlurEffectServiceEnvironmentKey: EnvironmentKey {
    static let defaultValue: BlurEffectServiceClient = .liveValue
}
