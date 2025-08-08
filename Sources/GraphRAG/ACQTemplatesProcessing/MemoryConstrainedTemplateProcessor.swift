import Foundation
import os.log

// MARK: - TemplateProcessingError

enum TemplateProcessingError: Error {
    case concurrencyViolation
    case memoryLimitExceeded
    case invalidChunkData
}

// MARK: - CategoryInferenceStrategy

/// Strategy pattern for template category inference
enum CategoryInferenceStrategy {
    // MARK: Internal

    /// Infer category from text using rule-based pattern matching
    static func infer(from text: String) -> TemplateCategory {
        for rule in categoryRules where rule.keywords.contains(where: text.contains) {
            return rule.category
        }
        return .contract
    }

    // MARK: Private

    private static let categoryRules: [(keywords: [String], category: TemplateCategory)] = [
        (["statement of work", "sow"], .statementOfWork),
        (["form", "evaluation"], .form),
        (["clause"], .clause),
        (["guide", "guidance"], .guide),
    ]
}

// MARK: - MemoryConstrainedTemplateProcessor

/// Memory-constrained template processor with actor-based concurrency
/// Implements strict 50MB memory limit enforcement during 256MB template processing
/// Uses single-chunk-in-flight policy to prevent memory spikes
@available(iOS 17.0, *)
actor MemoryConstrainedTemplateProcessor: TemplateProcessorProtocol {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(memoryPermitSystem: MemoryPermitSystem? = nil, useMemoryMapping: Bool = true) {
        self.memoryPermitSystem = memoryPermitSystem ?? MemoryPermitSystem(limitBytes: 50 * 1024 * 1024)
        self.useMemoryMapping = useMemoryMapping
        logger.info("MemoryConstrainedTemplateProcessor initialized with \(useMemoryMapping ? "memory mapping" : "standard") mode")
    }

    // MARK: Internal

    // MARK: - Template Processing

    func processTemplate(content: Data, metadata: TemplateMetadata) async throws -> ProcessedTemplate {
        logger.debug("Processing template: \(metadata.templateID), size: \(content.count) bytes")

        // Check if we need memory mapping for large content
        let shouldUseMemoryMapping = useMemoryMapping && content.count > 10 * 1024 * 1024 // 10MB threshold

        // Determine processing mode based on memory pressure
        let processingMode = await determineProcessingMode()
        currentProcessingMode = processingMode

        if shouldUseMemoryMapping {
            return try await processWithMemoryMapping(content: content, metadata: metadata, mode: processingMode)
        } else {
            return try await processInMemory(content: content, metadata: metadata, mode: processingMode)
        }
    }

    // MARK: - Memory Management

    func performMemoryCleanup() async {
        logger.debug("Performing memory cleanup...")

        // Clear memory-mapped files cache
        memoryMappedFiles.removeAll()

        // Reset processing state
        currentlyProcessingChunks.removeAll()
        currentProcessingMode = .normal

        // Trigger emergency memory release if needed
        let currentUsage = await memoryPermitSystem.usedBytes
        let limit = memoryPermitSystem.limitBytes

        if Double(currentUsage) / Double(limit) > 0.9 {
            await memoryPermitSystem.emergencyMemoryRelease()
        }

        logger.info("Memory cleanup completed")
    }

    // MARK: - Concurrency Management

    func getConcurrencyViolations() async -> Int {
        concurrencyViolations
    }

    // MARK: Private

    private let logger: Logger = .init(subsystem: "com.aiko.graphrag", category: "MemoryConstrainedTemplateProcessor")
    private let memoryPermitSystem: MemoryPermitSystem
    private let maxChunkSize = 4 * 1024 * 1024 // 4MB max chunk

    // Concurrency tracking
    private var concurrencyViolations: Int = 0
    private var currentlyProcessingChunks: Set<String> = []

    // Memory-mapped storage support
    private let useMemoryMapping: Bool
    private var memoryMappedFiles: [String: Data] = [:]

    /// Processing mode tracking
    private var currentProcessingMode: ProcessedTemplate.ProcessingMode = .normal

    private func processInMemory(content: Data, metadata: TemplateMetadata, mode: ProcessedTemplate.ProcessingMode) async throws -> ProcessedTemplate {
        // Split content into chunks
        let chunks = try await createChunks(from: content, metadata: metadata, memoryMapped: false)

        // Process chunks with single-chunk-in-flight policy
        let processedChunks = try await processChunksSequentially(chunks: chunks, metadata: metadata, content: content)

        // Infer category from content if not provided
        let inferredCategory = metadata.category ?? inferTemplateCategory(from: content)

        return ProcessedTemplate(
            chunks: processedChunks,
            category: inferredCategory,
            metadata: metadata,
            processingMode: mode
        )
    }

    private func processWithMemoryMapping(content: Data, metadata: TemplateMetadata, mode: ProcessedTemplate.ProcessingMode) async throws -> ProcessedTemplate {
        logger.debug("Using memory mapping for large template: \(metadata.templateID)")

        // Store content in memory-mapped cache
        memoryMappedFiles[metadata.templateID] = content

        // Create memory-mapped chunks
        let chunks = try await createMemoryMappedChunks(from: content, metadata: metadata)

        // Infer category from content if not provided
        let inferredCategory = metadata.category ?? inferTemplateCategory(from: content)

        return ProcessedTemplate(
            chunks: chunks,
            category: inferredCategory,
            metadata: metadata,
            processingMode: mode
        )
    }

    // MARK: - Chunk Creation

    private func createChunks(from content: Data, metadata _: TemplateMetadata, memoryMapped _: Bool) async throws -> [Data] {
        var chunks: [Data] = []
        let totalBytes = content.count

        var currentOffset = 0
        while currentOffset < totalBytes {
            let remainingBytes = totalBytes - currentOffset
            let chunkSize = min(maxChunkSize, remainingBytes)

            let chunkData = content.subdata(in: currentOffset ..< (currentOffset + chunkSize))
            chunks.append(chunkData)

            currentOffset += chunkSize
        }

        return chunks
    }

    private func createMemoryMappedChunks(from content: Data, metadata _: TemplateMetadata) async throws -> [TemplateChunk] {
        var chunks: [TemplateChunk] = []
        let totalBytes = content.count

        var currentOffset = 0
        var chunkIndex = 0

        while currentOffset < totalBytes {
            let remainingBytes = totalBytes - currentOffset
            let chunkSize = min(maxChunkSize, remainingBytes)
            let endOffset = currentOffset + chunkSize

            // Extract chunk content
            let chunkData = content.subdata(in: currentOffset ..< endOffset)
            let chunkContent = String(data: chunkData, encoding: .utf8) ?? ""

            // Create chunk metadata
            let chunkMetadata = ChunkMetadata(
                startOffset: currentOffset,
                endOffset: endOffset,
                tokens: estimateTokenCount(chunkData)
            )

            // Create memory-mapped chunk
            let chunk = TemplateChunk(
                content: chunkContent,
                chunkIndex: chunkIndex,
                overlap: "", // Memory-mapped chunks don't use overlap
                metadata: chunkMetadata,
                isMemoryMapped: true
            )

            chunks.append(chunk)

            currentOffset = endOffset
            chunkIndex += 1
        }

        return chunks
    }

    // MARK: - Processing Mode Determination

    private func determineProcessingMode() async -> ProcessedTemplate.ProcessingMode {
        let currentUsage = await memoryPermitSystem.usedBytes
        let limit = memoryPermitSystem.limitBytes
        let usagePercentage = Double(currentUsage) / Double(limit)

        if usagePercentage > 0.8 {
            return .memoryConstrained
        } else {
            return .normal
        }
    }

    // MARK: - Chunk Processing

    /// Process chunks sequentially with memory permits and concurrency control
    private func processChunksSequentially(chunks: [Data], metadata: TemplateMetadata, content: Data) async throws -> [TemplateChunk] {
        var processedChunks: [TemplateChunk] = []

        for (index, chunkContent) in chunks.enumerated() {
            let chunk = try await processSingleChunk(
                chunkContent: chunkContent,
                index: index,
                chunks: chunks,
                metadata: metadata,
                totalContent: content
            )
            processedChunks.append(chunk)
        }

        return processedChunks
    }

    /// Process a single chunk with memory permit management
    private func processSingleChunk(
        chunkContent: Data,
        index: Int,
        chunks: [Data],
        metadata: TemplateMetadata,
        totalContent: Data
    ) async throws -> TemplateChunk {
        let chunkID = "\(metadata.templateID)-\(index)"

        // Enforce single-chunk-in-flight policy
        try await enforceConcurrencyPolicy(chunkID: chunkID)
        defer { currentlyProcessingChunks.remove(chunkID) }

        // Process with memory permit
        return try await processWithMemoryPermit(
            chunkContent: chunkContent,
            index: index,
            chunks: chunks,
            totalContent: totalContent
        )
    }

    /// Enforce concurrency policy for chunk processing
    private func enforceConcurrencyPolicy(chunkID: String) async throws {
        guard !currentlyProcessingChunks.contains(chunkID) else {
            concurrencyViolations += 1
            logger.warning("Concurrency violation detected for chunk \(chunkID)")
            throw TemplateProcessingError.concurrencyViolation
        }

        currentlyProcessingChunks.insert(chunkID)
    }

    /// Process chunk with memory permit acquisition and release
    private func processWithMemoryPermit(
        chunkContent: Data,
        index: Int,
        chunks: [Data],
        totalContent: Data
    ) async throws -> TemplateChunk {
        // Acquire memory permit
        let chunkSize = Int64(chunkContent.count)
        let permit = try await memoryPermitSystem.acquire(bytes: chunkSize)
        defer {
            Task { await memoryPermitSystem.release(permit) }
        }

        // Create chunk metadata
        let chunkMetadata = createChunkMetadata(
            index: index,
            chunkContent: chunkContent,
            totalContent: totalContent
        )

        // Create template chunk
        return TemplateChunk(
            content: String(data: chunkContent, encoding: .utf8) ?? "",
            chunkIndex: index,
            overlap: generateOverlap(for: index, chunks: chunks),
            metadata: chunkMetadata,
            isMemoryMapped: false
        )
    }

    /// Create metadata for a chunk
    private func createChunkMetadata(index: Int, chunkContent: Data, totalContent: Data) -> ChunkMetadata {
        ChunkMetadata(
            startOffset: index * maxChunkSize,
            endOffset: min((index + 1) * maxChunkSize, totalContent.count),
            tokens: estimateTokenCount(chunkContent)
        )
    }

    // MARK: - Helper Methods

    private func estimateTokenCount(_ data: Data) -> Int {
        // Rough estimation: 4 characters per token
        data.count / 4
    }

    private func generateOverlap(for chunkIndex: Int, chunks: [Data]) -> String {
        guard chunkIndex > 0, chunkIndex < chunks.count else {
            return ""
        }

        // Generate overlap from previous chunk (last 100 characters)
        let previousChunk = chunks[chunkIndex - 1]
        let overlapLength = min(100, previousChunk.count)
        let overlapData = previousChunk.suffix(overlapLength)
        return String(data: overlapData, encoding: .utf8) ?? ""
    }

    private func inferTemplateCategory(from content: Data) -> TemplateCategory {
        guard let text = String(data: content, encoding: .utf8)?.lowercased() else {
            return .contract
        }

        return CategoryInferenceStrategy.infer(from: text)
    }
}
