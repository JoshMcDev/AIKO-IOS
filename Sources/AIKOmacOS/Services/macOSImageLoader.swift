#if os(macOS)
import Foundation
import SwiftUI
import AppKit
import AppCore

/// macOS implementation of ImageLoaderProtocol
public final class macOSImageLoader: ImageLoaderProtocol {
    public init() {}
    
    public func loadImage(from data: Data) -> Image? {
        guard let nsImage = NSImage(data: data) else {
            return nil
        }
        return Image(nsImage: nsImage)
    }
}#endif
