@testable import AppCore
import XCTest

@available(iOS 16.0, *)
final class BatchProcessingEngineTests: XCTestCase {
    private var batchEngine: BatchProcessingEngine?

    override func setUp() async throws {
        batchEngine = BatchProcessingEngine()
    }

    override func tearDown() async throws {
        if let engine = batchEngine {
            await engine.clearCompletedOperations()
        }
        batchEngine = nil
    }

    // MARK: - Basic Operation Tests

    func testStartBatchOperation() async throws {
        // Given
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let assetIds = [UUID(), UUID(), UUID()]
        let operation = BatchOperation(
            type: .compress,
            assetIds: assetIds,
            priority: .normal
        )

        // When
        let handle = try await engine.startBatchOperation(operation)

        // Then
        XCTAssertEqual(handle.operationId, operation.id)
        XCTAssertEqual(handle.type, .compress)
        XCTAssertEqual(handle.assetIds, assetIds)
        XCTAssertTrue(handle.startTime <= Date())

        // Verify operation status
        let status = await engine.getOperationStatus(handle)
        XCTAssertEqual(status.activeOperations.count, 1)
        XCTAssertEqual(status.totalItemsProcessing, 3)
    }

    func testOperationProgress() async throws {
        // Given
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let assetIds = [UUID(), UUID()]
        let operation = BatchOperation(type: .validate, assetIds: assetIds)
        let handle = try await engine.startBatchOperation(operation)

        // When
        let progress = await engine.getOperationProgress(handle)

        // Then
        XCTAssertEqual(progress.operationId, operation.id)
        XCTAssertEqual(progress.totalItems, 2)
        XCTAssertTrue(progress.status == .running || progress.status == .completed)
    }

    func testPauseOperation() async throws {
        // Given
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let operation = BatchOperation(type: .ocr, assetIds: [UUID(), UUID(), UUID()])
        let handle = try await engine.startBatchOperation(operation)

        // When
        try await engine.pauseOperation(handle)

        // Then
        let progress = await engine.getOperationProgress(handle)
        XCTAssertEqual(progress.status, .paused)
        XCTAssertEqual(progress.message, "Operation paused")
    }

    func testResumeOperation() async throws {
        // Given - Use OCR operation with multiple assets (2 seconds each, so longer total time)
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let operation = BatchOperation(type: .ocr, assetIds: [UUID(), UUID()])
        let handle = try await engine.startBatchOperation(operation)

        // Pause immediately to prevent completion
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        try await engine.pauseOperation(handle)
        let pausedProgress = await engine.getOperationProgress(handle)
        XCTAssertEqual(pausedProgress.status, .paused)

        // When
        try await engine.resumeOperation(handle)

        // Then - Check that resume worked (status is either running or completed)
        let resumedProgress = await engine.getOperationProgress(handle)
        XCTAssertTrue([.running, .completed].contains(resumedProgress.status), "Operation should be running or completed after resume")
        // The message may be "Operation resumed" or "Processing item X" or "Operation completed"
        XCTAssertNotEqual(resumedProgress.message, "Operation paused")
    }

    func testCancelOperation() async throws {
        // Given
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let operation = BatchOperation(type: .backup, assetIds: [UUID(), UUID()])
        let handle = try await engine.startBatchOperation(operation)

        // When
        try await engine.cancelOperation(handle)

        // Then
        let progress = await engine.getOperationProgress(handle)
        XCTAssertEqual(progress.status, .cancelled)
        XCTAssertEqual(progress.message, "Operation cancelled")
        XCTAssertNil(progress.estimatedTimeRemaining)
    }

    // MARK: - Results and Status Tests

    func testOperationResults() async throws {
        // Given
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let assetIds = [UUID(), UUID()]
        let operation = BatchOperation(type: .validate, assetIds: assetIds)
        let handle = try await engine.startBatchOperation(operation)

        // Wait for completion (validate operations are fast - 0.2s each)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // When
        let results = await engine.getOperationResults(handle)

        // Then
        XCTAssertEqual(results.count, 2)

        for result in results {
            XCTAssertEqual(result.operationId, operation.id)
            XCTAssertTrue(assetIds.contains(result.assetId))
            XCTAssertTrue([.completed, .failed].contains(result.status))
            XCTAssertNotNil(result.completedAt)
            XCTAssertTrue(result.processingTime >= 0)
        }
    }

    func testGetActiveOperations() async throws {
        // Given
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let operation1 = BatchOperation(type: .compress, assetIds: [UUID()])
        let operation2 = BatchOperation(type: .resize, assetIds: [UUID()])

        // When
        let handle1 = try await engine.startBatchOperation(operation1)
        let handle2 = try await engine.startBatchOperation(operation2)

        let activeOperations = await engine.getActiveOperations()

        // Then
        XCTAssertEqual(activeOperations.count, 2)
        XCTAssertTrue(activeOperations.contains { $0.operationId == handle1.operationId })
        XCTAssertTrue(activeOperations.contains { $0.operationId == handle2.operationId })
    }

    // MARK: - Priority and Configuration Tests

