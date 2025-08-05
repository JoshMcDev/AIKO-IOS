import AppCore
import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Document Picker Coordinator

/// Delegate coordinator for UIDocumentPickerViewController
@MainActor
final class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
    private let completion: ([URL], Error?) -> Void

    init(completion: @escaping ([URL], Error?) -> Void) {
        self.completion = completion
        super.init()
    }

    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        completion(urls, nil)
    }

    func documentPickerWasCancelled(_: UIDocumentPickerViewController) {
        completion([], nil)
    }
}

// MARK: - Utility Functions

/// Convert MediaType to iOS UTType
private func convertToUTType(_ mediaType: MediaType) -> UniformTypeIdentifiers.UTType? {
    switch mediaType {
    case .image, .photo, .screenshot:
        UniformTypeIdentifiers.UTType.image
    case .video:
        UniformTypeIdentifiers.UTType.movie
    case .document, .file:
        UniformTypeIdentifiers.UTType.data
    case .camera:
        UniformTypeIdentifiers.UTType.image
    }
}

/// Convert AppCore.UTType to iOS UTType
private func convertToIOSUTType(_ utType: AppCore.UTType) -> UniformTypeIdentifiers.UTType {
    UniformTypeIdentifiers.UTType(utType.identifier) ?? UniformTypeIdentifiers.UTType.data
}

