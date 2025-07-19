import ComposableArchitecture
import Foundation

/// Dependency client for email functionality
@DependencyClient
public struct EmailServiceClient: Sendable {
    public var canSendEmail: @Sendable () -> Bool = { false }
    public var sendEmail: @Sendable ([String], String, String, Bool, [(data: Data, mimeType: String, fileName: String)]?) async -> Bool = { _, _, _, _, _ in false }
    public var showEmailComposer: @Sendable ([String], String, String) async -> EmailComposeResult = { _, _, _ in 
        .failed(EmailServiceError.notAvailable)
    }
}

extension EmailServiceClient: DependencyKey {
    public static var liveValue: Self = Self()
}

extension DependencyValues {
    public var emailService: EmailServiceClient {
        get { self[EmailServiceClient.self] }
        set { self[EmailServiceClient.self] = newValue }
    }
}