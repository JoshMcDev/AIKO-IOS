#if os(macOS)
import Foundation
import AppCore
import AppKit

// MARK: - macOS Document Manager Implementation

/// macOS-specific implementation of DocumentManagerProtocol
/// Handles document downloads, storage, and management on macOS platform
public final class macOSDocumentManager: DocumentManagerProtocol, @unchecked Sendable {
    
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
        config.timeoutIntervalForResource = 600 // Longer timeout for macOS
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        
        self.fileManager = FileManager.default
        self.downloadQueue = DispatchQueue(label: "com.aiko.document.download.macos", qos: .userInitiated)
        
        // Get macOS Documents directory - prefer Downloads folder for user access
        self.documentsDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first ??
                                 fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ??
                                 fileManager.temporaryDirectory
        
        // Create AIKO subdirectory in Downloads/Documents
        let aikoDirectory = documentsDirectory.appendingPathComponent("AIKO Documents")
        try? fileManager.createDirectory(at: aikoDirectory, withIntermediateDirectories: true)
        
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
                    localURL: getStorageURL(for: .rrd), // Default DocumentType
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
        // Convert document content to data for saving
        let contentData = Data(document.content.utf8)
        
        return try await saveDocumentData(
            data: contentData,
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
        let aikoDirectory = documentsDirectory.appendingPathComponent("AIKO Documents")
        let typeDirectory = aikoDirectory.appendingPathComponent(documentType.rawValue.uppercased())
        
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
                    // Move to trash on macOS instead of permanent deletion
                    try self?.fileManager.trashItem(at: documentURL, resultingItemURL: nil)
                    continuation.resume()
                } catch {
                    // Fallback to permanent deletion if trash fails
                    do {
                        try self?.fileManager.removeItem(at: documentURL)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: DocumentManagerError.fileSystemError(error.localizedDescription))
                    }
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
            return 1024 * 1024 * 1024 // 1GB for macOS
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
        let fileURL = try await saveDocument(data: data, filename: filename, documentType: .rrd)
        
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
        let storageURL = getStorageURL(for: .rrd)
        let destinationURL = storageURL.appendingPathComponent(filename)
        
        // Use URLSession download task with progress tracking
        let (tempURL, response) = try await session.download(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
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
        let fileExtension = "pdf" // Default extension for generated documents
        
        // Remove existing extension if present
        let nameWithoutExtension = (baseFilename as NSString).deletingPathExtension
        
        return "\(nameWithoutExtension)_\(document.id.uuidString.prefix(8))_\(timestamp).\(fileExtension)"
    }
}

// MARK: - macOS-Specific Extensions

extension macOSDocumentManager {
    
    /// Reveal document in Finder
    /// - Parameter documentURL: URL of document to reveal
    public func revealInFinder(documentURL: URL) {
        NSWorkspace.shared.selectFile(documentURL.path, inFileViewerRootedAtPath: "")
    }
    
    /// Open document with default app
    /// - Parameter documentURL: URL of document to open
    /// - Throws: DocumentManagerError if opening fails
    public func openDocument(at documentURL: URL) throws {
        guard fileManager.fileExists(atPath: documentURL.path) else {
            throw DocumentManagerError.documentNotFound(UUID())
        }
        
        if !NSWorkspace.shared.open(documentURL) {
            throw DocumentManagerError.unsupportedDocumentType(documentURL.pathExtension)
        }
    }
    
    /// Get file type description for display
    /// - Parameter documentURL: URL of document
    /// - Returns: Human-readable file type description
    public func getFileTypeDescription(for documentURL: URL) -> String {
        do {
            let resourceValues = try documentURL.resourceValues(forKeys: [.typeIdentifierKey])
            if let typeIdentifier = resourceValues.typeIdentifier {
                return NSWorkspace.shared.localizedDescription(forType: typeIdentifier) ?? documentURL.pathExtension.uppercased()
            }
        } catch {
            // Fallback to extension
        }
        
        return documentURL.pathExtension.uppercased()
    }
    
    /// Get document icon for display
    /// - Parameter documentURL: URL of document
    /// - Returns: NSImage icon for the document
    public func getDocumentIcon(for documentURL: URL) -> NSImage {
        return NSWorkspace.shared.icon(forFile: documentURL.path)
    }
    
    /// Create alias (symbolic link) to document
    /// - Parameters:
    ///   - documentURL: Source document URL
    ///   - aliasURL: Destination alias URL
    /// - Throws: DocumentManagerError if alias creation fails
    public func createAlias(from documentURL: URL, to aliasURL: URL) throws {
        do {
            try fileManager.createSymbolicLink(at: aliasURL, withDestinationURL: documentURL)
        } catch {
            throw DocumentManagerError.fileSystemError("Failed to create alias: \(error.localizedDescription)")
        }
    }
}

#endif