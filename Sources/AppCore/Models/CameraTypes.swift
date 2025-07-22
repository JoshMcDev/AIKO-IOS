import Foundation

// MARK: - Camera Service Types

/// Configuration options for camera photo capture
public struct CameraPhotoOptions: Sendable {
    public let flashMode: FlashMode
    public let quality: ImageQuality
    public let enableHDR: Bool
    public let enablePortraitMode: Bool
    public let focusPoint: CGPoint?
    public let exposurePoint: CGPoint?

    public init(
        flashMode: FlashMode = .auto,
        quality: ImageQuality = .high,
        enableHDR: Bool = true,
        enablePortraitMode: Bool = false,
        focusPoint: CGPoint? = nil,
        exposurePoint: CGPoint? = nil
    ) {
        self.flashMode = flashMode
        self.quality = quality
        self.enableHDR = enableHDR
        self.enablePortraitMode = enablePortraitMode
        self.focusPoint = focusPoint
        self.exposurePoint = exposurePoint
    }
}

/// Configuration options for camera video recording
public struct CameraVideoOptions: Sendable {
    public let resolution: VideoResolution
    public let frameRate: VideoFrameRate
    public let quality: VideoQuality
    public let stabilization: Bool
    public let audioEnabled: Bool
    public let maxDuration: TimeInterval?

    public init(
        resolution: VideoResolution = .hd1080p,
        frameRate: VideoFrameRate = .fps30,
        quality: VideoQuality = .high,
        stabilization: Bool = true,
        audioEnabled: Bool = true,
        maxDuration: TimeInterval? = nil
    ) {
        self.resolution = resolution
        self.frameRate = frameRate
        self.quality = quality
        self.stabilization = stabilization
        self.audioEnabled = audioEnabled
        self.maxDuration = maxDuration
    }
}

/// Handle for managing an active camera recording session
public struct CameraRecordingSession: Sendable, Identifiable {
    public let id: UUID
    public let startTime: Date
    public let options: CameraVideoOptions
    public let isRecording: Bool
    public let duration: TimeInterval

    public init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        options: CameraVideoOptions,
        isRecording: Bool = false,
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.startTime = startTime
        self.options = options
        self.isRecording = isRecording
        self.duration = duration
    }
}

/// Represents captured video data and metadata
public struct CapturedVideo: Sendable {
    public let data: Data
    public let duration: TimeInterval
    public let resolution: VideoResolution
    public let frameRate: VideoFrameRate
    public let fileSize: Int64
    public let timestamp: Date
    public let location: MediaLocation?

    public init(
        data: Data,
        duration: TimeInterval,
        resolution: VideoResolution,
        frameRate: VideoFrameRate,
        fileSize: Int64,
        timestamp: Date = Date(),
        location: MediaLocation? = nil
    ) {
        self.data = data
        self.duration = duration
        self.resolution = resolution
        self.frameRate = frameRate
        self.fileSize = fileSize
        self.timestamp = timestamp
        self.location = location
    }
}

/// Camera settings and configuration
public struct CameraSettings: Sendable {
    public let defaultPhotoOptions: CameraPhotoOptions
    public let defaultVideoOptions: CameraVideoOptions
    public let preferredDevice: CameraDevice
    public let enableLocationServices: Bool
    public let saveToPhotoLibrary: Bool

    public init(
        defaultPhotoOptions: CameraPhotoOptions = CameraPhotoOptions(),
        defaultVideoOptions: CameraVideoOptions = CameraVideoOptions(),
        preferredDevice: CameraDevice = .back,
        enableLocationServices: Bool = true,
        saveToPhotoLibrary: Bool = false
    ) {
        self.defaultPhotoOptions = defaultPhotoOptions
        self.defaultVideoOptions = defaultVideoOptions
        self.preferredDevice = preferredDevice
        self.enableLocationServices = enableLocationServices
        self.saveToPhotoLibrary = saveToPhotoLibrary
    }
}

// MARK: - Supporting Enums

/// Available camera devices
public enum CameraDevice: String, Sendable, CaseIterable {
    case front
    case back
    case ultraWide
    case telephoto

    public var displayName: String {
        switch self {
        case .front: return "Front Camera"
        case .back: return "Back Camera"
        case .ultraWide: return "Ultra Wide Camera"
        case .telephoto: return "Telephoto Camera"
        }
    }
}

/// Flash mode options
public enum FlashMode: String, Sendable, CaseIterable {
    case auto
    case on
    case off

    public var displayName: String {
        switch self {
        case .auto: return "Auto Flash"
        case .on: return "Flash On"
        case .off: return "Flash Off"
        }
    }
}

/// Image quality levels
public enum ImageQuality: String, Sendable, CaseIterable {
    case low
    case medium
    case high
    case maximum

    public var compressionQuality: Float {
        switch self {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 0.8
        case .maximum: return 1.0
        }
    }
}

/// Video resolution options
public enum VideoResolution: String, Sendable, CaseIterable {
    case sd480p
    case hd720p
    case hd1080p
    case uhd4k

    public var displayName: String {
        switch self {
        case .sd480p: return "480p SD"
        case .hd720p: return "720p HD"
        case .hd1080p: return "1080p HD"
        case .uhd4k: return "4K UHD"
        }
    }

    public var dimensions: (width: Int, height: Int) {
        switch self {
        case .sd480p: return (640, 480)
        case .hd720p: return (1280, 720)
        case .hd1080p: return (1920, 1080)
        case .uhd4k: return (3840, 2160)
        }
    }
}

/// Video frame rate options
public enum VideoFrameRate: Int, Sendable, CaseIterable {
    case fps24 = 24
    case fps30 = 30
    case fps60 = 60
    case fps120 = 120

    public var displayName: String {
        return "\(rawValue) fps"
    }
}

/// Video quality levels
public enum VideoQuality: String, Sendable, CaseIterable {
    case low
    case medium
    case high
    case maximum

    public var bitRate: Int {
        switch self {
        case .low: return 1_000_000 // 1 Mbps
        case .medium: return 5_000_000 // 5 Mbps
        case .high: return 10_000_000 // 10 Mbps
        case .maximum: return 20_000_000 // 20 Mbps
        }
    }
}
