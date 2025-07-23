import Foundation

// MARK: - MediaAsset

@MainActor
public struct MediaAsset: Identifiable, Codable {
    public let id: UUID
    public let type: MediaType
    public let originalURL: URL?
    public let processedURL: URL?
    public let metadata: MediaMetadata
    public let createdAt: Date
    public let fileSize: Int64
    public let mimeType: String

    public init(
        id: UUID = UUID(),
        type: MediaType,
        originalURL: URL?,
        processedURL: URL? = nil,
        metadata: MediaMetadata = MediaMetadata(),
        createdAt: Date = Date(),
        fileSize: Int64 = 0,
        mimeType: String = ""
    ) {
        self.id = id
        self.type = type
        self.originalURL = originalURL
        self.processedURL = processedURL
        self.metadata = metadata
        self.createdAt = createdAt
        self.fileSize = fileSize
        self.mimeType = mimeType
    }
}

// MARK: - MediaType

public enum MediaType: String, Sendable, CaseIterable, Codable {
    case photo
    case document
    case screenshot
    case camera
    case file

    public var displayName: String {
        switch self {
        case .photo: "Photo"
        case .document: "Document"
        case .screenshot: "Screenshot"
        case .camera: "Camera"
        case .file: "File"
        }
    }
}

// MARK: - MediaMetadata

public struct MediaMetadata: Sendable, Codable {
    public let width: Int?
    public let height: Int?
    public let exifData: [String: String]
    public let location: MediaLocation?
    public let deviceInfo: MediaDeviceInfo?

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
    }
}

// MARK: - Supporting Types

public struct MediaLocation: Sendable, Codable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct MediaDeviceInfo: Sendable, Codable {
    public let deviceModel: String
    public let osVersion: String
    public let appVersion: String

    public init(deviceModel: String, osVersion: String, appVersion: String) {
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.appVersion = appVersion
    }
}

// Note: ValidationResult, ValidationError, and ValidationWarning types
// are defined in FormAutoPopulationEngine.swift and reused here
