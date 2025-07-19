import Foundation
import SwiftUI

/// Type-erased representation of a platform image
/// This allows us to work with images without platform conditionals
public struct PlatformImage: Sendable {
    /// The underlying image data
    public let data: Data
    
    /// Optional format hint
    public let format: ImageFormat?
    
    public enum ImageFormat: String, Sendable {
        case png = "png"
        case jpeg = "jpeg"
        case jpg = "jpg"
        case gif = "gif"
        case tiff = "tiff"
    }
    
    public init(data: Data, format: ImageFormat? = nil) {
        self.data = data
        self.format = format
    }
}

/// Extension to make PlatformImage Equatable
extension PlatformImage: Equatable {
    public static func == (lhs: PlatformImage, rhs: PlatformImage) -> Bool {
        lhs.data == rhs.data && lhs.format == rhs.format
    }
}

/// Extension to make PlatformImage Hashable
extension PlatformImage: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
        hasher.combine(format)
    }
}