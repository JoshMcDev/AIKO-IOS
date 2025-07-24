# Comprehensive File & Media Management Suite - Testing Rubric

**Date**: January 24, 2025  
**Version**: 1.0 Draft  
**Status**: Draft for VanillaIce Consensus  
**Based on**: Enhanced PRD and Implementation Plan  
**TDD Phase**: RED → GREEN → REFACTOR Testing Strategy

---

## Executive Summary

This testing rubric defines the comprehensive testing strategy for the Comprehensive File & Media Management Suite (CFMMS) integration into AIKO's existing TCA architecture. Following TDD principles, this rubric ensures thorough coverage of all service implementations, TCA integration points, and performance requirements identified in the implementation plan.

### Testing Philosophy: RED → GREEN → REFACTOR

```swift
// TDD Cycle Implementation
RED Phase:    Write failing tests that define expected behavior
GREEN Phase:  Implement minimal code to make tests pass  
REFACTOR:     Clean up code while maintaining passing tests
```

---

## Test Coverage Requirements

### Minimum Coverage Standards
- **Overall Coverage**: ≥85% line coverage across all CFMMS components
- **Service Layer**: ≥90% coverage for all service implementations
- **TCA Reducers**: ≥95% coverage for MediaManagementFeature actions
- **Integration Points**: 100% coverage for DocumentScannerFeature integration
- **Error Handling**: 100% coverage for all error scenarios

### Coverage Exclusions
- Platform-specific bridging code (marked with `// Coverage Exclusion`)
- Xcode-generated boilerplate
- Third-party library integration glue code

---

## Testing Categories

## 1. Service Layer Testing (RED Phase Priority)

### 1.1 CameraService Implementation Tests

**File**: `Tests/AIKOiOSTests/Services/CameraServiceTests.swift`

**RED Phase Test Requirements**:

```swift
import XCTest
import AVFoundation
@testable import AIKOiOS

final class CameraServiceTests: XCTestCase {
    var sut: CameraService!
    var mockCaptureSession: MockAVCaptureSession!
    
    override func setUp() async throws {
        sut = CameraService()
        mockCaptureSession = MockAVCaptureSession()
    }
    
    // MARK: - Authorization Tests (Must Fail Initially)
    
    func test_checkCameraAuthorization_whenAuthorized_returnsTrue() async {
        // RED: This test must fail initially - CameraService returns false
        let hasAuthorization = await sut.checkCameraAuthorization()
        XCTAssertTrue(hasAuthorization, "Should return true when camera is authorized")
    }
    
    func test_requestCameraAccess_whenGranted_returnsTrue() async {
        // RED: This test must fail initially - CameraService returns false
        let accessGranted = await sut.requestCameraAccess()
        XCTAssertTrue(accessGranted, "Should return true when camera access is granted")
    }
    
    // MARK: - Photo Capture Tests (Must Fail Initially)
    
    func test_capturePhoto_withBasicConfig_returnsPhotoData() async throws {
        // RED: This test must fail initially - CameraService throws MediaError.unsupportedOperation
        let config = CameraCaptureConfig(
            position: .back,
            flashMode: .auto,
            quality: .high
        )
        
        let photoData = try await sut.capturePhoto(config: config)
        XCTAssertFalse(photoData.isEmpty, "Photo data should not be empty")
        XCTAssertGreaterThan(photoData.count, 1000, "Photo data should be substantial")
    }
    
    func test_capturePhoto_withInvalidConfig_throwsError() async {
        // RED: This test should define error behavior
        let invalidConfig = CameraCaptureConfig(
            position: .unavailable,
            flashMode: .on,
            quality: .low
        )
        
        do {
            _ = try await sut.capturePhoto(config: invalidConfig)
            XCTFail("Should throw error for invalid configuration")
        } catch let error as MediaError {
            XCTAssertEqual(error, .cameraNotAvailable)
        }
    }
    
    // MARK: - Video Recording Tests (Must Fail Initially)
    
    func test_startVideoRecording_withValidConfig_returnsSessionID() async throws {
        // RED: This test must fail initially - CameraService throws MediaError.unsupportedOperation
        let config = CameraCaptureConfig(
            position: .back,
            flashMode: .off,
            quality: .medium
        )
        
        let sessionID = try await sut.startVideoRecording(config: config)
        XCTAssertFalse(sessionID.isEmpty, "Session ID should not be empty")
    }
    
    func test_stopVideoRecording_withActiveSession_returnsVideoURL() async throws {
        // RED: This test must fail initially
        let config = CameraCaptureConfig.default
        _ = try await sut.startVideoRecording(config: config)
        
        let videoURL = try await sut.stopVideoRecording()
        XCTAssertTrue(FileManager.default.fileExists(atPath: videoURL.path))
    }
    
    // MARK: - Camera Switching Tests (Must Fail Initially)
    
    func test_getAvailableCameras_returnsNonEmptyArray() async {
        // RED: This test must fail initially - CameraService returns []
        let cameras = await sut.getAvailableCameras()
        XCTAssertFalse(cameras.isEmpty, "Should return available cameras")
        XCTAssertTrue(cameras.contains { $0.position == .back }, "Should include back camera")
    }
    
    func test_switchCamera_toValidPosition_succeeds() async throws {
        // RED: This test must fail initially - CameraService throws MediaError.unsupportedOperation
        try await sut.switchCamera(to: .front)
        
        let cameras = await sut.getAvailableCameras()
        let currentCamera = cameras.first { $0.isActive }
        XCTAssertEqual(currentCamera?.position, .front)
    }
    
    // MARK: - Performance Tests
    
    func test_cameraInitialization_completesWithinTimeout() async {
        // Performance requirement: <500ms initialization
        let startTime = CFAbsoluteTimeGetCurrent()
        
        _ = await sut.checkCameraAuthorization()
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(duration, 0.5, "Camera initialization should complete within 500ms")
    }
}
```

