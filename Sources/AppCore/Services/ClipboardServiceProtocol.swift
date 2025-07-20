import Foundation

/// Protocol for platform-agnostic clipboard operations
public protocol ClipboardServiceProtocol: Sendable {
    /// Copies text to the clipboard
    /// - Parameter text: The text to copy
    func copyText(_ text: String)

    /// Copies data to the clipboard with a specific type
    /// - Parameters:
    ///   - data: The data to copy
    ///   - type: The UTI type of the data
    func copyData(_ data: Data, type: String)

    /// Gets text from the clipboard
    /// - Returns: The text content if available
    func getText() -> String?

    /// Checks if the clipboard has content of a specific type
    /// - Parameter type: The UTI type to check for
    /// - Returns: True if content of the specified type is available
    func hasContent(ofType type: String) -> Bool
}

// Common UTI types
public extension ClipboardServiceProtocol {
    static var plainTextType: String { "public.plain-text" }
    static var urlType: String { "public.url" }
    static var imageType: String { "public.image" }
}
