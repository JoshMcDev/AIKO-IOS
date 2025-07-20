import ComposableArchitecture
import CoreGraphics
import Foundation

@DependencyClient
public struct ScreenServiceClient: Sendable {
    public var mainScreenBounds: @Sendable () -> CGRect = { .zero }
    public var mainScreenWidth: @Sendable () -> CGFloat = { 0 }
    public var mainScreenHeight: @Sendable () -> CGFloat = { 0 }
    public var screenScale: @Sendable () -> CGFloat = { 1.0 }
    public var isCompact: @Sendable () -> Bool = { false }
}

extension ScreenServiceClient: TestDependencyKey {
    public static let testValue = Self()
    public static let previewValue = Self(
        mainScreenBounds: { CGRect(x: 0, y: 0, width: 390, height: 844) },
        mainScreenWidth: { 390 },
        mainScreenHeight: { 844 },
        screenScale: { 3.0 },
        isCompact: { true }
    )
}

public extension DependencyValues {
    var screenService: ScreenServiceClient {
        get { self[ScreenServiceClient.self] }
        set { self[ScreenServiceClient.self] = newValue }
    }
}
