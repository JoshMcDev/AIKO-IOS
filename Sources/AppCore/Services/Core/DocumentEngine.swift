import Foundation

/// DocumentEngine - Unified document generation core
/// Week 1-2 deliverable: Skeleton with actor isolation and basic structure
///
/// Consolidates functionality from:
/// - AIDocumentGenerator.swift
/// - LLMDocumentGenerator.swift
/// - ParallelDocumentGenerator.swift
/// - BatchDocumentGenerator.swift
///
/// Provides a single, unified pipeline for all document generation with:
/// - Actor isolation for thread safety
/// - Provider abstraction for multiple LLM backends
/// - Caching for performance optimization
/// - Template management integration
public actor DocumentEngine {
    // MARK: - Singleton

    public static let shared = DocumentEngine()

    // MARK: - Dependencies

    private let providerAdapter: UnifiedProviderAdapter
    private let templateService: UnifiedTemplateService
    private let cache: DocumentGenerationCache
    private let promptRegistry: PromptRegistry

    // MARK: - State

    private var isInitialized = false
    private var activeGenerations: [String: Task<AIGeneratedDocument, Error>] = [:]

    // MARK: - Initialization

    private init() {
        providerAdapter = UnifiedProviderAdapter()
        templateService = UnifiedTemplateService()
        cache = DocumentGenerationCache()
        promptRegistry = PromptRegistry()

        Task {
            await self.initialize()
        }
    }

    private func initialize() async {
        // Initialize dependencies and warm up caches
        await templateService.loadTemplates()
        await cache.warmUpCache()
        isInitialized = true
    }

    // MARK: - Public API

    /// Generate a document using the unified pipeline
    /// - Parameters:
    ///   - type: Document type to generate
    ///   - requirements: Requirements and specifications
    ///   - context: Acquisition context for personalization
    /// - Returns: Generated document with metadata
    /// - Throws: DocumentEngineError for any failures
    public func generateDocument(
        type documentType: AIDocumentType,
        requirements: String,
        context: AcquisitionContext
    ) async throws -> AIGeneratedDocument {
        guard isInitialized else {
            throw DocumentEngineError.notInitialized
        }

        guard !requirements.isEmpty else {
            throw DocumentEngineError.emptyRequirements
        }

        // Generate cache key for deduplication
        let cacheKey = generateCacheKey(type: documentType, requirements: requirements, context: context)

        // Check cache first
        if let cachedDocument = await cache.getDocument(key: cacheKey) {
            return cachedDocument
        }

        // Check if generation is already in progress
        if let existingTask = activeGenerations[cacheKey] {
            return try await existingTask.value
        }

        // Start new generation task
        let generationTask = Task<AIGeneratedDocument, Error> {
            try await performDocumentGeneration(
                type: documentType,
                requirements: requirements,
                context: context
            )
        }

        activeGenerations[cacheKey] = generationTask

        do {
            let document = try await generationTask.value
            await cache.storeDocument(key: cacheKey, document: document)
            activeGenerations.removeValue(forKey: cacheKey)
            return document
        } catch {
            activeGenerations.removeValue(forKey: cacheKey)
            throw error
        }
    }

    /// Generate multiple documents in parallel
    /// - Parameters:
    ///   - requests: Array of document generation requests
    /// - Returns: Array of generated documents (preserving order)
    /// - Throws: DocumentEngineError for any failures
    public func generateDocuments(
        requests: [DocumentGenerationRequest]
    ) async throws -> [AIGeneratedDocument] {
        guard isInitialized else {
            throw DocumentEngineError.notInitialized
        }

        // Start all generations in parallel
        let tasks = requests.map { request in
            Task {
                try await generateDocument(
                    type: request.type,
                    requirements: request.requirements,
                    context: request.context
                )
            }
        }

        // Wait for all to complete
        var results: [AIGeneratedDocument] = []
        for task in tasks {
            let document = try await task.value
            results.append(document)
        }

        return results
    }

    // MARK: - Private Implementation

    private func performDocumentGeneration(
        type documentType: AIDocumentType,
        requirements _: String,
        context: AcquisitionContext
    ) async throws -> AIGeneratedDocument {
        // Get optimized prompt from registry
        let prompt = promptRegistry.getPrompt(
            for: documentType,
            context: context,
            optimizations: [.governmentCompliance, .technical]
        )

        // Get template for document type
        let template = await templateService.getTemplate(for: documentType)

        // Generate document using provider
        let response = try await providerAdapter.generateResponseWithFallback(
            prompt: prompt,
            primaryProvider: .claude,
            fallbackProviders: [.openAI, .gemini],
            parameters: getParametersForDocumentType(documentType)
        )

        // Process response and apply template
        let processedContent = await applyTemplate(
            template: template,
            response: response.content,
            context: context
        )

        // Create document with metadata
        let metadata = AIDocumentMetadata(
            createdAt: Date(),
            generatedBy: "DocumentEngine",
            version: "1.0"
        )

        return AIGeneratedDocument(
            type: documentType,
            content: processedContent,
            metadata: metadata
        )
    }

    private func generateCacheKey(
        type: AIDocumentType,
        requirements: String,
        context: AcquisitionContext
    ) -> String {
        let contextHash = "\(context.programName)-\(context.agency ?? "")-\(context.contractValue?.description ?? "")"
        return "\(type.rawValue)-\(requirements.hashValue)-\(contextHash.hashValue)"
    }

    private func getParametersForDocumentType(_ type: AIDocumentType) -> LLMParameters {
        switch type {
        case .sf1449, .sf18, .sf26:
            // Form-based documents need more structured output
            LLMParameters(temperature: 0.3, maxTokens: 4000, topP: 0.8)
        case .sf30, .sf33:
            // Modification documents need balanced creativity
            LLMParameters(temperature: 0.5, maxTokens: 6000, topP: 0.9)
        case .sf44, .dd1155:
            // Complex documents need more creative output
            LLMParameters(temperature: 0.7, maxTokens: 8000, topP: 0.95)
        }
    }

    private func applyTemplate(
        template: DocumentTemplate,
        response: String,
        context: AcquisitionContext
    ) async -> String {
        // Apply template formatting and context substitution
        // This is a placeholder - actual implementation will be in GREEN phase
        template.applyFormatting(to: response, with: context)
    }
}

