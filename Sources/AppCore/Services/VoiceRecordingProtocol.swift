import Foundation

/// Platform-agnostic protocol for voice recording capabilities
public protocol VoiceRecordingProtocol: Sendable {
    func checkPermissions() -> Bool
    func requestPermissions() async -> Bool
    func startRecording() async throws
    func stopRecording() async throws -> String
    func cancelRecording() async throws
}

/// Errors that can occur during voice recording
public enum VoiceRecordingError: LocalizedError, Equatable, Sendable {
    case permissionDenied
    case recordingFailed
    case recognitionRequestFailed
    case transcriptionFailed
    case notAvailable

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Microphone or speech recognition permissions denied"
        case .recordingFailed:
            "Failed to start recording"
        case .recognitionRequestFailed:
            "Failed to create speech recognition request"
        case .transcriptionFailed:
            "Failed to transcribe audio"
        case .notAvailable:
            "Voice recording is not available on this platform"
        }
    }
}
