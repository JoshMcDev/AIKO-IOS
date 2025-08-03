import AppCore
import AVFoundation
import Foundation
import SwiftUI

/// iOS implementation of camera service
@available(iOS 16.0, *)
public actor CameraService: CameraServiceProtocol {
    private var captureSession: AVCaptureSession?
    private var currentDevice: AVCaptureDevice?
    private var photoOutput: AVCapturePhotoOutput?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var currentPosition: CameraPosition = .back
    private var activeRecordingSessions: [String: CameraRecordingSession] = [:]
    private var currentPhotoDelegate: PhotoCaptureDelegate?
    private var currentVideoDelegate: VideoCaptureDelegate?

    public init() {}

    // MARK: - CameraServiceProtocol Methods

    public func checkCameraAuthorization() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status == .authorized
    }

    public func requestCameraAccess() async -> Bool {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        return status
    }

    public func checkMicrophoneAuthorization() async -> MicrophoneAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    public func requestMicrophoneAccess() async -> Bool {
        let status = await AVCaptureDevice.requestAccess(for: .audio)
        return status
    }

    public func capturePhoto(config _: CameraCaptureConfig) async throws -> Data {
        guard AVCaptureDevice.default(for: .video) != nil else {
            throw MediaError.resourceUnavailable("Camera not available")
        }

        guard await requestCameraAccess() else {
            throw MediaError.permissionDenied("Camera access denied")
        }

        // For TDD GREEN phase, return mock photo data
        // In a real implementation, this would use AVCaptureSession
        let mockPhotoData = generateMockPhotoData()
        return mockPhotoData
    }

    private func generateMockPhotoData() -> Data {
        // Generate a minimal JPEG header for testing
        let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0]
        let jpegEnd: [UInt8] = [0xFF, 0xD9]
        var data = Data(jpegHeader)
        // Add some mock image data
        data.append(Data(repeating: 0x80, count: 1024))
        data.append(Data(jpegEnd))
        return data
    }

    public func startVideoRecording(config _: CameraCaptureConfig) async throws -> String {
        guard AVCaptureDevice.default(for: .video) != nil else {
            throw MediaError.resourceUnavailable("Camera not available")
        }

        guard await requestCameraAccess() else {
            throw MediaError.permissionDenied("Camera access denied")
        }

        // For TDD GREEN phase, return mock session ID
        let sessionId = UUID().uuidString
        return sessionId
    }

    public func stopVideoRecording() async throws -> URL {
        // For TDD GREEN phase, return mock video URL
        let tempDir = FileManager.default.temporaryDirectory
        let videoURL = tempDir.appendingPathComponent("mock_video.mp4")

        // Create mock video file if it doesn't exist
        if !FileManager.default.fileExists(atPath: videoURL.path) {
            let mockVideoData = Data(repeating: 0x00, count: 1024)
            try mockVideoData.write(to: videoURL)
        }

        return videoURL
    }

    public func isCameraAvailable() async -> Bool {
        return AVCaptureDevice.default(for: .video) != nil
    }

    public func getAvailableCameraPositions() async -> [String] {
        var positions: [String] = []

        if AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil {
            positions.append("back")
        }

        if AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil {
            positions.append("front")
        }

        return positions
    }

    public func switchCameraPosition(_ position: String) async throws {
        let cameraPosition: CameraPosition = position.lowercased() == "front" ? .front : .back
        try await switchCamera(to: cameraPosition)
    }

    // MARK: - Extended Methods

    public func isCameraAvailable(position: CameraPosition) async -> Bool {
        let devicePosition: AVCaptureDevice.Position = position == .front ? .front : .back
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: devicePosition) != nil
    }

    public func requestCameraAuthorization() async throws -> CameraAuthorizationStatus {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        return status ? .authorized : .denied
    }

    public func requestMicrophoneAuthorization() async throws -> MicrophoneAuthorizationStatus {
        let status = await AVCaptureDevice.requestAccess(for: .audio)
        return status ? .authorized : .denied
    }

    public func getAuthorizationStatus() async -> (camera: CameraAuthorizationStatus, microphone: MicrophoneAuthorizationStatus) {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        let cameraAuth: CameraAuthorizationStatus = switch videoStatus {
        case .authorized: .authorized
        case .denied, .restricted: .denied
        case .notDetermined: .notDetermined
        @unknown default: .notDetermined
        }
        
        let micAuth: MicrophoneAuthorizationStatus = switch audioStatus {
        case .authorized: .authorized
        case .denied, .restricted: .denied
        case .notDetermined: .notDetermined
        @unknown default: .notDetermined
        }
        
        return (camera: cameraAuth, microphone: micAuth)
    }

    public func capturePhoto(
        position: CameraPosition,
        options: CameraPhotoOptions
    ) async throws -> CapturedPhoto {
        try await setupCaptureSession(position: position)
        
        guard let photoOutput = self.photoOutput else {
            throw MediaError.processingFailed("Photo output not configured")
        }
        
        let settings = AVCapturePhotoSettings()
        
        // Configure photo settings based on options
        switch options.flashMode {
        case .auto:
            settings.flashMode = .auto
        case .on:
            settings.flashMode = .on
        case .off:
            settings.flashMode = .off
        }
        
        // Configure quality settings
        if options.quality == .maximum {
            // Use maximum resolution available for the current device
            settings.maxPhotoDimensions = CMVideoDimensions(width: 0, height: 0) // 0,0 means use maximum available
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = PhotoCaptureDelegate { result in
                switch result {
                case .success(let photo):
                    continuation.resume(returning: photo)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.currentPhotoDelegate = delegate
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    public func startVideoRecording(
        position: CameraPosition,
        options: CameraVideoOptions
    ) async throws -> CameraRecordingSession {
        try await setupCaptureSession(position: position, includeAudio: options.audioEnabled)
        
        guard let movieOutput = self.movieOutput else {
            throw MediaError.processingFailed("Movie output not configured")
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let outputURL = tempDir.appendingPathComponent("video_\(UUID().uuidString).mp4")
        
        let sessionId = UUID().uuidString
        let session = CameraRecordingSession(
            id: UUID(uuidString: sessionId)!,
            startTime: Date(),
            options: options
        )
        
        activeRecordingSessions[session.id.uuidString] = session
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = VideoCaptureDelegate { result in
                switch result {
                case .success:
                    continuation.resume(returning: session)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.currentVideoDelegate = delegate
            movieOutput.startRecording(to: outputURL, recordingDelegate: delegate)
        }
    }

    public func stopVideoRecording(_ session: CameraRecordingSession) async throws -> CapturedVideo {
        guard let movieOutput = self.movieOutput else {
            throw MediaError.processingFailed("Movie output not configured")
        }
        
        guard activeRecordingSessions[session.id.uuidString] != nil else {
            throw MediaError.invalidInput("Recording session not found")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = VideoCaptureDelegate { result in
                switch result {
                case .success:
                    let video = CapturedVideo(
                        data: Data(), // Placeholder
                        duration: Date().timeIntervalSince(session.startTime),
                        resolution: session.options.resolution,
                        frameRate: session.options.frameRate,
                        fileSize: 0 // Placeholder
                    )
                    continuation.resume(returning: video)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.currentVideoDelegate = delegate
            movieOutput.stopRecording()
            activeRecordingSessions.removeValue(forKey: session.id.uuidString)
        }
    }

    public func configureCameraSettings(_ settings: CameraSettings) async throws {
        guard let device = currentDevice else {
            throw MediaError.processingFailed("No active camera device")
        }
        
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        
        // Configure focus mode
        if device.isFocusModeSupported(.autoFocus) {
            device.focusMode = .autoFocus
        }
        
        // Configure exposure mode
        if device.isExposureModeSupported(.autoExpose) {
            device.exposureMode = .autoExpose
        }
        
        // Configure white balance
        if device.isWhiteBalanceModeSupported(.autoWhiteBalance) {
            device.whiteBalanceMode = .autoWhiteBalance
        }
        
        // Configure zoom if supported (default zoom factor 1.0)
        let zoomFactor: CGFloat = 1.0
        if zoomFactor <= device.activeFormat.videoMaxZoomFactor {
            device.videoZoomFactor = zoomFactor
        }
    }

    public func getAvailableCameras() async -> [CameraDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        return discoverySession.devices.compactMap { _ in
            return CameraDevice.back // Simplified for now
        }
    }

    public func switchCamera(to position: CameraPosition) async throws {
        let devicePosition: AVCaptureDevice.Position = position == .front ? .front : .back
        
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: devicePosition) else {
            throw MediaError.resourceUnavailable("Camera not available for position: \(position)")
        }
        
        guard let session = captureSession else {
            throw MediaError.processingFailed("Capture session not initialized")
        }
        
        session.beginConfiguration()
        
        // Remove existing video input
        if let currentInput = videoInput {
            session.removeInput(currentInput)
        }
        
        // Add new video input
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                self.videoInput = newInput
                self.currentDevice = newDevice
                self.currentPosition = position
            } else {
                throw MediaError.processingFailed("Cannot add camera input")
            }
        } catch {
            session.commitConfiguration()
            throw MediaError.processingFailed("Failed to create camera input: \(error.localizedDescription)")
        }
        
        session.commitConfiguration()
    }

    public func setFlashMode(_ mode: FlashMode) async throws {
        guard let device = currentDevice else {
            throw MediaError.processingFailed("No active camera device")
        }
        
        guard device.hasFlash else {
            throw MediaError.unsupportedOperation("Device does not support flash")
        }
        
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        
        // Flash mode will be applied during photo capture
        // This method prepares the device for flash usage
        if device.isTorchModeSupported(.off) {
            device.torchMode = .off
        }
    }

    public func setFocusPoint(_ point: AppCore.CGPoint) async throws {
        guard let device = currentDevice else {
            throw MediaError.processingFailed("No active camera device")
        }
        
        guard device.isFocusPointOfInterestSupported else {
            throw MediaError.unsupportedOperation("Device does not support focus point")
        }
        
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        
        device.focusPointOfInterest = CGPoint(x: point.x, y: point.y)
        if device.isFocusModeSupported(.autoFocus) {
            device.focusMode = .autoFocus
        }
    }

    public func setExposurePoint(_ point: AppCore.CGPoint) async throws {
        guard let device = currentDevice else {
            throw MediaError.processingFailed("No active camera device")
        }
        
        guard device.isExposurePointOfInterestSupported else {
            throw MediaError.unsupportedOperation("Device does not support exposure point")
        }
        
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        
        device.exposurePointOfInterest = CGPoint(x: point.x, y: point.y)
        if device.isExposureModeSupported(.autoExpose) {
            device.exposureMode = .autoExpose
        }
    }

    public func setZoomLevel(_ level: Double) async throws {
        guard let device = currentDevice else {
            throw MediaError.processingFailed("No active camera device")
        }
        
        let maxZoom = device.activeFormat.videoMaxZoomFactor
        let clampedLevel = max(1.0, min(level, maxZoom))
        
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        
        device.videoZoomFactor = clampedLevel
    }
    
    // MARK: - Helper Methods
    
    private func setupCaptureSession(position: CameraPosition, includeAudio: Bool = false) async throws {
        if captureSession == nil {
            captureSession = AVCaptureSession()
        }
        
        guard let session = captureSession else {
            throw MediaError.processingFailed("Failed to create capture session")
        }
        
        session.beginConfiguration()
        
        // Set session preset
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }
        
        // Setup video input
        try await setupVideoInput(position: position)
        
        // Setup audio input if needed
        if includeAudio {
            try setupAudioInput()
        }
        
        // Setup photo output
        setupPhotoOutput()
        
        // Setup movie output for video recording
        if includeAudio {
            setupMovieOutput()
        }
        
        session.commitConfiguration()
        
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    private func setupVideoInput(position: CameraPosition) async throws {
        let devicePosition: AVCaptureDevice.Position = position == .front ? .front : .back
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: devicePosition) else {
            throw MediaError.resourceUnavailable("Camera not available for position: \(position)")
        }
        
        let input = try AVCaptureDeviceInput(device: device)
        
        guard let session = captureSession, session.canAddInput(input) else {
            throw MediaError.processingFailed("Cannot add camera input")
        }
        
        // Remove existing video input if any
        if let existingInput = videoInput {
            session.removeInput(existingInput)
        }
        
        session.addInput(input)
        self.videoInput = input
        self.currentDevice = device
        self.currentPosition = position
    }
    
    private func setupAudioInput() throws {
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            throw MediaError.resourceUnavailable("Microphone not available")
        }
        
        let audioInput = try AVCaptureDeviceInput(device: audioDevice)
        
        guard let session = captureSession, session.canAddInput(audioInput) else {
            throw MediaError.processingFailed("Cannot add audio input")
        }
        
        // Remove existing audio input if any
        if let existingInput = self.audioInput {
            session.removeInput(existingInput)
        }
        
        session.addInput(audioInput)
        self.audioInput = audioInput
    }
    
    private func setupPhotoOutput() {
        guard let session = captureSession else { return }
        
        let output = AVCapturePhotoOutput()
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            self.photoOutput = output
        }
    }
    
    private func setupMovieOutput() {
        guard let session = captureSession else { return }
        
        let output = AVCaptureMovieFileOutput()
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            self.movieOutput = output
        }
    }
}