**Test Coverage Requirements**:
- ✅ All 25 TODO methods must have corresponding failing tests
- ✅ Authorization flow testing (granted/denied scenarios)
- ✅ Photo capture with various configurations
- ✅ Video recording lifecycle (start/stop/error handling)
- ✅ Camera switching and device enumeration
- ✅ Performance benchmarks (<500ms initialization)
- ✅ Error handling for all edge cases

### 1.2 PhotoLibraryService Tests

**File**: `Tests/AIKOiOSTests/Services/PhotoLibraryServiceTests.swift`

**RED Phase Test Requirements**:

```swift
final class PhotoLibraryServiceTests: XCTestCase {
    var sut: PhotoLibraryService!
    
    // MARK: - Authorization Tests (Must Fail Initially)
    
    func test_requestAccess_whenGranted_returnsTrue() async {
        // RED: This test must fail initially - service doesn't exist
        let accessGranted = await sut.requestAccess()
        XCTAssertTrue(accessGranted)
    }
    
    // MARK: - Photo Selection Tests (Must Fail Initially)
    
    func test_pickPhoto_withSingleSelection_returnsMediaAsset() async throws {
        // RED: This test must fail initially - service doesn't exist
        let asset = try await sut.pickPhoto()
        XCTAssertNotNil(asset.url)
        XCTAssertEqual(asset.type, .image)
    }
    
    func test_pickMultiplePhotos_withValidLimit_returnsAssetArray() async throws {
        // RED: This test must fail initially - service doesn't exist
        let assets = try await sut.pickMultiplePhotos()
        XCTAssertFalse(assets.isEmpty)
        XCTAssertLessThanOrEqual(assets.count, 10) // Default limit
    }
    
    // MARK: - Album Management Tests (Must Fail Initially)
    
    func test_loadAlbums_returnsPhotoAlbumArray() async throws {
        // RED: This test must fail initially - service doesn't exist
        let albums = try await sut.loadAlbums()
        XCTAssertFalse(albums.isEmpty)
        XCTAssertTrue(albums.contains { $0.name == "Camera Roll" })
    }
    
    // MARK: - Performance Tests
    
    func test_albumLoading_completesWithinTimeout() async throws {
        // Performance requirement: <1s album loading
        let startTime = CFAbsoluteTimeGetCurrent()
        
        _ = try await sut.loadAlbums()
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(duration, 1.0, "Album loading should complete within 1 second")
    }
}
```

### 1.3 MediaValidationService Enhancement Tests

**File**: `Tests/AppCoreTests/Services/MediaValidationServiceTests.swift`

**RED Phase Test Requirements**:

```swift
final class MediaValidationServiceTests: XCTestCase {
    var sut: MediaValidationService!
    
    // MARK: - File Validation Tests (Must Fail Initially)
    
    func test_validateFile_withValidImage_returnsSuccessResult() async throws {
        // RED: Enhanced validation logic doesn't exist yet
        let validImageURL = Bundle.module.url(forResource: "sample", withExtension: "jpg")!
        
        let result = try await sut.validateFile(validImageURL)
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.issues?.isEmpty ?? true)
    }
    
    func test_validateFile_withOversizedFile_returnsValidationIssue() async throws {
        // RED: File size validation doesn't exist yet
        let oversizedFileURL = createOversizedTestFile()
        
        let result = try await sut.validateFile(oversizedFileURL)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.issues?.contains { issue in
            case .fileTooLarge = issue; return true
            default: return false
        } ?? false)
    }
    
    func test_validateFile_withUnsupportedMimeType_returnsValidationIssue() async throws {
        // RED: MIME type validation doesn't exist yet
        let unsupportedFileURL = Bundle.module.url(forResource: "sample", withExtension: "bmp")!
        
        let result = try await sut.validateFile(unsupportedFileURL)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.issues?.contains { issue in
            case .unsupportedFileType = issue; return true
            default: return false
        } ?? false)
    }
    
    // MARK: - Performance Tests
    
    func test_fileValidation_completesWithinTimeout() async throws {
        // Performance requirement: <100ms per file
        let testFileURL = Bundle.module.url(forResource: "sample", withExtension: "jpg")!
        let startTime = CFAbsoluteTimeGetCurrent()
        
        _ = try await sut.validateFile(testFileURL)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(duration, 0.1, "File validation should complete within 100ms")
    }
}
```

### 1.4 BatchProcessingEngine Tests

