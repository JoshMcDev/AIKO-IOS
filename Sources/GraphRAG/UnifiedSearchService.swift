import Foundation

/// Unified search service for cross-domain GraphRAG queries
actor UnifiedSearchService {
    private let lfm2Service = LFM2Service.shared
    private let semanticIndex = ObjectBoxSemanticIndex.shared
    private var userContexts: [String: UserSearchContext] = [:]

    init() {
        // Initialized for GREEN phase implementation
    }

    func performUnifiedSearch(
        query: String,
        domains: [SearchDomain],
        limit: Int
    ) async throws -> [UnifiedSearchResult] {
        var allResults: [UnifiedSearchResult] = []

        // Search in regulation domain if requested
        if domains.contains(.regulations) {
            // Generate embedding for regulations domain
            let regulationQueryEmbedding = try await lfm2Service.generateEmbedding(
                text: query,
                domain: .regulations
            )

            let regulationResults = try await semanticIndex.findSimilarRegulations(
                queryEmbedding: regulationQueryEmbedding,
                limit: limit,
                threshold: 0.15 // Adjusted threshold based on observed LFM2Service similarities
            )

            let unifiedResults = regulationResults.map { result in
                UnifiedSearchResult(
                    content: result.content,
                    domain: .regulations,
                    relevanceScore: calculateRelevanceScore(
                        query: query,
                        content: result.content,
                        embedding: result.embedding,
                        queryEmbedding: regulationQueryEmbedding
                    ),
                    metadata: SearchResultMetadata(
                        sourceType: "regulation",
                        timestamp: Date(),
                        documentId: result.regulationNumber
                    )
                )
            }
            allResults.append(contentsOf: unifiedResults)
        }

        // Search in user history domain if requested
        if domains.contains(.userHistory) {
            // Generate embedding for user records domain
            let userQueryEmbedding = try await lfm2Service.generateEmbedding(
                text: query,
                domain: .userRecords
            )

            let userResults = try await semanticIndex.findSimilarUserWorkflow(
                queryEmbedding: userQueryEmbedding,
                limit: limit,
                threshold: 0.15 // Adjusted threshold based on observed LFM2Service similarities
            )

            let unifiedResults = userResults.map { result in
                UnifiedSearchResult(
                    content: result.content,
                    domain: .userHistory,
                    relevanceScore: calculateRelevanceScore(
                        query: query,
                        content: result.content,
                        embedding: result.embedding,
                        queryEmbedding: userQueryEmbedding
                    ),
                    metadata: SearchResultMetadata(
                        sourceType: "user_workflow",
                        timestamp: Date(),
                        documentId: result.regulationNumber // Reusing field for workflow ID
                    )
                )
            }
            allResults.append(contentsOf: unifiedResults)
        }

        // Sort by relevance and limit results
        allResults.sort { $0.relevanceScore > $1.relevanceScore }
        return Array(allResults.prefix(limit))
    }

    func analyzeQueryRouting(query: String) async throws -> QueryRoutingResult {
        let queryLower = query.lowercased()
        var confidence: Float = 0.0
        var recommendedDomains: [SearchDomain] = []
        var reasoning = ""

        // Regulation-specific keywords
        let regulationKeywords = [
            "far", "dfars", "regulation", "compliance", "procurement", "contract",
            "clause", "requirement", "federal", "acquisition", "solicitation",
        ]

        // User workflow keywords
        let workflowKeywords = [
            "workflow", "process", "step", "procedure", "template", "form",
            "document", "submission", "approval", "review", "history",
        ]

        let regulationScore = regulationKeywords.reduce(0) { score, keyword in
            score + (queryLower.contains(keyword) ? 1 : 0)
        }

        let workflowScore = workflowKeywords.reduce(0) { score, keyword in
            score + (queryLower.contains(keyword) ? 1 : 0)
        }

        // Determine routing based on keyword matches
        // If both domains have significant matches OR the query is ambiguous, search both
        let minSignificantScore = 1 // At least 1 keyword match to be considered significant
        let bothDomainsSignificant = regulationScore >= minSignificantScore && workflowScore >= minSignificantScore
        let ambiguousQueries = ["procurement requirements", "compliance", "requirements"] // Known multi-domain queries
        let isAmbiguous = ambiguousQueries.contains { queryLower.contains($0) }

        if bothDomainsSignificant || isAmbiguous || regulationScore == workflowScore {
            // Search both domains for comprehensive results
            recommendedDomains = [.regulations, .userHistory]
            confidence = Float(max(regulationScore, workflowScore)) / Float(max(regulationKeywords.count, workflowKeywords.count))
            reasoning = "Query spans multiple domains or is ambiguous, searching both domains"
        } else if regulationScore > workflowScore {
            recommendedDomains = [.regulations]
            confidence = Float(regulationScore) / Float(regulationKeywords.count)
            reasoning = "Query contains regulation-specific terminology"
        } else if workflowScore > regulationScore {
            recommendedDomains = [.userHistory]
            confidence = Float(workflowScore) / Float(workflowKeywords.count)
            reasoning = "Query contains workflow-specific terminology"
        } else {
            // Fallback: search both domains
            recommendedDomains = [.regulations, .userHistory]
            confidence = 0.5
            reasoning = "Query is domain-neutral, searching both domains"
        }

        // Boost confidence for clear domain indicators
        if regulationScore >= 2 || workflowScore >= 2 {
            confidence = min(confidence * 1.5, 1.0)
        }

        return QueryRoutingResult(
            recommendedDomains: recommendedDomains,
            confidence: confidence,
            reasoning: reasoning
        )
    }

    func updateUserContext(_ context: UserSearchContext) async throws {
        userContexts[context.userId] = context
    }

    func performOptimizedSearch(
        query: String,
        userContext: UserSearchContext,
        limit: Int
    ) async throws -> [UnifiedSearchResult] {
        // Store user context for personalization
        try await updateUserContext(userContext)

        // Analyze query routing with user context
        let routing = try await analyzeQueryRouting(query: query)

        // Perform unified search
        var results = try await performUnifiedSearch(
            query: query,
            domains: routing.recommendedDomains,
            limit: limit * 2 // Get more results for personalization filtering
        )

        // Apply personalization based on user context
        results = applyPersonalization(results: results, userContext: userContext)

        // Re-sort and limit final results
        results.sort { $0.relevanceScore > $1.relevanceScore }
        return Array(results.prefix(limit))
    }

    // MARK: - Helper Methods

    private func calculateRelevanceScore(
        query: String,
        content: String,
        embedding: [Float],
        queryEmbedding: [Float]
    ) -> Float {
        // Calculate semantic similarity
        let semanticScore = cosineSimilarity(queryEmbedding, embedding)

        // Handle NaN case for semantic score
        let validSemanticScore = semanticScore.isNaN ? 0.0 : semanticScore

        // Calculate lexical similarity (keyword overlap)
        let queryWords = Set(query.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        let contentWords = Set(content.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        let intersection = queryWords.intersection(contentWords)
        let lexicalScore = queryWords.isEmpty ? 0.0 : Float(intersection.count) / Float(queryWords.count)

        // Combine scores (70% semantic, 30% lexical)
        let combinedScore = (validSemanticScore * 0.7) + (lexicalScore * 0.3)

        // Ensure we return a valid float (not NaN or infinity)
        return combinedScore.isFinite ? combinedScore : 0.0
    }

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0.0 }

        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        guard magnitudeA > 0, magnitudeB > 0 else { return 0.0 }

        return dotProduct / (magnitudeA * magnitudeB)
    }

    private func applyPersonalization(
        results: [UnifiedSearchResult],
        userContext: UserSearchContext
    ) -> [UnifiedSearchResult] {
        results.map { result in
            var personalizedResult = result
            var personalizedScore = result.relevanceScore

            // Boost scores for user's preferred document types
            if userContext.documentTypes.contains(result.metadata.sourceType) {
                personalizedScore *= 1.25
            }

            // Boost scores based on recent query similarity
            for recentQuery in userContext.recentQueries {
                let queryWords = Set(recentQuery.lowercased().components(separatedBy: .whitespacesAndNewlines))
                let contentWords = Set(result.content.lowercased().components(separatedBy: .whitespacesAndNewlines))
                let similarity = Float(queryWords.intersection(contentWords).count) / Float(max(queryWords.count, 1))

                if similarity > 0.3 {
                    personalizedScore *= (1.0 + similarity * 0.2)
                }
            }

            // Apply preference-based adjustments
            for (key, _) in userContext.preferences where result.content.lowercased().contains(key.lowercased()) {
                // Simple preference boost - in real implementation would be more sophisticated
                personalizedScore *= 1.1
            }

            personalizedResult = UnifiedSearchResult(
                content: result.content,
                domain: result.domain,
                relevanceScore: min(personalizedScore, 1.0), // Cap at 1.0
                metadata: result.metadata
            )

            return personalizedResult
        }
    }
}
