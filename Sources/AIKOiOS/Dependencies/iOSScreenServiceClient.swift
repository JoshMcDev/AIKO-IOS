import AppCore
import ComposableArchitecture
import Foundation

extension ScreenServiceClient {
    private static let screenService = iOSScreenService()
    
    public static let iOSLive = Self(
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
public enum iOSScreenServiceClient {
    public static let live = ScreenServiceClient.iOSLive
}