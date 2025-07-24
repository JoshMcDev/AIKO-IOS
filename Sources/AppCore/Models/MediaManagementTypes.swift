import Foundation

// MARK: - Processing Job Types

/// Job type for different processing operations
public enum JobType: String, Sendable, CaseIterable, Codable, Equatable {
    case batchUpload
    case batchProcessing
    case formPopulation
    case export

    public var displayName: String {
        switch self {
        case .batchUpload: "Batch Upload"
        case .batchProcessing: "Batch Processing"
        case .formPopulation: "Form Population"
        case .export: "Export"
        }
    }
}

/// Processing job state
public enum ProcessingJobState: Sendable, Equatable {
    case pending
    case processing
    case completed
    case failed(error: MediaError)
    case cancelled

    public var isActive: Bool {
        switch self {
        case .pending, .processing: true
        case .completed, .failed, .cancelled: false
        }
    }
}

/// Processing job for batch operations
public struct ProcessingJob: Identifiable, Sendable, Equatable {
    public let id: UUID
    public var assets: [MediaAsset]
    public var state: ProcessingJobState
    public var progress: Progress
    public var jobType: JobType
    public var results: [ProcessingResult]
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        assets: [MediaAsset],
        state: ProcessingJobState,
        progress: Progress,
        jobType: JobType,
        results: [ProcessingResult],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.assets = assets
        self.state = state
        self.progress = progress
        self.jobType = jobType
        self.results = results
        self.createdAt = createdAt
    }
}

/// Result of a processing operation
public enum ProcessingResult: Sendable, Equatable {
    case success(asset: MediaAsset, processingDuration: TimeInterval = 0)
    case failure(originalAsset: MediaAsset, error: MediaError, processingDuration: TimeInterval = 0)

    public var isSuccess: Bool {
        switch self {
        case .success: true
        case .failure: false
        }
    }

    public var asset: MediaAsset? {
        switch self {
        case .success(let asset, _): asset
        case .failure: nil
        }
    }

    public var originalAsset: MediaAsset? {
        switch self {
        case .success: nil
        case .failure(let asset, _, _): asset
        }
    }

    public var error: MediaError? {
        switch self {
        case .success: nil
        case .failure(_, let error, _): error
        }
    }

    public var processingDuration: TimeInterval {
        switch self {
        case .success(_, let duration): duration
        case .failure(_, _, let duration): duration
        }
    }
}

// MARK: - Security Information

/// Security information for media assets
public struct SecurityInfo: Sendable, Codable, Equatable {
    public let isSafe: Bool
    public let scanDate: Date
    public let threatLevel: ThreatLevel
    public let scanDetails: [String: String]
    public let threats: [SecurityThreat]

    public init(
        isSafe: Bool,
        scanDate: Date = Date(),
        threatLevel: ThreatLevel = .none,
        scanDetails: [String: String] = [:],
        threats: [SecurityThreat] = []
    ) {
        self.isSafe = isSafe
        self.scanDate = scanDate
        self.threatLevel = threatLevel
        self.scanDetails = scanDetails
        self.threats = threats
    }
}

/// Security threat information
public struct SecurityThreat: Sendable, Codable, Equatable {
    public let type: ThreatType
    public let severity: ThreatLevel
    public let description: String

    public init(type: ThreatType, severity: ThreatLevel, description: String) {
        self.type = type
        self.severity = severity
        self.description = description
    }

    public enum ThreatType: String, Sendable, CaseIterable, Codable, Equatable {
        case executable
        case malware
        case virus
        case trojan
        case suspicious
        case unknown

        public var displayName: String {
            switch self {
            case .executable: "Executable"
            case .malware: "Malware"
            case .virus: "Virus"
            case .trojan: "Trojan"
            case .suspicious: "Suspicious"
            case .unknown: "Unknown"
            }
        }
    }
}

/// Threat level enumeration
public enum ThreatLevel: String, Sendable, CaseIterable, Codable, Equatable {
    case none
    case low
    case medium
    case high
    case critical

    public var displayName: String {
        switch self {
        case .none: "Safe"
        case .low: "Low Risk"
        case .medium: "Medium Risk"
        case .high: "High Risk"
        case .critical: "Critical Risk"
        }
    }
}

// MARK: - Media Source

/// Source information for media assets
public struct MediaSource: Sendable, Codable, Equatable {
    public let type: MediaSourceType
    public let identifier: String?
    public let timestamp: Date
    public let metadata: [String: String]

    public init(
        type: MediaSourceType,
        identifier: String? = nil,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.type = type
        self.identifier = identifier
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

/// Media source type
public enum MediaSourceType: String, Sendable, CaseIterable, Codable, Equatable {
    case photoLibrary
    case camera
    case filePicker
    case screenshot
    case imported
    case generated

    public var displayName: String {
        switch self {
        case .photoLibrary: "Photo Library"
        case .camera: "Camera"
        case .filePicker: "File Picker"
        case .screenshot: "Screenshot"
        case .imported: "Imported"
        case .generated: "Generated"
        }
    }
}

// MARK: - Extended MediaMetadata

/// Extended media metadata including security and source information
public struct ExtendedMediaMetadata: Sendable, Codable, Equatable {
    public let fileName: String
    public let fileSize: Int64
    public let mimeType: String
    public let securityInfo: SecurityInfo
    public let width: Int?
    public let height: Int?
    public let exifData: [String: String]
    public let location: MediaLocation?
    public let deviceInfo: MediaDeviceInfo?

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
    }
}

// MARK: - Processing State

/// Processing state for media assets
public enum MediaProcessingState: String, Sendable, CaseIterable, Codable, Equatable {
    case pending
    case processing
    case completed
    case failed
    case cancelled

    public var displayName: String {
        switch self {
        case .pending: "Pending"
        case .processing: "Processing"
        case .completed: "Completed"
        case .failed: "Failed"
        case .cancelled: "Cancelled"
        }
    }

    public var isActive: Bool {
        switch self {
        case .pending, .processing: true
        case .completed, .failed, .cancelled: false
        }
    }
}