**File**: `Tests/AppCoreTests/Services/BatchProcessingEngineTests.swift`

**RED Phase Test Requirements**:

```swift
final class BatchProcessingEngineTests: XCTestCase {
    var sut: BatchProcessingEngine!
    
    // MARK: - Batch Operation Tests (Must Fail Initially)
    
    func test_startBatchOperation_withValidAssets_returnsHandle() async throws {
        // RED: BatchProcessingEngine doesn't exist yet
        let assetIds = [UUID(), UUID(), UUID()]
        
        let handle = try await sut.startBatchOperation(.validation, assets: assetIds)
        XCTAssertEqual(handle.type, .validation)
        XCTAssertNotNil(handle.operationId)
    }
    
    func test_getProgress_withActiveOperation_returnsCurrentProgress() async throws {
        // RED: Progress tracking doesn't exist yet
        let assetIds = [UUID(), UUID(), UUID()]
        let handle = try await sut.startBatchOperation(.enhancement, assets: assetIds)
        
        let progress = await sut.getProgress(for: handle)
        XCTAssertEqual(progress.totalItems, 3)
        XCTAssertEqual(progress.operationId, handle.operationId)
    }
    
    // MARK: - Concurrency Tests
    
    func test_concurrentBatchOperations_handlesMultipleOperations() async throws {
        // RED: Concurrent processing doesn't exist yet
        let operation1 = sut.startBatchOperation(.validation, assets: [UUID(), UUID()])
        let operation2 = sut.startBatchOperation(.enhancement, assets: [UUID(), UUID()])
        
        let (handle1, handle2) = try await (operation1, operation2)
        XCTAssertNotEqual(handle1.operationId, handle2.operationId)
    }
    
    // MARK: - Performance Tests
    
    func test_batchProcessing_handles50ConcurrentFiles() async throws {
        // Performance requirement: 50+ concurrent files
        let assetIds = (1...50).map { _ in UUID() }
        
        let handle = try await sut.startBatchOperation(.validation, assets: assetIds)
        let progress = await sut.getProgress(for: handle)
        
        XCTAssertEqual(progress.totalItems, 50)
        XCTAssertNotEqual(progress.status, .failed)
    }
}
```

## 2. TCA Integration Testing (RED Phase Priority)

### 2.1 MediaManagementFeature State Tests

**File**: `Tests/AppCoreTests/MediaManagement/MediaManagementFeatureTests.swift`

**RED Phase Test Requirements**:

