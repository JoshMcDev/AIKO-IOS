import ComposableArchitecture
import Foundation

// MARK: - Platform-Agnostic Camera Models

/// Represents camera capabilities and state
public struct CameraState: Equatable, Sendable {
    public let isAvailable: Bool
    public let authorizationStatus: CameraAuthorizationStatus
    public let position: CameraPosition
    
    public init(
        isAvailable: Bool = false,
        authorizationStatus: CameraAuthorizationStatus = .notDetermined,
        position: CameraPosition = .back
    ) {
        self.isAvailable = isAvailable
        self.authorizationStatus = authorizationStatus
        self.position = position
    }
}

/// Camera authorization status
public enum CameraAuthorizationStatus: String, Equatable, Sendable {
    case notDetermined = "Not Determined"
    case restricted = "Restricted"
    case denied = "Denied"
    case authorized = "Authorized"
}

/// Camera position
public enum CameraPosition: String, Equatable, Sendable {
    case front = "Front"
    case back = "Back"
}

/// Captured photo data
public struct CapturedPhoto: Equatable, Sendable {
    public let id: UUID
    public let imageData: Data
    public let capturedAt: Date
    public let metadata: PhotoMetadata?
    
    public init(
        id: UUID = UUID(),
        imageData: Data,
        capturedAt: Date = Date(),
        metadata: PhotoMetadata? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.capturedAt = capturedAt
        self.metadata = metadata
    }
}

/// Photo metadata
public struct PhotoMetadata: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public let orientation: Int
    public let location: Location?
    
    public init(
        width: Int,
        height: Int,
        orientation: Int = 1,
        location: Location? = nil
    ) {
        self.width = width
        self.height = height
        self.orientation = orientation
        self.location = location
    }
    
    public struct Location: Equatable, Sendable {
        public let latitude: Double
        public let longitude: Double
        
        public init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }
    }
}

// MARK: - Camera Client Protocol

/// Platform-agnostic protocol for camera capabilities
@DependencyClient
public struct CameraClient: Sendable {
    /// Check camera availability
    public var checkAvailability: @Sendable () async -> Bool = { false }
    
    /// Request camera authorization
    public var requestAuthorization: @Sendable () async -> CameraAuthorizationStatus = { .denied }
    
    /// Get current authorization status
    public var authorizationStatus: @Sendable () -> CameraAuthorizationStatus = { .notDetermined }
    
    /// Capture a photo
    public var capturePhoto: @Sendable () async throws -> CapturedPhoto
    
    /// Switch camera position (front/back)
    public var switchCamera: @Sendable () async throws -> CameraPosition
    
    /// Get available camera positions
    public var availablePositions: @Sendable () -> [CameraPosition] = { [] }
}

// MARK: - Dependency Registration

extension CameraClient: DependencyKey {
    public static var liveValue: Self = Self()
    
    public static var testValue: Self = Self(
        checkAvailability: { true },
        requestAuthorization: { .authorized },
        authorizationStatus: { .authorized },
        capturePhoto: { 
            CapturedPhoto(
                imageData: Data(),
                metadata: PhotoMetadata(width: 1920, height: 1080)
            )
        },
        switchCamera: { .front },
        availablePositions: { [.back, .front] }
    )
}

extension DependencyValues {
    public var camera: CameraClient {
        get { self[CameraClient.self] }
        set { self[CameraClient.self] = newValue }
    }
}

// MARK: - Camera Errors

/// Errors that can occur during camera operations
public enum CameraError: LocalizedError, Equatable {
    case notAvailable
    case notAuthorized
    case captureFailed(String)
    case invalidPosition
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Camera is not available on this device"
        case .notAuthorized:
            return "Camera access is not authorized"
        case .captureFailed(let reason):
            return "Failed to capture photo: \(reason)"
        case .invalidPosition:
            return "Invalid camera position"
        case .unknownError(let message):
            return message
        }
    }
}