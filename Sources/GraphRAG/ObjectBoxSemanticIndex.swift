import Foundation
#if canImport(ObjectBox)
import ObjectBox
#endif

// MARK: - Conditional Entity Models

#if canImport(ObjectBox)
// Real ObjectBox entity models with proper annotations
// objectbox:Entity
class RegulationEmbedding {
    var id: Id
    var content: String
    var embedding: Data // Store [Float] as Data
    var regulationNumber: String
    var title: String
    var subpart: String?
    var supplement: String?
    var timestamp: Date

    required init() {
        self.id = 0
        self.content = ""
        self.embedding = Data()
        self.regulationNumber = ""
        self.title = ""
        self.subpart = nil
        self.supplement = nil
        self.timestamp = Date()
    }

    convenience init(content: String, embedding: [Float], metadata: RegulationMetadata) {
        self.init()
        self.content = content
        self.embedding = embedding.withUnsafeBytes { Data($0) }
        self.regulationNumber = metadata.regulationNumber
        self.title = metadata.title
        self.subpart = metadata.subpart
        self.supplement = metadata.supplement
        self.timestamp = Date()
    }

    /// Convert stored Data back to [Float] embedding vector
    func getEmbeddingVector() -> [Float] {
        return embedding.withUnsafeBytes { bytes in
            let floatBuffer = bytes.bindMemory(to: Float.self)
            return Array(floatBuffer)
        }
    }
}

// objectbox:Entity
class UserWorkflowEmbedding {
    var id: Id
    var content: String
    var embedding: Data
    var documentType: String
    var timestamp: Date

    required init() {
        self.id = 0
        self.content = ""
        self.embedding = Data()
        self.documentType = ""
        self.timestamp = Date()
    }

    convenience init(content: String, embedding: [Float], metadata: UserWorkflowMetadata) {
        self.init()
        self.content = content
        self.embedding = embedding.withUnsafeBytes { Data($0) }
        self.documentType = metadata.documentType
        self.timestamp = Date()
    }

    /// Convert stored Data back to [Float] embedding vector
    func getEmbeddingVector() -> [Float] {
        return embedding.withUnsafeBytes { bytes in
            let floatBuffer = bytes.bindMemory(to: Float.self)
            return Array(floatBuffer)
        }
    }
}

#else
// Mock implementation classes when ObjectBox is not available
// Define ObjectBoxId type alias for compatibility when ObjectBox is not available
typealias ObjectBoxId = UInt64

class RegulationEmbedding {
    var id: ObjectBoxId = 0
    var content: String = ""
    var embedding: Data = Data()
    var regulationNumber: String = ""
    var title: String = ""
    var subpart: String?
    var supplement: String?
    var timestamp: Date = Date()

    required init() {}

    convenience init(content: String, embedding: [Float], metadata: RegulationMetadata) {
        self.init()
        self.content = content
        self.embedding = embedding.withUnsafeBytes { Data($0) }
        self.regulationNumber = metadata.regulationNumber
        self.title = metadata.title
        self.subpart = metadata.subpart
        self.supplement = metadata.supplement
        self.timestamp = Date()
    }

    func getEmbeddingVector() -> [Float] {
        return embedding.withUnsafeBytes { bytes in
            let floatBuffer = bytes.bindMemory(to: Float.self)
            return Array(floatBuffer)
        }
    }
}

class UserWorkflowEmbedding {
    var id: ObjectBoxId = 0
    var content: String = ""
    var embedding: Data = Data()
    var documentType: String = ""
    var timestamp: Date = Date()

    required init() {}

    convenience init(content: String, embedding: [Float], metadata: UserWorkflowMetadata) {
        self.init()
        self.content = content
        self.embedding = embedding.withUnsafeBytes { Data($0) }
        self.documentType = metadata.documentType
        self.timestamp = Date()
    }

    func getEmbeddingVector() -> [Float] {
        return embedding.withUnsafeBytes { bytes in
            let floatBuffer = bytes.bindMemory(to: Float.self)
            return Array(floatBuffer)
        }
    }
}
#endif

