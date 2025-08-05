import AppCore
import Foundation
import UIKit

// MARK: - iOS Document Manager Implementation

/// iOS-specific implementation of DocumentManagerProtocol
/// Handles document downloads, storage, and management on iOS platform
public final class IOSDocumentManager: DocumentManagerProtocol, @unchecked Sendable {
    // MARK: - Properties

    private let session: URLSession
    private let fileManager: FileManager
    private let documentsDirectory: URL
    private let downloadQueue: DispatchQueue

    // MARK: - Initialization

    public init() {
        // Configure URLSession for downloads
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)

        fileManager = FileManager.default
        downloadQueue = DispatchQueue(label: "com.aiko.document.download", qos: .userInitiated)

        // Get iOS Documents directory
        do {
            documentsDirectory = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        } catch {
            // Fallback to temporary directory if documents directory is unavailable
            documentsDirectory = fileManager.temporaryDirectory
        }

        // Create subdirectories for different document types
        createDocumentDirectories()
    }

    // MARK: - Document Download Operations

    public func downloadDocuments(
        _ documents: [GeneratedDocument],
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> [DocumentDownloadResult] {
        guard !documents.isEmpty else { return [] }

        var results: [DocumentDownloadResult] = []
        let totalDocuments = documents.count

        for (index, document) in documents.enumerated() {
            do {
                let result = try await downloadDocument(document) { documentProgress in
                    // Calculate overall progress
                    let overallProgress = (Double(index) + documentProgress) / Double(totalDocuments)
                    progressHandler(overallProgress)
                }
                results.append(result)
            } catch {
                let failedResult = DocumentDownloadResult(
                    documentId: document.id,
                    localURL: getStorageURL(for: document.documentType ?? .sow),
                    fileName: document.title,
                    fileSize: 0,
                    success: false,
                    error: error as? DocumentManagerError ?? .downloadFailed(error.localizedDescription)
                )
                results.append(failedResult)
            }
        }

        // Final progress update
        progressHandler(1.0)
        return results
    }

    public func downloadDocument(
        _ document: GeneratedDocument,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> DocumentDownloadResult {
        // Check if document has content data (already downloaded)
        if let contentData = document.content.data(using: .utf8) {
            return try await saveDocumentData(
                data: contentData,
                document: document,
                progressHandler: progressHandler
            )
        }

        // Check if document has download URL
        guard let downloadURL = URL(string: "https://example.com/document/\(document.id)") else {
            throw DocumentManagerError.invalidDocument("No content data or download URL provided")
        }

        // Check available storage space
        let estimatedSize = try await getRemoteFileSize(url: downloadURL)
        let availableSpace = getAvailableStorageSpace()

        if estimatedSize > availableSpace {
            throw DocumentManagerError.insufficientStorage(estimatedSize - availableSpace)
        }

        // Perform download
        return try await performDownload(
            url: downloadURL,
            document: document,
            progressHandler: progressHandler
        )
    }

    // MARK: - Document Storage Operations

    public func saveDocument(
        data: Data,
        filename: String,
        documentType: DocumentType
    ) async throws -> URL {
        let storageURL = getStorageURL(for: documentType)
        let fileURL = storageURL.appendingPathComponent(filename)

        return try await withCheckedThrowingContinuation { continuation in
            downloadQueue.async {
                do {
                    try data.write(to: fileURL)
                    continuation.resume(returning: fileURL)
                } catch {
                    continuation.resume(throwing: DocumentManagerError.storageError(error.localizedDescription))
                }
            }
        }
    }

    public func getStorageURL(for documentType: DocumentType) -> URL {
        let typeDirectory = documentsDirectory.appendingPathComponent("Documents/\(documentType.rawValue)")

        // Ensure directory exists
        try? fileManager.createDirectory(at: typeDirectory, withIntermediateDirectories: true)

        return typeDirectory
    }

    // MARK: - Document Management Operations

    public func documentExists(documentId: UUID) -> Bool {
        guard let url = getLocalDocumentURL(documentId: documentId) else { return false }
        return fileManager.fileExists(atPath: url.path)
    }

    public func getLocalDocumentURL(documentId: UUID) -> URL? {
        // Search across all document type directories
        for documentType in DocumentType.allCases {
            let typeDirectory = getStorageURL(for: documentType)

            do {
                let files = try fileManager.contentsOfDirectory(at: typeDirectory, includingPropertiesForKeys: nil)
                for fileURL in files {
                    let filename = fileURL.lastPathComponent
                    if filename.contains(documentId.uuidString) {
                        return fileURL
                    }
                }
            } catch {
                continue
            }
        }

        return nil
    }

    public func deleteLocalDocument(documentId: UUID) async throws {
        guard let documentURL = getLocalDocumentURL(documentId: documentId) else {
            throw DocumentManagerError.documentNotFound(documentId)
        }

        try await withCheckedThrowingContinuation { continuation in
            downloadQueue.async { [weak self] in
                do {
                    try self?.fileManager.removeItem(at: documentURL)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: DocumentManagerError.fileSystemError(error.localizedDescription))
                }
            }
        }
    }

    public func getAvailableStorageSpace() -> Int64 {
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: documentsDirectory.path)
            if let freeSpace = attributes[.systemFreeSize] as? NSNumber {
                return freeSpace.int64Value
            }
        } catch {
            // If we can't determine free space, return a conservative estimate
            return 100 * 1024 * 1024 // 100MB
        }
        return 0
    }

    // MARK: - Private Implementation

    private func createDocumentDirectories() {
        for documentType in DocumentType.allCases {
            let typeDirectory = getStorageURL(for: documentType)
            try? fileManager.createDirectory(at: typeDirectory, withIntermediateDirectories: true)
        }
    }

    private func saveDocumentData(
        data: Data,
        document: GeneratedDocument,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> DocumentDownloadResult {
        progressHandler(0.1)

        let filename = generateUniqueFilename(for: document)
        let fileURL = try await saveDocument(data: data, filename: filename, documentType: document.documentType ?? .sow)

        progressHandler(1.0)

        return DocumentDownloadResult(
            documentId: document.id,
            localURL: fileURL,
            fileName: filename,
            fileSize: Int64(data.count)
        )
    }

    private func performDownload(
        url: URL,
        document: GeneratedDocument,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> DocumentDownloadResult {
        let filename = generateUniqueFilename(for: document)
        let storageURL = getStorageURL(for: document.documentType ?? .sow)
        let destinationURL = storageURL.appendingPathComponent(filename)

        // Use URLSession download task with progress tracking
        let (tempURL, response) = try await session.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200 ... 299 ~= httpResponse.statusCode
        else {
            throw DocumentManagerError.downloadFailed("HTTP error: \(response)")
        }

        // Move downloaded file to final destination
        try fileManager.moveItem(at: tempURL, to: destinationURL)

        let fileSize = try fileManager.attributesOfItem(atPath: destinationURL.path)[.size] as? Int64 ?? 0

        progressHandler(1.0)

        return DocumentDownloadResult(
            documentId: document.id,
            localURL: destinationURL,
            fileName: filename,
            fileSize: fileSize
        )
    }

    private func getRemoteFileSize(url: URL) async throws -> Int64 {
        let (_, response) = try await session.data(from: url)
        return response.expectedContentLength
    }

    private func generateUniqueFilename(for document: GeneratedDocument) -> String {
        let baseFilename = document.title.isEmpty ? "document" : document.title
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileExtension = (document.documentType ?? .sow).fileExtension

        // Remove existing extension if present
        let nameWithoutExtension = (baseFilename as NSString).deletingPathExtension

        return "\(nameWithoutExtension)_\(document.id.uuidString.prefix(8))_\(timestamp).\(fileExtension)"
    }
}

// MARK: - iOS-Specific Extensions

public extension IOSDocumentManager {
    /// Share documents using iOS share sheet
    /// - Parameters:
    ///   - documentURLs: URLs of documents to share
    ///   - sourceView: Source view for iPad popover presentation
    /// - Returns: UIActivityViewController for presentation
    @MainActor
    func createShareController(
        for documentURLs: [URL],
        sourceView: UIView? = nil
    ) -> UIActivityViewController {
        let activityController = UIActivityViewController(
            activityItems: documentURLs,
            applicationActivities: nil
        )

        // Configure for iPad
        if let sourceView,
           let popover = activityController.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }

        return activityController
    }

    /// Open document with system default app
    /// - Parameter documentURL: URL of document to open
    /// - Throws: DocumentManagerError if opening fails
    @MainActor
    func openDocument(at documentURL: URL) throws {
        guard fileManager.fileExists(atPath: documentURL.path) else {
            throw DocumentManagerError.documentNotFound(UUID())
        }

        if UIApplication.shared.canOpenURL(documentURL) {
            UIApplication.shared.open(documentURL)
        } else {
            throw DocumentManagerError.unsupportedDocumentType(documentURL.pathExtension)
        }
    }
}
