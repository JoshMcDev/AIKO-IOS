#if os(macOS)
    import AppCore
    import ComposableArchitecture
    import Foundation

    public extension EmailServiceClient {
        static let macOSLive = Self(
            canSendEmail: {
                MacOSEmailService().canSendEmail
            },
            sendEmail: { recipients, subject, body, isHTML, attachments in
                await withCheckedContinuation { continuation in
                    MacOSEmailService().sendEmail(
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
                    MacOSEmailService().showEmailComposer(
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
    public enum MacOSEmailServiceClient {
        public static let live = EmailServiceClient.macOSLive
    }#endif
