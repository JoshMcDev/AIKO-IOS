import Foundation

/// Mock ObjectBox semantic index for regulation embeddings
/// Provides vector storage and retrieval without ObjectBox dependency
public actor ObjectBoxSemanticIndex {
    // MARK: - Properties

    private var embeddings: [RegulationEmbedding] = []
    private var storagePerformanceMetrics: [String: TimeInterval] = [:]

    // MARK: - Initialization

    public init() {}

    // MARK: - Storage Operations

    /// Stores regulation embedding in vector database
    public func store(embedding: RegulationEmbedding) async throws {
        let startTime = Date()

        // Simulate storage operation
        embeddings.append(embedding)

        // Simulate indexing time
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        let storageTime = Date().timeIntervalSince(startTime)
        storagePerformanceMetrics["store"] = storageTime

        // Simulate potential storage errors for testing
        if embeddings.count > 10000 {
            throw RegulationFetchingError.serviceNotConfigured
        }
    }

    /// Retrieves all stored embeddings
    public func getAllEmbeddings() async throws -> [RegulationEmbedding] {
        let startTime = Date()

        // Simulate retrieval operation
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        let retrievalTime = Date().timeIntervalSince(startTime)
        storagePerformanceMetrics["retrieve"] = retrievalTime

        return embeddings
    }

    /// Performs similarity search on stored embeddings
    public func similaritySearch(query: [Float], limit: Int = 10) async throws -> [RegulationEmbedding] {
        let startTime = Date()

        // Simulate similarity computation
        var results: [(embedding: RegulationEmbedding, similarity: Float)] = []

        for embedding in embeddings.prefix(limit * 2) { // Search more to filter top results
            let similarity = computeCosineSimilarity(query, embedding.embedding)
            results.append((embedding: embedding, similarity: similarity))
        }

        // Sort by similarity and take top results
        let topResults = results
            .sorted { $0.similarity > $1.similarity }
            .prefix(limit)
            .map(\.embedding)

        let searchTime = Date().timeIntervalSince(startTime)
        storagePerformanceMetrics["search"] = searchTime

        return Array(topResults)
    }

    /// Clears all stored embeddings
    public func clearAll() async {
        embeddings.removeAll()
        storagePerformanceMetrics.removeAll()
    }

    // MARK: - Bulk Operations

    /// Stores multiple embeddings efficiently
    public func storeBulk(_ embeddings: [RegulationEmbedding]) async throws {
        let startTime = Date()

        // Simulate bulk storage with batching
        let batchSize = 100
        let batches = embeddings.chunked(into: batchSize)

        for batch in batches {
            // Simulate batch processing
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms per batch

            for embedding in batch {
                self.embeddings.append(embedding)
            }
        }

        let bulkStorageTime = Date().timeIntervalSince(startTime)
        storagePerformanceMetrics["bulk_store"] = bulkStorageTime
    }

    // MARK: - Performance Metrics

    /// Gets performance metrics for operations
    public func getPerformanceMetrics() async -> [String: TimeInterval] {
        storagePerformanceMetrics
    }

    /// Gets storage statistics
    public func getStorageStats() async -> StorageStats {
        StorageStats(
            totalEmbeddings: embeddings.count,
            averageEmbeddingSize: embeddings.isEmpty ? 0 : embeddings.first?.embedding.count ?? 0,
            totalStorageSize: Int64(embeddings.count * 768 * 4) // 768 dimensions * 4 bytes per float
        )
    }

    // MARK: - Private Helper Methods

    /// Computes cosine similarity between two vectors
    private func computeCosineSimilarity(_ vector1: [Float], _ vector2: [Float]) -> Float {
        guard vector1.count == vector2.count, !vector1.isEmpty else { return 0.0 }

        let dotProduct = zip(vector1, vector2).reduce(0.0) { $0 + ($1.0 * $1.1) }
        let magnitude1 = sqrt(vector1.reduce(0.0) { $0 + ($1 * $1) })
        let magnitude2 = sqrt(vector2.reduce(0.0) { $0 + ($1 * $1) })

        guard magnitude1 > 0, magnitude2 > 0 else { return 0.0 }

        return dotProduct / (magnitude1 * magnitude2)
    }
}

// MARK: - Supporting Types

/// Storage statistics for ObjectBox semantic index
public struct StorageStats: Sendable {
    public let totalEmbeddings: Int
    public let averageEmbeddingSize: Int
    public let totalStorageSize: Int64

    public init(totalEmbeddings: Int, averageEmbeddingSize: Int, totalStorageSize: Int64) {
        self.totalEmbeddings = totalEmbeddings
        self.averageEmbeddingSize = averageEmbeddingSize
        self.totalStorageSize = totalStorageSize
    }
}

// Array extension exists in LFM2Service.swift
