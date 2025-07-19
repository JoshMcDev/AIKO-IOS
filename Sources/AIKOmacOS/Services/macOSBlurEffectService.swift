#if os(macOS)
import SwiftUI
import AppKit
import AppCore

public final class macOSBlurEffectService: BlurEffectServiceProtocol {
    public init() {}
    
    public func createBlurredBackground(radius: CGFloat) -> AnyView {
        // macOS fallback using standard blur
        AnyView(
            Rectangle()
                .fill(Material.ultraThin)
                .blur(radius: radius * 0.3) // Adjusted for visual similarity
        )
    }
    
    public func supportsNativeBlur() -> Bool {
        false // macOS doesn't have a direct UIVisualEffectView equivalent
    }
    
    public func recommendedBlurStyle() -> Material {
        .ultraThin
    }
}
#endif