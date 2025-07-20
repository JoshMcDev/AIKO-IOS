#if os(iOS)
    import AppCore
    import AVFoundation
    import ComposableArchitecture
    import Foundation
    import UIKit

    /// iOS-specific implementation of CameraClient
    public struct iOSCameraClient: Sendable {}

    // MARK: - Live Implementation

    public extension iOSCameraClient {
        @MainActor
        static let live: CameraClient = .init(
            checkAvailability: {
                await checkAvailability()
            },
            requestAuthorization: {
                await requestAuthorization()
            },
            authorizationStatus: {
                authorizationStatus()
            },
            capturePhoto: {
                try await capturePhoto()
            },
            switchCamera: {
                try await switchCamera()
            },
            availablePositions: {
                availablePositions()
            }
        )
    }

    // MARK: - Implementation Methods

    extension iOSCameraClient {
        private static func checkAvailability() async -> Bool {
            await Task.detached { @MainActor in
                UIImagePickerController.isSourceTypeAvailable(.camera)
            }.value
        }

        private static func requestAuthorization() async -> CameraAuthorizationStatus {
            await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted ? .authorized : .denied)
                }
            }
        }

        private static func authorizationStatus() -> CameraAuthorizationStatus {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .notDetermined:
                return .notDetermined
            case .restricted:
                return .restricted
            case .denied:
                return .denied
            case .authorized:
                return .authorized
            @unknown default:
                return .denied
            }
        }

        @MainActor
        private static func capturePhoto() async throws -> CapturedPhoto {
            guard authorizationStatus() == .authorized else {
                throw CameraError.notAuthorized
            }

            guard await checkAvailability() else {
                throw CameraError.notAvailable
            }

            let coordinator = CameraCoordinator()
            return try await coordinator.capturePhoto()
        }

        @MainActor
        private static func switchCamera() async throws -> CameraPosition {
            let coordinator = CameraCoordinator()
            return try await coordinator.switchCamera()
        }

        private static func availablePositions() -> [CameraPosition] {
            var positions: [CameraPosition] = []

            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .unspecified
            )

            for device in discoverySession.devices {
                switch device.position {
                case .back:
                    positions.append(.back)
                case .front:
                    positions.append(.front)
                default:
                    break
                }
            }

            return positions
        }
    }

    // MARK: - Camera Coordinator

    @MainActor
    private final class CameraCoordinator: NSObject {
        private var captureCompletion: ((Result<CapturedPhoto, Error>) -> Void)?
        private var currentPosition: CameraPosition = .back

        func capturePhoto() async throws -> CapturedPhoto {
            try await withCheckedThrowingContinuation { continuation in
                self.captureCompletion = { result in
                    switch result {
                    case let .success(photo):
                        continuation.resume(returning: photo)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }

                let imagePickerController = UIImagePickerController()
                imagePickerController.sourceType = .camera
                imagePickerController.delegate = self
                imagePickerController.cameraDevice = currentPosition == .front ? .front : .rear

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController
                {
                    rootViewController.present(imagePickerController, animated: true)
                } else {
                    self.captureCompletion?(.failure(CameraError.unknownError("Failed to present camera interface")))
                }
            }
        }

        func switchCamera() async throws -> CameraPosition {
            currentPosition = currentPosition == .back ? .front : .back
            return currentPosition
        }
    }

    // MARK: - UIImagePickerControllerDelegate

    extension CameraCoordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)

            if let image = info[.originalImage] as? UIImage,
               let imageData = image.jpegData(compressionQuality: 0.8)
            {
                let photo = CapturedPhoto(
                    id: UUID(),
                    imageData: imageData,
                    capturedAt: Date(),
                    metadata: extractPhotoMetadata(from: image)
                )
                captureCompletion?(.success(photo))
            } else {
                captureCompletion?(.failure(CameraError.captureFailed("Failed to capture image")))
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            captureCompletion?(.failure(CameraError.unknownError("User cancelled photo capture")))
        }

        private func extractPhotoMetadata(from image: UIImage) -> PhotoMetadata? {
            guard let cgImage = image.cgImage else { return nil }

            return PhotoMetadata(
                width: cgImage.width,
                height: cgImage.height,
                orientation: Int(image.imageOrientation.rawValue),
                location: nil // Location would come from EXIF data if available
            )
        }
    }
#endif
