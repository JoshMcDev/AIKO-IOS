import Foundation

/// Actor-based semantic index using in-memory storage for dual-namespace GraphRAG
/// Provides thread-safe access to regulation and user workflow embeddings
/// Note: ObjectBox integration planned for future versions
@globalActor
actor ObjectBoxSemanticIndex {
    static let shared = ObjectBoxSemanticIndex()

    // In-memory storage for GREEN phase implementation
    private var regulationStore: [String: StoredRegulation] = [:]
    private var userWorkflowStore: [String: StoredUserWorkflow] = [:]
    private var isInitialized = false

    private init() {
        isInitialized = true
    }

    // MARK: - Regulation Storage

    func storeRegulationEmbedding(
        content: String,
        embedding: [Float],
        metadata: RegulationMetadata
    ) async throws {
        let id = UUID().uuidString
        let stored = StoredRegulation(
            id: id,
            content: content,
            embedding: embedding,
            metadata: metadata,
            timestamp: Date()
        )
        regulationStore[id] = stored
    }

    func findSimilarRegulations(
        queryEmbedding: [Float],
        limit: Int,
        threshold: Float = 0.7
    ) async throws -> [RegulationSearchResult] {
        var similarities: [(StoredRegulation, Float)] = []
        var maxSimilarity: Float = 0.0

        for regulation in regulationStore.values {
            let similarity = cosineSimilarity(queryEmbedding, regulation.embedding)
            maxSimilarity = max(maxSimilarity, similarity)
            if similarity >= threshold {
                similarities.append((regulation, similarity))
            }
        }

        // Sort by similarity descending and limit results
        similarities.sort { $0.1 > $1.1 }
        let topResults = similarities.prefix(limit)

        return topResults.map { regulation, _ in
            RegulationSearchResult(
                content: regulation.content,
                domain: .regulations,
                regulationNumber: regulation.metadata.regulationNumber,
                embedding: regulation.embedding
            )
        }
    }

    // MARK: - User Workflow Storage

    func storeUserWorkflowEmbedding(
        content: String,
        embedding: [Float],
        metadata: UserWorkflowMetadata
    ) async throws {
        let id = UUID().uuidString
        let stored = StoredUserWorkflow(
            id: id,
            content: content,
            embedding: embedding,
            metadata: metadata,
            timestamp: Date()
        )
        userWorkflowStore[id] = stored
    }

    func findSimilarUserWorkflow(
        queryEmbedding: [Float],
        limit: Int,
        threshold: Float = 0.7
    ) async throws -> [RegulationSearchResult] {
        var similarities: [(StoredUserWorkflow, Float)] = []
        var maxSimilarity: Float = 0.0

        for workflow in userWorkflowStore.values {
            let similarity = cosineSimilarity(queryEmbedding, workflow.embedding)
            maxSimilarity = max(maxSimilarity, similarity)
            if similarity >= threshold {
                similarities.append((workflow, similarity))
            }
        }

        // Sort by similarity descending and limit results
        similarities.sort { $0.1 > $1.1 }
        let topResults = similarities.prefix(limit)

        return topResults.map { workflow, _ in
            RegulationSearchResult(
                content: workflow.content,
                domain: .userHistory,
                regulationNumber: workflow.metadata.documentType,
                embedding: workflow.embedding
            )
        }
    }

    // MARK: - Storage Performance

    func getStorageStats() async -> StorageStats {
        return StorageStats(
            regulationCount: regulationStore.count,
            userWorkflowCount: userWorkflowStore.count,
            totalSize: calculateTotalSize()
        )
    }

    func clearAllData() async throws {
        regulationStore.removeAll()
        userWorkflowStore.removeAll()
    }

    // MARK: - Helper Methods

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0.0 }

        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        guard magnitudeA > 0 && magnitudeB > 0 else { return 0.0 }

        return dotProduct / (magnitudeA * magnitudeB)
    }

    private func calculateTotalSize() -> Int {
        let regulationSize = regulationStore.values.reduce(0) { total, reg in
            total + reg.content.count + (reg.embedding.count * 4) // 4 bytes per Float
        }
        let workflowSize = userWorkflowStore.values.reduce(0) { total, workflow in
            total + workflow.content.count + (workflow.embedding.count * 4) // 4 bytes per Float
        }
        return regulationSize + workflowSize
    }
}

// MARK: - Supporting Types

struct StoredRegulation {
    let id: String
    let content: String
    let embedding: [Float]
    let metadata: RegulationMetadata
    let timestamp: Date
}

struct StoredUserWorkflow {
    let id: String
    let content: String
    let embedding: [Float]
    let metadata: UserWorkflowMetadata
    let timestamp: Date
}

struct StorageStats {
    let regulationCount: Int
    let userWorkflowCount: Int
    let totalSize: Int
}