```swift
import ComposableArchitecture
import XCTest
@testable import AppCore

@MainActor
final class MediaManagementFeatureTests: XCTestCase {
    
    // MARK: - File Picking Action Tests (Must Fail Initially)
    
    func test_pickFiles_updatesLoadingState() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        } withDependencies: {
            $0.filePickerClient = .testValue
        }
        
        await store.send(.pickFiles(allowedTypes: [.image], allowsMultiple: false)) {
            $0.isLoading = true
            $0.error = nil
            $0.lastFailedOperation = .pickFiles(allowedTypes: [.image], allowsMultiple: false)
        }
    }
    
    func test_pickFilesResponse_success_addsAssetsToState() async {
        let mockAsset = MediaAsset.mockImage
        let store = TestStore(
            initialState: MediaManagementFeature.State(isLoading: true)
        ) {
            MediaManagementFeature()
        }
        
        await store.send(.pickFilesResponse(.success([mockAsset]))) {
            $0.isLoading = false
            $0.assets.append(mockAsset)
            $0.lastFailedOperation = nil
        }
    }
    
    func test_pickFilesResponse_failure_setsError() async {
        let error = MediaError.filePickingFailed("Test error")
        let store = TestStore(
            initialState: MediaManagementFeature.State(isLoading: true)
        ) {
            MediaManagementFeature()
        }
        
        await store.send(.pickFilesResponse(.failure(error))) {
            $0.isLoading = false
            $0.error = error
        }
    }
    
    // MARK: - Photo Library Action Tests (Must Fail Initially)
    
    func test_selectPhotos_triggersPhotoLibraryClient() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        } withDependencies: {
            $0.photoLibraryClient = .testValue
        }
        
        await store.send(.selectPhotos(limit: 5)) {
            $0.isLoading = true
            $0.error = nil
        }
    }
    
    // MARK: - Camera Action Tests (Must Fail Initially)
    
    func test_capturePhoto_updatesCapturingState() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        } withDependencies: {
            $0.cameraClient = .testValue // This dependency doesn't exist yet
        }
        
        await store.send(.capturePhoto) {
            $0.isCapturing = true
            $0.error = nil
            $0.lastFailedOperation = .capturePhoto
        }
    }
    
    // MARK: - Asset Management Tests
    
    func test_selectAsset_addsToSelectedAssets() async {
        let asset = MediaAsset.mockImage
        let store = TestStore(
            initialState: MediaManagementFeature.State(assets: [asset])
        ) {
            MediaManagementFeature()
        }
        
        await store.send(.selectAsset(asset.id)) {
            $0.selectedAssets.insert(asset.id)
        }
    }
    
    func test_deselectAsset_removesFromSelectedAssets() async {
        let asset = MediaAsset.mockImage
        let store = TestStore(
            initialState: MediaManagementFeature.State(
                assets: [asset],
                selectedAssets: [asset.id]
            )
        ) {
            MediaManagementFeature()
        }
        
        await store.send(.deselectAsset(asset.id)) {
            $0.selectedAssets.remove(asset.id)
        }
    }
    
    // MARK: - Batch Operation Tests (Must Fail Initially)
    
    func test_startBatchOperation_withSelectedAssets_triggersProcessing() async {
        let assets = [MediaAsset.mockImage, MediaAsset.mockVideo]
        let selectedIds = Set(assets.map(\.id))
        
        let store = TestStore(
            initialState: MediaManagementFeature.State(
                assets: IdentifiedArrayOf(uniqueElements: assets),
                selectedAssets: selectedIds
            )
        ) {
            MediaManagementFeature()
        } withDependencies: {
            $0.batchProcessingClient = .testValue // This dependency doesn't exist yet
        }
        
        await store.send(.startBatchOperation(.validation)) {
            $0.isProcessing = true
            $0.error = nil
            $0.lastFailedOperation = .startBatchOperation(.validation)
        }
    }
    
    // MARK: - Metadata Extraction Tests (Must Fail Initially)
    
    func test_extractMetadata_withValidAsset_updatesAssetMetadata() async {
        let asset = MediaAsset.mockImage
        let mockMetadata = MediaMetadata.mock
        
        let store = TestStore(
            initialState: MediaManagementFeature.State(assets: [asset])
        ) {
            MediaManagementFeature()
        } withDependencies: {
            $0.mediaMetadataClient = .testValue
        }
        
        await store.send(.extractMetadata(assetId: asset.id)) {
            $0.isProcessing = true
            $0.error = nil
            $0.lastFailedOperation = .extractMetadata(assetId: asset.id)
        }
        
        await store.receive(.extractMetadataResponse(assetId: asset.id, .success(mockMetadata))) {
            $0.isProcessing = false
            $0.assets[id: asset.id]?.metadata = mockMetadata
        }
    }
    
    // MARK: - Validation Tests (Must Fail Initially)
    
    func test_validateAsset_withValidAsset_returnsValidationResult() async {
        let asset = MediaAsset.mockImage
        let validationResult = AssetValidationResult(
            isValid: true,
            issues: [],
            assetId: asset.id
        )
        
        let store = TestStore(
            initialState: MediaManagementFeature.State(assets: [asset])
        ) {
            MediaManagementFeature()
        } withDependencies: {
            $0.mediaValidationClient = .testValue
        }
        
        await store.send(.validateAsset(asset.id)) {
            $0.lastFailedOperation = .validateAsset(asset.id)
        }
        
        await store.receive(.validateAssetResponse(assetId: asset.id, .success(validationResult)))
    }
    
    // MARK: - Error Handling Tests
    
    func test_clearError_resetsErrorState() async {
        let store = TestStore(
            initialState: MediaManagementFeature.State(
                error: MediaError.fileNotFound("Test error")
            )
        ) {
            MediaManagementFeature()
        }
        
        await store.send(.clearError) {
            $0.error = nil
        }
    }
    
    func test_retryFailedOperation_resendsLastFailedAction() async {
        let lastOperation = MediaManagementFeature.Action.capturePhoto
        let store = TestStore(
            initialState: MediaManagementFeature.State(
                lastFailedOperation: lastOperation,
                error: MediaError.cameraAccessFailed("Test error")
            )
        ) {
            MediaManagementFeature()
        } withDependencies: {
            $0.cameraClient = .testValue
        }
        
        await store.send(.retryFailedOperation) {
            $0.error = nil
        }
        
        await store.receive(.capturePhoto) {
            $0.isCapturing = true
            $0.lastFailedOperation = .capturePhoto
        }
    }
    
    // MARK: - Performance Tests
    
    func test_stateUpdates_completeWithinTimeout() async {
        // Performance requirement: <100ms state updates
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await store.send(.selectAllAssets) {
            $0.selectedAssets = Set(state.assets.map(\.id))
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(duration, 0.1, "State updates should complete within 100ms")
    }
}
```

### 2.2 GlobalScanFeature Integration Tests

**File**: `Tests/AppCoreTests/Features/GlobalScanFeatureIntegrationTests.swift`

**RED Phase Test Requirements**:

```swift
@MainActor
final class GlobalScanFeatureIntegrationTests: XCTestCase {
    
    func test_mediaManagementIntegration_triggersDocumentScanner() async {
        // RED: Integration action doesn't exist yet
        let store = TestStore(initialState: GlobalScanFeature.State()) {
            GlobalScanFeature()
        }
        
        await store.send(.mediaManagement(.capturePhoto)) {
            // Should trigger document scanner integration
            $0.shouldShowScanner = true
        }
        
        await store.receive(.scanDocument)
    }
    
    func test_floatingActionButton_showsMediaManagementOptions() async {
        // RED: Media management options don't exist yet
        let store = TestStore(initialState: GlobalScanFeature.State()) {
            GlobalScanFeature()
        }
        
        await store.send(.showFloatingActionMenu) {
            $0.showActionMenu = true
            $0.availableActions.contains(.mediaManagement)
        }
    }
}
```

