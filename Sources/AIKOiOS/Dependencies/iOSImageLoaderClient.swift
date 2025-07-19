import AppCore
import ComposableArchitecture
import Foundation
import SwiftUI

extension ImageLoaderClient {
    public static let iOSLive = Self(
        loadImage: { data in
            iOSImageLoader().loadImage(from: data)
        },
        loadImageFromBundle: { name, ext, bundle in
            iOSImageLoader().loadImage(named: name, withExtension: ext, in: bundle)
        }
    )
}

// Convenience static accessor
public enum iOSImageLoaderClient {
    public static let live = ImageLoaderClient.iOSLive
}