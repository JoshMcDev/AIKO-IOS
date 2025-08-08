//
//  WorkflowEmbedding.swift
//  AIKO
//
//  User Acquisition Records GraphRAG Data Collection System
//  Privacy-preserving vector embeddings for workflow events
//

import Foundation

// MARK: - WorkflowEmbedding

/// Privacy-preserved workflow embeddings with community assignment
public struct WorkflowEmbedding: Sendable {
    public let embedding: [Float]      // 384-dimensional (compressed from 768)
    public let privacyNoise: Float     // Differential privacy epsilon
    public let timestamp: Date
    public let domain: WorkflowDomain
    public let communityId: Int?       // Leiden community assignment
    public let confidence: Float       // Embedding quality confidence

    public init(
        embedding: [Float],
        privacyNoise: Float,
        timestamp: Date,
        domain: WorkflowDomain,
        communityId: Int? = nil,
        confidence: Float = 1.0
    ) {
        self.embedding = embedding
        self.privacyNoise = privacyNoise
        self.timestamp = timestamp
        self.domain = domain
        self.communityId = communityId
        self.confidence = confidence
    }

    // MARK: - Compression Methods

    /// Compress 768-dimensional LFM2 embedding to 384 dimensions using PCA
    public static func compress(_ fullEmbedding: [Float]) -> [Float] {
        // Simplified compression - in production would use actual PCA
        let targetDimensions = 384
        guard fullEmbedding.count == 768 else { return fullEmbedding }

        var compressed: [Float] = []
        compressed.reserveCapacity(targetDimensions)

        // Simple averaging compression (2:1 ratio)
        for i in stride(from: 0, to: fullEmbedding.count, by: 2) {
            let avg = (fullEmbedding[i] + fullEmbedding[i + 1]) / 2.0
            compressed.append(avg)
        }

        return compressed
    }

    // MARK: - Privacy Methods

    /// Apply differential privacy noise to embedding
    public func withPrivacyNoise(epsilon: Float) -> WorkflowEmbedding {
        guard epsilon > 0 else { return self }

        let noisyEmbedding = embedding.map { value in
            let noise = Float.random(in: -epsilon...epsilon)
            return value + noise
        }

        return WorkflowEmbedding(
            embedding: noisyEmbedding,
            privacyNoise: epsilon,
            timestamp: timestamp,
            domain: domain,
            communityId: communityId,
            confidence: confidence * 0.95 // Slightly reduce confidence due to noise
        )
    }

    // MARK: - Similarity Methods

    /// Calculate cosine similarity with another embedding
    public func cosineSimilarity(with other: WorkflowEmbedding) -> Float {
        guard embedding.count == other.embedding.count else { return 0 }

        let dotProduct = zip(embedding, other.embedding).reduce(0.0) { $0 + ($1.0 * $1.1) }
        let magnitude1 = sqrt(embedding.reduce(0.0) { $0 + ($1 * $1) })
        let magnitude2 = sqrt(other.embedding.reduce(0.0) { $0 + ($1 * $1) })

        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }

        return dotProduct / (magnitude1 * magnitude2)
    }
}

// MARK: - WorkflowDomain

/// Domain classification for workflow embeddings
public enum WorkflowDomain: String, CaseIterable, Sendable {
    case acquisition
    case compliance
    case documentation
    case template
    case search
    case general

    /// Domain-specific embedding optimization parameters
    public var optimizationParams: DomainOptimizationParams {
        switch self {
        case .acquisition:
            return DomainOptimizationParams(
                targetDimensions: 384,
                compressionRatio: 0.5,
                privacyBudget: 0.1
            )
        case .compliance:
            return DomainOptimizationParams(
                targetDimensions: 384,
                compressionRatio: 0.4,
                privacyBudget: 0.05 // Higher privacy for compliance
            )
        case .documentation:
            return DomainOptimizationParams(
                targetDimensions: 256,
                compressionRatio: 0.6,
                privacyBudget: 0.2
            )
        case .template:
            return DomainOptimizationParams(
                targetDimensions: 384,
                compressionRatio: 0.5,
                privacyBudget: 0.15
            )
        case .search:
            return DomainOptimizationParams(
                targetDimensions: 512,
                compressionRatio: 0.3,
                privacyBudget: 0.25
            )
        case .general:
            return DomainOptimizationParams(
                targetDimensions: 384,
                compressionRatio: 0.5,
                privacyBudget: 0.1
            )
        }
    }
}