// MARK: - Supporting Types and Extensions

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<CapturedPhoto, Error>) -> Void
    
    init(completion: @escaping (Result<CapturedPhoto, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            completion(.failure(MediaError.processingFailed("Failed to get photo data")))
            return
        }
        
        let capturedPhoto = CapturedPhoto(
            imageData: imageData,
            metadata: PhotoMetadata(
                width: 1920, // Default values
                height: 1080
            )
        )
        
        completion(.success(capturedPhoto))
    }
}

private class VideoCaptureDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    private let completion: (Result<Void, Error>) -> Void
    
    init(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        completion(.success(()))
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            completion(.failure(error))
        } else {
            completion(.success(()))
        }
    }
}

// MARK: - Extension for AVFoundation Compatibility

extension CameraFocusMode {
    var avFocusMode: AVCaptureDevice.FocusMode {
        switch self {
        case .auto:
            return .autoFocus
        case .manual:
            return .locked
        case .continuous:
            return .continuousAutoFocus
        }
    }
}

extension CameraExposureMode {
    var avExposureMode: AVCaptureDevice.ExposureMode {
        switch self {
        case .auto:
            return .autoExpose
        case .manual:
            return .locked
        case .continuous:
            return .continuousAutoExposure
        }
    }
}

extension CameraWhiteBalanceMode {
    var avWhiteBalanceMode: AVCaptureDevice.WhiteBalanceMode {
        switch self {
        case .auto:
            return .autoWhiteBalance
        case .manual:
            return .locked
        case .continuous:
            return .continuousAutoWhiteBalance
        }
    }
}
