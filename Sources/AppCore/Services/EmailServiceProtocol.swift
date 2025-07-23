import Foundation

/// Email composition configuration
public struct EmailConfiguration: Sendable {
    public let recipients: [String]
    public let subject: String
    public let body: String
    public let isHTML: Bool
    public let attachments: [(data: Data, mimeType: String, fileName: String)]?

    public init(
        recipients: [String],
        subject: String,
        body: String,
        isHTML: Bool = false,
        attachments: [(data: Data, mimeType: String, fileName: String)]? = nil
    ) {
        self.recipients = recipients
        self.subject = subject
        self.body = body
        self.isHTML = isHTML
        self.attachments = attachments
    }
}

/// Email composer configuration for showing composer UI
public struct EmailComposerConfiguration: Sendable {
    public let recipients: [String]
    public let subject: String
    public let body: String

    public init(
        recipients: [String],
        subject: String,
        body: String
    ) {
        self.recipients = recipients
        self.subject = subject
        self.body = body
    }
}

/// Protocol for platform-agnostic email functionality
public protocol EmailServiceProtocol: Sendable {
    /// Checks if the device can send email
    /// - Returns: True if email is available, false otherwise
    var canSendEmail: Bool { get }

    /// Composes and sends an email
    /// - Parameters:
    ///   - configuration: Email configuration with all necessary parameters
    ///   - completion: Completion handler with success status
    func sendEmail(
        configuration: EmailConfiguration,
        completion: @escaping @Sendable (Bool) -> Void
    )

    /// Shows the system email composer if available
    /// - Parameters:
    ///   - configuration: Email composer configuration with necessary parameters
    ///   - completion: Completion handler with result
    func showEmailComposer(
        configuration: EmailComposerConfiguration,
        completion: @escaping @Sendable (EmailComposeResult) -> Void
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
public enum EmailServiceError: LocalizedError, Sendable {
    case notAvailable
    case compositionFailed
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            "Email service is not available on this device"
        case .compositionFailed:
            "Failed to compose email"
        case .cancelled:
            "Email was cancelled"
        }
    }
}
