import ComposableArchitecture
import Foundation

// MARK: - Platform-Agnostic File System Models

/// Represents a file in the file system
public struct FileItem: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let size: Int64
    public let createdAt: Date
    public let modifiedAt: Date
    public let type: FileType
    public let attributes: FileAttributes
    
    public init(
        id: UUID = UUID(),
        url: URL,
        name: String,
        size: Int64,
        createdAt: Date,
        modifiedAt: Date,
        type: FileType,
        attributes: FileAttributes = FileAttributes()
    ) {
        self.id = id
        self.url = url
        self.name = name
        self.size = size
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.type = type
        self.attributes = attributes
    }
}

/// File type enumeration
public enum FileType: String, Equatable, Sendable, CaseIterable {
    case pdf = "PDF"
    case image = "Image"
    case document = "Document"
    case spreadsheet = "Spreadsheet"
    case presentation = "Presentation"
    case archive = "Archive"
    case text = "Text"
    case unknown = "Unknown"
    
    public static func from(extension ext: String) -> FileType {
        switch ext.lowercased() {
        case "pdf":
            return .pdf
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff":
            return .image
        case "doc", "docx", "odt", "rtf":
            return .document
        case "xls", "xlsx", "ods", "csv":
            return .spreadsheet
        case "ppt", "pptx", "odp":
            return .presentation
        case "zip", "rar", "7z", "tar", "gz":
            return .archive
        case "txt", "md":
            return .text
        default:
            return .unknown
        }
    }
}

/// File attributes
public struct FileAttributes: Equatable, Sendable {
    public let isReadOnly: Bool
    public let isHidden: Bool
    public let isDirectory: Bool
    
    public init(
        isReadOnly: Bool = false,
        isHidden: Bool = false,
        isDirectory: Bool = false
    ) {
        self.isReadOnly = isReadOnly
        self.isHidden = isHidden
        self.isDirectory = isDirectory
    }
}

/// Directory to search or save files
public enum FileDirectory: Equatable, Sendable {
    case documents
    case temporary
    case cache
    case custom(URL)
    
    public var name: String {
        switch self {
        case .documents:
            return "Documents"
        case .temporary:
            return "Temporary"
        case .cache:
            return "Cache"
        case .custom(let url):
            return url.lastPathComponent
        }
    }
}

// MARK: - File System Client Protocol

/// Platform-agnostic protocol for file system operations
@DependencyClient
public struct FileSystemClient: Sendable {
    /// Get URL for a specific directory
    public var directoryURL: @Sendable (FileDirectory) throws -> URL
    
    /// List files in a directory
    public var listFiles: @Sendable (URL, FileType?) async throws -> [FileItem]
    
    /// Save data to a file
    public var save: @Sendable (Data, String, FileDirectory) async throws -> URL
    
    /// Load data from a file
    public var load: @Sendable (URL) async throws -> Data
    
    /// Delete a file
    public var delete: @Sendable (URL) async throws -> Void
    
    /// Move a file
    public var move: @Sendable (URL, URL) async throws -> URL
    
    /// Copy a file
    public var copy: @Sendable (URL, URL) async throws -> URL
    
    /// Check if file exists
    public var fileExists: @Sendable (URL) -> Bool = { _ in false }
    
    /// Get file attributes
    public var fileAttributes: @Sendable (URL) async throws -> FileAttributes
    
    /// Create directory
    public var createDirectory: @Sendable (URL) async throws -> Void
}

// MARK: - Dependency Registration

extension FileSystemClient: DependencyKey {
    public static var liveValue: Self = Self()
    
    public static var testValue: Self = Self(
        directoryURL: { _ in URL(fileURLWithPath: "/tmp") },
        listFiles: { _, _ in [] },
        save: { _, filename, _ in URL(fileURLWithPath: "/tmp/\(filename)") },
        load: { _ in Data() },
        delete: { _ in },
        move: { _, destination in destination },
        copy: { _, destination in destination },
        fileExists: { _ in true },
        fileAttributes: { _ in FileAttributes() },
        createDirectory: { _ in }
    )
}

extension DependencyValues {
    public var fileSystem: FileSystemClient {
        get { self[FileSystemClient.self] }
        set { self[FileSystemClient.self] = newValue }
    }
}

// MARK: - File System Errors

/// Errors that can occur during file system operations
public enum FileSystemError: LocalizedError, Equatable {
    case directoryNotFound
    case fileNotFound(String)
    case accessDenied(String)
    case diskFull
    case invalidFileName(String)
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case moveFailed(String)
    case copyFailed(String)
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .directoryNotFound:
            return "Directory not found"
        case .fileNotFound(let name):
            return "File not found: \(name)"
        case .accessDenied(let path):
            return "Access denied: \(path)"
        case .diskFull:
            return "Disk is full"
        case .invalidFileName(let name):
            return "Invalid file name: \(name)"
        case .saveFailed(let reason):
            return "Failed to save file: \(reason)"
        case .loadFailed(let reason):
            return "Failed to load file: \(reason)"
        case .deleteFailed(let reason):
            return "Failed to delete file: \(reason)"
        case .moveFailed(let reason):
            return "Failed to move file: \(reason)"
        case .copyFailed(let reason):
            return "Failed to copy file: \(reason)"
        case .unknownError(let message):
            return message
        }
    }
}