// MARK: - Supporting Types

public struct DocumentGenerationRequest: Sendable {
    public let type: AIDocumentType
    public let requirements: String
    public let context: AcquisitionContext

    public init(type: AIDocumentType, requirements: String, context: AcquisitionContext) {
        self.type = type
        self.requirements = requirements
        self.context = context
    }
}

public enum DocumentEngineError: Error, LocalizedError {
    case notInitialized
    case emptyRequirements
    case templateNotFound(AIDocumentType)
    case providerError(String)
    case templateProcessingError(String)
    case cacheError(String)
    case generationTimeout
    case unknownError(String)

    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            "Document engine not initialized"
        case .emptyRequirements:
            "Requirements cannot be empty"
        case let .templateNotFound(type):
            "Template not found for document type: \(type.rawValue)"
        case let .providerError(message):
            "Provider error: \(message)"
        case let .templateProcessingError(message):
            "Template processing error: \(message)"
        case let .cacheError(message):
            "Cache error: \(message)"
        case .generationTimeout:
            "Document generation timed out"
        case let .unknownError(message):
            "Unknown error: \(message)"
        }
    }
}

// MARK: - Placeholder Dependencies (Will be implemented in GREEN phase)

public struct UnifiedProviderAdapter: Sendable {
    public init() {}