// MARK: - ObjectBox Semantic Index Actor (Always Available)

/// ObjectBox-powered semantic index with vector database capabilities
/// GREEN PHASE: Real ObjectBox integration with vector database storage
/// Provides dual-namespace storage for regulations and user workflows
@globalActor
actor ObjectBoxSemanticIndex {
    static let shared = ObjectBoxSemanticIndex()

    #if canImport(ObjectBox)
    // Real ObjectBox implementation
    private var store: Store?
    private var regulationBox: Box<RegulationEmbedding>?
    private var userWorkflowBox: Box<UserWorkflowEmbedding>?

    private init() {
        do {
            guard let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                              in: .userDomainMask).first else {
                throw ObjectBoxSemanticIndexError.storeNotInitialized
            }
            let objectBoxPath = documentsPath.appendingPathComponent("objectbox")

            // Create directory if it doesn't exist
            try FileManager.default.createDirectory(at: objectBoxPath, withIntermediateDirectories: true)

            // Initialize ObjectBox store
            self.store = try Store(directoryPath: objectBoxPath.path)
            self.regulationBox = store?.box(for: RegulationEmbedding.self)
            self.userWorkflowBox = store?.box(for: UserWorkflowEmbedding.self)

            print("ObjectBox initialized successfully")
        } catch {
            print("ObjectBox initialization failed: \(error)")
            // Store remains nil - this is expected in RED phase but should work in GREEN phase
            self.store = nil
            self.regulationBox = nil
            self.userWorkflowBox = nil
        }
    }

    #else
    // Mock implementation for when ObjectBox is not available
    private var mockRegulations: [RegulationEmbedding] = []
    private var mockUserWorkflows: [UserWorkflowEmbedding] = []

    private init() {
        print("ObjectBoxSemanticIndex using mock implementation (ObjectBox not available)")
    }
    #endif

    // MARK: - Regulation Storage with Vector Search (Common Interface)

    func storeRegulationEmbedding(
        content: String,
        embedding: [Float],
        metadata: RegulationMetadata
    ) async throws {
        #if canImport(ObjectBox)
        guard let regulationBox = regulationBox else {
            throw ObjectBoxSemanticIndexError.objectBoxNotAvailable
        }

        let regulation = RegulationEmbedding(
            content: content,
            embedding: embedding,
            metadata: metadata
        )

        try regulationBox.put(regulation)
        #else
        // Mock implementation
        let regulation = RegulationEmbedding(
            content: content,
            embedding: embedding,
            metadata: metadata
        )
        mockRegulations.append(regulation)
        #endif
    }

    func findSimilarRegulations(
        queryEmbedding: [Float],
        limit: Int,
        threshold: Float = 0.7
    ) async throws -> [RegulationSearchResult] {
        #if canImport(ObjectBox)
        guard let regulationBox = regulationBox else {
            throw ObjectBoxSemanticIndexError.objectBoxNotAvailable
        }

        // Get all regulations for vector similarity search
        let allRegulations = regulationBox.all()
        #else
        // Mock implementation
        let allRegulations = mockRegulations
        #endif

        var similarities: [(RegulationEmbedding, Float)] = []

        for regulation in allRegulations {
            let embeddingVector = regulation.getEmbeddingVector()
            let similarity = cosineSimilarity(queryEmbedding, embeddingVector)

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
                regulationNumber: regulation.regulationNumber,
                embedding: regulation.getEmbeddingVector()
            )
        }
    }

    // MARK: - User Workflow Storage with Vector Search (Common Interface)

    func storeUserWorkflowEmbedding(
        content: String,
        embedding: [Float],
        metadata: UserWorkflowMetadata
    ) async throws {
        #if canImport(ObjectBox)
        guard let userWorkflowBox = userWorkflowBox else {
            throw ObjectBoxSemanticIndexError.objectBoxNotAvailable
        }

        let workflow = UserWorkflowEmbedding(
            content: content,
            embedding: embedding,
            metadata: metadata
        )

        try userWorkflowBox.put(workflow)
        #else
        // Mock implementation
        let workflow = UserWorkflowEmbedding(
            content: content,
            embedding: embedding,
            metadata: metadata
        )
        mockUserWorkflows.append(workflow)
        #endif
    }

    func findSimilarUserWorkflow(
        queryEmbedding: [Float],
        limit: Int,
        threshold: Float = 0.7
    ) async throws -> [RegulationSearchResult] {
        #if canImport(ObjectBox)
        guard let userWorkflowBox = userWorkflowBox else {
            throw ObjectBoxSemanticIndexError.objectBoxNotAvailable
        }

        // Get all user workflows for vector similarity search
        let allWorkflows = userWorkflowBox.all()
        #else
        // Mock implementation
        let allWorkflows = mockUserWorkflows
        #endif

        var similarities: [(UserWorkflowEmbedding, Float)] = []

        for workflow in allWorkflows {
            let embeddingVector = workflow.getEmbeddingVector()
            let similarity = cosineSimilarity(queryEmbedding, embeddingVector)

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
                regulationNumber: workflow.documentType,
                embedding: workflow.getEmbeddingVector()
            )
        }
    }

    // MARK: - Storage Management (Common Interface)

    func getStorageStats() async -> StorageStats {
        #if canImport(ObjectBox)
        guard let regulationBox = regulationBox,
              let userWorkflowBox = userWorkflowBox else {
            return StorageStats(
                regulationCount: 0,
                userWorkflowCount: 0,
                totalSize: 0
            )
        }

        let regulationCount = regulationBox.count()
        let userWorkflowCount = userWorkflowBox.count()

        // Calculate approximate storage size
        let totalSize = Int(regulationCount + userWorkflowCount) * 1024 // Rough estimate

        return StorageStats(
            regulationCount: Int(regulationCount),
            userWorkflowCount: Int(userWorkflowCount),
            totalSize: totalSize
        )
        #else
        // Mock implementation
        return StorageStats(
            regulationCount: mockRegulations.count,
            userWorkflowCount: mockUserWorkflows.count,
            totalSize: (mockRegulations.count + mockUserWorkflows.count) * 1024
        )
        #endif
    }

    func clearAllData() async throws {
        #if canImport(ObjectBox)
        guard let regulationBox = regulationBox,
              let userWorkflowBox = userWorkflowBox else {
            throw ObjectBoxSemanticIndexError.objectBoxNotAvailable
        }

        try regulationBox.removeAll()
        try userWorkflowBox.removeAll()
        #else
        // Mock implementation
        mockRegulations.removeAll()
        mockUserWorkflows.removeAll()
        #endif
    }

    // MARK: - Private Helper Methods

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0.0 }

        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        guard magnitudeA > 0, magnitudeB > 0 else { return 0.0 }

        return dotProduct / (magnitudeA * magnitudeB)
    }
}

// MARK: - Error Types

enum ObjectBoxSemanticIndexError: Error, LocalizedError {
    case objectBoxNotAvailable
    case storeNotInitialized
    case embeddingStorageFailed
    case vectorSearchFailed
    case invalidEmbeddingDimensions

    var errorDescription: String? {
        switch self {
        case .objectBoxNotAvailable:
            return "ObjectBox Swift package is not available. Add ObjectBox dependency to Package.swift and configure entity models."
        case .storeNotInitialized:
            return "ObjectBox store is not initialized. Ensure ObjectBox is properly configured."
        case .embeddingStorageFailed:
            return "Failed to store embedding in ObjectBox database."
        case .vectorSearchFailed:
            return "Vector similarity search operation failed."
        case .invalidEmbeddingDimensions:
            return "Embedding dimensions do not match expected format."
        }
    }
}

// MARK: - Storage Statistics

struct StorageStats {
    let regulationCount: Int
    let userWorkflowCount: Int
    let totalSize: Int
}
