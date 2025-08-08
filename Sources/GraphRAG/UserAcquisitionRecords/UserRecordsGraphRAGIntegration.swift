//
//  UserRecordsGraphRAGIntegration.swift
//  AIKO
//
//  User Acquisition Records GraphRAG Data Collection System
//  Integration with ObjectBox semantic indexing and GraphRAG infrastructure
//

import Foundation
import os.log

// MARK: - UserRecordsGraphRAGIntegration

/// Integration layer connecting User Records system with existing GraphRAG infrastructure
/// Provides semantic indexing, vector storage, and graph relationship management
actor UserRecordsGraphRAGIntegration {

    // MARK: - Properties

    private let logger: Logger = .init(subsystem: "com.aiko.graphrag", category: "UserRecordsGraphRAGIntegration")
    private let objectBoxIndex: ObjectBoxSemanticIndex
    private let privacyEngine: PrivacyEngine

    // Namespace constants for ObjectBox separation
    private let userRecordsNamespace = "UserRecords"
    private let embeddingDimension = 384 // LFM2 compressed dimension

    // Performance tracking
    private var indexedEventCount: Int = 0
    private var lastIndexingTime: TimeInterval = 0

    // MARK: - Initialization

    init(objectBoxIndex: ObjectBoxSemanticIndex, privacyEngine: PrivacyEngine) {
        self.objectBoxIndex = objectBoxIndex
        self.privacyEngine = privacyEngine
        logger.info("UserRecordsGraphRAGIntegration initialized with ObjectBox namespace: \(self.userRecordsNamespace)")
    }

    // MARK: - Core Integration Methods

    /// Index user workflow event in GraphRAG system with privacy protection
    func indexUserWorkflowEvent(_ event: CompactWorkflowEvent) async throws {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Convert to UserAction for privacy processing
        let userAction = convertToUserAction(event)

        // Apply privacy protection
        let privatizedAction = try await privacyEngine.privatize(userAction)

        // Generate workflow embedding
        let embedding = try await generateWorkflowEmbedding(privatizedAction)

        // Create semantic content for indexing
        let semanticContent = createSemanticContent(from: privatizedAction, embedding: embedding)

        // Index in ObjectBox with UserRecords namespace
        try await objectBoxIndex.indexContent(
            content: semanticContent,
            namespace: userRecordsNamespace,
            metadata: createIndexingMetadata(from: privatizedAction)
        )

        // Update performance metrics
        indexedEventCount += 1
        lastIndexingTime = CFAbsoluteTimeGetCurrent() - startTime

        logger.debug("Indexed workflow event: \(String(describing: event.actionType)) in \(String(format: "%.3f", self.lastIndexingTime))ms")
    }

    /// Search for related workflow patterns using semantic similarity
    func searchRelatedWorkflows(
        query: String,
        eventType: WorkflowEventType? = nil,
        limit: Int = 10
    ) async throws -> [WorkflowSearchResult] {
        // Perform semantic search in UserRecords namespace
        let searchResults = try await objectBoxIndex.semanticSearch(
            query: query,
            namespace: userRecordsNamespace,
            limit: limit,
            filters: eventType.map { ["eventType": String($0.rawValue)] }
        )

        // Convert to workflow-specific results
        return searchResults.compactMap { result in
            WorkflowSearchResult(
                workflowId: result.id,
                eventType: extractEventType(from: result.metadata),
                similarity: result.similarity,
                timestamp: extractTimestamp(from: result.metadata),
                privacyLevel: extractPrivacyLevel(from: result.metadata)
            )
        }
    }

    /// Get workflow analytics and patterns from indexed data
    func getWorkflowAnalytics() async throws -> WorkflowAnalytics {
        // Retrieve analytics from ObjectBox namespace
        let namespaceStats = try await objectBoxIndex.getNamespaceStatistics(userRecordsNamespace)

        // Calculate workflow-specific metrics
        let eventTypeDistribution = try await calculateEventTypeDistribution()
        let temporalPatterns = try await analyzeTemporalPatterns()
        let privacyMetrics = await privacyEngine.getPrivacyMetrics()

        return WorkflowAnalytics(
            totalIndexedEvents: indexedEventCount,
            namespaceSize: namespaceStats.documentCount,
            embeddingDimension: embeddingDimension,
            averageIndexingTime: lastIndexingTime,
            eventTypeDistribution: eventTypeDistribution,
            temporalPatterns: temporalPatterns,
            privacyMetrics: privacyMetrics
        )
    }

    /// Update graph relationships between workflow events
    func updateGraphRelationships(_ relationships: [WorkflowRelationship]) async throws {
        for relationship in relationships {
            try await objectBoxIndex.addRelationship(
                from: relationship.sourceEventId,
                to: relationship.targetEventId,
                relationshipType: relationship.type,
                weight: relationship.strength,
                namespace: userRecordsNamespace
            )
        }

        logger.debug("Updated \(relationships.count) graph relationships")
    }

    /// Cleanup old workflow data based on retention policy
    func cleanupOldWorkflowData(olderThan: TimeInterval) async throws {
        let cutoffDate = Date().addingTimeInterval(-olderThan)
        let deletedCount = try await objectBoxIndex.deleteContent(
            namespace: userRecordsNamespace,
            olderThan: cutoffDate
        )

        logger.info("Cleaned up \(deletedCount) old workflow records")
    }

    // MARK: - Private Helper Methods

    private func convertToUserAction(_ event: CompactWorkflowEvent) -> UserAction {
        let eventType = WorkflowEventType(rawValue: event.actionType) ?? .documentOpen

        return UserAction(
            type: eventType,
            documentId: "doc-\(event.documentId)",
            timestamp: Date(timeIntervalSince1970: TimeInterval(event.timestamp)),
            metadata: [
                "userId": String(event.userId),
                "templateId": String(event.templateId),
                "flags": String(event.flags),
                "privacyProtected": event.isPrivacyProtected ? "true" : "false"
            ]
        )
    }

    private func generateWorkflowEmbedding(_ action: UserAction) async throws -> WorkflowEmbedding {
        // Generate base embedding using LFM2 (simulated)
        let baseEmbedding = generateLFM2Embedding(for: action)

        // Compress from 768 to 384 dimensions
        let compressedEmbedding = WorkflowEmbedding.compress(baseEmbedding)

        // Apply privacy noise
        let privacyEmbedding = WorkflowEmbedding(
            embedding: compressedEmbedding,
            privacyNoise: 0.1,
            timestamp: action.timestamp,
            domain: .acquisition
        )

        return privacyEmbedding.withPrivacyNoise(epsilon: 1.0)
    }

    private func generateLFM2Embedding(for action: UserAction) -> [Float] {
        // Simulated LFM2 embedding generation
        // In production, this would call the actual LFM2 service
        var embedding: [Float] = []
        embedding.reserveCapacity(768)

        // Generate based on action type and metadata
        let seed = action.type.rawValue + UInt16(action.documentId.hashValue & 0xFFFF)
        var generator = SeededRandomGenerator(seed: UInt64(seed))

        for _ in 0..<768 {
            embedding.append(Float.random(in: -1.0...1.0, using: &generator))
        }

        return embedding
    }

    private func createSemanticContent(from action: UserAction, embedding: WorkflowEmbedding) -> String {
        // Create searchable content from the privatized action
        let eventTypeDescription = getEventTypeDescription(action.type)
        let temporalContext = getTemporalContext(action.timestamp)

        return """
        \(eventTypeDescription) workflow event occurred \(temporalContext).
        Document context: \(action.documentId)
        Metadata: \(action.metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
        Privacy level: Protected with differential privacy
        """
    }

    private func createIndexingMetadata(from action: UserAction) -> [String: String] {
        return [
            "eventType": String(action.type.rawValue),
            "timestamp": ISO8601DateFormatter().string(from: action.timestamp),
            "documentId": action.documentId,
            "privacyProtected": "true",
            "namespace": userRecordsNamespace,
            "version": "1.0"
        ]
    }

    private func getEventTypeDescription(_ eventType: WorkflowEventType) -> String {
        switch eventType {
        case .documentOpen: return "Document opening"
        case .documentEdit: return "Document editing"
        case .documentSave: return "Document saving"
        case .templateSelect: return "Template selection"
        case .templateCustomize: return "Template customization"
        case .formFieldEdit: return "Form field editing"
        case .formValidate: return "Form validation"
        case .complianceCheck: return "Compliance verification"
        default: return "Workflow action"
        }
    }

    private func getTemporalContext(_ timestamp: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    private func extractEventType(from metadata: [String: String]) -> WorkflowEventType? {
        guard let rawValue = metadata["eventType"],
              let eventTypeValue = UInt16(rawValue) else { return nil }
        return WorkflowEventType(rawValue: eventTypeValue)
    }

    private func extractTimestamp(from metadata: [String: String]) -> Date? {
        guard let timestampString = metadata["timestamp"] else { return nil }
        return ISO8601DateFormatter().date(from: timestampString)
    }

    private func extractPrivacyLevel(from metadata: [String: String]) -> PrivacyLevel {
        return metadata["privacyProtected"] == "true" ? .high : .low
    }

    private func calculateEventTypeDistribution() async throws -> [WorkflowEventType: Int] {
        // This would query ObjectBox for event type distribution
        // For now, return simulated data
        return [
            .documentOpen: 150,
            .documentEdit: 300,
            .documentSave: 145,
            .templateSelect: 80,
            .formFieldEdit: 220,
            .complianceCheck: 45
        ]
    }

    private func analyzeTemporalPatterns() async throws -> [String] {
        // This would analyze temporal patterns from ObjectBox data
        // For now, return simulated patterns
        return [
            "Peak activity: 9-11 AM",
            "Secondary peak: 2-4 PM",
            "Low activity: 12-1 PM",
            "Weekday preference: 85%"
        ]
    }
}

// MARK: - Supporting Types

/// Workflow search result from GraphRAG system
public struct WorkflowSearchResult: Sendable {
    public let workflowId: String
    public let eventType: WorkflowEventType?
    public let similarity: Float
    public let timestamp: Date?
    public let privacyLevel: PrivacyLevel

    public init(workflowId: String, eventType: WorkflowEventType?, similarity: Float, timestamp: Date?, privacyLevel: PrivacyLevel) {
        self.workflowId = workflowId
        self.eventType = eventType
        self.similarity = similarity
        self.timestamp = timestamp
        self.privacyLevel = privacyLevel
    }
}

/// Workflow analytics from GraphRAG system
public struct WorkflowAnalytics: Sendable {
    public let totalIndexedEvents: Int
    public let namespaceSize: Int
    public let embeddingDimension: Int
    public let averageIndexingTime: TimeInterval
    public let eventTypeDistribution: [WorkflowEventType: Int]
    public let temporalPatterns: [String]
    public let privacyMetrics: PrivacyMetrics

    public init(totalIndexedEvents: Int, namespaceSize: Int, embeddingDimension: Int, averageIndexingTime: TimeInterval, eventTypeDistribution: [WorkflowEventType: Int], temporalPatterns: [String], privacyMetrics: PrivacyMetrics) {
        self.totalIndexedEvents = totalIndexedEvents
        self.namespaceSize = namespaceSize
        self.embeddingDimension = embeddingDimension
        self.averageIndexingTime = averageIndexingTime
        self.eventTypeDistribution = eventTypeDistribution
        self.temporalPatterns = temporalPatterns
        self.privacyMetrics = privacyMetrics
    }
}

/// Graph relationship between workflow events
public struct WorkflowRelationship: Sendable {
    public let sourceEventId: String
    public let targetEventId: String
    public let type: String
    public let strength: Float

    public init(sourceEventId: String, targetEventId: String, type: String, strength: Float) {
        self.sourceEventId = sourceEventId
        self.targetEventId = targetEventId
        self.type = type
        self.strength = strength
    }
}

/// Seeded random number generator for reproducible embeddings
struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }
}

