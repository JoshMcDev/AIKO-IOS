#if os(iOS)
import AppCore
import Foundation
import SwiftUI

/// iOS Image Loader Service Client using SimpleServiceTemplate
public final class IOSImageLoaderClient: SimpleServiceTemplate {
    private let service = IOSImageLoader()

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
            let service = IOSImageLoader()
            return service.loadImage(from: data)
        },
        loadImageFromData: { data in
            let service = IOSImageLoader()
            return service.loadImage(from: data)
        },
        createImage: { platformImage in
            let service = IOSImageLoader()
            return service.createImage(from: platformImage)
        },
        loadImageFromBundle: { name, ext, bundle in
            let service = IOSImageLoader()
            return service.loadImage(named: name, withExtension: ext, in: bundle)
        },
        loadImageFromFile: { path in
            let service = IOSImageLoader()
            return service.loadImageFromFile(path)
        },
        convertToSwiftUIImage: { platformImage in
            let service = IOSImageLoader()
            return service.convertToSwiftUIImage(platformImage)
        }
    )
}

// Convenience static accessor
public enum IOSImageLoaderClientLive {
    public static let live = ImageLoaderClient.iOSLive
}
#endif
