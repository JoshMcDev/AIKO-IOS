import AppCore
import Combine
import Foundation
import os.log

/// iOS implementation of batch processing engine
@available(iOS 16.0, *)
public actor BatchProcessingEngine: BatchProcessingEngineProtocol {
    private var operations: [UUID: BatchOperation] = [:]
    private var handles: [UUID: BatchOperationHandle] = [:]
    private var operationStatus: [UUID: BatchOperationStatus] = [:]
    private var operationProgress: [UUID: BatchProgress] = [:]
    private var operationResults: [UUID: [BatchOperationResult]] = [:]
    private var settings = BatchEngineSettings()
    private var activeTasks: [UUID: Task<Void, Never>] = [:]

    private let logger = Logger(subsystem: "com.aiko.batch", category: "BatchProcessingEngine")

    public init() {}

    public func startBatchOperation(_ operation: BatchOperation) async throws -> BatchOperationHandle {
        let handle = BatchOperationHandle(
            operationId: operation.id,
            type: operation.type,
            assetIds: operation.assetIds,
            startTime: Date()
        )

        // Store operation and handle
        operations[operation.id] = operation
        handles[operation.id] = handle
        operationStatus[operation.id] = .running

        // Initialize progress
        operationProgress[operation.id] = BatchProgress(
            operationId: operation.id,
            totalItems: operation.assetIds.count,
            status: .running
        )

        operationResults[operation.id] = []

        // Start processing task
        let task = Task {
            await processOperation(operation)
        }
        activeTasks[operation.id] = task

        logger.info("Started batch operation: \(operation.type.displayName) with \(operation.assetIds.count) items")

        return handle
    }

    public func pauseOperation(_ handle: BatchOperationHandle) async throws {
        guard let operation = operations[handle.operationId] else {
            throw MediaError.operationNotFound("Operation not found")
        }

        // Cancel current task and mark as paused
        activeTasks[handle.operationId]?.cancel()
        activeTasks.removeValue(forKey: handle.operationId)
        operationStatus[handle.operationId] = .paused

        // Update progress
        if var progress = operationProgress[handle.operationId] {
            progress = BatchProgress(
                operationId: progress.operationId,
                totalItems: progress.totalItems,
                completedItems: progress.completedItems,
                failedItems: progress.failedItems,
                currentItem: progress.currentItem,
                estimatedTimeRemaining: progress.estimatedTimeRemaining,
                bytesProcessed: progress.bytesProcessed,
                totalBytes: progress.totalBytes,
                status: .paused,
                message: "Operation paused",
                timestamp: Date()
            )
            operationProgress[handle.operationId] = progress
        }

        logger.info("Paused batch operation: \(operation.type.displayName)")
    }

    public func resumeOperation(_ handle: BatchOperationHandle) async throws {
        guard let operation = operations[handle.operationId] else {
            throw MediaError.operationNotFound("Operation not found")
        }

        guard operationStatus[handle.operationId] == .paused else {
            throw MediaError.invalidOperation("Operation is not paused")
        }

        // Resume processing
        operationStatus[handle.operationId] = .running

        let task = Task {
            await processOperation(operation)
        }
        activeTasks[handle.operationId] = task

        // Update progress
        if var progress = operationProgress[handle.operationId] {
            progress = BatchProgress(
                operationId: progress.operationId,
                totalItems: progress.totalItems,
                completedItems: progress.completedItems,
                failedItems: progress.failedItems,
                currentItem: progress.currentItem,
                estimatedTimeRemaining: progress.estimatedTimeRemaining,
                bytesProcessed: progress.bytesProcessed,
                totalBytes: progress.totalBytes,
                status: .running,
                message: "Operation resumed",
                timestamp: Date()
            )
            operationProgress[handle.operationId] = progress
        }

        logger.info("Resumed batch operation: \(operation.type.displayName)")
    }

    public func cancelOperation(_ handle: BatchOperationHandle) async throws {
        guard let operation = operations[handle.operationId] else {
            throw MediaError.operationNotFound("Operation not found")
        }

        // Cancel task and mark as cancelled
        activeTasks[handle.operationId]?.cancel()
        activeTasks.removeValue(forKey: handle.operationId)
        operationStatus[handle.operationId] = .cancelled

        // Update progress
        if var progress = operationProgress[handle.operationId] {
            progress = BatchProgress(
                operationId: progress.operationId,
                totalItems: progress.totalItems,
                completedItems: progress.completedItems,
                failedItems: progress.failedItems,
                currentItem: progress.currentItem,
                estimatedTimeRemaining: nil,
                bytesProcessed: progress.bytesProcessed,
                totalBytes: progress.totalBytes,
                status: .cancelled,
                message: "Operation cancelled",
                timestamp: Date()
            )
            operationProgress[handle.operationId] = progress
        }

        logger.info("Cancelled batch operation: \(operation.type.displayName)")
    }

    public func getOperationStatus(_ handle: BatchOperationHandle) async -> MediaBatchOperationStatus {
        let activeHandles = Array(handles.values).filter { handle in
            operationStatus[handle.operationId]?.isActive == true
        }

        let completedSummaries: [BatchOperationSummary] = handles.values.compactMap { handle in
            guard let status = operationStatus[handle.operationId],
                  !status.isActive,
                  let progress = operationProgress[handle.operationId]
            else {
                return nil
            }

            return BatchOperationSummary(
                handle: handle,
                finalStatus: status,
                totalItems: progress.totalItems,
                successfulItems: progress.completedItems,
                failedItems: progress.failedItems,
                totalProcessingTime: Date().timeIntervalSince(handle.startTime),
                completedAt: status == .completed ? Date() : nil
            )
        }

        let totalProcessing = activeHandles.reduce(0) { total, handle in
            total + (operationProgress[handle.operationId]?.totalItems ?? 0)
        }

        return MediaBatchOperationStatus(
            activeOperations: activeHandles,
            completedOperations: completedSummaries,
            totalItemsProcessing: totalProcessing
        )
    }

    public func getOperationProgress(_ handle: BatchOperationHandle) async -> BatchProgress {
        return operationProgress[handle.operationId] ?? BatchProgress(
            operationId: handle.operationId,
            totalItems: 0,
            status: .failed,
            message: "Progress not found"
        )
    }

    public func getOperationResults(_ handle: BatchOperationHandle) async -> [BatchOperationResult] {
        return operationResults[handle.operationId] ?? []
    }

    // MARK: - Private Implementation

    private func processOperation(_ operation: BatchOperation) async {
        logger.info("Processing operation: \(operation.type.displayName)")

        for (index, assetId) in operation.assetIds.enumerated() {
            // Check if task was cancelled
            if Task.isCancelled {
                break
            }

            // Check if operation is paused
            if operationStatus[operation.id] == .paused {
                break
            }

            let startTime = Date()

            // Update progress
            updateProgress(for: operation, currentIndex: index, currentAssetId: assetId)

            do {
                // Simulate processing time based on operation type
                let processingTime = getSimulatedProcessingTime(for: operation.type)
                try await Task.sleep(nanoseconds: UInt64(processingTime * 1_000_000_000))

                // Create successful result
                let result = BatchOperationResult(
                    assetId: assetId,
                    operationId: operation.id,
                    status: .completed,
                    result: "Success",
                    processingTime: Date().timeIntervalSince(startTime),
                    completedAt: Date()
                )

                operationResults[operation.id]?.append(result)

            } catch {
                // Create failed result
                let result = BatchOperationResult(
                    assetId: assetId,
                    operationId: operation.id,
                    status: .failed,
                    error: error.localizedDescription,
                    processingTime: Date().timeIntervalSince(startTime),
                    completedAt: Date()
                )

                operationResults[operation.id]?.append(result)
            }
        }

        // Mark operation as completed if not cancelled or paused
        if operationStatus[operation.id] == .running {
            operationStatus[operation.id] = .completed
            updateProgress(for: operation, currentIndex: operation.assetIds.count, currentAssetId: nil)
            logger.info("Completed operation: \(operation.type.displayName)")
        }

        // Clean up task reference
        activeTasks.removeValue(forKey: operation.id)
    }

    private func updateProgress(for operation: BatchOperation, currentIndex: Int, currentAssetId: UUID?) {
        let results = operationResults[operation.id] ?? []
        let completedItems = results.count { $0.status == .completed }
        let failedItems = results.count { $0.status == .failed }

        let status: BatchOperationStatus
        if currentIndex >= operation.assetIds.count {
            status = .completed
        } else {
            status = operationStatus[operation.id] ?? .running
        }

        let progress = BatchProgress(
            operationId: operation.id,
            totalItems: operation.assetIds.count,
            completedItems: completedItems,
            failedItems: failedItems,
            currentItem: currentAssetId?.uuidString,
            estimatedTimeRemaining: estimateTimeRemaining(operation, currentIndex: currentIndex),
            status: status,
            message: status == .completed ? "Operation completed" : "Processing item \(currentIndex + 1) of \(operation.assetIds.count)",
            timestamp: Date()
        )

        operationProgress[operation.id] = progress
    }

    private func estimateTimeRemaining(_ operation: BatchOperation, currentIndex: Int) -> TimeInterval? {
        guard currentIndex > 0 else { return nil }

        let handle = handles[operation.id]
        let elapsedTime = Date().timeIntervalSince(handle?.startTime ?? Date())
        let avgTimePerItem = elapsedTime / Double(currentIndex)
        let remainingItems = operation.assetIds.count - currentIndex

        return avgTimePerItem * Double(remainingItems)
    }

    private func getSimulatedProcessingTime(for type: BatchOperationType) -> TimeInterval {
        switch type {
        case .compress, .resize: 0.5
        case .convert, .enhance: 1.0
        case .validate, .tag: 0.2
        case .backup, .export: 0.8
        case .organize: 0.3
        case .ocr: 2.0
        }
    }

    // MARK: - Additional Protocol Methods

    public func monitorProgress(_ handle: BatchOperationHandle) -> AsyncStream<BatchProgress> {
        AsyncStream { continuation in
            Task {
                while let progress = operationProgress[handle.operationId] {
                    continuation.yield(progress)

                    // Stop monitoring if operation is complete
                    if !progress.status.isActive {
                        break
                    }

                    // Update every 0.5 seconds
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
                continuation.finish()
            }
        }
    }

    public func setOperationPriority(_ handle: BatchOperationHandle, priority: OperationPriority) async throws {
        guard var operation = operations[handle.operationId] else {
            throw MediaError.operationNotFound("Operation not found")
        }

        // Create updated operation with new priority
        operation = BatchOperation(
            id: operation.id,
            type: operation.type,
            assetIds: operation.assetIds,
            parameters: operation.parameters,
            priority: priority,
            settings: operation.settings
        )

        operations[handle.operationId] = operation
        logger.info("Updated priority for operation \(operation.type.displayName) to \(priority.displayName)")
    }

    public func getActiveOperations() async -> [BatchOperationHandle] {
        return Array(handles.values.filter { handle in
            operationStatus[handle.operationId]?.isActive == true
        })
    }

    public func getOperationHistory(limit: Int) async -> [BatchOperationSummary] {
        let completedOperations = handles.values.compactMap { handle -> BatchOperationSummary? in
            guard let status = operationStatus[handle.operationId],
                  !status.isActive,
                  let progress = operationProgress[handle.operationId]
            else {
                return nil
            }

            return BatchOperationSummary(
                handle: handle,
                finalStatus: status,
                totalItems: progress.totalItems,
                successfulItems: progress.completedItems,
                failedItems: progress.failedItems,
                totalProcessingTime: Date().timeIntervalSince(handle.startTime),
                completedAt: status == .completed ? Date() : nil
            )
        }.sorted { $0.completedAt ?? Date.distantPast > $1.completedAt ?? Date.distantPast }

        return Array(completedOperations.prefix(limit))
    }

    public func clearCompletedOperations() async {
        let completedIds = operationStatus.compactMap { id, status in
            status.isActive ? nil : id
        }

        for id in completedIds {
            operations.removeValue(forKey: id)
            handles.removeValue(forKey: id)
            operationStatus.removeValue(forKey: id)
            operationProgress.removeValue(forKey: id)
            operationResults.removeValue(forKey: id)
        }

        logger.info("Cleared \(completedIds.count) completed operations")
    }

    public func configureEngine(_ settings: BatchEngineSettings) async {
        self.settings = settings
        logger.info("Updated batch engine settings: max concurrent = \(settings.maxConcurrentOperations)")
    }
}
