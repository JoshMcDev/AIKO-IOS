import Foundation
import SwiftUI

/// AIOrchestrator - Central AI coordination hub
/// Week 1-2 deliverable: Skeleton implementation with basic routing
///
/// This is the main entry point for all AI operations in AIKO.
/// It coordinates between the 5 Core Engines and provides a unified API
/// for document generation, compliance validation, and personalization.
///
/// Architecture:
/// - MainActor for UI thread safety
/// - ObservableObject for SwiftUI integration
/// - Sendable for Swift 6 concurrency compliance
/// - Singleton pattern for global access
@MainActor
public final class AIOrchestrator: ObservableObject {
    // MARK: - Singleton

    public static let shared = AIOrchestrator()

    // MARK: - Core Engine Dependencies

    private let documentEngine: DocumentEngine
    private let promptRegistry: PromptRegistry
    private let complianceValidator: ComplianceValidator
    private let personalizationEngine: PersonalizationEngine
    private let providerAdapter: UnifiedProviderAdapter

    // MARK: - Feature Flags Integration

    @Published private var featureFlags: FeatureFlags

    // MARK: - State

    @Published public private(set) var isInitialized = false
    @Published public private(set) var lastError: AIOrchestrationError?

    // MARK: - Initialization

    private init() {
        // Initialize core engines
        documentEngine = DocumentEngine.shared
        promptRegistry = PromptRegistry()
        complianceValidator = ComplianceValidator.shared
        personalizationEngine = PersonalizationEngine.shared
        providerAdapter = UnifiedProviderAdapter()
        featureFlags = FeatureFlags.shared

        // Mark as initialized
        Task { @MainActor in
            self.isInitialized = true
        }
    }

    // MARK: - Public API - Document Generation

    /// Generate a document using the unified AI pipeline
    /// - Parameters:
    ///   - type: The type of document to generate
    ///   - requirements: Requirements and context for the document
    ///   - context: Acquisition context and metadata
    /// - Returns: Generated document with metadata
    /// - Throws: AIOrchestrationError for any failures
    public func generateDocument(
        type documentType: AIDocumentType,
        requirements: String,
        context: AcquisitionContext
    ) async throws -> AIGeneratedDocument {
        guard !requirements.isEmpty else {
            let error = AIValidationError.emptyRequirements
            setLastError(.validationError(error))
            throw error
        }

        // Route through feature flags
        if featureFlags.useNewAIOrchestrator {
            return try await generateDocumentWithNewPipeline(
                type: documentType,
                requirements: requirements,
                context: context
            )
        } else {
            return try await generateDocumentWithLegacyPipeline(
                type: documentType,
                requirements: requirements,
                context: context
            )
        }
    }

    // MARK: - Public API - Compliance Validation

    /// Validate document compliance using unified validator
    /// - Parameters:
    ///   - document: Document to validate
    ///   - requirements: Compliance requirements to check against
    /// - Returns: Validation result with score and issues
    /// - Throws: AIOrchestrationError for any failures
    public func validateCompliance(
        document: AIGeneratedDocument,
        requirements: AIComplianceRequirements
    ) async throws -> AIValidationResult {
        if featureFlags.useComplianceValidator {
            try await complianceValidator.validateDocument(document, against: requirements)
        } else {
            // Fallback to legacy compliance checking
            try await validateComplianceWithLegacySystem(document: document, requirements: requirements)
        }
    }

    // MARK: - Public API - Personalization

    /// Get personalized recommendations for user
    /// - Parameter context: Current acquisition context
    /// - Returns: Personalized recommendations
    public func getPersonalizedRecommendations(for context: AcquisitionContext) async -> PersonalizedRecommendations {
        // Get user history (placeholder)
        let userHistory = await getUserHistory(for: context)

        return await personalizationEngine.adaptForUser(context, history: userHistory)
    }

    /// Get prompt for document type with personalization
    /// - Parameters:
    ///   - documentType: Type of document
    ///   - context: Acquisition context
    /// - Returns: Optimized prompt string
    public func getPrompt(for documentType: AIDocumentType, context: AcquisitionContext) -> String {
        promptRegistry.getPrompt(
            for: documentType,
            context: context,
            optimizations: getOptimizationsForUser(context)
        )
    }

    // MARK: - Private Implementation - New Pipeline

    private func generateDocumentWithNewPipeline(
        type documentType: AIDocumentType,
        requirements: String,
        context: AcquisitionContext
    ) async throws -> AIGeneratedDocument {
        // This is the skeleton - actual implementation will be in GREEN phase
        try await documentEngine.generateDocument(
            type: documentType,
            requirements: requirements,
            context: context
        )
    }

    // MARK: - Private Implementation - Legacy Pipeline

    private func generateDocumentWithLegacyPipeline(
        type _: AIDocumentType,
        requirements _: String,
        context _: AcquisitionContext
    ) async throws -> AIGeneratedDocument {
        // Placeholder for legacy pipeline integration
        // This will be implemented to maintain backward compatibility
        throw AIOrchestrationError.legacyPipelineNotImplemented
    }

    // MARK: - Private Implementation - Legacy Compliance

    private func validateComplianceWithLegacySystem(
        document _: AIGeneratedDocument,
        requirements _: AIComplianceRequirements
    ) async throws -> AIValidationResult {
        // Placeholder for legacy compliance system
        throw AIOrchestrationError.legacyComplianceNotImplemented
    }

    // MARK: - Private Helpers

    private func getUserHistory(for _: AcquisitionContext) async -> [UserAction] {
        // Placeholder - will be implemented with actual user tracking
        []
    }

    private func getOptimizationsForUser(_: AcquisitionContext) -> [PromptPattern] {
        // Placeholder - will be implemented with user preferences
        [.governmentCompliance]
    }

    @MainActor
    private func setLastError(_ error: AIOrchestrationError) {
        lastError = error
    }
}

// MARK: - Error Types

public enum AIOrchestrationError: Error, LocalizedError {
    case validationError(AIValidationError)
    case documentEngineError(String)
    case complianceValidatorError(String)
    case providerError(String)
    case legacyPipelineNotImplemented
    case legacyComplianceNotImplemented
    case unknownError(String)

    public var errorDescription: String? {
        switch self {
        case let .validationError(validationError):
            "Validation error: \(validationError.localizedDescription)"
        case let .documentEngineError(message):
            "Document engine error: \(message)"
        case let .complianceValidatorError(message):
            "Compliance validator error: \(message)"
        case let .providerError(message):
            "Provider error: \(message)"
        case .legacyPipelineNotImplemented:
            "Legacy pipeline not yet implemented"
        case .legacyComplianceNotImplemented:
            "Legacy compliance system not yet implemented"
        case let .unknownError(message):
            "Unknown error: \(message)"
        }
    }
}

public enum AIValidationError: Error, LocalizedError {
    case emptyRequirements
    case invalidDocumentType
    case missingContext

    public var errorDescription: String? {
        switch self {
        case .emptyRequirements:
            "Requirements cannot be empty"
        case .invalidDocumentType:
            "Invalid document type specified"
        case .missingContext:
            "Acquisition context is required"
        }
    }
}

// Types are imported from AIDocumentType.swift and AICoreTypes.swift
