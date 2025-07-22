#if os(iOS)
    import AppCore
    import Foundation
    import UIKit
    import UniformTypeIdentifiers

    /// iOS implementation of FileServiceProtocol
    public final class IOSFileService: FileServiceProtocol {
        public init() {}

        public func saveFile(
            content: String,
            suggestedFileName: String,
            allowedFileTypes _: [String],
            completion: @escaping @Sendable (Result<URL, Error>) -> Void
        ) {
            Task { @MainActor in
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first,
                      let rootViewController = window.rootViewController
                else {
                    completion(.failure(FileServiceError.saveFailure(NSError(domain: "FileService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller"]))))
                    return
                }

                // Create temporary file
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedFileName)

                do {
                    try content.write(to: tempURL, atomically: true, encoding: .utf8)

                    let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL], asCopy: true)
                    documentPicker.shouldShowFileExtensions = true

                    // Present the picker
                    rootViewController.present(documentPicker, animated: true) {
                        completion(.success(tempURL))
                    }
                } catch {
                    completion(.failure(FileServiceError.saveFailure(error)))
                }
            }
        }

        public func openFile(
            allowedFileTypes: [String],
            completion: @escaping @Sendable (URL?) -> Void
        ) {
            Task { @MainActor in
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first,
                      let rootViewController = window.rootViewController
                else {
                    completion(nil)
                    return
                }

                let types = allowedFileTypes.compactMap { ext in
                    UTType(filenameExtension: ext)
                }

                let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: types)

                // Create a delegate to handle selection
                let delegate = DocumentPickerDelegate(completion: completion)
                documentPicker.delegate = delegate

                // Keep delegate alive during presentation
                objc_setAssociatedObject(documentPicker, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

                rootViewController.present(documentPicker, animated: true)
            }
        }
    }

    // Helper delegate for document picker
    private class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
        let completion: @Sendable (URL?) -> Void

        init(completion: @escaping @Sendable (URL?) -> Void) {
            self.completion = completion
        }

        func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            completion(urls.first)
        }

        func documentPickerWasCancelled(_: UIDocumentPickerViewController) {
            completion(nil)
        }
    }#endif
