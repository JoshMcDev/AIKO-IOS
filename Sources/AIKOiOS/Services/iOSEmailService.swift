#if os(iOS)
    import AppCore
    import Foundation
    import MessageUI
    import UIKit

    /// iOS implementation of EmailServiceProtocol
    public final class iOSEmailService: DelegateServiceTemplate<EmailComposeResult>, EmailServiceProtocol {
        @MainActor
        public static let shared = iOSEmailService()
        
        override public init() {
            super.init()
        }

        nonisolated public var canSendEmail: Bool {
            // MFMailComposeViewController.canSendMail() must be called on main thread
            if Thread.isMainThread {
                return MainActor.assumeIsolated {
                    MFMailComposeViewController.canSendMail()
                }
            } else {
                return DispatchQueue.main.sync {
                    MainActor.assumeIsolated {
                        MFMailComposeViewController.canSendMail()
                    }
                }
            }
        }

        nonisolated public func sendEmail(
            to recipients: [String],
            subject: String,
            body: String,
            isHTML _: Bool,
            attachments _: [(data: Data, mimeType: String, fileName: String)]?,
            completion: @escaping @Sendable (Bool) -> Void
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

        nonisolated public func showEmailComposer(
            recipients: [String],
            subject: String,
            body: String,
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
