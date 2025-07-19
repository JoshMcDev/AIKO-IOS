import Foundation
import SwiftUI

/// Protocol for platform-agnostic image loading functionality
public protocol ImageLoaderProtocol: Sendable {
    /// Loads an image from the given data
    /// - Parameter data: The image data to load
    /// - Returns: A SwiftUI Image if successful, nil otherwise
    func loadImage(from data: Data) -> Image?
    
    /// Loads an image from a bundle resource
    /// - Parameters:
    ///   - name: The name of the resource
    ///   - extension: The file extension
    ///   - bundle: The bundle containing the resource (defaults to Bundle.module)
    /// - Returns: A SwiftUI Image if successful, nil otherwise
    func loadImage(named name: String, withExtension ext: String, in bundle: Bundle) -> Image?
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
}