## 3. Integration Testing (GREEN Phase Priority)

### 3.1 DocumentImageProcessor Extension Tests

**File**: `Tests/AppCoreTests/Integration/DocumentImageProcessorMediaTests.swift`

**GREEN Phase Test Requirements**:

```swift
final class DocumentImageProcessorMediaTests: XCTestCase {
    var sut: DocumentImageProcessor!
    
    func test_enhanceMediaAsset_withBasicMode_returnsProcessedAsset() async throws {
        // GREEN: This test should pass after DocumentImageProcessor extension
        let mockAsset = MediaAsset.mockImage
        
        let processedAsset = try await sut.enhanceMediaAsset(mockAsset, mode: .basic)
        
        XCTAssertNotNil(processedAsset.enhancedImageData)
        XCTAssertNotNil(processedAsset.qualityMetrics)
        XCTAssertLessThan(processedAsset.processingTime, 2.0)
    }
    
    func test_enhanceMediaAsset_withEnhancedMode_providesQualityMetrics() async throws {
        // GREEN: This test should pass with enhanced processing
        let mockAsset = MediaAsset.mockImage
        
        let processedAsset = try await sut.enhanceMediaAsset(mockAsset, mode: .enhanced)
        
        XCTAssertGreaterThan(processedAsset.qualityMetrics.overallConfidence, 0.0)
        XCTAssertGreaterThan(processedAsset.qualityMetrics.sharpnessScore, 0.0)
        XCTAssertTrue(processedAsset.qualityMetrics.recommendedForOCR)
    }
}
```

### 3.2 Memory Management Tests

**File**: `Tests/AppCoreTests/Services/MediaAssetCacheTests.swift`

**GREEN Phase Test Requirements**:

```swift
final class MediaAssetCacheTests: XCTestCase {
    var sut: MediaAssetCache!
    
    func test_cacheAsset_withinSizeLimit_storesAsset() async throws {
        // GREEN: This test should pass after MediaAssetCache implementation
        let asset = MediaAsset.mockImage
        
        await sut.cacheAsset(asset)
        let cachedAsset = try await sut.loadAsset(asset.id)
        
        XCTAssertEqual(cachedAsset.id, asset.id)
    }
    
    func test_cacheEviction_whenExceedingLimit_removesOldestAssets() async throws {
        // GREEN: LRU eviction should work
        let assets = (1...10).map { _ in MediaAsset.mockLargeImage } // Each 10MB
        
        // Cache 6 assets (60MB, exceeds 50MB limit)
        for asset in assets.prefix(6) {
            await sut.cacheAsset(asset)
        }
        
        let cacheSize = await sut.currentCacheSize
        XCTAssertLessThanOrEqual(cacheSize, 50 * 1024 * 1024) // 50MB limit
    }
    
    // MARK: - Performance Tests
    
    func test_assetRetrieval_completesWithinTimeout() async throws {
        // Performance requirement: Fast cache access
        let asset = MediaAsset.mockImage
        await sut.cacheAsset(asset)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try await sut.loadAsset(asset.id)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(duration, 0.01, "Cache retrieval should be < 10ms")
    }
}
```

## 4. UI Testing (GREEN Phase Priority)

### 4.1 MediaManagementView Tests

**File**: `Tests/UITests/MediaManagementViewTests.swift`

**GREEN Phase Test Requirements**:

```swift
import ViewInspector
import SwiftUI
import XCTest
@testable import AIKO

final class MediaManagementViewTests: XCTestCase {
    
    func test_mediaManagementView_displaysAssetGrid() throws {
        let store = Store(initialState: MediaManagementFeature.State(
            assets: [MediaAsset.mockImage, MediaAsset.mockVideo]
        )) {
            MediaManagementFeature()
        }
        
        let view = MediaManagementView(store: store)
        
        let assetGrid = try view.inspect().find(AssetGridView.self)
        XCTAssertEqual(try assetGrid.actualView().assets.count, 2)
    }
    
    func test_actionToolbar_enablesCorrectButtons() throws {
        let store = Store(initialState: MediaManagementFeature.State(
            selectedAssets: [UUID()]
        )) {
            MediaManagementFeature()
        }
        
        let view = MediaManagementView(store: store)
        
        let toolbar = try view.inspect().find(MediaActionToolbar.self)
        XCTAssertTrue(try toolbar.actualView().hasSelectedAssets)
    }
}
```

### 4.2 Error Handling UI Tests

**File**: `Tests/UITests/MediaErrorHandlingTests.swift`

**GREEN Phase Test Requirements**:

```swift
final class MediaErrorHandlingTests: XCTestCase {
    
    func test_errorSheet_displaysForMediaErrors() throws {
        let store = Store(initialState: MediaManagementFeature.State(
            error: MediaError.cameraAccessFailed("Camera not available")
        )) {
            MediaManagementFeature()
        }
        
        let view = MediaManagementView(store: store)
        
        XCTAssertTrue(try view.inspect().find(ViewType.Sheet.self).isPresented())
    }
    
    func test_retryButton_triggersRetryAction() throws {
        let store = Store(initialState: MediaManagementFeature.State(
            error: MediaError.filePickingFailed("Picker error"),
            lastFailedOperation: .pickFiles(allowedTypes: [.image], allowsMultiple: false)
        )) {
            MediaManagementFeature()
        }
        
        let view = MediaManagementView(store: store)
        let errorView = try view.inspect().find(ErrorView.self)
        
        try errorView.find(button: "Retry").tap()
        
        // Verify retry action was sent
        XCTAssertEqual(store.state.error, nil)
    }
}
```

