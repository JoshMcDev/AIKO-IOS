import ComposableArchitecture
import Foundation

@DependencyClient
public struct VoiceRecordingClient {
    public var checkPermissions: @Sendable () -> Bool = { false }
    public var requestPermissions: @Sendable () async -> Bool = { false }
    public var startRecording: @Sendable () async throws -> Void
    public var stopRecording: @Sendable () async throws -> String
    public var cancelRecording: @Sendable () async throws -> Void
}

extension VoiceRecordingClient: TestDependencyKey {
    public static let testValue = Self()
}

public extension DependencyValues {
    var voiceRecordingService: VoiceRecordingClient {
        get { self[VoiceRecordingClient.self] }
        set { self[VoiceRecordingClient.self] = newValue }
    }
}
