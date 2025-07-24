import XCTest
import ComposableArchitecture
import Dependencies
@testable import AppCore

@MainActor
final class MediaManagementFeatureTests: XCTestCase {
    
    // MARK: - State Initialization Tests
    
    func testInitialState() {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        XCTAssertTrue(store.state.assets.isEmpty)
        XCTAssertTrue(store.state.selectedAssets.isEmpty)
        XCTAssertFalse(store.state.isLoading)
        XCTAssertFalse(store.state.isProcessing)
        XCTAssertFalse(store.state.isCapturing)
        XCTAssertFalse(store.state.isRecording)
        XCTAssertFalse(store.state.hasCameraPermission)
        XCTAssertFalse(store.state.hasPhotoLibraryPermission)
        XCTAssertFalse(store.state.hasMicrophonePermission)
        XCTAssertNil(store.state.error)
        XCTAssertTrue(store.state.albums.isEmpty)
        XCTAssertNil(store.state.currentBatchOperation)
        XCTAssertNil(store.state.batchProgress)
        XCTAssertTrue(store.state.availableWorkflows.isEmpty)
        XCTAssertTrue(store.state.workflowTemplates.isEmpty)
        XCTAssertEqual(store.state.filter, .none)
        XCTAssertEqual(store.state.sortOrder, .dateDescending)
        XCTAssertNil(store.state.mediaSession)
        XCTAssertFalse(store.state.isSessionActive)
    }
    
    func testComputedProperties() {
        var state = MediaManagementFeature.State()
        
        // Test hasAssets
        XCTAssertFalse(state.hasAssets)
        
        let asset = MediaAsset(id: UUID(), type: .image)
        state.assets.append(asset)
        XCTAssertTrue(state.hasAssets)
        
        // Test hasSelectedAssets
        XCTAssertFalse(state.hasSelectedAssets)
        
        state.selectedAssets.insert(asset.id)
        XCTAssertTrue(state.hasSelectedAssets)
        
        // Test canStartBatchOperation
        XCTAssertTrue(state.canStartBatchOperation) // has selected assets and not processing
        
        state.isProcessing = true
        XCTAssertFalse(state.canStartBatchOperation) // processing
    }
    
    // MARK: - File Picking Tests
    
    func testPickFilesSuccess() async {
        let mockAssets = [
            MediaAsset(id: UUID(), type: .image),
            MediaAsset(id: UUID(), type: .document)
        ]
        
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        } withDependencies: {
            $0.filePickerClient.pickMultipleFiles = { mockAssets }
        }
        
        await store.send(.pickFiles(allowedTypes: [.image, .document], allowsMultiple: true)) {
            $0.isLoading = true
            $0.error = nil
        }
        
