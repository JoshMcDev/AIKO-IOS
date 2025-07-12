import AVFoundation
import Foundation
#if canImport(Speech)
    import Speech
#endif
import ComposableArchitecture

public struct VoiceRecordingService {
    public var startRecording: () async throws -> Void
    public var stopRecording: () async throws -> String
    public var requestPermissions: () async -> Bool
    public var checkPermissions: () -> Bool

    public init(
        startRecording: @escaping () async throws -> Void,
        stopRecording: @escaping () async throws -> String,
        requestPermissions: @escaping () async -> Bool,
        checkPermissions: @escaping () -> Bool
    ) {
        self.startRecording = startRecording
        self.stopRecording = stopRecording
        self.requestPermissions = requestPermissions
        self.checkPermissions = checkPermissions
    }
}

extension VoiceRecordingService: DependencyKey {
    public static var liveValue: VoiceRecordingService {
        let recorder = AudioRecorder()

        return VoiceRecordingService(
            startRecording: {
                try await recorder.startRecording()
            },
            stopRecording: {
                try await recorder.stopRecording()
            },
            requestPermissions: {
                await recorder.requestPermissions()
            },
            checkPermissions: {
                recorder.checkPermissions()
            }
        )
    }

    public static var testValue: VoiceRecordingService {
        VoiceRecordingService(
            startRecording: {},
            stopRecording: { "Test transcription" },
            requestPermissions: { true },
            checkPermissions: { true }
        )
    }
}

// MARK: - Audio Recorder Implementation

private class AudioRecorder: NSObject {
    private var audioRecorder: AVAudioRecorder?
    #if os(iOS)
        private var audioSession: AVAudioSession
    #endif
    private let audioEngine = AVAudioEngine()
    private var audioFileURL: URL?

    #if canImport(Speech)
        private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
        private var recognitionTask: SFSpeechRecognitionTask?
    #endif

    override init() {
        #if os(iOS)
            audioSession = AVAudioSession.sharedInstance()
        #endif
        super.init()
    }

    func checkPermissions() -> Bool {
        #if os(iOS) && canImport(Speech)
            let microphoneStatus = AVAudioSession.sharedInstance().recordPermission
            let speechStatus = SFSpeechRecognizer.authorizationStatus()
            return microphoneStatus == .granted && speechStatus == .authorized
        #else
            // macOS handles permissions differently
            return true
        #endif
    }

    func requestPermissions() async -> Bool {
        #if os(iOS)
            // Request microphone permission
            let microphoneGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }

            #if canImport(Speech)
                // Request speech recognition permission
                let speechGranted = await withCheckedContinuation { continuation in
                    SFSpeechRecognizer.requestAuthorization { status in
                        continuation.resume(returning: status == .authorized)
                    }
                }

                return microphoneGranted && speechGranted
            #else
                return microphoneGranted
            #endif

        #else
            // macOS handles permissions differently
            return true
        #endif
    }

    func startRecording() async throws {
        #if canImport(Speech)
            // Cancel any ongoing recognition task
            recognitionTask?.cancel()
            recognitionTask = nil
        #endif

        // Configure audio session
        #if os(iOS)
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif

        #if canImport(Speech)
            // Create recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest else {
                throw VoiceRecordingError.recognitionRequestFailed
            }

            // Configure request
            recognitionRequest.shouldReportPartialResults = true
            #if os(iOS) && !targetEnvironment(simulator)
                recognitionRequest.requiresOnDeviceRecognition = false
            #endif

            // Get input node
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            // Install tap on input node
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
        #else
            // Fallback for platforms without Speech framework
            // Create audio file for recording
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            audioFileURL = documentsPath.appendingPathComponent("recording.m4a")

            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]

            audioRecorder = try AVAudioRecorder(url: audioFileURL!, settings: settings)
            audioRecorder?.record()
        #endif

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopRecording() async throws -> String {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        #if canImport(Speech)
            recognitionRequest?.endAudio()

            // Get final transcription
            let transcription = await withCheckedContinuation { continuation in
                var finalTranscription = ""

                recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { result, error in
                    if let result {
                        finalTranscription = result.bestTranscription.formattedString

                        if result.isFinal {
                            continuation.resume(returning: finalTranscription)
                        }
                    } else if let error {
                        print("Speech recognition error: \(error)")
                        continuation.resume(returning: finalTranscription.isEmpty ? "Error transcribing audio" : finalTranscription)
                    }
                }

                // Timeout after 5 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    if !Task.isCancelled {
                        continuation.resume(returning: finalTranscription.isEmpty ? "No speech detected" : finalTranscription)
                    }
                }
            }

            // Clean up
            recognitionRequest = nil
            recognitionTask = nil
        #else
            // Fallback without Speech framework
            audioRecorder?.stop()
            audioRecorder = nil

            // Return a placeholder since we can't transcribe without Speech framework
            let transcription = "Voice transcription requires iOS with Speech framework"
        #endif

        // Deactivate audio session
        #if os(iOS)
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        #endif

        return transcription
    }
}

public enum VoiceRecordingError: Error {
    case permissionDenied
    case recordingFailed
    case recognitionRequestFailed
    case transcriptionFailed
}

public extension DependencyValues {
    var voiceRecordingService: VoiceRecordingService {
        get { self[VoiceRecordingService.self] }
        set { self[VoiceRecordingService.self] = newValue }
    }
}
