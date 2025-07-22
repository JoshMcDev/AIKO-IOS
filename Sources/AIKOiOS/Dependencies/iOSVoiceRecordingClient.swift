#if os(iOS)
    import AppCore
    import AVFoundation
    import ComposableArchitecture
    import Foundation
    import Speech

    // MARK: - iOS Voice Recording Client

    public extension VoiceRecordingClient {
        static var iOSLive: Self {
            Self(
                checkPermissions: {
                    MainActor.assumeIsolated {
                        iOSAudioRecorder.shared.checkPermissions()
                    }
                },
                requestPermissions: {
                    await iOSAudioRecorder.shared.requestPermissions()
                },
                startRecording: {
                    try await iOSAudioRecorder.shared.startRecording()
                },
                stopRecording: {
                    try await iOSAudioRecorder.shared.stopRecording()
                },
                cancelRecording: {
                    try await iOSAudioRecorder.shared.cancelRecording()
                }
            )
        }
    }

    // MARK: - iOS Audio Recorder Implementation

    @MainActor
    private class iOSAudioRecorder: NSObject {
        static let shared = iOSAudioRecorder()

        private var audioRecorder: AVAudioRecorder?
        private let audioSession: AVAudioSession
        private let audioEngine = AVAudioEngine()
        private var audioFileURL: URL?

        private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
        private var recognitionTask: SFSpeechRecognitionTask?

        override init() {
            audioSession = AVAudioSession.sharedInstance()
            super.init()
        }

        func checkPermissions() -> Bool {
            let microphoneStatus = AVAudioSession.sharedInstance().recordPermission
            let speechStatus = SFSpeechRecognizer.authorizationStatus()
            return microphoneStatus == .granted && speechStatus == .authorized
        }

        func requestPermissions() async -> Bool {
            // Request microphone permission
            let microphoneGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }

            // Request speech recognition permission
            let speechGranted = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }

            return microphoneGranted && speechGranted
        }

        func startRecording() async throws {
            // Cancel any ongoing recognition task
            recognitionTask?.cancel()
            recognitionTask = nil

            // Configure audio session
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            // Create recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest else {
                throw VoiceRecordingError.recognitionRequestFailed
            }

            // Configure request
            recognitionRequest.shouldReportPartialResults = true
            #if !targetEnvironment(simulator)
                recognitionRequest.requiresOnDeviceRecognition = false
            #endif

            // Get input node
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            // Install tap on input node
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }

            // Start audio engine
            audioEngine.prepare()
            try audioEngine.start()
        }

        func stopRecording() async throws -> String {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)

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

            // Deactivate audio session
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)

            return transcription
        }

        func cancelRecording() async throws {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)

            recognitionRequest?.endAudio()
            recognitionTask?.cancel()

            recognitionRequest = nil
            recognitionTask = nil

            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    // MARK: - Voice Recording Error

    public enum VoiceRecordingError: Error {
        case permissionDenied
        case recordingFailed
        case recognitionRequestFailed
        case transcriptionFailed
    }
#endif
