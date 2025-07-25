import Foundation

public struct VoiceRecordingClient: Sendable {
    public var checkPermissions: @Sendable () -> Bool = { false }
    public var requestPermissions: @Sendable () async -> Bool = { false }
    public var startRecording: @Sendable () async throws -> Void
    public var stopRecording: @Sendable () async throws -> String
    public var cancelRecording: @Sendable () async throws -> Void

    public init(
        checkPermissions: @escaping @Sendable () -> Bool = { false },
        requestPermissions: @escaping @Sendable () async -> Bool = { false },
        startRecording: @escaping @Sendable () async throws -> Void,
        stopRecording: @escaping @Sendable () async throws -> String,
        cancelRecording: @escaping @Sendable () async throws -> Void
    ) {
        self.checkPermissions = checkPermissions
        self.requestPermissions = requestPermissions
        self.startRecording = startRecording
        self.stopRecording = stopRecording
        self.cancelRecording = cancelRecording
    }
}

extension VoiceRecordingClient {
    public static let testValue = Self(
        startRecording: { },
        stopRecording: { "test-recording.m4a" },
        cancelRecording: { }
    )
}

extension VoiceRecordingClient {
    public static let liveValue: Self = .init(
        startRecording: { },
        stopRecording: { "live-recording.m4a" },
        cancelRecording: { }
    )
}
