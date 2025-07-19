import Foundation

public protocol VoiceRecordingProtocol {
    func checkPermissions() -> Bool
    func requestPermissions() async -> Bool
    func startRecording() async throws
    func stopRecording() async throws -> String
    func cancelRecording() async throws
}
