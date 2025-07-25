import Foundation

// MARK: - Core GraphRAG Types

/// Embedding domain for optimization and tracking
enum SearchDomain: String, CaseIterable {
    case regulations
    case userHistory
}

// MARK: - Regulation Processing Types

enum RegulationSource {
    case far
    case dfars
    case agency
}

struct ProcessedRegulation {
    let chunks: [RegulationChunk]
    let metadata: RegulationMetadata
    let source: RegulationSource
}

struct RegulationChunk {
    let content: String
    let chunkIndex: Int
    let sectionTitle: String?
}

struct RegulationMetadata {
    let regulationNumber: String
    let title: String
    let subpart: String?
    let supplement: String?
}

struct RegulationSearchResult {
    let content: String
    let domain: SearchDomain
    let regulationNumber: String
    let embedding: [Float]
}

struct UserWorkflowMetadata {
    let documentType: String
}

// MARK: - Search Service Types

struct UnifiedSearchResult {
    let content: String
    let domain: SearchDomain
    let relevanceScore: Float
    let metadata: SearchResultMetadata
}

struct SearchResultMetadata {
    let sourceType: String
    let timestamp: Date
    let documentId: String
}

struct QueryRoutingResult {
    let recommendedDomains: [SearchDomain]
    let confidence: Float
    let reasoning: String
}

struct UserSearchContext: Sendable {
    let userId: String
    let recentQueries: [String]
    let documentTypes: [String]
    let preferences: [String: String] // Changed to Sendable type
}

// MARK: - Workflow Tracking Types

struct WorkflowStep: Sendable {
    let stepId: String
    let timestamp: Date
    let documentType: String
    let formFields: [String: String] // Changed to Sendable type
    let userActions: [UserAction]
}

struct UserAction: Sendable, Codable {
    let actionType: String
    let target: String
    let timestamp: Date
}

struct PatternAnalysisResult {
    let overallAccuracy: Float
    let detectedPatterns: [DetectedPattern]
    let temporalPatterns: [TemporalPattern]
}

struct DetectedPattern {
    let patternId: String
    let confidence: Float
    let supportingEvidence: [String]
}

struct TemporalPattern {
    let pattern: String
    let accuracy: Float
}

struct EncryptionInfo {
    let algorithm: EncryptionAlgorithm
    let keyLength: Int
    let keyId: String
}

enum EncryptionAlgorithm {
    case aes256
    case aes128
}

struct EncryptionKeyAccess {
    let isUserSpecific: Bool
    let isSecurelyStored: Bool
    let isAccessibleByOtherUsers: Bool
}

// MARK: - Test Helper Types

struct TestRegulationInput {
    let html: String
    let source: RegulationSource
}

struct WorkflowSequence {
    let sequenceId: String
    let steps: [WorkflowStep]
    let expectedPattern: String
}

struct TestQueryWithExpectedDomains {
    let query: String
    let expectedDomains: [SearchDomain]
}

struct TestQuery {
    let text: String
    let domains: [SearchDomain]
}

struct TestRegulationData {
    let content: String
    let embedding: [Float]
    let metadata: RegulationMetadata
}

struct TestRegulation {
    let content: String
}
