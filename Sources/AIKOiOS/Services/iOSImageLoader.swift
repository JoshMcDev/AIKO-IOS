#if os(iOS)
    import AppCore
    import Foundation
    import SwiftUI
    import UIKit

    /// iOS implementation of ImageLoaderProtocol
    public final class IOSImageLoader: ImageLoaderProtocol {
        public init() {}

        public func loadImage(from data: Data) -> Image? {
            guard let uiImage = UIImage(data: data) else {
                return nil
            }
            return Image(uiImage: uiImage)
        }

        public func createImage(from platformImage: PlatformImage) -> Image {
            guard let uiImage = UIImage(data: platformImage.data) else {
                return Image(systemName: "photo")
            }
            return Image(uiImage: uiImage)
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
            guard let uiImage = UIImage(contentsOfFile: path),
                  let data = uiImage.pngData()
            else {
                return nil
            }
            return PlatformImage(data: data, format: .png)
        }

        public func convertToSwiftUIImage(_ platformImage: PlatformImage) -> Image {
            createImage(from: platformImage)
        }
    }#endif
