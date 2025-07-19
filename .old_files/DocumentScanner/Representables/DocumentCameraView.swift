import SwiftUI
#if os(iOS)
import VisionKit
import ComposableArchitecture

// MARK: - Document Camera View Representable

public struct DocumentCameraView: UIViewControllerRepresentable {
    @Bindable var store: StoreOf<DocumentScannerFeature>
    
    public init(store: StoreOf<DocumentScannerFeature>) {
        self.store = store
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }
    
    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed for this view controller
    }
    
    // MARK: - Coordinator
    
    public class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let store: StoreOf<DocumentScannerFeature>
        
        init(store: StoreOf<DocumentScannerFeature>) {
            self.store = store
            super.init()
        }
        
        // MARK: VNDocumentCameraViewControllerDelegate
        
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Extract images from the scan
            var scannedImages: [UIImage] = []
            
            for pageIndex in 0..<scan.pageCount {
                let scannedImage = scan.imageOfPage(at: pageIndex)
                scannedImages.append(scannedImage)
            }
            
            // Send success action with scanned images
            store.send(.scannerDidFinish(.success(scannedImages)))
        }
        
        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            // Send cancel action
            store.send(.scannerDidCancel)
        }
        
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            // Send failure action
            store.send(.scannerDidFinish(.failure(error)))
        }
    }
}

// MARK: - Scanner Availability Check

public struct DocumentScannerAvailability {
    public static var isSupported: Bool {
        VNDocumentCameraViewController.isSupported
    }
    
    public static func checkAvailability() -> ScannerAvailabilityStatus {
        if !isSupported {
            return .notSupported
        }
        
        // Check camera permissions
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthStatus {
        case .authorized:
            return .available
        case .notDetermined:
            return .permissionNotDetermined
        case .denied:
            return .permissionDenied
        case .restricted:
            return .permissionRestricted
        @unknown default:
            return .notSupported
        }
    }
    
    public static func requestCameraPermission() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}

// MARK: - Scanner Availability Status

public enum ScannerAvailabilityStatus {
    case available
    case notSupported
    case permissionNotDetermined
    case permissionDenied
    case permissionRestricted
    
    public var isAvailable: Bool {
        self == .available
    }
    
    public var message: String {
        switch self {
        case .available:
            return "Scanner is ready to use"
        case .notSupported:
            return "Document scanning is not supported on this device"
        case .permissionNotDetermined:
            return "Camera permission has not been requested"
        case .permissionDenied:
            return "Camera access is denied. Please enable it in Settings"
        case .permissionRestricted:
            return "Camera access is restricted on this device"
        }
    }
    
    public var requiresPermission: Bool {
        switch self {
        case .permissionNotDetermined, .permissionDenied:
            return true
        default:
            return false
        }
    }
}

// MARK: - Camera Permission Alert

public struct CameraPermissionAlert: View {
    let status: ScannerAvailabilityStatus
    let onRequestPermission: () -> Void
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(status.message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                if status == .permissionNotDetermined {
                    Button("Request Permission") {
                        onRequestPermission()
                    }
                    .buttonStyle(.borderedProminent)
                } else if status == .permissionDenied {
                    Button("Open Settings") {
                        onOpenSettings()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Cancel") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: 350)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

// MARK: - AVFoundation Import

import AVFoundation

// MARK: - Helper Extension

extension View {
    /// Presents the document scanner if available, otherwise shows an appropriate alert
    public func documentScanner(
        isPresented: Binding<Bool>,
        store: StoreOf<DocumentScannerFeature>
    ) -> some View {
        self.modifier(DocumentScannerModifier(isPresented: isPresented, store: store))
    }
}

// MARK: - Document Scanner Modifier

struct DocumentScannerModifier: ViewModifier {
    @Binding var isPresented: Bool
    let store: StoreOf<DocumentScannerFeature>
    
    @State private var showingPermissionAlert = false
    @State private var scannerStatus = DocumentScannerAvailability.checkAvailability()
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                if scannerStatus.isAvailable {
                    DocumentCameraView(store: store)
                        .ignoresSafeArea()
                } else {
                    CameraPermissionAlert(
                        status: scannerStatus,
                        onRequestPermission: {
                            Task {
                                let granted = await DocumentScannerAvailability.requestCameraPermission()
                                if granted {
                                    scannerStatus = .available
                                } else {
                                    scannerStatus = .permissionDenied
                                }
                            }
                        },
                        onOpenSettings: {
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsURL)
                            }
                            isPresented = false
                        },
                        onDismiss: {
                            isPresented = false
                        }
                    )
                }
            }
            .onAppear {
                scannerStatus = DocumentScannerAvailability.checkAvailability()
            }
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    scannerStatus = DocumentScannerAvailability.checkAvailability()
                }
            }
    }
}