    public func generateResponseWithFallback(
        prompt: String,
        primaryProvider: LLMProvider,
        fallbackProviders: [LLMProvider],
        parameters: LLMParameters
    ) async throws -> LLMResponse {
        // GREEN phase implementation - generate realistic document content

        // Try primary provider first
        if let response = try? await generateResponse(prompt: prompt, provider: primaryProvider, parameters: parameters) {
            return response
        }

        // Try fallback providers
        for provider in fallbackProviders {
            if let response = try? await generateResponse(prompt: prompt, provider: provider, parameters: parameters) {
                return response
            }
        }

        // If all providers fail, return a basic response
        let content = generateBasicDocumentContent(from: prompt)
        return LLMResponse(content: content, usedProvider: primaryProvider)
    }

    public func generateResponse(
        prompt: String,
        provider: LLMProvider,
        parameters _: LLMParameters
    ) async throws -> LLMResponse {
        // GREEN phase mock implementation
        let content = generateBasicDocumentContent(from: prompt)
        return LLMResponse(content: content, usedProvider: provider)
    }

    private func generateBasicDocumentContent(from prompt: String) -> String {
        // Generate basic document content based on prompt keywords
        if prompt.contains("SF-1449") {
            generateSF1449Content()
        } else if prompt.contains("SF-18") {
            generateSF18Content()
        } else if prompt.contains("SF-26") {
            generateSF26Content()
        } else if prompt.contains("SF-30") {
            generateSF30Content()
        } else if prompt.contains("SF-33") {
            generateSF33Content()
        } else if prompt.contains("SF-44") {
            generateSF44Content()
        } else if prompt.contains("DD-1155") {
            generateDD1155Content()
        } else {
            "Generated document content based on requirements: \(prompt.prefix(100))..."
        }
    }

    private func generateSF1449Content() -> String {
        """
        SOLICITATION/CONTRACT/ORDER FOR COMMERCIAL ITEMS

        1. CONTRACT NO.
        [Contract Number]

        2. SOLICITATION NO.
        [Solicitation Number]

        3. DATE ISSUED
        \(Date().formatted(.dateTime.day().month().year()))

        4. REQUISITION/PURCHASE REQUEST NO.
        [PR Number]

        5. PROJECT NO. (If applicable)
        [Project Number]

        6. ISSUED BY
        [Contracting Office Name and Address]

        7. ADMINISTERED BY (If other than Item 6)
        [Administration Office]

        This document constitutes a Contract when signed by both parties.

        [Additional contract terms and conditions as specified in requirements]
        """
    }

    private func generateSF18Content() -> String {
        """
        REQUEST FOR QUOTATIONS

        1. REQUEST NO.
        [RFQ Number]

        2. DATE ISSUED
        \(Date().formatted(.dateTime.day().month().year()))

        3. REQUISITION/PURCHASE REQUEST NO.
        [PR Number]

        4. ISSUED BY
        [Issuing Office]

        5. DELIVERY DATE
        [Delivery Requirements]

        DESCRIPTION OF SUPPLIES/SERVICES:
        [Detailed description of required supplies or services]

        Please submit quotations by [Date] to [Address].
        """
    }

    private func generateSF26Content() -> String {
        """
        AWARD/CONTRACT

        1. CONTRACT NO.
        [Contract Number]

        2. EFFECTIVE DATE
        \(Date().formatted(.dateTime.day().month().year()))

        3. CONTRACTOR
        [Contractor Name and Address]

        4. ADMINISTERED BY
        [Contracting Office]

        5. ISSUING OFFICE
        [Issuing Office Details]

        This document constitutes the award of the contract referenced above.

        [Contract terms, conditions, and specifications]
        """
    }

    private func generateSF30Content() -> String {
        """
        AMENDMENT OF SOLICITATION/MODIFICATION OF CONTRACT

        1. CONTRACT ID CODE
        [Contract ID]

        2. AMENDMENT/MODIFICATION NO.
        [Modification Number]

        3. EFFECTIVE DATE
        \(Date().formatted(.dateTime.day().month().year()))

        4. REQUISITION/PURCHASE REQUEST NO.
        [PR Number]

        5. PROJECT NO.
        [Project Number]

        6. ISSUED BY
        [Contracting Office]

        This modification is issued to [describe modification purpose].

        [Detailed modification specifications]
        """
    }

