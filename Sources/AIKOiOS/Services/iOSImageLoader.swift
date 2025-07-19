import Foundation
import SwiftUI
import UIKit
import AppCore

/// iOS implementation of ImageLoaderProtocol
public final class iOSImageLoader: ImageLoaderProtocol {
    public init() {}
    
    public func loadImage(from data: Data) -> Image? {
        guard let uiImage = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}