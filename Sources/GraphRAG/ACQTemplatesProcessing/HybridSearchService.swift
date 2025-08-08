import Accelerate
import Foundation
import os.log
import SwiftUI

// MARK: - HybridSearchService

/// Hybrid Search Service implementing BM25 prefilter + vector reranking
/// Targets: P50 <10ms, P95 <20ms, P99 <50ms latency
@MainActor
final class HybridSearchService: ObservableObject {
    // MARK: Lifecycle

    // MARK: - Initialization

    init() {
        bm25Index = BM25Index()
        objectBoxIndex = ObjectBoxSemanticIndex.shared
        lfm2Service = LFM2Service.shared
        logger.info("HybridSearchService initialized")
    }

    // MARK: Internal

    // MARK: - Published Properties

    @Published var searchResults: [TemplateSearchResult] = []
    @Published var isSearching = false
    @Published var searchLatency: TimeInterval = 0

    // MARK: - Search Operations

    func hybridSearch(query: String, category: TemplateCategory?, limit: Int) async {
        let startTime = CFAbsoluteTimeGetCurrent()

        guard !query.isEmpty else {
            searchResults = []
            searchLatency = 0
            return
        }

        logger.debug("Starting hybrid search for: '\(query)', category: \(category?.rawValue ?? "all"), limit: \(limit)")

        isSearching = true
        defer { isSearching = false }

        do {
            // Check cache first
            let cacheKey = "\(query)-\(category?.rawValue ?? "all")-\(limit)"
            if let cachedResults = queryCache[cacheKey] {
                searchResults = cachedResults
                searchLatency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                return
            }

            // Step 1: BM25 Lexical Prefilter (target <2ms)
            let prefilterStartTime = CFAbsoluteTimeGetCurrent()
            let lexicalCandidates = try await performLexicalPrefilter(
                query: query,
                category: category,
                candidateLimit: min(1000, limit * 10) // Get 10x candidates for reranking
            )
            let prefilterTime = (CFAbsoluteTimeGetCurrent() - prefilterStartTime) * 1000
            logger.debug("Lexical prefilter completed in \(prefilterTime)ms, found \(lexicalCandidates.count) candidates")

            // Step 2: Vector Reranking (target <8ms)
            let rerankStartTime = CFAbsoluteTimeGetCurrent()
            let queryEmbedding = try await generateQueryEmbedding(query: query)
            let rerankedResults = try await performExactReranking(
                candidates: lexicalCandidates,
                queryEmbedding: queryEmbedding,
                limit: limit
            )
            let rerankTime = (CFAbsoluteTimeGetCurrent() - rerankStartTime) * 1000
            logger.debug("Vector reranking completed in \(rerankTime)ms")

            // Update results and cache
            searchResults = rerankedResults
            searchLatency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

            // Cache results for future queries
            cacheResults(key: cacheKey, results: rerankedResults)

            logger.info("Hybrid search completed in \(self.searchLatency)ms: prefilter=\(prefilterTime)ms, rerank=\(rerankTime)ms")

        } catch {
            logger.error("Hybrid search failed: \(error.localizedDescription)")
            searchResults = []
            searchLatency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        }
    }

    func performExactReranking(candidates: [LexicalCandidate], queryEmbedding: [Float], limit: Int) async throws -> [TemplateSearchResult] {
        guard !candidates.isEmpty else {
            return []
        }

        logger.debug("Reranking \(candidates.count) candidates with SIMD-optimized cosine similarity")

        // Process candidates in batches and compute scores
        let scoredResults = try await computeBatchedSimilarityScores(
            candidates: candidates,
            queryEmbedding: queryEmbedding
        )

        // Return top results sorted by hybrid score
        return extractTopResults(from: scoredResults, limit: limit)
    }

    // MARK: - Template Management

    func addTemplate(_ template: ProcessedTemplate) async throws {
        logger.debug("Adding template to search index: \(template.metadata.templateID)")

        // Add to BM25 index
        let fullContent = template.chunks.map(\.content).joined(separator: " ")
        await bm25Index.addDocument(
            template.metadata.templateID,
            content: fullContent,
            metadata: template.metadata
        )

        // Generate and store embedding
        let embedding = try await lfm2Service.generateEmbedding(text: fullContent)
        try await objectBoxIndex.storeTemplateEmbedding(
            content: fullContent,
            embedding: embedding,
            metadata: template.metadata
        )

        logger.debug("Template added to search index successfully")
    }

    // MARK: - Cache Management

    func clearAllCaches() async {
        logger.info("Clearing all search caches")
        queryCache.removeAll()
    }

    // MARK: Private

    // MARK: - Private Properties

    private let logger: Logger = .init(subsystem: "com.aiko.graphrag", category: "HybridSearchService")
    private let bm25Index: BM25Index
    private let objectBoxIndex: ObjectBoxSemanticIndex
    private let lfm2Service: LFM2Service