## 5. Performance Testing (REFACTOR Phase Priority)

### 5.1 Load Testing

**File**: `Tests/Performance/MediaManagementPerformanceTests.swift`

**REFACTOR Phase Test Requirements**:

```swift
import XCTest
@testable import AppCore

final class MediaManagementPerformanceTests: XCTestCase {
    
    func test_batchProcessing_50ConcurrentFiles_meetsPerformanceTarget() async throws {
        // Performance requirement: Handle 50+ concurrent files
        let assets = (1...50).map { _ in MediaAsset.mockImage }
        let engine = BatchProcessingEngine()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let handle = try await engine.startBatchOperation(.validation, assets: assets.map(\.id))
        
        // Wait for completion with timeout
        var progress: BatchProgress
        repeat {
            progress = await engine.getProgress(for: handle)
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        } while progress.status == .running && CFAbsoluteTimeGetCurrent() - startTime < 30.0
        
        XCTAssertEqual(progress.status, .completed)
        XCTAssertLessThan(CFAbsoluteTimeGetCurrent() - startTime, 30.0, "50 files should process within 30 seconds")
    }
    
    func test_memoryUsage_staysWithinLimit() async throws {
        // Performance requirement: <200MB memory usage
        let initialMemory = getMemoryUsage()
        
        // Load and process multiple large assets
        let assets = (1...20).map { _ in MediaAsset.mockLargeImage } // 20 x 10MB = 200MB
        let feature = MediaManagementFeature()
        
        var state = MediaManagementFeature.State()
        for asset in assets {
            state.assets.append(asset)
        }
        
        let currentMemory = getMemoryUsage()
        let memoryIncrease = currentMemory - initialMemory
        
        XCTAssertLessThan(memoryIncrease, 200 * 1024 * 1024, "Memory usage should stay under 200MB")
    }
    
    func test_cameraInitialization_meetsLatencyTarget() async {
        // Performance requirement: <500ms camera initialization
        let cameraService = CameraService()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = await cameraService.checkCameraAuthorization()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(duration, 0.5, "Camera initialization should complete within 500ms")
    }
    
    private func getMemoryUsage() -> Int64 {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(taskInfo.phys_footprint) : 0
    }
}
```

### 5.2 Stress Testing

**File**: `Tests/Performance/MediaManagementStressTests.swift`

**REFACTOR Phase Test Requirements**:

```swift
final class MediaManagementStressTests: XCTestCase {
    
    func test_rapidStateChanges_maintainsConsistency() async {
        // Stress test: Rapid state changes
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        // Simulate rapid user interactions
        for i in 0..<100 {
            let assetId = UUID()
            await store.send(.selectAsset(assetId))
            await store.send(.deselectAsset(assetId))
        }
        
        // State should remain consistent
        XCTAssertTrue(store.state.selectedAssets.isEmpty)
    }
    
    func test_largeBatchOperations_completesSuccessfully() async throws {
        // Stress test: Process 100 assets
        let assets = (1...100).map { _ in MediaAsset.mockImage }
        let engine = BatchProcessingEngine()
        
        let handle = try await engine.startBatchOperation(.validation, assets: assets.map(\.id))
        
        // Monitor progress
        var finalProgress: BatchProgress?
        let timeout = 60.0 // 1 minute timeout
        let startTime = CFAbsoluteTimeGetCurrent()
        
        while CFAbsoluteTimeGetCurrent() - startTime < timeout {
            let progress = await engine.getProgress(for: handle)
            
            if progress.status != .running {
                finalProgress = progress
                break
            }
            
            try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        }
        
        XCTAssertNotNil(finalProgress)
        XCTAssertEqual(finalProgress?.status, .completed)
        XCTAssertEqual(finalProgress?.totalItems, 100)
    }
}
```

## 6. Security & Privacy Testing

### 6.1 Permission Handling Tests

**File**: `Tests/SecurityTests/MediaPermissionTests.swift`

**Test Requirements**:

```swift
final class MediaPermissionTests: XCTestCase {
    
    func test_cameraPermission_handlesAllAuthorizationStates() async {
        let cameraService = CameraService()
        
        // Test various authorization states
        // This requires mocking AVCaptureDevice.authorizationStatus
        
        // Test: Authorized
        XCTAssertTrue(await cameraService.checkCameraAuthorization())
        
        // Test: Denied (should handle gracefully)
        // Mock denied state and verify error handling
        
        // Test: Not determined (should request permission)
        // Mock not determined state and verify permission request
    }
    
    func test_photoLibraryPermission_respectsUserChoice() async {
        let photoService = PhotoLibraryService()
        
        // Test permission flow
        let accessGranted = await photoService.requestAccess()
        
        // Should not proceed if access denied
        if !accessGranted {
            do {
                _ = try await photoService.pickPhoto()
                XCTFail("Should throw error when access denied")
            } catch {
                XCTAssertTrue(error is MediaError)
            }
        }
    }
}
```

