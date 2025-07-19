import Foundation
import UIKit
import AppCore

/// iOS implementation of ScreenServiceProtocol
public final class iOSScreenService: ScreenServiceProtocol {
    public init() {}
    
    public var mainScreenBounds: CGRect {
        UIScreen.main.bounds
    }
    
    public var mainScreenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    public var mainScreenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    public var screenScale: CGFloat {
        UIScreen.main.scale
    }
    
    public var isCompact: Bool {
        // iPhone or iPad in compact mode
        UIDevice.current.userInterfaceIdiom == .phone ||
        (UIDevice.current.userInterfaceIdiom == .pad && mainScreenWidth < 768)
    }
}