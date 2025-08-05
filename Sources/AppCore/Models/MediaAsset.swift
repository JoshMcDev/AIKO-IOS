import Foundation

// MARK: - MediaAsset

public struct MediaAsset: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public let type: MediaType
    public let url: URL?
    public let originalURL: URL?
    public let processedURL: URL?
    public var metadata: MediaMetadata
    public let data: Data?
    public let processingState: MediaProcessingState
    public let sourceInfo: MediaSource?
    public let createdAt: Date
    public let size: Int64
    public let fileSize: Int64
    public let mimeType: String

    // Primary initializer (existing interface)
    public init(
        id: UUID = UUID(),
        type: MediaType,
        url: URL? = nil,
        originalURL: URL? = nil,
        processedURL: URL? = nil,
        metadata: MediaMetadata = MediaMetadata(),
        createdAt: Date = Date(),
        size: Int64 = 0,
        fileSize: Int64 = 0,
        mimeType: String = ""
    ) {
        self.id = id
        self.type = type
        self.url = url ?? originalURL
        self.originalURL = originalURL
        self.processedURL = processedURL
        self.metadata = metadata
        data = nil
        processingState = .pending
        sourceInfo = nil
        self.createdAt = createdAt
        self.size = size > 0 ? size : fileSize
        self.fileSize = fileSize > 0 ? fileSize : size
        self.mimeType = mimeType
    }

    // Test-compatible initializer (exact match for ProcessingJobTests)
    public init(
        id: UUID = UUID(),
        type: MediaType,
        data: Data,
        metadata: MediaMetadata,
        processingState: MediaProcessingState,
        sourceInfo: MediaSource,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.data = data
        self.metadata = metadata
        self.processingState = processingState
        self.sourceInfo = sourceInfo
        self.createdAt = createdAt

        // Extract values from metadata if available
        size = metadata.fileSize ?? 0
        fileSize = metadata.fileSize ?? 0
        mimeType = metadata.mimeType ?? ""

        // URLs are nil for data-based assets
        url = nil
        originalURL = nil
        processedURL = nil
    }
}

// MARK: - MediaType

public enum MediaType: String, Sendable, CaseIterable, Codable {
    case image
    case video
    case photo
    case document
    case screenshot
    case camera
    case file

    public var displayName: String {
        switch self {
        case .image: "Image"
        case .video: "Video"
        case .photo: "Photo"
        case .document: "Document"
        case .screenshot: "Screenshot"
        case .camera: "Camera"
        case .file: "File"
        }
    }
}

// MARK: - MediaMetadata

public struct MediaMetadata: Sendable, Codable, Equatable {
    public let width: Int?
    public let height: Int?
    public let exifData: [String: String]
    public let location: MediaLocation?
    public let deviceInfo: MediaDeviceInfo?

    // Additional fields for test compatibility
    public let fileName: String?
    public let fileSize: Int64?
    public let mimeType: String?
    public let securityInfo: SecurityInfo?
    public let dimensions: MediaDimensions?

    // Primary initializer (existing interface)
    public init(
        width: Int? = nil,
        height: Int? = nil,
        exifData: [String: String] = [:],
        location: MediaLocation? = nil,
        deviceInfo: MediaDeviceInfo? = nil
    ) {
        self.width = width
        self.height = height
        self.exifData = exifData
        self.location = location
        self.deviceInfo = deviceInfo
        fileName = nil
        fileSize = nil
        mimeType = nil
        securityInfo = nil
        dimensions = if let width, let height {
            MediaDimensions(width: width, height: height)
        } else {
            nil
        }
    }

    // Test-compatible initializer
    public init(
        fileName: String,
        fileSize: Int64,
        mimeType: String,
        securityInfo: SecurityInfo,
        width: Int? = nil,
        height: Int? = nil,
        exifData: [String: String] = [:],
        location: MediaLocation? = nil,
        deviceInfo: MediaDeviceInfo? = nil
    ) {
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.securityInfo = securityInfo
        self.width = width
        self.height = height
        self.exifData = exifData
        self.location = location
        self.deviceInfo = deviceInfo
        dimensions = if let width, let height {
            MediaDimensions(width: width, height: height)
        } else {
            nil
        }
    }

    // Test-compatible initializer with dimensions
    public init(
        fileName: String,
        fileSize: Int64,
        mimeType: String,
        dimensions: MediaDimensions,
        securityInfo: SecurityInfo,
        exifData: [String: String] = [:],
        location: MediaLocation? = nil,
        deviceInfo: MediaDeviceInfo? = nil
    ) {
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.securityInfo = securityInfo
        width = dimensions.width
        height = dimensions.height
        self.dimensions = dimensions
        self.exifData = exifData
        self.location = location
        self.deviceInfo = deviceInfo
    }
}

// MARK: - Supporting Types

public struct MediaLocation: Sendable, Codable, Equatable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct MediaDeviceInfo: Sendable, Codable, Equatable {
    public let deviceModel: String
    public let osVersion: String
    public let appVersion: String

    public init(deviceModel: String, osVersion: String, appVersion: String) {
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.appVersion = appVersion
    }
}

// MARK: - ValidationResult Types

// These types are defined here to avoid conflicts and provide media-specific validation

/// Result of media validation process
public struct MediaValidationResult: Sendable, Equatable {
    public let isValid: Bool
    public let errors: [MediaValidationError]
    public let warnings: [MediaValidationWarning]

    public init(isValid: Bool, errors: [MediaValidationError] = [], warnings: [MediaValidationWarning] = []) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
    }
}

/// Media validation error
public struct MediaValidationError: Sendable, Equatable {
    public let message: String
    public let code: String?

    public init(message: String, code: String? = nil) {
        self.message = message
        self.code = code
    }
}

/// Media validation warning
public struct MediaValidationWarning: Sendable, Equatable {
    public let message: String
    public let suggestion: String?

    public init(message: String, suggestion: String? = nil) {
        self.message = message
        self.suggestion = suggestion
    }
}

// Note: Use MediaValidationResult directly instead of ValidationResult to avoid conflicts