    // Cache for hot queries
    private var queryCache: [String: [TemplateSearchResult]] = [:]
    private let maxCacheSize = 100

    // MARK: - Lexical Prefiltering

    private func performLexicalPrefilter(query: String, category: TemplateCategory?, candidateLimit: Int) async throws -> [LexicalCandidate] {
        let filter = category.map { CategoryFilter.category($0) }
        return try await bm25Index.search(query: query, filter: filter, limit: candidateLimit)
    }

    // MARK: - Vector Operations

    private func generateQueryEmbedding(query: String) async throws -> [Float] {
        // Use LFM2Service to generate 384-dimensional embedding
        try await lfm2Service.generateEmbedding(text: query)
    }

    // MARK: - Batch Processing

    /// Compute similarity scores for candidates in batches
    private func computeBatchedSimilarityScores(
        candidates: [LexicalCandidate],
        queryEmbedding: [Float]
    ) async throws -> [(candidate: LexicalCandidate, score: Float)] {
        var scoredResults: [(candidate: LexicalCandidate, score: Float)] = []
        let batchSize = 100

        for batchStart in stride(from: 0, to: candidates.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, candidates.count)
            let batch = Array(candidates[batchStart ..< batchEnd])

            let batchScores = try await processBatch(
                batch: batch,
                queryEmbedding: queryEmbedding
            )
            scoredResults.append(contentsOf: batchScores)
        }

        return scoredResults
    }

    /// Process a single batch of candidates
    private func processBatch(
        batch: [LexicalCandidate],
        queryEmbedding: [Float]
    ) async throws -> [(candidate: LexicalCandidate, score: Float)] {
        // Get embeddings for batch
        let batchEmbeddings = try await getBatchEmbeddings(for: batch)

        // Compute hybrid scores for all candidates in batch
        return batch.enumerated().map { index, candidate in
            let similarity = computeCosineSimilarity(queryEmbedding, batchEmbeddings[index])
            let hybridScore = computeHybridScore(semantic: similarity, lexical: candidate.score)
            return (candidate: candidate, score: hybridScore)
        }
    }

    /// Compute hybrid score from semantic and lexical components
    private func computeHybridScore(semantic: Float, lexical: Float) -> Float {
        // 70% semantic, 30% lexical weighting
        Float(0.7) * semantic + Float(0.3) * lexical
    }

    /// Extract top results from scored candidates
    private func extractTopResults(
        from scoredResults: [(candidate: LexicalCandidate, score: Float)],
        limit: Int
    ) -> [TemplateSearchResult] {
        scoredResults
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { result in
                TemplateSearchResult(
                    template: result.candidate.metadata,
                    score: result.score,
                    snippet: result.candidate.snippet,
                    category: result.candidate.category,
                    crossReferences: [],
                    searchLatency: nil
                )
            }
    }

    private func getBatchEmbeddings(for candidates: [LexicalCandidate]) async throws -> [[Float]] {
        var embeddings: [[Float]] = []

        for candidate in candidates {
            // Try to get embedding from ObjectBox index first
            if let storedEmbedding = try await objectBoxIndex.getStoredEmbedding(for: candidate.templateID) {
                embeddings.append(storedEmbedding)
            } else {
                // Generate embedding if not stored
                let embedding = try await lfm2Service.generateEmbedding(text: candidate.snippet)
                embeddings.append(embedding)

                // Store for future use
                try await objectBoxIndex.storeTemplateEmbedding(
                    content: candidate.snippet,
                    embedding: embedding,
                    metadata: candidate.metadata
                )
            }
        }

        return embeddings
    }

    // MARK: - SIMD-Optimized Cosine Similarity

    private func computeCosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else {
            return 0.0
        }

        let count = vDSP_Length(a.count)
        var dotProduct: Float = 0
        var aNorm: Float = 0
        var bNorm: Float = 0

        // Use Accelerate framework for SIMD operations
        vDSP_dotpr(a, 1, b, 1, &dotProduct, count)
        vDSP_dotpr(a, 1, a, 1, &aNorm, count)
        vDSP_dotpr(b, 1, b, 1, &bNorm, count)

        let magnitude = sqrt(aNorm) * sqrt(bNorm)
        return magnitude > 0 ? dotProduct / magnitude : 0
    }

    private func cacheResults(key: String, results: [TemplateSearchResult]) {
        // Implement LRU cache eviction
        if queryCache.count >= maxCacheSize {
            let oldestKey = queryCache.keys.first
            if let key = oldestKey {
                queryCache.removeValue(forKey: key)
            }
        }

        queryCache[key] = results
    }
}

// MARK: - BM25Index

@MainActor
final class BM25Index {
    // MARK: Internal

