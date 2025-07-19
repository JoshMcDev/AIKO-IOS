import Foundation
import SwiftUI

/// Protocol for platform-agnostic image loading functionality
public protocol ImageLoaderProtocol: Sendable {
    /// Loads an image from the given data
    /// - Parameter data: The image data to load
    /// - Returns: A SwiftUI Image if successful, nil otherwise
    func loadImage(from data: Data) -> Image?
    
    /// Creates a SwiftUI Image from a PlatformImage
    /// - Parameter platformImage: The platform image to convert
    /// - Returns: A SwiftUI Image
    func createImage(from platformImage: PlatformImage) -> Image
    
    /// Loads an image from a bundle resource
    /// - Parameters:
    ///   - name: The name of the resource
    ///   - extension: The file extension
    ///   - bundle: The bundle containing the resource (defaults to Bundle.module)
    /// - Returns: A SwiftUI Image if successful, nil otherwise
    func loadImage(named name: String, withExtension ext: String, in bundle: Bundle) -> Image?
    
    /// Loads a PlatformImage from a file path
    /// - Parameter path: The file path to load from
    /// - Returns: A PlatformImage if successful, nil otherwise
    func loadImageFromFile(_ path: String) -> PlatformImage?
    
    /// Converts a PlatformImage to a SwiftUI Image
    /// - Parameter platformImage: The platform image to convert
    /// - Returns: A SwiftUI Image
    func convertToSwiftUIImage(_ platformImage: PlatformImage) -> Image
}

// Default implementation for bundle loading
public extension ImageLoaderProtocol {
    func loadImage(named name: String, withExtension ext: String, in bundle: Bundle = Bundle.main) -> Image? {
        guard let url = bundle.url(forResource: name, withExtension: ext),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return loadImage(from: data)
    }
    
    func createImage(from platformImage: PlatformImage) -> Image {
        // Default implementation uses loadImage(from:) with the data
        // If that fails, return a placeholder image
        loadImage(from: platformImage.data) ?? Image(systemName: "photo")
    }
}