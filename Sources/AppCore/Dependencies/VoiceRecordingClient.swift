import ComposableArchitecture
import Foundation

@DependencyClient
public struct VoiceRecordingClient: Sendable {
    public var checkPermissions: @Sendable () -> Bool = { false }
    public var requestPermissions: @Sendable () async -> Bool = { false }
    public var startRecording: @Sendable () async throws -> Void
    public var stopRecording: @Sendable () async throws -> String
    public var cancelRecording: @Sendable () async throws -> Void
}

extension VoiceRecordingClient: TestDependencyKey {
    public static let testValue = Self()
}

extension VoiceRecordingClient: DependencyKey {
    public static let liveValue: Self = .init()
}

public extension DependencyValues {
    var voiceRecordingClient: VoiceRecordingClient {
        get { self[VoiceRecordingClient.self] }
        set { self[VoiceRecordingClient.self] = newValue }
    }
}