    func addDocument(_ id: String, content: String, metadata: TemplateMetadata) async {
        let terms = tokenizeText(content)
        let termFrequencies = countTermFrequencies(terms)

        let document = BM25Document(
            id: id,
            content: content,
            metadata: metadata,
            terms: termFrequencies,
            length: terms.count
        )

        documents[id] = document
        updateVocabulary(for: document)
        updateAverageDocumentLength()

        logger.debug("Added document to BM25 index: \(id)")
    }

    func search(query: String, filter: CategoryFilter?, limit: Int) async throws -> [LexicalCandidate] {
        let queryTerms = tokenizeText(query)
        guard !queryTerms.isEmpty else {
            return []
        }

        var scores: [(id: String, score: Float)] = []

        for document in documents.values {
            // Apply category filter if specified
            if let filter, !filter.matches(document.metadata.category) {
                continue
            }

            let score = calculateBM25Score(queryTerms: queryTerms, document: document)
            scores.append((id: document.id, score: score))
        }

        // Sort by score and return top results
        let topResults = scores
            .sorted { $0.score > $1.score }
            .prefix(limit)

        return topResults.compactMap { result in
            guard let document = documents[result.id] else {
                return nil
            }

            return LexicalCandidate(
                templateID: result.id,
                score: result.score,
                metadata: document.metadata,
                snippet: generateSnippet(from: document.content, query: query),
                category: document.metadata.category ?? .contract
            )
        }
    }

    // MARK: Private

    private struct BM25Document {
        let id: String
        let content: String
        let metadata: TemplateMetadata
        let terms: [String: Int]
        let length: Int
    }

    private struct DocumentFrequency {
        let term: String
        var documentCount: Int
        var totalFrequency: Int
    }

    private let logger: Logger = .init(subsystem: "com.aiko.graphrag", category: "BM25Index")

    // BM25 parameters
    private let k1: Float = 1.2
    private let b: Float = 0.75

    // Document storage
    private var documents: [String: BM25Document] = [:]
    private var vocabulary: [String: DocumentFrequency] = [:]
    private var averageDocumentLength: Float = 0

    private func calculateBM25Score(queryTerms: [String], document: BM25Document) -> Float {
        queryTerms.reduce(Float(0)) { score, term in
            score + calculateTermScore(term: term, document: document)
        }
    }

    /// Calculate BM25 score contribution for a single term
    private func calculateTermScore(term: String, document: BM25Document) -> Float {
        guard let termFrequency = document.terms[term],
              let documentFrequency = vocabulary[term]
        else {
            return 0
        }

        let idf = calculateInverseDocumentFrequency(documentFrequency: documentFrequency)
        let tf = calculateTermFrequencyComponent(
            termFrequency: termFrequency,
            documentLength: document.length
        )

        return idf * tf
    }

    /// Calculate inverse document frequency (IDF) component
    private func calculateInverseDocumentFrequency(documentFrequency: DocumentFrequency) -> Float {
        log(Float(documents.count) / Float(documentFrequency.documentCount))
    }

    /// Calculate term frequency (TF) component with length normalization
    private func calculateTermFrequencyComponent(termFrequency: Int, documentLength: Int) -> Float {
        let tf = Float(termFrequency)
        let lengthNormalization = 1 - b + b * Float(documentLength) / averageDocumentLength

        let numerator = tf * (k1 + 1)
        let denominator = tf + k1 * lengthNormalization

        return numerator / denominator
    }

    private func tokenizeText(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .compactMap { word in
                let cleaned = word.trimmingCharacters(in: .punctuationCharacters)
                return cleaned.isEmpty ? nil : cleaned
            }
    }

    private func countTermFrequencies(_ terms: [String]) -> [String: Int] {
        var frequencies: [String: Int] = [:]
        for term in terms {
            frequencies[term, default: 0] += 1
        }
        return frequencies
    }

    private func updateVocabulary(for document: BM25Document) {
        for (term, frequency) in document.terms {
            if var existing = vocabulary[term] {
                existing.documentCount += 1
                existing.totalFrequency += frequency
                vocabulary[term] = existing
            } else {
                vocabulary[term] = DocumentFrequency(
                    term: term,
                    documentCount: 1,
                    totalFrequency: frequency
                )
            }
        }
    }

    private func updateAverageDocumentLength() {
        let totalLength = documents.values.map { Float($0.length) }.reduce(0, +)
        averageDocumentLength = totalLength / Float(documents.count)
    }

    private func generateSnippet(from content: String, query: String) -> String {
        let queryTerms = Set(tokenizeText(query))
        let sentences = content.components(separatedBy: ". ")

        // Find sentence with most query terms
        var bestSentence = sentences.first ?? ""
        var maxMatches = 0

        for sentence in sentences {
            let sentenceTerms = Set(tokenizeText(sentence))
            let matches = queryTerms.intersection(sentenceTerms).count

            if matches > maxMatches {
                maxMatches = matches
                bestSentence = sentence
            }
        }

        // Truncate to reasonable length
        return String(bestSentence.prefix(200))
    }
}
