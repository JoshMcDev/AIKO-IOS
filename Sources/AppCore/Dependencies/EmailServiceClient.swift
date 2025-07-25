import Foundation

/// Dependency client for email functionality
public struct EmailServiceClient: Sendable {
    public var canSendEmail: @Sendable () -> Bool = { false }
    public var sendEmail: @Sendable ([String], String, String, Bool, [(data: Data, mimeType: String, fileName: String)]?) async -> Bool = { _, _, _, _, _ in false }
    public var showEmailComposer: @Sendable ([String], String, String) async -> EmailComposeResult = { _, _, _ in
        .failed(EmailServiceError.notAvailable)
    }

    public init(
        canSendEmail: @escaping @Sendable () -> Bool = { false },
        sendEmail: @escaping @Sendable ([String], String, String, Bool, [(data: Data, mimeType: String, fileName: String)]?) async -> Bool = { _, _, _, _, _ in false },
        showEmailComposer: @escaping @Sendable ([String], String, String) async -> EmailComposeResult = { _, _, _ in
            .failed(EmailServiceError.notAvailable)
        }
    ) {
        self.canSendEmail = canSendEmail
        self.sendEmail = sendEmail
        self.showEmailComposer = showEmailComposer
    }
}

extension EmailServiceClient {
    public static let liveValue: Self = .init()
}
