#if os(macOS)
import AppCore
import ComposableArchitecture
import Foundation

extension ScreenServiceClient {
    private static let screenService = macOSScreenService()
    
    public static let macOSLive = Self(
        mainScreenBounds: {
            screenService.mainScreenBounds
        },
        mainScreenWidth: {
            screenService.mainScreenWidth
        },
        mainScreenHeight: {
            screenService.mainScreenHeight
        },
        screenScale: {
            screenService.screenScale
        },
        isCompact: {
            screenService.isCompact
        }
    )
}

// Convenience static accessor
public enum macOSScreenServiceClient {
    public static let live = ScreenServiceClient.macOSLive
}#endif
