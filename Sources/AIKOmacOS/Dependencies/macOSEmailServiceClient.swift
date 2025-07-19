#if os(macOS)
import AppCore
import ComposableArchitecture
import Foundation

extension EmailServiceClient {
    public static let macOSLive = Self(
        canSendEmail: {
            macOSEmailService().canSendEmail
        },
        sendEmail: { recipients, subject, body, isHTML, attachments in
            await withCheckedContinuation { continuation in
                macOSEmailService().sendEmail(
                    to: recipients,
                    subject: subject,
                    body: body,
                    isHTML: isHTML,
                    attachments: attachments
                ) { success in
                    continuation.resume(returning: success)
                }
            }
        },
        showEmailComposer: { recipients, subject, body in
            await withCheckedContinuation { continuation in
                macOSEmailService().showEmailComposer(
                    recipients: recipients,
                    subject: subject,
                    body: body
                ) { result in
                    continuation.resume(returning: result)
                }
            }
        }
    )
}

// Convenience static accessor
public enum macOSEmailServiceClient {
    public static let live = EmailServiceClient.macOSLive
}#endif
