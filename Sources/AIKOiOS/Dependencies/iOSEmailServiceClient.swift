import AppCore
import ComposableArchitecture
import Foundation

extension EmailServiceClient {
    private static let emailService = iOSEmailService()
    
    public static let iOSLive = Self(
        canSendEmail: {
            emailService.canSendEmail
        },
        sendEmail: { recipients, subject, body, isHTML, attachments in
            await withCheckedContinuation { continuation in
                emailService.sendEmail(
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
                emailService.showEmailComposer(
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
public enum iOSEmailServiceClient {
    public static let live = EmailServiceClient.iOSLive
}