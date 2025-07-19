import AppCore
import ComposableArchitecture
import Foundation
import SwiftUI

extension ImageLoaderClient {
    private static let imageLoader = iOSImageLoader()
    
    public static let iOSLive = Self(
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
        },
        loadImageFromFile: { path in
            imageLoader.loadImageFromFile(path)
        },
        convertToSwiftUIImage: { platformImage in
            imageLoader.convertToSwiftUIImage(platformImage)
        }
    )
}

// Convenience static accessor
public enum iOSImageLoaderClient {
    public static let live = ImageLoaderClient.iOSLive
}