/// iOS implementation of file picker service
@available(iOS 16.0, *)
public actor FilePickerService: FilePickerServiceProtocol {
    private var recentlyPicked: [URL] = []
    private var defaultOptions: FilePickerOptions = .init(
        allowedTypes: [AppCore.UTType.data],
        allowsMultipleSelection: false,
        maxFileSize: nil
    )

    public init() {}

    // MARK: - FilePickerServiceProtocol Methods

    public func presentFilePicker(options: FilePickerOptions) async throws -> FilePickerResult {
        let utTypes = options.allowedTypes.isEmpty ? [UniformTypeIdentifiers.UTType.data] : options.allowedTypes.map { convertToIOSUTType($0) }

        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: utTypes)
                documentPicker.allowsMultipleSelection = options.allowsMultipleSelection
                documentPicker.shouldShowFileExtensions = true

                let coordinator = DocumentPickerCoordinator { urls, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    // Filter by file size if specified
                    var validUrls = urls
                    if let maxSize = options.maxFileSize {
                        validUrls = urls.filter { url in
                            do {
                                let resources = try url.resourceValues(forKeys: [.fileSizeKey])
                                return (resources.fileSize ?? 0) <= maxSize
                            } catch {
                                return false
                            }
                        }
                    }

                    // Update recently picked files
                    Task {
                        await self.updateRecentlyPicked(urls: validUrls)
                    }

                    // Convert URLs to SelectedFiles for FilePickerResult
                    let selectedFiles = validUrls.compactMap { url -> SelectedFile? in
                        do {
                            let resources = try url.resourceValues(forKeys: [.fileSizeKey, .nameKey, .contentModificationDateKey, .isDirectoryKey])
                            let typeIdentifier = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier ?? "public.data"
                            return SelectedFile(
                                url: url,
                                name: resources.name ?? url.lastPathComponent,
                                size: Int64(resources.fileSize ?? 0),
                                type: AppCore.UTType(identifier: typeIdentifier),
                                lastModified: resources.contentModificationDate ?? Date(),
                                isDirectory: resources.isDirectory ?? false
                            )
                        } catch {
                            return nil
                        }
                    }

                    let result = FilePickerResult(
                        selectedFiles: selectedFiles,
                        cancelled: selectedFiles.isEmpty && !urls.isEmpty
                    )
                    continuation.resume(returning: result)
                }

                documentPicker.delegate = coordinator

                guard let presentingViewController = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first?.windows
                        .first(where: { $0.isKeyWindow })?.rootViewController
                else {
                    continuation.resume(throwing: MediaError.processingFailed("No presenting view controller found"))
                    return
                }

                presentingViewController.present(documentPicker, animated: true)
            }
        }
    }

    public func getSupportedTypes() async -> [AppCore.UTType] {
        // Common supported types for iOS file picker
        [
            AppCore.UTType(identifier: "public.data"),
            AppCore.UTType(identifier: "public.image"),
            AppCore.UTType(identifier: "public.movie"),
            AppCore.UTType(identifier: "public.audio"),
            AppCore.UTType(identifier: "public.text"),
            AppCore.UTType(identifier: "com.adobe.pdf"),
            AppCore.UTType(identifier: "org.openxmlformats.wordprocessingml.document"),
            AppCore.UTType(identifier: "com.microsoft.word.doc"),
            AppCore.UTType(identifier: "org.openxmlformats.spreadsheetml.sheet"),
            AppCore.UTType(identifier: "com.microsoft.excel.xls"),
            AppCore.UTType(identifier: "org.openxmlformats.presentationml.presentation"),
            AppCore.UTType(identifier: "com.microsoft.powerpoint.ppt"),
            AppCore.UTType(identifier: "public.zip-archive"),
            AppCore.UTType(identifier: "public.json"),
        ]
    }

    public func isTypeSupported(_ type: AppCore.UTType) async -> Bool {
        let supportedTypes = await getSupportedTypes()
        return supportedTypes.contains { $0.identifier == type.identifier } ||
            convertToUTType(MediaType.document) != nil ||
            convertToUTType(MediaType.image) != nil ||
            convertToUTType(MediaType.video) != nil
    }

    public func setDefaultOptions(_ options: FilePickerOptions) async {
        defaultOptions = options
    }

    public func getCurrentOptions() async -> FilePickerOptions {
        defaultOptions
    }

    // MARK: - Extended Methods

    public func pickFiles(
        allowedTypes: [MediaType],
        allowsMultiple: Bool,
        maxFileSize: Int64?
    ) async throws -> [URL] {
        // Convert MediaTypes to AppCore.UTTypes
        let utTypes = allowedTypes.compactMap { mediaType -> AppCore.UTType? in
            switch mediaType {
            case .image, .photo, .screenshot:
                return AppCore.UTType.image
            case .video:
                return AppCore.UTType.movie
            case .document, .file:
                return AppCore.UTType.data
            case .camera:
                return AppCore.UTType.image
            }
        }

        let options = FilePickerOptions(
            allowedTypes: utTypes,
            allowsMultipleSelection: allowsMultiple,
            maxFileSize: maxFileSize
        )

        let result = try await presentFilePicker(options: options)
        return result.selectedFiles.map(\.url)
    }

    public func pickFolder() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
                documentPicker.allowsMultipleSelection = false
                documentPicker.shouldShowFileExtensions = true

                let coordinator = DocumentPickerCoordinator { urls, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let folderUrl = urls.first else {
                        continuation.resume(throwing: MediaError.processingFailed("No folder selected"))
                        return
                    }

                    continuation.resume(returning: folderUrl)
                }

                documentPicker.delegate = coordinator

                guard let presentingViewController = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first?.windows
                        .first(where: { $0.isKeyWindow })?.rootViewController
                else {
                    continuation.resume(throwing: MediaError.processingFailed("No presenting view controller found"))
                    return
                }

                presentingViewController.present(documentPicker, animated: true)
            }
        }
    }

    public func saveFile(
        _ sourceURL: URL,
        suggestedName _: String?,
        allowedTypes _: [MediaType]
    ) async throws -> URL {
        // Note: UTTypes parameter is not used in UIDocumentPickerViewController for exporting

        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let documentPicker = UIDocumentPickerViewController(forExporting: [sourceURL])

                let coordinator = DocumentPickerCoordinator { urls, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let savedUrl = urls.first else {
                        continuation.resume(throwing: MediaError.processingFailed("File save operation cancelled"))
                        return
                    }

                    continuation.resume(returning: savedUrl)
                }

                documentPicker.delegate = coordinator

                guard let presentingViewController = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first?.windows
                        .first(where: { $0.isKeyWindow })?.rootViewController
                else {
                    continuation.resume(throwing: MediaError.processingFailed("No presenting view controller found"))
                    return
                }

                presentingViewController.present(documentPicker, animated: true)
            }
        }
    }

    public nonisolated var isAvailable: Bool {
        true
    }

    public func getRecentlyPicked(limit: Int) async -> [URL] {
        Array(recentlyPicked.prefix(limit))
    }

    public func clearRecentlyPicked() async {
        recentlyPicked.removeAll()
    }

    // MARK: - Private Methods

    private func updateRecentlyPicked(urls: [URL]) {
        // Add new URLs to the front, remove duplicates, and limit to 10
        let newUrls = urls.filter { !recentlyPicked.contains($0) }
        recentlyPicked = (newUrls + recentlyPicked).prefix(10).map { $0 }
    }
}
