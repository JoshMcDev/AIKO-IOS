#if os(macOS)
import AppCore
import AppKit
import Foundation
import SwiftUI

/// macOS implementation of ImageLoaderProtocol
public final class MacOSImageLoader: ImageLoaderProtocol {
    public init() {}

    public func loadImage(from data: Data) -> Image? {
        guard let nsImage = NSImage(data: data) else {
            return nil
        }
        return Image(nsImage: nsImage)
    }

    public func createImage(from platformImage: PlatformImage) -> Image {
        guard let nsImage = NSImage(data: platformImage.data) else {
            return Image(systemName: "photo")
        }
        return Image(nsImage: nsImage)
    }

    public func loadImage(named name: String, withExtension ext: String, in bundle: Bundle) -> Image? {
        guard let url = bundle.url(forResource: name, withExtension: ext),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        return loadImage(from: data)
    }

    public func loadImageFromFile(_ path: String) -> PlatformImage? {
        guard let nsImage = NSImage(contentsOfFile: path),
              let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: .png, properties: [:])
        else {
            return nil
        }
        return PlatformImage(data: data, format: .png)
    }

    public func convertToSwiftUIImage(_ platformImage: PlatformImage) -> Image {
        createImage(from: platformImage)
    }
}#endif
