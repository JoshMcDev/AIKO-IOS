import Foundation
import Combine

// MARK: - Document Manager Protocol

/// Protocol defining document management operations across platforms
/// Provides unified interface for document download, storage, and management
public protocol DocumentManagerProtocol: Sendable {
    
    // MARK: - Document Download Operations
    
    /// Download multiple documents with progress tracking
    /// - Parameters:
    ///   - documents: Array of documents to download
    ///   - progressHandler: Closure called with progress updates (0.0 to 1.0)
    /// - Returns: Array of successful download results
    /// - Throws: DocumentManagerError for any failures
    func downloadDocuments(
        _ documents: [GeneratedDocument],
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> [DocumentDownloadResult]
    
    /// Download a single document
    /// - Parameters:
    ///   - document: Document to download
    ///   - progressHandler: Progress callback (0.0 to 1.0)
    /// - Returns: Download result with local file URL
    /// - Throws: DocumentManagerError for failures
    func downloadDocument(
        _ document: GeneratedDocument,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> DocumentDownloadResult
    
    // MARK: - Document Storage Operations
    
    /// Save document data to platform-appropriate location
    /// - Parameters:
    ///   - data: Document data to save
    ///   - filename: Desired filename
    ///   - documentType: Type of document for organization
    /// - Returns: Local file URL where document was saved
    /// - Throws: DocumentManagerError for storage failures
    func saveDocument(
        data: Data,
        filename: String,
        documentType: DocumentType
    ) async throws -> URL
    
    /// Get local storage URL for document type
    /// - Parameter documentType: Type of document
    /// - Returns: Directory URL for document storage
    func getStorageURL(for documentType: DocumentType) -> URL
    
    // MARK: - Document Management Operations
    
    /// Check if document exists locally
    /// - Parameter documentId: Unique document identifier
    /// - Returns: True if document exists locally
    func documentExists(documentId: UUID) -> Bool
    
    /// Get local file URL for document
    /// - Parameter documentId: Unique document identifier
    /// - Returns: Local file URL if document exists
    func getLocalDocumentURL(documentId: UUID) -> URL?
    
    /// Delete local document
    /// - Parameter documentId: Unique document identifier
    /// - Throws: DocumentManagerError if deletion fails
    func deleteLocalDocument(documentId: UUID) async throws
    
    /// Get available storage space
    /// - Returns: Available bytes for document storage
    func getAvailableStorageSpace() -> Int64
}

// MARK: - Supporting Types

/// Result of document download operation
public struct DocumentDownloadResult: Sendable {
    public let documentId: UUID
    public let localURL: URL
    public let fileName: String
    public let fileSize: Int64
    public let downloadDate: Date
    public let success: Bool
    public let error: DocumentManagerError?
    
    public init(
        documentId: UUID,
        localURL: URL,
        fileName: String,
        fileSize: Int64,
        downloadDate: Date = Date(),
        success: Bool = true,
        error: DocumentManagerError? = nil
    ) {
        self.documentId = documentId
        self.localURL = localURL
        self.fileName = fileName
        self.fileSize = fileSize
        self.downloadDate = downloadDate
        self.success = success
        self.error = error
    }
}

/// Comprehensive error handling for document operations
public enum DocumentManagerError: Error, LocalizedError, Sendable {
    case networkError(String)
    case storageError(String)
    case fileSystemError(String)
    case invalidDocument(String)
    case downloadFailed(String)
    case insufficientStorage(Int64)
    case permissionDenied
    case documentNotFound(UUID)
    case unsupportedDocumentType(String)
    case corruptedData
    
    public var errorDescription: String? {
        switch self {
        case let .networkError(message):
            return "Network error: \(message)"
        case let .storageError(message):
            return "Storage error: \(message)"
        case let .fileSystemError(message):
            return "File system error: \(message)"
        case let .invalidDocument(message):
            return "Invalid document: \(message)"
        case let .downloadFailed(message):
            return "Download failed: \(message)"
        case let .insufficientStorage(needed):
            return "Insufficient storage space. Need \(ByteCountFormatter().string(fromByteCount: needed)) more."
        case .permissionDenied:
            return "Permission denied. Please check app permissions for file access."
        case let .documentNotFound(id):
            return "Document not found: \(id.uuidString)"
        case let .unsupportedDocumentType(type):
            return "Unsupported document type: \(type)"
        case .corruptedData:
            return "Document data is corrupted and cannot be processed."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again."
        case .storageError, .insufficientStorage:
            return "Free up storage space and try again."
        case .fileSystemError:
            return "Check file permissions and try again."
        case .permissionDenied:
            return "Grant file access permission in Settings."
        case .downloadFailed:
            return "Try downloading the document again."
        default:
            return "Please try again or contact support if the problem persists."
        }
    }
}

// MARK: - Progress Tracking

/// Progress information for document operations
public struct DocumentOperationProgress: Sendable {
    public let documentId: UUID
    public let fileName: String
    public let bytesProcessed: Int64
    public let totalBytes: Int64
    public let progress: Double
    public let estimatedTimeRemaining: TimeInterval?
    
    public init(
        documentId: UUID,
        fileName: String,
        bytesProcessed: Int64,
        totalBytes: Int64,
        estimatedTimeRemaining: TimeInterval? = nil
    ) {
        self.documentId = documentId
        self.fileName = fileName
        self.bytesProcessed = bytesProcessed
        self.totalBytes = totalBytes
        self.progress = totalBytes > 0 ? Double(bytesProcessed) / Double(totalBytes) : 0.0
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
}