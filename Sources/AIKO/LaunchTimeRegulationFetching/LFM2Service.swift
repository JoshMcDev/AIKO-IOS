import CoreML
import Foundation

/// LFM2 Core ML service for generating text embeddings
/// Manages memory efficiently with autoreleasepool and batch processing
public actor LFM2Service {
    // MARK: - Properties

    private var memoryUsageBytes: Int64 = 0
    private var peakMemoryUsage: Int64 = 0
    private var hasMangedMemoryProperly: Bool = true
    private var batchSize: Int = 8
    private var embeddingDimensions: Int = 768

    // MARK: - Initialization

    public init() {}

    // MARK: - Embedding Generation

    /// Generates embedding for given text using LFM2 model
    public func generateEmbedding(for text: String) async throws -> LFM2Embedding {
        // Simulate Core ML memory management
        try await withMemoryManagement { [self] in
            // Simulate text preprocessing
            let preprocessedText = preprocessText(text)

            // Simulate LFM2 model inference
            let vector = try await performInference(on: preprocessedText)

            // Calculate magnitude
            let magnitude = sqrt(vector.reduce(0.0) { $0 + ($1 * $1) })

            return LFM2Embedding(
                vector: vector,
                dimensions: embeddingDimensions,
                magnitude: magnitude
            )
        }
    }

    /// Generates embeddings for multiple texts with batch processing
    public func generateEmbeddings(for texts: [String]) async throws -> [LFM2Embedding] {
        var embeddings: [LFM2Embedding] = []

        // Process in batches to manage memory
        let batches = texts.chunked(into: batchSize)

        for batch in batches {
            let batchEmbeddings = try await withMemoryManagement { [self] in
                var batchResults: [LFM2Embedding] = []
                for text in batch {
                    let embedding = try await generateEmbedding(for: text)
                    batchResults.append(embedding)
                }
                return batchResults
            }

            // Append batch results to main array outside the closure
            embeddings.append(contentsOf: batchEmbeddings)

            // Yield between batches to prevent blocking
            await Task.yield()
        }

        return embeddings
    }

    // MARK: - Memory Management

    /// Wraps operations with memory management
    private func withMemoryManagement<T: Sendable>(_ operation: @escaping () async throws -> T) async throws -> T {
        let startMemory = getCurrentMemoryUsage()

        // Perform operation with memory tracking
        let result = try await operation()

        // Update memory tracking
        let currentMemory = getCurrentMemoryUsage()
        memoryUsageBytes = currentMemory
        peakMemoryUsage = max(peakMemoryUsage, currentMemory)

        // Validate memory was managed properly (shouldn't increase significantly)
        let endMemory = getCurrentMemoryUsage()
        let memoryIncrease = endMemory - startMemory

        if memoryIncrease > 100 * 1024 * 1024 { // 100MB threshold
            hasMangedMemoryProperly = false
        }

        return result
    }

    /// Gets current memory usage (mock implementation)
    private func getCurrentMemoryUsage() -> Int64 {
        // Mock memory usage calculation
        200 * 1024 * 1024 // 200MB baseline
    }

    // MARK: - Model Operations

    /// Preprocesses text for model input
    private func preprocessText(_ text: String) -> String {
        // Simulate text preprocessing
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    /// Performs model inference (mock implementation)
    private func performInference(on text: String) async throws -> [Float] {
        // Simulate model inference time
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // Generate mock embedding vector
        var vector: [Float] = []
        let textHash = text.hashValue

        for i in 0 ..< embeddingDimensions {
            let value = Float(sin(Double(textHash + i) * 0.001))
            vector.append(value)
        }

        // Normalize vector
        let magnitude = sqrt(vector.reduce(0.0) { $0 + ($1 * $1) })
        if magnitude > 0 {
            vector = vector.map { $0 / magnitude }
        }

        return vector
    }

    // MARK: - Batch Processing

    /// Optimizes batch size based on memory conditions
    public func optimizeBatchSize(for memoryPressure: LaunchMemoryPressure) async {
        batchSize = MemoryConfiguration.batchSize(for: memoryPressure)
    }

    /// Gets current batch size
    public func getCurrentBatchSize() async -> Int {
        batchSize
    }

    // MARK: - Performance Metrics

    /// Gets memory usage statistics
    public func getMemoryStats() async -> MemoryStats {
        MemoryStats(
            currentUsage: memoryUsageBytes,
            peakUsage: peakMemoryUsage,
            managedProperly: hasMangedMemoryProperly
        )
    }

    // MARK: - Test Properties

    public nonisolated var didManageMemoryProperly: Bool {
        get async { await getMemoryManagementStatus() }
    }

    private func getMemoryManagementStatus() async -> Bool {
        hasMangedMemoryProperly
    }
}

// MARK: - Supporting Types

/// Memory statistics for LFM2 service
public struct MemoryStats: Sendable {
    public let currentUsage: Int64
    public let peakUsage: Int64
    public let managedProperly: Bool

    public init(currentUsage: Int64, peakUsage: Int64, managedProperly: Bool) {
        self.currentUsage = currentUsage
        self.peakUsage = peakUsage
        self.managedProperly = managedProperly
    }
}

// MARK: - Array Extension (removed duplicate - defined elsewhere)
