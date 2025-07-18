#if os(macOS)
import Foundation
import AppKit
import AppCore

/// macOS implementation of ScreenServiceProtocol
public final class macOSScreenService: ScreenServiceProtocol {
    public init() {}
    
    public var mainScreenBounds: CGRect {
        NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
    }
    
    public var mainScreenWidth: CGFloat {
        NSScreen.main?.frame.width ?? 1920
    }
    
    public var mainScreenHeight: CGFloat {
        NSScreen.main?.frame.height ?? 1080
    }
    
    public var screenScale: CGFloat {
        NSScreen.main?.backingScaleFactor ?? 2.0
    }
    
    public var isCompact: Bool {
        // macOS is never compact
        false
    }
}#endif
