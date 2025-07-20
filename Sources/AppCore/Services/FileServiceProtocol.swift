import Foundation

/// Protocol for platform-agnostic file operations
public protocol FileServiceProtocol: Sendable {
    /// Shows a save dialog and saves content to the selected location
    /// - Parameters:
    ///   - content: The text content to save
    ///   - suggestedFileName: The suggested file name
    ///   - allowedFileTypes: Array of allowed file types (e.g., ["txt", "md"])
    ///   - completion: Completion handler with the saved URL or error
    func saveFile(
        content: String,
        suggestedFileName: String,
        allowedFileTypes: [String],
        completion: @escaping @Sendable (Result<URL, Error>) -> Void
    )

    /// Shows an open dialog to select a file
    /// - Parameters:
    ///   - allowedFileTypes: Array of allowed file types
    ///   - completion: Completion handler with the selected URL or nil
    func openFile(
        allowedFileTypes: [String],
        completion: @escaping @Sendable (URL?) -> Void
    )
}

/// Errors that can occur during file operations
public enum FileServiceError: LocalizedError, Sendable {
    case saveCancelled
    case saveFailure(Error)
    case openCancelled
    case saveFailed
    case openFailed
    case accessDenied
    case invalidURL

    public var errorDescription: String? {
        switch self {
        case .saveCancelled:
            "Save operation was cancelled"
        case let .saveFailure(error):
            "Failed to save file: \(error.localizedDescription)"
        case .openCancelled:
            "Open operation was cancelled"
        case .saveFailed:
            "Failed to save file"
        case .openFailed:
            "Failed to open file"
        case .accessDenied:
            "Access denied to file system"
        case .invalidURL:
            "Invalid file URL"
        }
    }
}