// MARK: - ObjectBox Extensions

extension ObjectBoxSemanticIndex {
    /// Index content with namespace support
    func indexContent(content: String, namespace: String, metadata: [String: String]) async throws {
        // This would integrate with the actual ObjectBox indexing
        // For now, simulate the operation
        logger.debug("Indexing content in namespace: \(namespace)")
    }

    /// Semantic search within namespace
    func semanticSearch(query: String, namespace: String, limit: Int, filters: [String: String]? = nil) async throws -> [SemanticSearchResult] {
        // This would perform actual semantic search
        // For now, return simulated results
        return (0..<min(limit, 5)).map { i in
            SemanticSearchResult(
                id: "result-\(i)",
                similarity: Float.random(in: 0.7...0.95),
                metadata: filters ?? [:]
            )
        }
    }

    /// Get namespace statistics
    func getNamespaceStatistics(_ namespace: String) async throws -> NamespaceStatistics {
        // This would query actual ObjectBox statistics
        return NamespaceStatistics(documentCount: 1000, averageEmbeddingSize: 384)
    }

    /// Add relationship between documents
    func addRelationship(from: String, to: String, relationshipType: String, weight: Float, namespace: String) async throws {
        // This would add actual graph relationships
        logger.debug("Added relationship: \(from) -> \(to) (\(relationshipType))")
    }

    /// Delete old content
    func deleteContent(namespace: String, olderThan: Date) async throws -> Int {
        // This would delete actual old content
        return Int.random(in: 10...100)
    }

    private var logger: Logger {
        Logger(subsystem: "com.aiko.graphrag", category: "ObjectBoxSemanticIndex")
    }
}

/// Semantic search result
public struct SemanticSearchResult: Sendable {
    public let id: String
    public let similarity: Float
    public let metadata: [String: String]

    public init(id: String, similarity: Float, metadata: [String: String]) {
        self.id = id
        self.similarity = similarity
        self.metadata = metadata
    }
}

/// Namespace statistics
public struct NamespaceStatistics: Sendable {
    public let documentCount: Int
    public let averageEmbeddingSize: Int

    public init(documentCount: Int, averageEmbeddingSize: Int) {
        self.documentCount = documentCount
        self.averageEmbeddingSize = averageEmbeddingSize
    }
}
