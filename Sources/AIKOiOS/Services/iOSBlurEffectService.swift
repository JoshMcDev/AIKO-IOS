#if os(iOS)
import SwiftUI
import UIKit
import AppCore

public final class iOSBlurEffectService: BlurEffectServiceProtocol {
    public init() {}
    
    public func createBlurredBackground(radius: CGFloat) -> AnyView {
        AnyView(BlurredBackgroundUIKit(radius: radius))
    }
    
    public func supportsNativeBlur() -> Bool {
        true
    }
    
    public func recommendedBlurStyle() -> Material {
        .ultraThinMaterial
    }
}

// Internal UIKit blur implementation
struct BlurredBackgroundUIKit: UIViewRepresentable {
    let radius: CGFloat
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView()
        updateUIView(view, context: context)
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context _: Context) {
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        uiView.effect = blur
    }
}
#endif