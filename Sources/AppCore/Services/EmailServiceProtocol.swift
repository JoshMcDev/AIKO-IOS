import Foundation

/// Protocol for platform-agnostic email functionality
public protocol EmailServiceProtocol: Sendable {
    /// Checks if the device can send email
    /// - Returns: True if email is available, false otherwise
    var canSendEmail: Bool { get }
    
    /// Composes and sends an email
    /// - Parameters:
    ///   - to: Array of recipient email addresses
    ///   - subject: Email subject
    ///   - body: Email body content
    ///   - isHTML: Whether the body contains HTML
    ///   - attachments: Optional array of attachment data with filenames
    ///   - completion: Completion handler with success status
    func sendEmail(
        to recipients: [String],
        subject: String,
        body: String,
        isHTML: Bool,
        attachments: [(data: Data, mimeType: String, fileName: String)]?,
        completion: @escaping (Bool) -> Void
    )
    
    /// Shows the system email composer if available
    /// - Parameters:
    ///   - recipients: Array of recipient email addresses
    ///   - subject: Email subject
    ///   - body: Email body content
    ///   - completion: Completion handler with result
    func showEmailComposer(
        recipients: [String],
        subject: String,
        body: String,
        completion: @escaping (EmailComposeResult) -> Void
    )
}

/// Result of email composition
public enum EmailComposeResult: Sendable {
    case sent
    case saved
    case cancelled
    case failed(Error)
}

/// Email service errors
public enum EmailServiceError: LocalizedError {
    case notAvailable
    case compositionFailed
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Email service is not available on this device"
        case .compositionFailed:
            return "Failed to compose email"
        case .cancelled:
            return "Email was cancelled"
        }
    }
}