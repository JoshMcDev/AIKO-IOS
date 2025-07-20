#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import Foundation
    import SwiftUI

    /// iOS Image Loader Service Client using SimpleServiceTemplate
    public final class iOSImageLoaderClient: SimpleServiceTemplate {
        private let service = iOSImageLoader()

        override public init() {
            super.init()
        }

        public func loadImage(from data: Data) async -> Image? {
            await executeMainActorOperation {
                self.service.loadImage(from: data)
            }
        }

        public func loadImageFromData(_ data: Data) async -> Image? {
            await executeMainActorOperation {
                self.service.loadImage(from: data)
            }
        }

        public func createImage(from platformImage: PlatformImage) async -> Image {
            await executeMainActorOperation {
                self.service.createImage(from: platformImage)
            }
        }

        public func loadImageFromBundle(named name: String, withExtension ext: String, in bundle: Bundle) async -> Image? {
            await executeMainActorOperation {
                self.service.loadImage(named: name, withExtension: ext, in: bundle)
            }
        }

        public func loadImageFromFile(_ path: String) async -> PlatformImage? {
            await executeMainActorOperation {
                self.service.loadImageFromFile(path)
            }
        }

        public func convertToSwiftUIImage(_ platformImage: PlatformImage) async -> Image {
            await executeMainActorOperation {
                self.service.convertToSwiftUIImage(platformImage)
            }
        }
    }

    public extension ImageLoaderClient {
        static let iOSLive = Self(
            loadImage: { data in
                let client = iOSImageLoaderClient()
                return await client.loadImage(from: data)
            },
            loadImageFromData: { data in
                let client = iOSImageLoaderClient()
                return await client.loadImageFromData(data)
            },
            createImage: { platformImage in
                let client = iOSImageLoaderClient()
                return await client.createImage(from: platformImage)
            },
            loadImageFromBundle: { name, ext, bundle in
                let client = iOSImageLoaderClient()
                return await client.loadImageFromBundle(named: name, withExtension: ext, in: bundle)
            },
            loadImageFromFile: { path in
                let client = iOSImageLoaderClient()
                return await client.loadImageFromFile(path)
            },
            convertToSwiftUIImage: { platformImage in
                let client = iOSImageLoaderClient()
                return await client.convertToSwiftUIImage(platformImage)
            }
        )
    }

    // Convenience static accessor
    public enum iOSImageLoaderClient {
        public static let live = ImageLoaderClient.iOSLive
    }
#endif
