#if os(iOS)
    import AppCore
    import Foundation
    import MessageUI
    import UIKit

    /// iOS implementation of EmailServiceProtocol
    public final class IOSEmailService: DelegateServiceTemplate<EmailComposeResult>, EmailServiceProtocol {
        @MainActor
        public static let shared = IOSEmailService()

        override public init() {
            super.init()
        }

        public nonisolated var canSendEmail: Bool {
            // MFMailComposeViewController.canSendMail() must be called on main thread
            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    MFMailComposeViewController.canSendMail()
                }
            } else {
                DispatchQueue.main.sync {
                    MainActor.assumeIsolated {
                        MFMailComposeViewController.canSendMail()
                    }
                }
            }
        }

        public nonisolated func sendEmail(
            configuration: EmailConfiguration,
            completion: @escaping @Sendable (Bool) -> Void
        ) {
            // iOS doesn't support background email sending
            // Show composer instead
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

        public nonisolated func showEmailComposer(
            configuration: EmailComposerConfiguration,
            completion: @escaping @Sendable (EmailComposeResult) -> Void
        ) {
            guard canSendEmail else {
                completion(.failed(EmailServiceError.notAvailable))
                return
            }

            Task { @MainActor in
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first,
                      let rootViewController = window.rootViewController
                else {
                    completion(.failed(EmailServiceError.compositionFailed))
                    return
                }

                let mailComposer = MFMailComposeViewController()
                mailComposer.mailComposeDelegate = self
                mailComposer.setToRecipients(configuration.recipients)
                mailComposer.setSubject(configuration.subject)
                mailComposer.setMessageBody(configuration.body, isHTML: false)

                // Store completion handler using template system
                self.uiManager.setCompletion(completion)

                rootViewController.present(mailComposer, animated: true)
            }
        }
    }

    // MARK: - MFMailComposeViewControllerDelegate

    extension IOSEmailService: MFMailComposeViewControllerDelegate {
        public nonisolated func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            Task { @MainActor in
                let composeResult: EmailComposeResult = switch result {
                case .sent:
                    .sent
                case .saved:
                    .saved
                case .cancelled:
                    .cancelled
                case .failed:
                    .failed(error ?? EmailServiceError.compositionFailed)
                @unknown default:
                    .failed(EmailServiceError.compositionFailed)
                }

                self.handleDelegateDismissal(controller, with: composeResult)
            }
        }
    }#endif
