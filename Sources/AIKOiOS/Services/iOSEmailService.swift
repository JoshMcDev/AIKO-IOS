#if os(iOS)
    import AppCore
    import Foundation
    import MessageUI
    import UIKit

    /// iOS implementation of EmailServiceProtocol
    public final class iOSEmailService: DelegateServiceTemplate<EmailComposeResult>, EmailServiceProtocol {
        override public init() {
            super.init()
        }

        public var canSendEmail: Bool {
            MFMailComposeViewController.canSendMail()
        }

        public func sendEmail(
            to recipients: [String],
            subject: String,
            body: String,
            isHTML _: Bool,
            attachments _: [(data: Data, mimeType: String, fileName: String)]?,
            completion: @escaping (Bool) -> Void
        ) {
            // iOS doesn't support background email sending
            // Show composer instead
            showEmailComposer(
                recipients: recipients,
                subject: subject,
                body: body
            ) { result in
                switch result {
                case .sent:
                    completion(true)
                default:
                    completion(false)
                }
            }
        }

        public func showEmailComposer(
            recipients: [String],
            subject: String,
            body: String,
            completion: @escaping (EmailComposeResult) -> Void
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
                mailComposer.setToRecipients(recipients)
                mailComposer.setSubject(subject)
                mailComposer.setMessageBody(body, isHTML: false)

                // Store completion handler using template system
                self.uiManager.setCompletion(completion)

                rootViewController.present(mailComposer, animated: true)
            }
        }
    }

    // MARK: - MFMailComposeViewControllerDelegate

    extension iOSEmailService: MFMailComposeViewControllerDelegate {
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
