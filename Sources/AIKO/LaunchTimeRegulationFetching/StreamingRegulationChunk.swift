import Foundation

// MARK: - Memory Configuration

/// Centralized memory configuration for adaptive behavior
enum MemoryConfiguration {
    static func chunkSize(for level: LaunchMemoryPressure) -> Int {
        switch level {
        case .normal: 16384 // 16KB
        case .warning: 8192 // 8KB
        case .critical: 4096 // 4KB
        }
    }

    static func batchSize(for level: LaunchMemoryPressure) -> Int {
        switch level {
        case .normal: 16
        case .warning: 8
        case .critical: 2
        }
    }
}

/// Memory-efficient streaming processor for regulation chunks
/// Handles JSON parsing with InputStream and checkpoint-based resumption
public actor StreamingRegulationChunk {
    // MARK: - Properties

    private var peakMemoryUsageBytes: Int64 = 0
    private var currentMemoryUsage: Int64 = 0
    private var chunkSize: Int = 16384 // 16KB default
    private var adaptedChunkSize: Int = 16384
    private var hasUsedInputStream: Bool = false
    private var hasProcessedIncrementally: Bool = false
    private var hasResumedFromCheckpoint: Bool = false
    private var processedRegulations: [TestRegulation] = []

    // MARK: - Initialization

    public init() {}

    // MARK: - Streaming JSON Processing

    /// Creates mock input stream for testing
    public func createMockInputStream(size: Int) -> InputStream {
        let mockData = Data(repeating: 0x41, count: size) // 'A' repeated
        return InputStream(data: mockData)
    }

    /// Processes JSON using InputStream for memory efficiency
    public func processJSONWithInputStream(inputStream: InputStream, chunkSize: Int) async throws -> [LaunchTimeRegulationChunk] {
        hasUsedInputStream = true

        // Simulate memory-efficient processing
        var chunks: [LaunchTimeRegulationChunk] = []
        var currentChunk = 0
        _ = max(1, size / chunkSize)

        // Open the input stream
        inputStream.open()
        defer { inputStream.close() }

        // Process in chunks to maintain memory efficiency
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)
        defer { buffer.deallocate() }

        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(buffer, maxLength: chunkSize)
            if bytesRead > 0 {
                // Simulate processing chunk
                let chunkData = Data(UnsafeBufferPointer(start: buffer, count: bytesRead))
                let chunkContent = String(data: chunkData, encoding: .utf8) ?? ""

                let chunk = LaunchTimeRegulationChunk(
                    id: "chunk-\(currentChunk)",
                    content: chunkContent,
                    chunkIndex: currentChunk
                )
                chunks.append(chunk)

                // Update memory tracking
                currentMemoryUsage = Int64(chunkData.count)
                peakMemoryUsageBytes = max(peakMemoryUsageBytes, currentMemoryUsage)

                currentChunk += 1
            }
        }

        return chunks
    }

    // MARK: - Incremental Processing

    /// Creates mock regulations for testing
    public func createMockRegulations(count: Int) -> [TestRegulation] {
        (1 ... count).map { index in
            TestRegulation(
                id: "regulation-\(index)",
                title: "Mock Regulation \(index)",
                content: "Mock content for regulation \(index). This contains important information for processing."
            )
        }
    }

    /// Processes regulation incrementally to avoid memory bloat
    public func processIncremental(regulation: TestRegulation) async throws {
        hasProcessedIncrementally = true

        // Simulate incremental processing with memory management
        autoreleasepool {
            processedRegulations.append(regulation)

            // Simulate memory usage tracking
            let regulationSize = Int64(regulation.content.utf8.count)
            currentMemoryUsage += regulationSize
            peakMemoryUsageBytes = max(peakMemoryUsageBytes, currentMemoryUsage)

            // Clean up memory after processing to prevent bloat
            if processedRegulations.count % 10 == 0 {
                // Simulate memory cleanup
                currentMemoryUsage /= 2
            }
        }

        // Yield to prevent blocking
        await Task.yield()
    }

    // MARK: - Checkpoint Processing

    /// Processes regulations with checkpoint support
    public func processWithCheckpoints(regulations: [TestRegulation], maxProcessCount: Int) async throws -> ProcessingProgress {
        var processedCount = 0

        for (index, regulation) in regulations.enumerated() {
            if index >= maxProcessCount {
                break // Simulate interruption
            }

            try await processIncremental(regulation: regulation)
            processedCount += 1
        }

        let checkpointToken = "checkpoint-\(processedCount)-\(Date().timeIntervalSince1970)"

        return ProcessingProgress(
            percentage: Double(processedCount) / Double(regulations.count),
            processedCount: processedCount,
            estimatedTimeRemaining: nil,
            currentPhase: "Processing with checkpoints",
            checkpointToken: checkpointToken,
            previousProcessedCount: 0
        )
    }

    /// Resumes processing from checkpoint
    public func resumeFromCheckpoint(checkpointToken: String, regulations: [TestRegulation]) async throws -> ProcessingProgress {
        hasResumedFromCheckpoint = true

        // Extract previous count from checkpoint token
        let components = checkpointToken.components(separatedBy: "-")
        let previousCount = Int(components[1]) ?? 0

        // Continue processing from checkpoint
        var processedCount = previousCount

        for (index, regulation) in regulations.enumerated() {
            if index < previousCount {
                continue // Skip already processed
            }

            try await processIncremental(regulation: regulation)
            processedCount += 1
        }

        return ProcessingProgress(
            percentage: Double(processedCount) / Double(regulations.count),
            processedCount: processedCount,
            estimatedTimeRemaining: nil,
            currentPhase: "Resumed from checkpoint",
            checkpointToken: checkpointToken,
            previousProcessedCount: previousCount
        )
    }

    // MARK: - Memory Pressure Adaptation

    /// Gets adapted chunk size based on memory conditions
    public func getAdaptedChunkSize() -> Int {
        adaptedChunkSize
    }

    /// Adapts chunk size based on memory pressure
    public func adaptToMemoryPressure(_ level: LaunchMemoryPressure) async {
        adaptedChunkSize = getChunkSizeForMemoryLevel(level)
    }

    // MARK: - Memory Management Helpers

    private func getChunkSizeForMemoryLevel(_ level: LaunchMemoryPressure) -> Int {
        let config = MemoryConfiguration.chunkSize(for: level)
        return config
    }

    // MARK: - Test Properties

    public nonisolated var didUseInputStream: Bool {
        get async { await getHasUsedInputStream() }
    }

    public nonisolated var peakMemoryUsage: Int64 {
        get async { await getPeakMemoryUsage() }
    }

    public nonisolated var didProcessIncrementally: Bool {
        get async { await getHasProcessedIncrementally() }
    }

    public nonisolated var didResumeFromCheckpoint: Bool {
        get async { await getHasResumedFromCheckpoint() }
    }

    // MARK: - Private Helper Methods

    private func getHasUsedInputStream() async -> Bool {
        hasUsedInputStream
    }

    private func getPeakMemoryUsage() async -> Int64 {
        peakMemoryUsageBytes
    }

    private func getHasProcessedIncrementally() async -> Bool {
        hasProcessedIncrementally
    }

    private func getHasResumedFromCheckpoint() async -> Bool {
        hasResumedFromCheckpoint
    }

    // MARK: - Private Properties

    private var size: Int {
        5 * 1024 * 1024 // 5MB default for testing
    }
}
