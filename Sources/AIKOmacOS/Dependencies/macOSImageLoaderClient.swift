#if os(macOS)
import AppCore
import ComposableArchitecture
import Foundation
import SwiftUI

extension ImageLoaderClient {
    private static let imageLoader = macOSImageLoader()
    
    public static let macOSLive = Self(
        loadImage: { data in
            imageLoader.loadImage(from: data)
        },
        loadImageFromData: { data in
            imageLoader.loadImage(from: data)
        },
        createImage: { platformImage in
            imageLoader.createImage(from: platformImage)
        },
        loadImageFromBundle: { name, ext, bundle in
            imageLoader.loadImage(named: name, withExtension: ext, in: bundle)
        }
    )
}

// Convenience static accessor
public enum macOSImageLoaderClient {
    public static let live = ImageLoaderClient.macOSLive
}#endif
