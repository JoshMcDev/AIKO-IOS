#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import Foundation

    public extension EmailServiceClient {
        static let iOSLive = Self(
            canSendEmail: {
                MainActor.assumeIsolated {
                    iOSEmailService.shared.canSendEmail
                }
            },
            sendEmail: { recipients, subject, body, isHTML, attachments in
                await withCheckedContinuation { continuation in
                    Task { @MainActor in
                        iOSEmailService.shared.sendEmail(
                            to: recipients,
                            subject: subject,
                            body: body,
                            isHTML: isHTML,
                            attachments: attachments
                        ) { success in
                            continuation.resume(returning: success)
                        }
                    }
                }
            },
            showEmailComposer: { recipients, subject, body in
                await withCheckedContinuation { continuation in
                    Task { @MainActor in
                        iOSEmailService.shared.showEmailComposer(
                            recipients: recipients,
                            subject: subject,
                            body: body
                        ) { result in
                            continuation.resume(returning: result)
                        }
                    }
                }
            }
        )
    }

    // Convenience static accessor
    public enum iOSEmailServiceClient {
        public static let live = EmailServiceClient.iOSLive
    }
#endif