        await store.receive(.pickFilesResponse(.success(mockAssets))) {
            $0.isLoading = false
            $0.assets.append(contentsOf: mockAssets)
        }
    }
    
    func testPickFilesSingleFileSuccess() async {
        let mockAsset = MediaAsset(id: UUID(), type: .image)
        
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        } withDependencies: {
            $0.filePickerClient.pickFile = { mockAsset }
        }
        
        await store.send(.pickFiles(allowedTypes: [.image], allowsMultiple: false)) {
            $0.isLoading = true
            $0.error = nil
        }
        
        await store.receive(.pickFilesResponse(.success([mockAsset]))) {
            $0.isLoading = false
            $0.assets.append(mockAsset)
        }
    }
    
    func testPickFilesFailure() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        } withDependencies: {
            $0.filePickerClient.pickMultipleFiles = {
                throw NSError(domain: "FilePickerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Access denied"])
            }
        }
        
        await store.send(.pickFiles(allowedTypes: [.image], allowsMultiple: true)) {
            $0.isLoading = true
            $0.error = nil
        }
        
        await store.receive(.pickFilesResponse(.failure(.filePickingFailed("Access denied")))) {
            $0.isLoading = false
            $0.error = .filePickingFailed("Access denied")
        }
    }
    
    // MARK: - Photo Library Tests
    
    func testSelectPhotosSuccess() async {
        let mockAssets = [
            MediaAsset(id: UUID(), type: .photo),
            MediaAsset(id: UUID(), type: .photo)
        ]
        
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        } withDependencies: {
            $0.photoLibraryClient.pickMultiplePhotos = { mockAssets }
        }
        
        await store.send(.selectPhotos(limit: 5)) {
            $0.isLoading = true
            $0.error = nil
        }
        
        await store.receive(.selectPhotosResponse(.success(mockAssets))) {
            $0.isLoading = false
            $0.assets.append(contentsOf: mockAssets)
        }
    }
    
    func testSelectSinglePhotoSuccess() async {
        let mockAsset = MediaAsset(id: UUID(), type: .photo)
        
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        } withDependencies: {
            $0.photoLibraryClient.pickPhoto = { mockAsset }
        }
        
        await store.send(.selectPhotos(limit: 1)) {
            $0.isLoading = true
            $0.error = nil
        }
        
        await store.receive(.selectPhotosResponse(.success([mockAsset]))) {
            $0.isLoading = false
            $0.assets.append(mockAsset)
        }
    }
    
    func testRequestPhotoLibraryPermission() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        } withDependencies: {
            $0.photoLibraryClient.requestAccess = { true }
        }
        
        await store.send(.requestPhotoLibraryPermission)
        
        await store.receive(.photoLibraryPermissionResponse(true)) {
            $0.hasPhotoLibraryPermission = true
        }
    }
    
    // MARK: - Camera Tests
    
    func testRequestCameraPermission() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        await store.send(.requestCameraPermission)
        
        await store.receive(.cameraPermissionResponse(false))
    }
    
    func testCapturePhotoNotImplemented() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        await store.send(.capturePhoto) {
            $0.isCapturing = true
            $0.error = nil
        }
        
        await store.receive(.capturePhotoResponse(.failure(.cameraAccessFailed("Camera functionality requires CameraClient implementation")))) {
            $0.isCapturing = false
            $0.error = .cameraAccessFailed("Camera functionality requires CameraClient implementation")
        }
    }
    
    func testVideoRecordingNotImplemented() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        await store.send(.startVideoRecording) {
            $0.isRecording = true
            $0.error = nil
        }
        
        await store.receive(.startVideoRecordingResponse(.failure(.cameraAccessFailed("Video recording requires CameraClient implementation")))) {
            $0.isRecording = false
            $0.error = .cameraAccessFailed("Video recording requires CameraClient implementation")
        }
    }
    
    // MARK: - Screenshot Tests
    
    func testCaptureScreenshotSuccess() async {
        let mockAsset = MediaAsset(id: UUID(), type: .screenshot)
        
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        } withDependencies: {
            $0.screenshotClient.captureScreen = { mockAsset }
        }
        
        await store.send(.captureScreenshot(.fullScreen)) {
            $0.isCapturing = true
            $0.error = nil
        }
        
        await store.receive(.captureScreenshotResponse(.success(mockAsset))) {
            $0.isCapturing = false
            $0.assets.append(mockAsset)
        }
    }
    
    func testCaptureScreenshotFailure() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        } withDependencies: {
            $0.screenshotClient.captureScreen = {
                throw NSError(domain: "ScreenshotError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
            }
        }
        
        await store.send(.captureScreenshot(.fullScreen)) {
            $0.isCapturing = true
            $0.error = nil
        }
        
        await store.receive(.captureScreenshotResponse(.failure(.screenshotFailed("Permission denied")))) {
            $0.isCapturing = false
            $0.error = .screenshotFailed("Permission denied")
        }
    }
    
    func testScreenRecordingSuccess() async {
        let mockAsset = MediaAsset(id: UUID(), type: .video)
        
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        } withDependencies: {
            $0.screenshotClient.startRecording = { }
            $0.screenshotClient.stopRecording = { mockAsset }
        }
        
        // Start recording
        await store.send(.startScreenRecording) {
            $0.isRecording = true
            $0.error = nil
        }
        
        await store.receive(.startScreenRecordingResponse(.success(true)))
        
        // Stop recording
        await store.send(.stopScreenRecording) {
            $0.isRecording = false
        }
        
        await store.receive(.stopScreenRecordingResponse(.success(mockAsset))) {
            $0.assets.append(mockAsset)
        }
    }
    
    // MARK: - Asset Management Tests
    
    func testSelectAsset() async {
        let assetId = UUID()
        let asset = MediaAsset(id: assetId, type: .image)
        
        var initialState = MediaManagementFeature.State()
        initialState.assets.append(asset)
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        }
        
        await store.send(.selectAsset(assetId)) {
            $0.selectedAssets.insert(assetId)
        }
    }
    
    func testDeselectAsset() async {
        let assetId = UUID()
        
        var initialState = MediaManagementFeature.State()
        initialState.selectedAssets.insert(assetId)
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        }
        
        await store.send(.deselectAsset(assetId)) {
            $0.selectedAssets.remove(assetId)
        }
    }
    
    func testSelectAllAssets() async {
        let asset1 = MediaAsset(id: UUID(), type: .image)
        let asset2 = MediaAsset(id: UUID(), type: .video)
        
        var initialState = MediaManagementFeature.State()
        initialState.assets.append(contentsOf: [asset1, asset2])
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        }
        
        await store.send(.selectAllAssets) {
            $0.selectedAssets = Set([asset1.id, asset2.id])
        }
    }
    
    func testDeselectAllAssets() async {
        var initialState = MediaManagementFeature.State()
        initialState.selectedAssets = Set([UUID(), UUID()])
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        }
        
        await store.send(.deselectAllAssets) {
            $0.selectedAssets = []
        }
    }
    
    func testDeleteAsset() async {
        let asset1 = MediaAsset(id: UUID(), type: .image)
        let asset2 = MediaAsset(id: UUID(), type: .video)
        
        var initialState = MediaManagementFeature.State()
        initialState.assets.append(contentsOf: [asset1, asset2])
        initialState.selectedAssets.insert(asset1.id)
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        }
        
        await store.send(.deleteAsset(asset1.id)) {
            $0.assets.remove(id: asset1.id)
            $0.selectedAssets.remove(asset1.id)
        }
        
        XCTAssertEqual(store.state.assets.count, 1)
        XCTAssertEqual(store.state.assets.first?.id, asset2.id)
    }
    
    func testDeleteSelectedAssets() async {
        let asset1 = MediaAsset(id: UUID(), type: .image)
        let asset2 = MediaAsset(id: UUID(), type: .video)
        let asset3 = MediaAsset(id: UUID(), type: .document)
        
        var initialState = MediaManagementFeature.State()
        initialState.assets.append(contentsOf: [asset1, asset2, asset3])
        initialState.selectedAssets = Set([asset1.id, asset3.id])
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        }
        
        await store.send(.deleteSelectedAssets) {
            $0.assets.remove(id: asset1.id)
            $0.assets.remove(id: asset3.id)
            $0.selectedAssets = []
        }
        
        XCTAssertEqual(store.state.assets.count, 1)
        XCTAssertEqual(store.state.assets.first?.id, asset2.id)
    }
    
    // MARK: - Metadata Tests
    
    func testExtractMetadataSuccess() async {
        let assetId = UUID()
        let assetURL = URL(string: "file:///test.jpg")!
        let asset = MediaAsset(id: assetId, type: .image, url: assetURL)
        let mockMetadata = MediaMetadata(width: 1920, height: 1080)
        
        var initialState = MediaManagementFeature.State()
        initialState.assets.append(asset)
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        } withDependencies: {
            $0.mediaMetadataClient.extractMetadata = { _ in mockMetadata }
        }
        
        await store.send(.extractMetadata(assetId: assetId)) {
            $0.isProcessing = true
            $0.error = nil
        }
        
        await store.receive(.extractMetadataResponse(assetId: assetId, .success(mockMetadata))) {
            $0.isProcessing = false
            $0.assets[id: assetId]?.metadata = mockMetadata
        }
    }
    
    func testExtractMetadataAssetNotFound() async {
        let assetId = UUID()
        
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        await store.send(.extractMetadata(assetId: assetId)) {
            $0.isProcessing = true
            $0.error = nil
        }
        
        await store.receive(.extractMetadataResponse(assetId: assetId, .failure(.fileNotFound("Asset not found")))) {
            $0.isProcessing = false
            $0.error = .fileNotFound("Asset not found")
        }
    }
    
    func testUpdateMetadata() async {
        let assetId = UUID()
        let asset = MediaAsset(id: assetId, type: .image)
        let newMetadata = MediaMetadata(width: 1920, height: 1080)
        
        var initialState = MediaManagementFeature.State()
        initialState.assets.append(asset)
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        }
        
        await store.send(.updateMetadata(assetId: assetId, metadata: newMetadata)) {
            $0.assets[id: assetId]?.metadata = newMetadata
        }
    }
    
    // MARK: - Validation Tests
    
    func testValidateAssetSuccess() async {
        let assetId = UUID()
        let assetURL = URL(string: "file:///test.jpg")!
        let asset = MediaAsset(id: assetId, type: .image, url: assetURL)
        let mockValidationResult = MediaClientValidationResult(isValid: true)
        
        var initialState = MediaManagementFeature.State()
        initialState.assets.append(asset)
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        } withDependencies: {
            $0.mediaValidationClient.validateFile = { _ in mockValidationResult }
        }
        
        await store.send(.validateAsset(assetId))
        
        // We expect a response but don't assert the exact content due to dynamic timestamps
        // The test ensures the async flow works correctly
        _ = await store.receive(\.validateAssetResponse)
    }
    
    func testValidateAllAssets() async {
        let asset1 = MediaAsset(id: UUID(), type: .image, url: URL(string: "file:///test1.jpg")!)
        let asset2 = MediaAsset(id: UUID(), type: .image, url: URL(string: "file:///test2.jpg")!)
        let mockValidationResult = MediaClientValidationResult(isValid: true)
        
        var initialState = MediaManagementFeature.State()
        initialState.assets.append(contentsOf: [asset1, asset2])
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        } withDependencies: {
            $0.mediaValidationClient.validateFile = { _ in mockValidationResult }
        }
        
        await store.send(.validateAllAssets) {
            $0.isProcessing = true
        }
        
        // Expect validation responses for both assets (don't assert exact content due to dynamic timestamps)
        _ = await store.receive(\.validateAssetResponse)
        _ = await store.receive(\.validateAssetResponse)
        await store.receive(.validateAllAssetsComplete) {
            $0.isProcessing = false
        }
    }
    
    // MARK: - Batch Operations Tests
    
    func testStartBatchOperationSuccess() async {
        let assetId = UUID()
        let asset = MediaAsset(id: assetId, type: .image)
        
        var initialState = MediaManagementFeature.State()
        initialState.assets.append(asset)
        initialState.selectedAssets.insert(assetId)
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        }
        
        await store.send(.startBatchOperation(.compress)) {
            $0.isProcessing = true
            $0.error = nil
        }
        
        await store.receive(\.batchOperationResponse.success) { state in
            state.isProcessing = false
            // The reducer will set currentBatchOperation - match the structure
            state.currentBatchOperation = BatchOperationHandle(operationId: UUID(), type: .compress)
        }
    }
    
    func testStartBatchOperationNoAssetsSelected() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        await store.send(.startBatchOperation(.compress)) {
            $0.isProcessing = true
            $0.error = nil
        }
        
        await store.receive(.batchOperationResponse(.failure(.invalidInput("No assets selected for batch operation")))) {
            $0.isProcessing = false
            $0.error = .invalidInput("No assets selected for batch operation")
        }
    }
    
    func testMonitorBatchProgress() async {
        let operationHandle = BatchOperationHandle(operationId: UUID(), type: .compress)
        
        var initialState = MediaManagementFeature.State()
        initialState.selectedAssets = Set([UUID(), UUID()])
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        }
        
        await store.send(.monitorBatchProgress(operationHandle)) { state in
            // Check that batch progress is set with correct basic properties
            XCTAssertNotNil(state.batchProgress)
            XCTAssertEqual(state.batchProgress?.operationId, operationHandle.operationId)
            XCTAssertEqual(state.batchProgress?.totalItems, 2)
            XCTAssertEqual(state.batchProgress?.status, .running)
        }
    }
    
    func testCancelBatchOperation() async {
        var initialState = MediaManagementFeature.State()
        initialState.isProcessing = true
        initialState.currentBatchOperation = BatchOperationHandle(operationId: UUID(), type: .compress)
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        }
        
        await store.send(.cancelBatchOperation) {
            $0.isProcessing = false
        }
        
        await store.receive(.batchOperationCancelled) {
            $0.currentBatchOperation = nil
        }
    }
    
    // MARK: - Workflow Tests
    
    func testExecuteWorkflowSuccess() async {
        let assetId = UUID()
        let asset = MediaAsset(id: assetId, type: .image)
        let workflow = MediaWorkflow(id: UUID(), name: "Test Workflow")
        
        var initialState = MediaManagementFeature.State()
        initialState.assets.append(asset)
        initialState.selectedAssets.insert(assetId)
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        }
        
        await store.send(.executeWorkflow(workflow)) {
            $0.isProcessing = true
            $0.error = nil
        }
        
        await store.receive(\.workflowResponse.success) {
            $0.isProcessing = false
        }
    }
    
    func testExecuteWorkflowNoAssetsSelected() async {
        let workflow = MediaWorkflow(id: UUID(), name: "Test Workflow")
        
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        await store.send(.executeWorkflow(workflow)) {
            $0.isProcessing = true
            $0.error = nil
        }
        
        await store.receive(.workflowResponse(.failure(.invalidInput("No assets selected for workflow execution")))) {
            $0.isProcessing = false
            $0.error = .invalidInput("No assets selected for workflow execution")
        }
    }
    
    func testSaveWorkflowTemplate() async {
        let workflow = MediaWorkflow(id: UUID(), name: "Test Workflow")
        let templateName = "My Template"
        
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        await store.send(.saveWorkflowTemplate(workflow, name: templateName))
        
        await store.receive(\.saveWorkflowTemplateResponse.success) { state in
            // The reducer will append the new template to the state
            state.workflowTemplates.append(WorkflowTemplate(id: UUID(), name: templateName, workflow: workflow))
        }
    }
    
    // MARK: - Filtering and Sorting Tests
    
    func testSetFilter() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        await store.send(.setFilter(.type(.image))) {
            $0.filter = .type(.image)
        }
    }
    
    func testSetSortOrder() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        await store.send(.setSortOrder(.nameAscending)) {
            $0.sortOrder = .nameAscending
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() async {
        var initialState = MediaManagementFeature.State()
        initialState.error = .fileNotFound("Test error")
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        }
        
        await store.send(.clearError) {
            $0.error = nil
        }
    }
    
    func testRetryFailedOperation() async {
        var initialState = MediaManagementFeature.State()
        initialState.error = .cameraAccessFailed("Test error")
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        }
        
        await store.send(.retryFailedOperation) {
            $0.error = nil
        }
        
        // No longer retries - just clears the error
    }
    
    func testRetryFailedOperationNoLastOperation() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        await store.send(.retryFailedOperation)
        // Should do nothing since there's no last failed operation
    }
    
    // MARK: - Session Management Tests
    
    func testStartMediaSession() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        await store.send(.startMediaSession) {
            $0.isSessionActive = true
        }
    }
    
    func testEndMediaSession() async {
        var initialState = MediaManagementFeature.State()
        initialState.isSessionActive = true
        initialState.mediaSession = MediaSession(id: UUID())
        
        let store = TestStore(initialState: initialState) {
            MediaManagementFeature()
        }
        
        await store.send(.endMediaSession) {
            $0.isSessionActive = false
            $0.mediaSession = nil
        }
    }
    
    func testSessionUpdate() async {
        let session = MediaSession(id: UUID())
        
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        await store.send(.sessionUpdate(session)) {
            $0.mediaSession = session
        }
    }
    
    // MARK: - Load Albums Tests
    
    func testLoadAlbumsNotImplemented() async {
        let store = TestStore(initialState: MediaManagementFeature.State()) {
            MediaManagementFeature()
        }
        
        await store.send(.loadAlbums) {
            $0.isLoading = true
        }
        
        await store.receive(.loadAlbumsResponse(.failure(.unsupportedOperation("Not implemented")))) {
            $0.isLoading = false
            $0.error = .unsupportedOperation("Not implemented")
        }
    }
}