// MARK: - DomainOptimizationParams

/// Optimization parameters for domain-specific embeddings
public struct DomainOptimizationParams: Sendable {
    public let targetDimensions: Int
    public let compressionRatio: Float
    public let privacyBudget: Float

    public init(targetDimensions: Int, compressionRatio: Float, privacyBudget: Float) {
        self.targetDimensions = targetDimensions
        self.compressionRatio = compressionRatio
        self.privacyBudget = privacyBudget
    }
}

// MARK: - EmbeddingMetadata

/// Metadata for embedding storage and retrieval
public struct EmbeddingMetadata: Sendable {
    public let id: UUID
    public let createdAt: Date
    public let updatedAt: Date
    public let version: Int
    public let source: EmbeddingSource
    public let quality: EmbeddingQuality

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        version: Int = 1,
        source: EmbeddingSource,
        quality: EmbeddingQuality
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.version = version
        self.source = source
        self.quality = quality
    }
}

// MARK: - EmbeddingSource

/// Source of the embedding generation
public enum EmbeddingSource: String, Sendable {
    case lfm2
    case compressed
    case synthetic
    case cached
}

// MARK: - EmbeddingQuality

/// Quality metrics for embeddings
public struct EmbeddingQuality: Sendable {
    public let confidence: Float
    public let coherence: Float
    public let privacyLevel: Float
    public let compressionLoss: Float

    public init(confidence: Float, coherence: Float, privacyLevel: Float, compressionLoss: Float = 0) {
        self.confidence = confidence
        self.coherence = coherence
        self.privacyLevel = privacyLevel
        self.compressionLoss = compressionLoss
    }

    /// Overall quality score (0-1)
    public var overallScore: Float {
        (confidence + coherence + privacyLevel - compressionLoss) / 3.0
    }
}

// MARK: - WorkflowPattern

/// Detected workflow patterns from embeddings
public struct WorkflowPattern: Sendable {
    public let id: UUID
    public let sequence: [WorkflowEventType]
    public let frequency: Int
    public let avgDuration: TimeInterval
    public let confidence: Float
    public let nextPredicted: [PredictedAction]
    public let temporalWindow: ClosedRange<Int>
    public let eventTypes: Set<WorkflowEventType>

    public init(
        id: UUID = UUID(),
        sequence: [WorkflowEventType],
        frequency: Int,
        avgDuration: TimeInterval,
        confidence: Float,
        nextPredicted: [PredictedAction] = [],
        temporalWindow: ClosedRange<Int> = 0...23,
        eventTypes: Set<WorkflowEventType>? = nil
    ) {
        self.id = id
        self.sequence = sequence
        self.frequency = frequency
        self.avgDuration = avgDuration
        self.confidence = confidence
        self.nextPredicted = nextPredicted
        self.temporalWindow = temporalWindow
        self.eventTypes = eventTypes ?? Set(sequence)
    }
}

// MARK: - PredictedAction

/// Predicted next action in workflow
public struct PredictedAction: Sendable {
    public let eventType: WorkflowEventType
    public let probability: Float
    public let expectedTiming: TimeInterval
    public let confidence: ConfidenceLevel

    public init(eventType: WorkflowEventType, probability: Float, expectedTiming: TimeInterval, confidence: ConfidenceLevel) {
        self.eventType = eventType
        self.probability = probability
        self.expectedTiming = expectedTiming
        self.confidence = confidence
    }
}

// MARK: - ConfidenceLevel

public enum ConfidenceLevel: String, CaseIterable, Sendable {
    case veryLow = "very_low"      // <20%
    case low = "low"                // 20-40%
    case medium = "medium"          // 40-60%
    case high = "high"              // 60-80%
    case veryHigh = "very_high"     // >80%

    /// Numeric representation of confidence
    public var numericValue: Float {
        switch self {
        case .veryLow: return 0.1
        case .low: return 0.3
        case .medium: return 0.5
        case .high: return 0.7
        case .veryHigh: return 0.9
        }
    }
}
