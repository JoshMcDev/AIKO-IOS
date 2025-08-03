import AppCore
import Foundation
import ReplayKit
@preconcurrency import SwiftUI
@preconcurrency import UIKit

/// iOS implementation of screenshot service
@available(iOS 16.0, *)
public actor ScreenshotService: ScreenshotServiceProtocol {
    private var recorder: RPScreenRecorder?
    private var currentRecordingSession: ScreenRecordingSession?
    private var recordingStartTime: Date?

    public init() {
        self.recorder = RPScreenRecorder.shared()
    }

    public func captureScreen() async throws -> ScreenshotResult {
        guard RPScreenRecorder.shared().isAvailable else {
            throw MediaError.unsupportedOperation("Screen recording not available on device")
        }

        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                guard let windowScene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first else {
                    continuation.resume(throwing: MediaError.processingFailed("No active window scene found"))
                    return
                }

                // Capture the entire screen using the window scene
                let renderer = UIGraphicsImageRenderer(bounds: windowScene.screen.bounds)
                let image = renderer.image { _ in
                    // Draw all windows in the scene
                    for window in windowScene.windows {
                        window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
                    }
                }

                // Convert UIImage to Data
                guard let imageData = image.pngData() else {
                    continuation.resume(throwing: MediaError.processingFailed("Failed to convert captured image to data"))
                    return
                }

                let result = ScreenshotResult(
                    imageData: imageData,
                    captureDate: Date(),
                    dimensions: AppCore.CGSize(width: Double(image.size.width), height: Double(image.size.height)),
                    scaleFactor: Double(UIScreen.main.scale)
                )

                continuation.resume(returning: result)
            }
        }
    }

    public func captureArea(_ area: AppCore.CGRect) async throws -> ScreenshotResult {
        // First capture the entire screen
        let fullScreenshot = try await captureScreen()

        // Extract the specified area from the full screenshot
        guard let fullImage = UIImage(data: fullScreenshot.imageData) else {
            throw MediaError.processingFailed("Failed to load captured screen image")
        }

        let cropRect = CoreGraphics.CGRect(x: area.origin.x, y: area.origin.y, width: area.size.width, height: area.size.height)

        // Validate crop area is within image bounds
        let imageBounds = CGRect(origin: .zero, size: fullImage.size)
        guard imageBounds.contains(cropRect) else {
            throw MediaError.invalidInput("Crop area exceeds image bounds")
        }

        // Crop the image
        guard let cgImage = fullImage.cgImage?.cropping(to: cropRect) else {
            throw MediaError.processingFailed("Failed to crop image to specified area")
        }

        let croppedImage = UIImage(cgImage: cgImage)

        guard let croppedData = croppedImage.pngData() else {
            throw MediaError.processingFailed("Failed to convert cropped image to data")
        }

        return ScreenshotResult(
            imageData: croppedData,
            captureDate: Date(),
            dimensions: AppCore.CGSize(width: Double(croppedImage.size.width), height: Double(croppedImage.size.height)),
            scaleFactor: 1.0
        )
    }

    public func captureView(_ view: AnyView) async throws -> ScreenshotResult {
        // Use a wrapper to work around the Sendable requirement
        struct ViewHolder: @unchecked Sendable {
            let view: AnyView
        }

        let holder = ViewHolder(view: view)

        return try await MainActor.run {
            // Create a hosting controller for the SwiftUI view
            let hostingController = UIHostingController(rootView: holder.view)

            // Size the hosting controller
            let targetSize = CGSize(width: 320, height: 568) // Default iPhone size
            hostingController.view.frame = CGRect(origin: .zero, size: targetSize)
            hostingController.view.layoutIfNeeded()

            // Render the view to an image
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let image = renderer.image { _ in
                hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
            }

            guard let imageData = image.pngData() else {
                throw MediaError.processingFailed("Failed to convert view to image data")
            }

            let result = ScreenshotResult(
                imageData: imageData,
                captureDate: Date(),
                dimensions: AppCore.CGSize(width: Double(image.size.width), height: Double(image.size.height)),
                scaleFactor: 1.0
            )

            return result
        }
    }

    public func captureWindow(_: WindowInfo) async throws -> ScreenshotResult {
        // Not applicable on iOS
        throw MediaError.unsupportedOperation("Window capture not available on iOS")
    }

    public func startScreenRecording(options: ScreenRecordingOptions) async throws -> ScreenRecordingSession {
        guard let recorder = recorder else {
            throw MediaError.processingFailed("Screen recorder not initialized")
        }

        guard recorder.isAvailable else {
            throw MediaError.unsupportedOperation("Screen recording not available on device")
        }

        // Check if already recording
        guard currentRecordingSession == nil else {
            throw MediaError.processingFailed("Recording session already in progress")
        }

        // Configure recording options
        recorder.isMicrophoneEnabled = options.enableMicrophone
        recorder.isCameraEnabled = false // iOS doesn't support camera overlay through ReplayKit in this context

        return try await withCheckedThrowingContinuation { continuation in
            recorder.startRecording { error in
                if let error = error {
                    continuation.resume(throwing: MediaError.processingFailed("Failed to start recording: \(error.localizedDescription)"))
                    return
                }

                let session = ScreenRecordingSession(
                    startTime: Date(),
                    options: options
                )

                self.currentRecordingSession = session
                self.recordingStartTime = Date()

                continuation.resume(returning: session)
            }
        }
    }

    public func stopScreenRecording(_ session: ScreenRecordingSession) async throws -> ScreenRecordingResult {
        guard let recorder = recorder else {
            throw MediaError.processingFailed("Screen recorder not initialized")
        }

        guard let currentSession = currentRecordingSession,
              currentSession.id == session.id else {
            throw MediaError.processingFailed("No matching recording session found")
        }

        return try await withCheckedThrowingContinuation { continuation in
            recorder.stopRecording { _, error in
                if let error = error {
                    continuation.resume(throwing: MediaError.processingFailed("Failed to stop recording: \(error.localizedDescription)"))
                    return
                }

                let endTime = Date()
                let duration = self.recordingStartTime.map { endTime.timeIntervalSince($0) } ?? 0

                // For iOS, ReplayKit provides a preview controller rather than direct file access
                // In a real implementation, you would handle the preview controller appropriately
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                let result = ScreenRecordingResult(
                    videoURL: tempURL,
                    duration: duration,
                    fileSize: 0, // Cannot determine without file access
                    session: session
                )

                // Clean up
                self.currentRecordingSession = nil
                self.recordingStartTime = nil

                continuation.resume(returning: result)
            }
        }
    }

    public func getAvailableWindows() async throws -> [WindowInfo] {
        // Not applicable on iOS
        throw MediaError.unsupportedOperation("Window listing not available on iOS")
    }

    public func checkScreenRecordingPermission() async -> Bool {
        guard RPScreenRecorder.shared().isAvailable else {
            return false
        }

        // ReplayKit doesn't have explicit permission checking like screen recording on macOS
        // Availability generally indicates permission is granted
        return true
    }

    public func requestScreenRecordingPermission() async -> Bool {
        // On iOS, ReplayKit permissions are handled automatically when recording starts
        // We can only check availability
        return RPScreenRecorder.shared().isAvailable
    }
}
