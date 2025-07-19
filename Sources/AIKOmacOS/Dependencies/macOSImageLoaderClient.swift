import AppCore
import ComposableArchitecture
import Foundation
import SwiftUI

extension ImageLoaderClient {
    public static let macOSLive = Self(
        loadImage: { data in
            macOSImageLoader().loadImage(from: data)
        },
        loadImageFromBundle: { name, ext, bundle in
            macOSImageLoader().loadImage(named: name, withExtension: ext, in: bundle)
        }
    )
}

// Convenience static accessor
public enum macOSImageLoaderClient {
    public static let live = ImageLoaderClient.macOSLive
}