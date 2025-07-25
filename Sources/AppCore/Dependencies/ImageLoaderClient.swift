import ComposableArchitecture
import Foundation
import SwiftUI

/// Dependency client for image loading functionality
@DependencyClient
public struct ImageLoaderClient: Sendable {
    public var loadImage: @Sendable (Data) -> Image? = { _ in nil }
    public var loadImageFromData: @Sendable (Data) -> Image? = { _ in nil }
    public var createImage: @Sendable (PlatformImage) -> Image = { _ in Image(systemName: "photo") }
    public var loadImageFromBundle: @Sendable (String, String, Bundle) -> Image? = { _, _, _ in nil }
    public var loadImageFromFile: @Sendable (String) -> PlatformImage? = { _ in nil }
    public var convertToSwiftUIImage: @Sendable (PlatformImage) -> Image = { _ in Image(systemName: "photo") }
}

extension ImageLoaderClient: DependencyKey {
    public static let liveValue: Self = .init()
}

public extension DependencyValues {
    var imageLoader: ImageLoaderClient {
        get { self[ImageLoaderClient.self] }
        set { self[ImageLoaderClient.self] = newValue }
    }
}
