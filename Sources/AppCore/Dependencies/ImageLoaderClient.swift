import Foundation
import SwiftUI

/// Dependency client for image loading functionality
public struct ImageLoaderClient: Sendable {
    public var loadImage: @Sendable (Data) -> Image? = { _ in nil }
    public var loadImageFromData: @Sendable (Data) -> Image? = { _ in nil }
    public var createImage: @Sendable (PlatformImage) -> Image = { _ in Image(systemName: "photo") }
    public var loadImageFromBundle: @Sendable (String, String, Bundle) -> Image? = { _, _, _ in nil }
    public var loadImageFromFile: @Sendable (String) -> PlatformImage? = { _ in nil }
    public var convertToSwiftUIImage: @Sendable (PlatformImage) -> Image = { _ in Image(systemName: "photo") }

    public init(
        loadImage: @escaping @Sendable (Data) -> Image? = { _ in nil },
        loadImageFromData: @escaping @Sendable (Data) -> Image? = { _ in nil },
        createImage: @escaping @Sendable (PlatformImage) -> Image = { _ in Image(systemName: "photo") },
        loadImageFromBundle: @escaping @Sendable (String, String, Bundle) -> Image? = { _, _, _ in nil },
        loadImageFromFile: @escaping @Sendable (String) -> PlatformImage? = { _ in nil },
        convertToSwiftUIImage: @escaping @Sendable (PlatformImage) -> Image = { _ in Image(systemName: "photo") }
    ) {
        self.loadImage = loadImage
        self.loadImageFromData = loadImageFromData
        self.createImage = createImage
        self.loadImageFromBundle = loadImageFromBundle
        self.loadImageFromFile = loadImageFromFile
        self.convertToSwiftUIImage = convertToSwiftUIImage
    }
}

extension ImageLoaderClient {
    public static let liveValue: Self = .init()
}