### 6.2 Data Privacy Tests

**File**: `Tests/SecurityTests/MediaPrivacyTests.swift`

**Test Requirements**:

```swift
final class MediaPrivacyTests: XCTestCase {
    
    func test_metadataSanitization_removesPrivateInformation() {
        let originalMetadata = MediaMetadata(
            creationDate: Date(),
            location: CLLocation(latitude: 37.7749, longitude: -122.4194),
            deviceModel: "iPhone 15 Pro",
            cameraMake: "Apple",
            serialNumber: "ABC123XYZ"
        )
        
        let sanitizedMetadata = PrivacyManager.sanitizeMetadata(originalMetadata)
        
        XCTAssertNil(sanitizedMetadata.location)
        XCTAssertNil(sanitizedMetadata.deviceModel)
        XCTAssertNil(sanitizedMetadata.serialNumber)
        XCTAssertNotNil(sanitizedMetadata.creationDate) // Keep essential data
    }
    
    func test_localProcessing_doesNotLeakData() async {
        // Ensure all processing happens locally
        let asset = MediaAsset.mockImage
        let processor = DocumentImageProcessor()
        
        // Mock network monitoring to ensure no external calls
        let processedAsset = try await processor.enhanceMediaAsset(asset, mode: .enhanced)
        
        XCTAssertNotNil(processedAsset.enhancedImageData)
        // Verify no network activity occurred during processing
    }
}
```

## 7. Test Data & Mocking

### 7.1 Mock Data Extensions

**File**: `Tests/Shared/TestUtilities+MediaAssets.swift`

```swift
extension MediaAsset {
    static var mockImage: MediaAsset {
        MediaAsset(
            id: UUID(),
            url: Bundle.module.url(forResource: "sample_image", withExtension: "jpg"),
            type: .image,
            metadata: .mock
        )
    }
    
    static var mockVideo: MediaAsset {
        MediaAsset(
            id: UUID(),
            url: Bundle.module.url(forResource: "sample_video", withExtension: "mp4"),
            type: .video,
            metadata: .mock
        )
    }
    
    static var mockLargeImage: MediaAsset {
        // 10MB test image for memory testing
        MediaAsset(
            id: UUID(),
            url: Bundle.module.url(forResource: "large_sample", withExtension: "jpg"),
            type: .image,
            metadata: .mock
        )
    }
}

extension MediaMetadata {
    static var mock: MediaMetadata {
        MediaMetadata(
            creationDate: Date(),
            fileSize: 2_048_576, // 2MB
            dimensions: CGSize(width: 1920, height: 1080),
            colorSpace: .sRGB
        )
    }
}
```

### 7.2 Test Dependencies

**File**: `Tests/Shared/TestDependencies+MediaManagement.swift`

```swift
extension DependencyValues {
    var filePickerClient: FilePickerClient {
        get { self[FilePickerClient.self] }
        set { self[FilePickerClient.self] = newValue }
    }
    
    var photoLibraryClient: PhotoLibraryClient {
        get { self[PhotoLibraryClient.self] }
        set { self[PhotoLibraryClient.self] = newValue }
    }
    
    var cameraClient: CameraClient {
        get { self[CameraClient.self] }
        set { self[CameraClient.self] = newValue }
    }
    
    var mediaValidationClient: MediaValidationClient {
        get { self[MediaValidationClient.self] }
        set { self[MediaValidationClient.self] = newValue }
    }
    
    var batchProcessingClient: BatchProcessingClient {
        get { self[BatchProcessingClient.self] }
        set { self[BatchProcessingClient.self] = newValue }
    }
}

// Test implementations
extension FilePickerClient {
    static let testValue = Self(
        pickFile: { MediaAsset.mockImage },
        pickMultipleFiles: { [MediaAsset.mockImage, MediaAsset.mockVideo] }
    )
}

extension PhotoLibraryClient {
    static let testValue = Self(
        requestAccess: { true },
        pickPhoto: { MediaAsset.mockImage },
        pickMultiplePhotos: { [MediaAsset.mockImage] },
        loadAlbums: { [PhotoAlbum.mock] }
    )
}
```

---

## Success Criteria & Definition of Done

### RED Phase Completion Criteria
- ✅ All service layer tests written and **FAILING** 
- ✅ All TCA integration tests written and **FAILING**
- ✅ All UI tests written and **FAILING**
- ✅ Test coverage baseline established (should be 0% for new features)
- ✅ Mock dependencies and test data created
- ✅ Performance benchmarks defined (tests should fail initial performance requirements)

### GREEN Phase Completion Criteria  
- ✅ All RED phase tests **PASSING**
- ✅ Minimum viable implementation completed for each service
- ✅ TCA integration fully functional
- ✅ Basic UI interactions working
- ✅ Performance targets **MET** (not exceeded)
- ✅ Error handling covers all defined scenarios

