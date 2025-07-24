import Foundation

/// PromptRegistry - Unified prompt management core
/// Week 1-2 deliverable: Skeleton with basic prompt optimization
///
/// Consolidates functionality from multiple prompt management systems into
/// a single, optimized registry with:
/// - Document type specific prompts
/// - Context-aware optimization
/// - Government compliance patterns
/// - Performance-optimized prompt caching
public struct PromptRegistry: Sendable {
    // MARK: - Dependencies

    private let promptCache: PromptCache
    private let optimizationEngine: PromptOptimizationEngine
    private let compliancePatterns: CompliancePatternEngine

    // MARK: - Initialization

    public init() {
        promptCache = PromptCache()
        optimizationEngine = PromptOptimizationEngine()
        compliancePatterns = CompliancePatternEngine()
    }

    // MARK: - Public API

    /// Get optimized prompt for document type and context
    /// - Parameters:
    ///   - documentType: Type of document to generate prompt for
    ///   - context: Acquisition context for personalization
    ///   - optimizations: Array of optimization patterns to apply
    /// - Returns: Optimized prompt string ready for LLM generation
    public func getPrompt(
        for documentType: AIDocumentType,
        context: AcquisitionContext,
        optimizations: [PromptPattern] = []
    ) -> String {
        // Generate cache key
        let cacheKey = generateCacheKey(
            documentType: documentType,
            context: context,
            optimizations: optimizations
        )

        // Check cache first
        if let cachedPrompt = promptCache.getPrompt(key: cacheKey) {
            return cachedPrompt
        }

        // Build base prompt for document type
        let basePrompt = buildBasePrompt(for: documentType)

        // Apply context personalization
        let contextualizedPrompt = applyContextualization(
            prompt: basePrompt,
            context: context
        )

        // Apply optimization patterns
        let optimizedPrompt = applyOptimizations(
            prompt: contextualizedPrompt,
            patterns: optimizations
        )

        // Apply compliance patterns
        let compliantPrompt = compliancePatterns.applyCompliancePatterns(
            prompt: optimizedPrompt,
            documentType: documentType
        )

        // Cache the result
        promptCache.storePrompt(key: cacheKey, prompt: compliantPrompt)

        return compliantPrompt
    }

    /// Get prompt optimized for specific provider capabilities
    /// - Parameters:
    ///   - documentType: Type of document to generate
    ///   - provider: Target LLM provider
    ///   - context: Acquisition context
    /// - Returns: Provider-optimized prompt
    public func getProviderOptimizedPrompt(
        for documentType: AIDocumentType,
        provider: LLMProvider,
        context: AcquisitionContext
    ) -> String {
        let basePrompt = getPrompt(for: documentType, context: context)

        return optimizationEngine.optimizeForProvider(
            prompt: basePrompt,
            provider: provider,
            documentType: documentType
        )
    }

    /// Batch get prompts for multiple document types
    /// - Parameters:
    ///   - requests: Array of prompt requests
    /// - Returns: Array of optimized prompts
    public func getPrompts(requests: [PromptRequest]) -> [String] {
        requests.map { request in
            getPrompt(
                for: request.documentType,
                context: request.context,
                optimizations: request.optimizations
            )
        }
    }

    // MARK: - Private Implementation

    private func buildBasePrompt(for documentType: AIDocumentType) -> String {
        switch documentType {
        case .sf1449:
            """
            Generate a comprehensive SF-1449 (Solicitation/Contract/Order for Commercial Items) document.
            This form is used for acquiring commercial items and must include all required sections:
            - Contract/Order identification
            - Item details and specifications
            - Quantity and unit pricing
            - Delivery terms and schedule
            - Payment terms and conditions
            - Compliance with FAR regulations
            """

        case .sf18:
            """
            Generate an SF-18 (Request for Quotation) document.
            This form requests price quotations from vendors and must include:
            - Item descriptions and specifications
            - Quantity requirements
            - Delivery requirements
            - Terms and conditions
            - Response instructions
            """

        case .sf26:
            """
            Generate an SF-26 (Award/Contract) document.
            This form officially awards a contract and must include:
            - Award details and contractor information
            - Contract terms and conditions
            - Performance requirements
            - Payment schedules
            - Modification procedures
            """

        case .sf30:
            """
            Generate an SF-30 (Amendment of Solicitation/Modification of Contract) document.
            This form modifies existing contracts and must include:
            - Original contract identification
            - Modification details and rationale
            - Changed terms and conditions
            - Price adjustments
            - Effective dates
            """

        case .sf33:
            """
            Generate an SF-33 (Solicitation, Offer and Award) document.
            This comprehensive form handles the complete acquisition process:
            - Solicitation requirements
            - Offer acceptance procedures
            - Award criteria and process
            - Contract terms and conditions
            """

        case .sf44:
            """
            Generate an SF-44 (Purchase Order-Invoice-Voucher) document.
            This form handles simple purchases and must include:
            - Purchase order details
            - Item specifications and pricing
            - Delivery instructions
            - Invoice and payment information
            """

        case .dd1155:
            """
            Generate a DD-1155 (Order for Supplies or Services) document.
            This DoD-specific form orders supplies/services and must include:
            - Order details and specifications
            - Military-specific requirements
            - Security and clearance requirements
            - Delivery and performance terms
            """
        }
    }

