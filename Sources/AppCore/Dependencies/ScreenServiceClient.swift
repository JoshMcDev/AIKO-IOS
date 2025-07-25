import CoreGraphics
import Foundation

public struct ScreenServiceClient: Sendable {
    public var mainScreenBounds: @Sendable () -> CGRect = { .zero }
    public var mainScreenWidth: @Sendable () -> CGFloat = { 0 }
    public var mainScreenHeight: @Sendable () -> CGFloat = { 0 }
    public var screenScale: @Sendable () -> CGFloat = { 1.0 }
    public var isCompact: @Sendable () -> Bool = { false }

    public init(
        mainScreenBounds: @escaping @Sendable () -> CGRect = { .zero },
        mainScreenWidth: @escaping @Sendable () -> CGFloat = { 0 },
        mainScreenHeight: @escaping @Sendable () -> CGFloat = { 0 },
        screenScale: @escaping @Sendable () -> CGFloat = { 1.0 },
        isCompact: @escaping @Sendable () -> Bool = { false }
    ) {
        self.mainScreenBounds = mainScreenBounds
        self.mainScreenWidth = mainScreenWidth
        self.mainScreenHeight = mainScreenHeight
        self.screenScale = screenScale
        self.isCompact = isCompact
    }
}

public extension ScreenServiceClient {
    static let testValue = Self()
    static let previewValue = Self(
        mainScreenBounds: { CGRect(x: 0, y: 0, width: 390, height: 844) },
        mainScreenWidth: { 390 },
        mainScreenHeight: { 844 },
        screenScale: { 3.0 },
        isCompact: { true }
    )
}
