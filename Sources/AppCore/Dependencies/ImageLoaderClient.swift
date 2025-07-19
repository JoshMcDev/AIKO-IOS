import ComposableArchitecture
import Foundation
import SwiftUI

/// Dependency client for image loading functionality
@DependencyClient
public struct ImageLoaderClient: Sendable {
    public var loadImage: @Sendable (Data) -> Image? = { _ in nil }
    public var loadImageFromBundle: @Sendable (String, String, Bundle) -> Image? = { _, _, _ in nil }
}

extension ImageLoaderClient: DependencyKey {
    public static var liveValue: Self = Self()
}

extension DependencyValues {
    public var imageLoader: ImageLoaderClient {
        get { self[ImageLoaderClient.self] }
        set { self[ImageLoaderClient.self] = newValue }
    }
}