    private func applyContextualization(
        prompt: String,
        context: AcquisitionContext
    ) -> String {
        var contextualizedPrompt = prompt

        // Add program-specific context
        contextualizedPrompt += "\n\nProgram Context:"
        contextualizedPrompt += "\n- Program Name: \(context.programName)"

        if let agency = context.agency {
            contextualizedPrompt += "\n- Agency: \(agency)"
        }

        if let contractValue = context.contractValue {
            contextualizedPrompt += "\n- Contract Value: $\(contractValue)"
        }

        return contextualizedPrompt
    }

    private func applyOptimizations(
        prompt: String,
        patterns: [PromptPattern]
    ) -> String {
        var optimizedPrompt = prompt

        for pattern in patterns {
            optimizedPrompt = optimizationEngine.applyPattern(
                prompt: optimizedPrompt,
                pattern: pattern
            )
        }

        return optimizedPrompt
    }

    private func generateCacheKey(
        documentType: AIDocumentType,
        context: AcquisitionContext,
        optimizations: [PromptPattern]
    ) -> String {
        let contextHash = "\(context.programName)-\(context.agency ?? "")"
        let optimizationsHash = optimizations.map(\.rawValue).joined(separator: "-")
        return "\(documentType.rawValue)-\(contextHash.hashValue)-\(optimizationsHash.hashValue)"
    }
}

// MARK: - Supporting Types

public struct PromptRequest: Sendable {
    public let documentType: AIDocumentType
    public let context: AcquisitionContext
    public let optimizations: [PromptPattern]

    public init(
        documentType: AIDocumentType,
        context: AcquisitionContext,
        optimizations: [PromptPattern] = []
    ) {
        self.documentType = documentType
        self.context = context
        self.optimizations = optimizations
    }
}

// PromptPattern is defined in LLMProviderProtocol.swift

// MARK: - Placeholder Dependencies (Will be implemented in GREEN phase)

public struct PromptCache: Sendable {
    public init() {}

    public func getPrompt(key _: String) -> String? {
        nil // No cache during RED phase
    }

    public func storePrompt(key _: String, prompt _: String) {
        // Cache storage will be implemented in GREEN phase
    }
}

public struct PromptOptimizationEngine: Sendable {
    public init() {}

    public func applyPattern(prompt: String, pattern: PromptPattern) -> String {
        switch pattern {
        case .concise:
            prompt + "\n\nProvide a concise, focused response."
        case .detailed:
            prompt + "\n\nProvide comprehensive details and explanations."
        case .governmentCompliance:
            prompt + "\n\nEnsure full compliance with Federal Acquisition Regulations (FAR)."
        case .technical:
            prompt + "\n\nInclude technical specifications and requirements."
        case .structured:
            prompt + "\n\nOrganize the response in a clear, structured format."
        case .conversational:
            prompt + "\n\nUse a professional but conversational tone."
        }
    }

    public func optimizeForProvider(
        prompt: String,
        provider: LLMProvider,
        documentType _: AIDocumentType
    ) -> String {
        switch provider {
        case .claude:
            prompt + "\n\n[Optimized for Claude's structured reasoning capabilities]"
        case .openAI:
            prompt + "\n\n[Optimized for GPT's creative and detailed outputs]"
        case .gemini:
            prompt + "\n\n[Optimized for Gemini's multimodal and analytical strengths]"
        default:
            prompt
        }
    }
}

public struct CompliancePatternEngine: Sendable {
    public init() {}

    public func applyCompliancePatterns(
        prompt: String,
        documentType _: AIDocumentType
    ) -> String {
        let complianceAddition = """

        CRITICAL COMPLIANCE REQUIREMENTS:
        - Must comply with Federal Acquisition Regulation (FAR)
        - Include all mandatory clauses and provisions
        - Ensure accessibility compliance (Section 508)
        - Follow security requirements for government contracts
        - Include proper contract administration procedures
        """

        return prompt + complianceAddition
    }
}
