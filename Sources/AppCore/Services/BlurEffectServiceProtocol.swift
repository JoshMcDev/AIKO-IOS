import SwiftUI

/// Protocol for platform-specific blur effects
public protocol BlurEffectServiceProtocol: Sendable {
    /// Creates a platform-specific blurred background view
    func createBlurredBackground(radius: CGFloat) -> AnyView

    /// Indicates whether native blur effects are supported
    func supportsNativeBlur() -> Bool

    /// Returns the recommended blur style for the platform
    func recommendedBlurStyle() -> Material
}
