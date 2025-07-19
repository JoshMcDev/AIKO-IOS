import Foundation
import MessageUI
import UIKit
import AppCore

/// iOS implementation of EmailServiceProtocol
public final class iOSEmailService: NSObject, EmailServiceProtocol, @unchecked Sendable {
    private var currentCompletion: ((EmailComposeResult) -> Void)?
    
    public override init() {
        super.init()
    }
    
    public var canSendEmail: Bool {
        MFMailComposeViewController.canSendMail()
    }
    
    public func sendEmail(
        to recipients: [String],
        subject: String,
        body: String,
        isHTML: Bool,
        attachments: [(data: Data, mimeType: String, fileName: String)]?,
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
                  let rootViewController = window.rootViewController else {
                completion(.failed(EmailServiceError.compositionFailed))
                return
            }
            
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(recipients)
            mailComposer.setSubject(subject)
            mailComposer.setMessageBody(body, isHTML: false)
            
            // Store completion handler
            self.currentCompletion = completion
            
            rootViewController.present(mailComposer, animated: true)
        }
    }
}

// MARK: - MFMailComposeViewControllerDelegate
extension iOSEmailService: MFMailComposeViewControllerDelegate {
    public func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true) { [weak self] in
            guard let completion = self?.currentCompletion else { return }
            
            switch result {
            case .sent:
                completion(.sent)
            case .saved:
                completion(.saved)
            case .cancelled:
                completion(.cancelled)
            case .failed:
                completion(.failed(error ?? EmailServiceError.compositionFailed))
            @unknown default:
                completion(.failed(EmailServiceError.compositionFailed))
            }
            
            self?.currentCompletion = nil
        }
    }
}