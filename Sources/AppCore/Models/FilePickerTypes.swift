import Foundation

// MARK: - File Picker Types

/// Configuration options for file picker
public struct FilePickerOptions: Sendable {
    public let allowedTypes: [UTType]
    public let allowsMultipleSelection: Bool
    public let allowsPickingDirectories: Bool
    public let startingDirectory: URL?
    public let maxFileSize: Int64?
    public let maxFiles: Int?

    public init(
        allowedTypes: [UTType] = [.data],
        allowsMultipleSelection: Bool = false,
        allowsPickingDirectories: Bool = false,
        startingDirectory: URL? = nil,
        maxFileSize: Int64? = nil,
        maxFiles: Int? = nil
    ) {
        self.allowedTypes = allowedTypes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.allowsPickingDirectories = allowsPickingDirectories
        self.startingDirectory = startingDirectory
        self.maxFileSize = maxFileSize
        self.maxFiles = maxFiles
    }
}

/// Result of file picker selection
public struct FilePickerResult: Sendable {
    public let selectedFiles: [SelectedFile]
    public let cancelled: Bool
    public let error: FilePickerError?

    public init(
        selectedFiles: [SelectedFile] = [],
        cancelled: Bool = false,
        error: FilePickerError? = nil
    ) {
        self.selectedFiles = selectedFiles
        self.cancelled = cancelled
        self.error = error
    }
}

/// Represents a file selected from the file picker
public struct SelectedFile: Sendable, Identifiable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let size: Int64
    public let type: UTType
    public let lastModified: Date
    public let isDirectory: Bool
    public let data: Data?

    public init(
        id: UUID = UUID(),
        url: URL,
        name: String,
        size: Int64,
        type: UTType,
        lastModified: Date,
        isDirectory: Bool = false,
        data: Data? = nil
    ) {
        self.id = id
        self.url = url
        self.name = name
        self.size = size
        self.type = type
        self.lastModified = lastModified
        self.isDirectory = isDirectory
        self.data = data
    }
}

/// File picker specific error types
public enum FilePickerError: Error, Sendable, LocalizedError {
    case accessDenied(String)
    case fileTooLarge(String)
    case tooManyFiles(String)
    case unsupportedType(String)
    case readError(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case let .accessDenied(message):
            "Access denied: \(message)"
        case let .fileTooLarge(message):
            "File too large: \(message)"
        case let .tooManyFiles(message):
            "Too many files: \(message)"
        case let .unsupportedType(message):
            "Unsupported file type: \(message)"
        case let .readError(message):
            "Read error: \(message)"
        case let .unknown(message):
            "Unknown error: \(message)"
        }
    }
}

// MARK: - Uniform Type Identifiers

/// Platform-agnostic representation of UTType
public struct UTType: Sendable, Hashable, CustomStringConvertible {
    public let identifier: String
    public let description: String
    public let conformsTo: [UTType]
    public let preferredMIMEType: String?
    public let preferredFilenameExtension: String?

    public init(
        identifier: String,
        description: String = "",
        conformsTo: [UTType] = [],
        preferredMIMEType: String? = nil,
        preferredFilenameExtension: String? = nil
    ) {
        self.identifier = identifier
        self.description = description
        self.conformsTo = conformsTo
        self.preferredMIMEType = preferredMIMEType
        self.preferredFilenameExtension = preferredFilenameExtension
    }

    // Common UTTypes
    public static let data = UTType(
        identifier: "public.data",
        description: "Data",
        preferredMIMEType: "application/octet-stream"
    )

    public static let text = UTType(
        identifier: "public.text",
        description: "Text",
        preferredMIMEType: "text/plain",
        preferredFilenameExtension: "txt"
    )

    public static let image = UTType(
        identifier: "public.image",
        description: "Image",
        preferredMIMEType: "image/*"
    )

    public static let jpeg = UTType(
        identifier: "public.jpeg",
        description: "JPEG Image",
        conformsTo: [.image],
        preferredMIMEType: "image/jpeg",
        preferredFilenameExtension: "jpg"
    )

    public static let png = UTType(
        identifier: "public.png",
        description: "PNG Image",
        conformsTo: [.image],
        preferredMIMEType: "image/png",
        preferredFilenameExtension: "png"
    )

    public static let pdf = UTType(
        identifier: "com.adobe.pdf",
        description: "PDF Document",
        preferredMIMEType: "application/pdf",
        preferredFilenameExtension: "pdf"
    )

    public static let json = UTType(
        identifier: "public.json",
        description: "JSON Document",
        conformsTo: [.text],
        preferredMIMEType: "application/json",
        preferredFilenameExtension: "json"
    )

    public static let xml = UTType(
        identifier: "public.xml",
        description: "XML Document",
        conformsTo: [.text],
        preferredMIMEType: "application/xml",
        preferredFilenameExtension: "xml"
    )

    public static let zip = UTType(
        identifier: "public.zip-archive",
        description: "ZIP Archive",
        preferredMIMEType: "application/zip",
        preferredFilenameExtension: "zip"
    )

    public static let movie = UTType(
        identifier: "public.movie",
        description: "Movie",
        preferredMIMEType: "video/*"
    )

    public static let audio = UTType(
        identifier: "public.audio",
        description: "Audio",
        preferredMIMEType: "audio/*"
    )

    public static let folder = UTType(
        identifier: "public.folder",
        description: "Folder"
    )
}
