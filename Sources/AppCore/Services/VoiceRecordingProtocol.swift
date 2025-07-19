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
public enum VoiceRecordingError: LocalizedError, Equatable {
    case permissionDenied
    case recordingFailed
    case recognitionRequestFailed
    case transcriptionFailed
    case notAvailable
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone or speech recognition permissions denied"
        case .recordingFailed:
            return "Failed to start recording"
        case .recognitionRequestFailed:
            return "Failed to create speech recognition request"
        case .transcriptionFailed:
            return "Failed to transcribe audio"
        case .notAvailable:
            return "Voice recording is not available on this platform"
        }
    }
}