    private func generateSF33Content() -> String {
        """
        SOLICITATION, OFFER AND AWARD

        1. THIS CONTRACT IS A RATED ORDER UNDER DPAS (15 CFR 700)
        RATING: [Rating]

        2. CONTRACT NO.
        [Contract Number]

        3. SOLICITATION NO.
        [Solicitation Number]

        4. TYPE OF SOLICITATION
        [X] SEALED BID (IFB)  [ ] NEGOTIATED (RFP)

        5. DATE ISSUED
        \(Date().formatted(.dateTime.day().month().year()))

        6. REQUISITION/PURCHASE REQUEST NO.
        [PR Number]

        SOLICITATION/CONTRACT/ORDER FOR COMMERCIAL ITEMS

        [Detailed solicitation terms and conditions]
        """
    }

    private func generateSF44Content() -> String {
        """
        PURCHASE ORDER-INVOICE-VOUCHER

        1. DATE OF ORDER
        \(Date().formatted(.dateTime.day().month().year()))

        2. PURCHASE ORDER NO.
        [PO Number]

        3. DATE REQUIRED
        [Required Date]

        4. SHIP TO:
        [Shipping Address]

        5. ORDERED FROM:
        [Vendor Information]

        DESCRIPTION OF SUPPLIES/SERVICES:
        [Item descriptions, quantities, and unit prices]

        TERMS AND CONDITIONS:
        [Standard terms and conditions]
        """
    }

    private func generateDD1155Content() -> String {
        """
        ORDER FOR SUPPLIES OR SERVICES

        1. DATE OF ORDER
        \(Date().formatted(.dateTime.day().month().year()))

        2. ORDER NO.
        [Order Number]

        3. ACCOUNTING AND APPROPRIATION DATA
        [Accounting Data]

        4. REQUISITIONING OFFICE
        [Requisitioning Office]

        5. FROM: (Vendor)
        [Vendor Information]

        6. TO: (Ship to address)
        [Delivery Address]

        DESCRIPTION OF SUPPLIES/SERVICES:
        [Detailed description of ordered items]

        [Additional terms and delivery requirements]
        """
    }
}

public struct UnifiedTemplateService: Sendable {
    public init() {}

    public func loadTemplates() async {}

    public func getTemplate(for documentType: AIDocumentType) async -> DocumentTemplate {
        DocumentTemplate(type: documentType)
    }
}

public struct DocumentGenerationCache: Sendable {
    public init() {}

    public func warmUpCache() async {}

    public func getDocument(key _: String) async -> AIGeneratedDocument? {
        nil // No cache during RED phase
    }

    public func storeDocument(key _: String, document _: AIGeneratedDocument) async {}
}

public struct DocumentTemplate: Sendable {
    public let type: AIDocumentType

    public init(type: AIDocumentType) {
        self.type = type
    }

    public func applyFormatting(to content: String, with _: AcquisitionContext) -> String {
        // Placeholder implementation
        content
    }
}

public struct LLMParameters: Sendable {
    public let temperature: Double
    public let maxTokens: Int
    public let topP: Double

    public init(temperature: Double, maxTokens: Int, topP: Double) {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
    }

    public static let `default` = LLMParameters(temperature: 0.7, maxTokens: 4000, topP: 0.9)
}

public struct LLMResponse: Sendable {
    public let content: String
    public let usedProvider: LLMProvider
    public let metadata: [String: String]

    public init(content: String, usedProvider: LLMProvider, metadata: [String: String] = [:]) {
        self.content = content
        self.usedProvider = usedProvider
        self.metadata = metadata
    }
}