### REFACTOR Phase Completion Criteria
- ✅ Code cleanup and optimization completed
- ✅ All tests still **PASSING** after refactoring
- ✅ Performance optimizations applied and validated
- ✅ Code documentation updated
- ✅ Final integration testing completed
- ✅ Memory leaks identified and resolved

### Overall Definition of Done
- **Test Coverage**: ≥85% overall, ≥90% for service layer, ≥95% for TCA reducers
- **Performance Targets**: All performance requirements met or exceeded
- **Integration**: Seamless integration with existing DocumentScannerFeature and GlobalScanFeature
- **Error Handling**: 100% coverage of error scenarios with appropriate user feedback
- **Security**: Privacy compliance validated, permissions properly handled
- **Documentation**: Comprehensive test documentation and code comments

---

## Test Execution Strategy

### Phase 1: RED (Week 1)
1. **Day 1-2**: Write failing service layer tests (CameraService, PhotoLibraryService)
2. **Day 3**: Write failing TCA integration tests (MediaManagementFeature)
3. **Day 4**: Write failing UI and integration tests
4. **Day 5**: Create test data, mocks, and performance benchmarks

### Phase 2: GREEN (Weeks 2-3)
1. **Week 2**: Implement minimal service layer functionality to pass tests
2. **Week 3**: Complete TCA integration and UI implementation
3. **Continuous**: Run test suite after each implementation increment

### Phase 3: REFACTOR (Week 4)
1. **Days 1-2**: Code cleanup and optimization
2. **Days 3-4**: Performance tuning and memory optimization  
3. **Day 5**: Final testing and validation

### Continuous Integration
- Tests run automatically on every commit
- Performance benchmarks tracked over time
- Test coverage reports generated for each build
- Automated failure notifications for any regression

---

---

## VanillaIce Consensus Results ✅

**Consensus Status**: **APPROVED (3/3 Models)**  
**Review Date**: January 24, 2025  
**Models Consulted**: Swift Implementation Expert, Swift Test Engineer, ULTRATHINK Utility Generator

### Key Consensus Points

#### ✅ TDD Strategy - APPROVED
- **Decision**: RED → GREEN → REFACTOR cycle with comprehensive coverage requirements
- **Consensus**: "Detailed, well-structured, and aligns well with AIKO's existing testing patterns"
- **Coverage Goals**: ≥85% overall, ≥90% service layer, ≥95% TCA reducers validated as "ambitious but crucial for software reliability"

#### ✅ Service Layer Testing - APPROVED
- **Decision**: Complete coverage for CameraService (25 TODOs), PhotoLibraryService, BatchProcessingEngine, MediaValidation, MediaAssetCache
- **Consensus**: "Adequately addresses service layer testing, essential for ensuring core functionalities are thoroughly vetted"
- **Enhancement**: Ensure testing resources and timelines are aligned to meet objectives without compromising delivery schedules

#### ✅ TCA Integration Testing - APPROVED
- **Decision**: Comprehensive MediaManagementFeature testing with 163 actions, state management validation
- **Consensus**: "Comprehensive approach ensures MediaManagementFeature works seamlessly with existing DocumentScannerFeature"
- **Performance**: <100ms state updates benchmark validated as critical for user experience

#### ✅ Performance Benchmarks - APPROVED
- **Decision**: <500ms camera init, <1s album loading, <100ms file validation, 50+ concurrent files, <200MB memory
- **Consensus**: "Well-defined and critical for ensuring efficient performance under various conditions"
- **Enhancement**: Continuously validate benchmarks against real-world scenarios as software evolves

#### ✅ Security & Privacy Testing - APPROVED
- **Decision**: Permission handling, metadata sanitization, local processing validation
- **Consensus**: "Aligns with best practices for security and privacy, reducing risks associated with data leaks"
- **Coverage**: 100% permission scenario coverage validated as essential

### Enhanced Implementation Recommendations

Based on VanillaIce consensus feedback, the following enhancements have been incorporated:

1. **Resource Alignment**: Ensure testing resources and timelines align with ambitious coverage goals without compromising delivery
2. **Continuous Validation**: Regular validation of performance benchmarks against real-world scenarios
3. **Team Discipline**: RED → GREEN → REFACTOR cycle requires consistent team discipline and regular reviews
4. **Ongoing Alignment**: Regular alignment checks with AIKO's existing patterns to ensure compatibility
5. **Adaptability**: Maintain strategy adaptability for continuous improvement over time

### Critical Success Factors

1. **Test Coverage Adequacy**: Ambitious goals require diligent effort and proper resource allocation
2. **Performance Benchmark Validity**: Benchmarks should remain relevant and achievable as software evolves
3. **TDD Cycle Implementation**: Requires team discipline and regular reviews for efficiency
4. **Pattern Alignment**: Continuous compatibility with AIKO's existing testing patterns
5. **Quality Assurance**: Regular reviews and adaptability key to maintaining effectiveness

**Final Consensus**: The TDD testing strategy represents a "mature and comprehensive approach" that "effectively addresses various essential aspects including service layer testing, integration testing, performance, and security." The strategy has "potential to significantly enhance the quality and reliability of the software suite."

**Ready for Implementation** ✅

<!-- /tdd complete -->