import Foundation
import os.log

/// Extensions to LFM2Service for template processing with 384-dimensional embeddings
extension LFM2Service {
    /// Generate 384-dimensional embedding for template content
    /// Optimized for template search and semantic similarity
    func generateTemplateEmbedding(text: String) async throws -> [Float] {
        let logger = Logger(subsystem: "com.aiko.graphrag", category: "LFM2Service+Templates")

        guard !text.isEmpty else {
            throw NSError(domain: "LFM2ServiceError", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Empty text provided"])
        }

        logger.debug("Generating 384-dimensional template embedding for text length: \(text.count)")

        // Use the existing generateEmbedding method but ensure 384 dimensions
        let embedding = try await generateEmbedding(text: text)

        // Convert to 384 dimensions if needed
        if embedding.count != 384 {
            return resizeEmbedding(embedding, targetSize: 384)
        }

        return embedding
    }

    /// Generate embeddings optimized for SIMD operations
    /// Returns normalized vectors for efficient cosine similarity computation
    func generateSIMDOptimizedEmbedding(text: String) async throws -> [Float] {
        let embedding = try await generateTemplateEmbedding(text: text)
        return normalizeVector(embedding)
    }

    /// Batch embedding generation for multiple templates
    /// Optimized for throughput while maintaining memory constraints
    func generateBatchTemplateEmbeddings(texts: [String]) async throws -> [[Float]] {
        let logger = Logger(subsystem: "com.aiko.graphrag", category: "LFM2Service+Templates")

        logger.debug("Generating batch embeddings for \(texts.count) templates")

        var embeddings: [[Float]] = []
        let batchSize = 10 // Process 10 at a time to manage memory

        for batchStart in stride(from: 0, to: texts.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, texts.count)
            let batch = Array(texts[batchStart ..< batchEnd])

            // Process batch concurrently
            let batchEmbeddings = try await withThrowingTaskGroup(of: (Int, [Float]).self) { group in
                for (index, text) in batch.enumerated() {
                    group.addTask {
                        let embedding = try await self.generateTemplateEmbedding(text: text)
                        return (index, embedding)
                    }
                }

                var results: [(Int, [Float])] = []
                for try await result in group {
                    results.append(result)
                }

                // Sort by index to maintain order
                results.sort { $0.0 < $1.0 }
                return results.map(\.1)
            }

            embeddings.append(contentsOf: batchEmbeddings)

            // Small delay between batches to prevent memory pressure
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        logger.debug("Batch embedding generation completed: \(embeddings.count) embeddings")
        return embeddings
    }

    // MARK: - Embedding Processing Utilities

    private func resizeEmbedding(_ embedding: [Float], targetSize: Int) -> [Float] {
        let currentSize = embedding.count

        if currentSize == targetSize {
            return embedding
        } else if currentSize > targetSize {
            // Truncate to target size
            return Array(embedding.prefix(targetSize))
        } else {
            // Pad with zeros to reach target size
            var resized = embedding
            resized.append(contentsOf: Array(repeating: 0.0, count: targetSize - currentSize))
            return resized
        }
    }

    private func normalizeVector(_ vector: [Float]) -> [Float] {
        let magnitude = sqrt(vector.map { $0 * $0 }.reduce(0, +))

        guard magnitude > 0 else {
            return Array(repeating: 0.0, count: vector.count)
        }

        return vector.map { $0 / magnitude }
    }

    /// Calculate cosine similarity between two embeddings using SIMD
    func computeCosineSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float {
        guard embedding1.count == embedding2.count, !embedding1.isEmpty else {
            return 0.0
        }

        let count = embedding1.count
        var dotProduct: Float = 0

        // Use vectorized operations for better performance
        for i in 0 ..< count {
            dotProduct += embedding1[i] * embedding2[i]
        }

        return dotProduct // Assuming normalized vectors
    }

    /// Memory-efficient embedding storage format
    func serializeEmbedding(_ embedding: [Float]) -> Data {
        embedding.withUnsafeBytes { Data($0) }
    }

    /// Deserialize embedding from storage format
    func deserializeEmbedding(_ data: Data) -> [Float] {
        data.withUnsafeBytes { bytes in
            let floatBuffer = bytes.bindMemory(to: Float.self)
            return Array(floatBuffer)
        }
    }

    // MARK: - Performance Monitoring for Templates

    /// Generate embedding with performance tracking
    func generateEmbeddingWithMetrics(text: String) async throws -> (embedding: [Float], metrics: EmbeddingMetrics) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()

        let embedding = try await generateTemplateEmbedding(text: text)

        let endTime = CFAbsoluteTimeGetCurrent()
        let endMemory = getCurrentMemoryUsage()

        let metrics = EmbeddingMetrics(
            generationTimeMs: (endTime - startTime) * 1000,
            memoryUsedBytes: endMemory - startMemory,
            inputTextLength: text.count,
            outputDimensions: embedding.count
        )

        return (embedding, metrics)
    }

    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

// MARK: - Supporting Types

struct EmbeddingMetrics {
    let generationTimeMs: Double
    let memoryUsedBytes: Int64
    let inputTextLength: Int
    let outputDimensions: Int

    var isWithinPerformanceTarget: Bool {
        generationTimeMs < 2000 // 2 second target
    }

    var memoryEfficiencyRatio: Double {
        Double(outputDimensions * 4) / Double(memoryUsedBytes) // bytes per float dimension
    }
}