    func testSetOperationPriority() async throws {
        // Given
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let operation = BatchOperation(type: .convert, assetIds: [UUID()], priority: .normal)
        let handle = try await engine.startBatchOperation(operation)

        // When
        try await engine.setOperationPriority(handle, priority: .high)

        // Then - This test verifies the method doesn't throw, priority change is internal
        // In a real implementation, we could verify priority affects processing order
    }

    func testConfigureEngine() async throws {
        // Given
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let settings = BatchEngineSettings(
            maxConcurrentOperations: 5,
            maxMemoryUsage: 200 * 1024 * 1024,
            defaultTimeout: 600,
            retryAttempts: 3,
            enableProgressCallbacks: true
        )

        // When
        await engine.configureEngine(settings)

        // Then - Configuration is applied (internal state)
        // This test verifies the method works without throwing
    }

    // MARK: - History and Cleanup Tests

    func testOperationHistory() async throws {
        // Given
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let operation = BatchOperation(type: .tag, assetIds: [UUID()])
        let handle = try await engine.startBatchOperation(operation)

        // Wait for completion
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // When
        let history = await engine.getOperationHistory(limit: 10)

        // Then
        XCTAssertGreaterThanOrEqual(history.count, 1)

        if let summary = history.first(where: { $0.handle.operationId == handle.operationId }) {
            XCTAssertEqual(summary.handle.type, .tag)
            XCTAssertEqual(summary.totalItems, 1)
            XCTAssertTrue([.completed, .failed, .cancelled].contains(summary.finalStatus))
        }
    }

    func testClearCompletedOperations() async throws {
        // Given
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let operation = BatchOperation(type: .validate, assetIds: [UUID()])
        let handle = try await engine.startBatchOperation(operation)

        // Wait for completion
        try await Task.sleep(nanoseconds: 500_000_000)

        // Verify operation exists in history
        let historyBefore = await engine.getOperationHistory(limit: 10)
        XCTAssertTrue(historyBefore.contains { $0.handle.operationId == handle.operationId })

        // When
        await engine.clearCompletedOperations()

        // Then
        let historyAfter = await engine.getOperationHistory(limit: 10)
        XCTAssertFalse(historyAfter.contains { $0.handle.operationId == handle.operationId })
    }

    // MARK: - Progress Monitoring Tests

    func testMonitorProgress() async throws {
        // Given
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let operation = BatchOperation(type: .enhance, assetIds: [UUID(), UUID()])
        let handle = try await engine.startBatchOperation(operation)

        var progressUpdates: [BatchProgress] = []
        let expectation = XCTestExpectation(description: "Progress monitoring")

        // When
        let monitorTask = Task {
            for await progress in await engine.monitorProgress(handle) {
                progressUpdates.append(progress)

                if !progress.status.isActive {
                    expectation.fulfill()
                    break
                }
            }
        }

        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        monitorTask.cancel()

        XCTAssertGreaterThan(progressUpdates.count, 0)
        XCTAssertEqual(progressUpdates.first?.operationId, operation.id)
        XCTAssertEqual(progressUpdates.first?.totalItems, 2)
    }

    // MARK: - Error Handling Tests

    func testResumeNonPausedOperation() async throws {
        // Given
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let operation = BatchOperation(type: .compress, assetIds: [UUID()])
        let handle = try await engine.startBatchOperation(operation)

        // When/Then
        do {
            try await engine.resumeOperation(handle)
            XCTFail("Should throw error when resuming non-paused operation")
        } catch let error as MediaError {
            if case let .invalidOperation(message) = error {
                XCTAssertEqual(message, "Operation is not paused")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testOperationNotFound() async throws {
        // Given
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let fakeHandle = BatchOperationHandle(
            operationId: UUID(),
            type: .compress,
            assetIds: []
        )

        // When/Then
        do {
            try await engine.pauseOperation(fakeHandle)
            XCTFail("Should throw error for non-existent operation")
        } catch let error as MediaError {
            if case let .operationNotFound(message) = error {
                XCTAssertEqual(message, "Operation not found")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Performance Tests

    func testMultipleOperationsPerformance() async throws {
        // Given
        guard let engine = batchEngine else {
            XCTFail("BatchEngine not initialized")
            return
        }

        let operationCount = 5
        var handles: [BatchOperationHandle] = []

        // When
        let startTime = Date()

        for i in 0 ..< operationCount {
            let operation = BatchOperation(
                type: .validate, // Fast operation type
                assetIds: [UUID()],
                priority: i < 2 ? .high : .normal
            )
            let handle = try await engine.startBatchOperation(operation)
            handles.append(handle)
        }

        // Wait for all to complete
        var allCompleted = false
        while !allCompleted {
            let activeOps = await engine.getActiveOperations()
            allCompleted = activeOps.isEmpty

            if !allCompleted {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }

        let endTime = Date()

        // Then
        let totalTime = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(totalTime, 5.0, "Multiple operations should complete within reasonable time")

        // Verify all operations completed
        for handle in handles {
            let progress = await engine.getOperationProgress(handle)
            XCTAssertTrue([.completed, .failed].contains(progress.status))
        }
    }
}
