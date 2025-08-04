#if os(macOS)
import AppCore
import AppKit
import Foundation

/// macOS implementation of EmailServiceProtocol
public final class MacOSEmailService: EmailServiceProtocol {
    public init() {}

    public var canSendEmail: Bool {
        // macOS doesn't have built-in email composer like iOS
        // Check if default mail client is configured
        if let mailURL = URL(string: "mailto:test@example.com") {
            return NSWorkspace.shared.urlForApplication(toOpen: mailURL) != nil
        }
        return false
    }

    public func sendEmail(
        configuration: EmailConfiguration,
        completion: @escaping @Sendable (Bool) -> Void
    ) {
        // macOS can only open default mail client with mailto URL
        let composerConfig = EmailComposerConfiguration(
            recipients: configuration.recipients,
            subject: configuration.subject,
            body: configuration.body
        )
        showEmailComposer(configuration: composerConfig) { result in
            switch result {
            case .sent:
                completion(true)
            default:
                completion(false)
            }
        }
    }

    public func showEmailComposer(
        configuration: EmailComposerConfiguration,
        completion: @escaping @Sendable (EmailComposeResult) -> Void
    ) {
        guard canSendEmail else {
            completion(.failed(EmailServiceError.notAvailable))
            return
        }

        // Create mailto URL
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = configuration.recipients.joined(separator: ",")

        var queryItems: [URLQueryItem] = []

        if !configuration.subject.isEmpty {
            queryItems.append(URLQueryItem(name: "subject", value: configuration.subject))
        }

        if !configuration.body.isEmpty {
            queryItems.append(URLQueryItem(name: "body", value: configuration.body))
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            completion(.failed(EmailServiceError.compositionFailed))
            return
        }

        Task { @MainActor in
            if NSWorkspace.shared.open(url) {
                // We can't know if the email was actually sent on macOS
                completion(.sent)
            } else {
                completion(.failed(EmailServiceError.compositionFailed))
            }
        }
    }
}#endif
