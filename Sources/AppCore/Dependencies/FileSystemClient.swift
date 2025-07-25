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
            .pdf
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff":
            .image
        case "doc", "docx", "odt", "rtf":
            .document
        case "xls", "xlsx", "ods", "csv":
            .spreadsheet
        case "ppt", "pptx", "odp":
            .presentation
        case "zip", "rar", "7z", "tar", "gz":
            .archive
        case "txt", "md":
            .text
        default:
            .unknown
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
            "Documents"
        case .temporary:
            "Temporary"
        case .cache:
            "Cache"
        case let .custom(url):
            url.lastPathComponent
        }
    }
}

// MARK: - File System Client Protocol

/// Platform-agnostic protocol for file system operations
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

    // MARK: - Initializer

    public init(
        directoryURL: @escaping @Sendable (FileDirectory) throws -> URL,
        listFiles: @escaping @Sendable (URL, FileType?) async throws -> [FileItem],
        save: @escaping @Sendable (Data, String, FileDirectory) async throws -> URL,
        load: @escaping @Sendable (URL) async throws -> Data,
        delete: @escaping @Sendable (URL) async throws -> Void,
        move: @escaping @Sendable (URL, URL) async throws -> URL,
        copy: @escaping @Sendable (URL, URL) async throws -> URL,
        fileExists: @escaping @Sendable (URL) -> Bool = { _ in false },
        fileAttributes: @escaping @Sendable (URL) async throws -> FileAttributes,
        createDirectory: @escaping @Sendable (URL) async throws -> Void
    ) {
        self.directoryURL = directoryURL
        self.listFiles = listFiles
        self.save = save
        self.load = load
        self.delete = delete
        self.move = move
        self.copy = copy
        self.fileExists = fileExists
        self.fileAttributes = fileAttributes
        self.createDirectory = createDirectory
    }
}

// MARK: - Dependency Registration

public extension FileSystemClient {
    static let liveValue: Self = .init(
        directoryURL: { _ in URL(fileURLWithPath: NSTemporaryDirectory()) },
        listFiles: { _, _ in [] },
        save: { _, filename, _ in URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename) },
        load: { _ in Data() },
        delete: { _ in },
        move: { _, destination in destination },
        copy: { _, destination in destination },
        fileAttributes: { _ in FileAttributes() },
        createDirectory: { _ in }
    )

    static let testValue: Self = .init(
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
            "Directory not found"
        case let .fileNotFound(name):
            "File not found: \(name)"
        case let .accessDenied(path):
            "Access denied: \(path)"
        case .diskFull:
            "Disk is full"
        case let .invalidFileName(name):
            "Invalid file name: \(name)"
        case let .saveFailed(reason):
            "Failed to save file: \(reason)"
        case let .loadFailed(reason):
            "Failed to load file: \(reason)"
        case let .deleteFailed(reason):
            "Failed to delete file: \(reason)"
        case let .moveFailed(reason):
            "Failed to move file: \(reason)"
        case let .copyFailed(reason):
            "Failed to copy file: \(reason)"
        case let .unknownError(message):
            message
        }
    }
}
