import AikoCompat
import AppCore
import ComposableArchitecture
import Foundation

/// Batch document generation service that combines multiple document requests into single API calls
public struct BatchDocumentGenerator: Sendable {
    // MARK: - Configuration

    /// Maximum documents per batch API call
    private let maxDocumentsPerBatch = 5

    /// Maximum total tokens per batch (to stay within API limits)
    private let maxTokensPerBatch = 8192

    // MARK: - Dependencies

    @Dependency(\.documentGenerationCache) var cache
    @Dependency(\.userProfileService) var userProfileService
    @Dependency(\.spellCheckService) var spellCheckService
    @Dependency(\.standardTemplateService) var templateService
    @Dependency(\.dfTemplateService) var dfTemplateService

    // MARK: - Batch Generation Types

    public struct BatchRequest {
        let documentType: DocumentType
        let requirements: String
        let template: String?
        let systemPrompt: String
    }

    public struct DFBatchRequest {
        let dfDocumentType: DFDocumentType
        let requirements: String
        let template: DFTemplate
        let systemPrompt: String
    }

    // MARK: - Batch Generation Methods

    /// Generate multiple documents in a single API call
    public func generateDocumentsBatch(
        requirements: String,
        documentTypes: Set<DocumentType>,
        profile: UserProfile?
    ) async throws -> [GeneratedDocument] {
        // Filter out cached documents
        var documentsToGenerate: [DocumentType] = []
        var cachedDocuments: [GeneratedDocument] = []

        for documentType in documentTypes {
            if let cachedContent = await cache.getCachedDocument(
                for: documentType,
                requirements: requirements,
                profile: profile
            ) {
                let document = GeneratedDocument(
                    title: "\(documentType.shortName) - \(Date().formatted(date: .abbreviated, time: .omitted))",
                    documentType: documentType,
                    content: cachedContent
                )
                cachedDocuments.append(document)
            } else {
                documentsToGenerate.append(documentType)
            }
        }

        if documentsToGenerate.isEmpty {
            return cachedDocuments
        }

        // Prepare batch requests
        let batchRequests = try await prepareBatchRequests(
            documentTypes: documentsToGenerate,
            requirements: requirements,
            profile: profile
        )

        // Process in batches
        let generatedDocuments = try await processBatches(
            requests: batchRequests,
            requirements: requirements,
            profile: profile
        )

        return cachedDocuments + generatedDocuments
    }

    /// Generate D&F documents in batch
    public func generateDFDocumentsBatch(
        requirements: String,
        dfDocumentTypes: Set<DFDocumentType>,
        profile: UserProfile?
    ) async throws -> [GeneratedDocument] {
        // Filter out cached documents
        var documentsToGenerate: [DFDocumentType] = []
        var cachedDocuments: [GeneratedDocument] = []

        for dfDocumentType in dfDocumentTypes {
            if let cachedContent = await cache.getCachedDocument(
                for: dfDocumentType,
                requirements: requirements,
                profile: profile
            ) {
                let document = GeneratedDocument(
                    title: "\(dfDocumentType.shortName) D&F - \(Date().formatted(date: .abbreviated, time: .omitted))",
                    dfDocumentType: dfDocumentType,
                    content: cachedContent
                )
                cachedDocuments.append(document)
            } else {
                documentsToGenerate.append(dfDocumentType)
            }
        }

        if documentsToGenerate.isEmpty {
            return cachedDocuments
        }

        // Prepare batch requests
        let batchRequests = try await prepareDFBatchRequests(
            dfDocumentTypes: documentsToGenerate,
            requirements: requirements,
            profile: profile
        )

        // Process in batches
        let generatedDocuments = try await processDFBatches(
            requests: batchRequests,
            requirements: requirements,
            profile: profile
        )

        return cachedDocuments + generatedDocuments
    }

    // MARK: - Private Methods

    private func prepareBatchRequests(
        documentTypes: [DocumentType],
        requirements: String,
        profile: UserProfile?
    ) async throws -> [BatchRequest] {
        var requests: [BatchRequest] = []

        for documentType in documentTypes {
            // Load template
            let template: String?
            if let cachedTemplate = await cache.getCachedTemplate(for: documentType) {
                template = cachedTemplate
            } else if let loadedTemplate = try? await templateService.loadTemplate(documentType) {
                await cache.cacheTemplate(loadedTemplate, for: documentType)
                template = loadedTemplate
            } else {
                template = nil
            }

            // Process template with profile variables
            var processedTemplate = template
            if template != nil, let profile {
                for (key, value) in profile.templateVariables {
                    processedTemplate = processedTemplate?.replacingOccurrences(of: "{{\(key)}}", with: value)
                }
            }

            // Get system prompt
            let systemPrompt: String
            if let cachedPrompt = await cache.getCachedSystemPrompt(for: documentType) {
                systemPrompt = cachedPrompt
            } else {
                systemPrompt = AIDocumentGenerator.getSystemPrompt(for: documentType)
                await cache.cacheSystemPrompt(systemPrompt, for: documentType)
            }

            requests.append(BatchRequest(
                documentType: documentType,
                requirements: requirements,
                template: processedTemplate,
                systemPrompt: systemPrompt
            ))
        }

        return requests
    }

    private func prepareDFBatchRequests(
        dfDocumentTypes: [DFDocumentType],
        requirements: String,
        profile: UserProfile?
    ) async throws -> [DFBatchRequest] {
        var requests: [DFBatchRequest] = []

        for dfDocumentType in dfDocumentTypes {
            // Load template
            let dfTemplate = try await dfTemplateService.loadTemplate(dfDocumentType)

            // Process template with profile variables
            var processedTemplate = dfTemplate.template
            if let profile {
                for (key, value) in profile.templateVariables {
                    processedTemplate = processedTemplate.replacingOccurrences(of: "{{\(key)}}", with: value)
                }
            }

            // Get system prompt
            let systemPrompt: String
            if let cachedPrompt = await cache.getCachedSystemPrompt(for: dfDocumentType) {
                systemPrompt = cachedPrompt
            } else {
                systemPrompt = AIDocumentGenerator.getDFSystemPrompt(for: dfDocumentType)
                await cache.cacheSystemPrompt(systemPrompt, for: dfDocumentType)
            }

            let modifiedTemplate = DFTemplate(
                type: dfDocumentType,
                template: processedTemplate,
                quickReferenceGuide: dfTemplate.quickReferenceGuide
            )

            requests.append(DFBatchRequest(
                dfDocumentType: dfDocumentType,
                requirements: requirements,
                template: modifiedTemplate,
                systemPrompt: systemPrompt
            ))
        }

        return requests
    }

    private func processBatches(
        requests: [BatchRequest],
        requirements: String,
        profile: UserProfile?
    ) async throws -> [GeneratedDocument] {
        guard let aiProvider = await AIProviderFactory.defaultProvider() else {
            throw BatchDocumentGeneratorError.noProvider
        }

        var allDocuments: [GeneratedDocument] = []

        // Process requests in batches
        for batchStart in stride(from: 0, to: requests.count, by: maxDocumentsPerBatch) {
            let batchEnd = min(batchStart + maxDocumentsPerBatch, requests.count)
            let batch = Array(requests[batchStart ..< batchEnd])

            // Create combined batch prompt
            let batchPrompt = createBatchPrompt(for: batch, profile: profile)
            let combinedSystemPrompt = createCombinedSystemPrompt(for: batch)

            let messages = [
                AIMessage.user(batchPrompt),
            ]

            let request = AICompletionRequest(
                messages: messages,
                model: "claude-sonnet-4-20250514",
                maxTokens: maxTokensPerBatch,
                systemPrompt: combinedSystemPrompt
            )

            let result = try await aiProvider.complete(request)

            // Parse batch response
            let documents = try await parseBatchResponse(
                result: result,
                batch: batch,
                requirements: requirements,
                profile: profile
            )

            allDocuments.append(contentsOf: documents)

            // Small delay between batches
            if batchEnd < requests.count {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }

        return allDocuments
    }

    private func processDFBatches(
        requests: [DFBatchRequest],
        requirements: String,
        profile: UserProfile?
    ) async throws -> [GeneratedDocument] {
        guard let aiProvider = await AIProviderFactory.defaultProvider() else {
            throw BatchDocumentGeneratorError.noProvider
        }

        var allDocuments: [GeneratedDocument] = []

        // Process requests in batches
        for batchStart in stride(from: 0, to: requests.count, by: maxDocumentsPerBatch) {
            let batchEnd = min(batchStart + maxDocumentsPerBatch, requests.count)
            let batch = Array(requests[batchStart ..< batchEnd])

            // Create combined batch prompt
            let batchPrompt = createDFBatchPrompt(for: batch, profile: profile)
            let combinedSystemPrompt = createDFCombinedSystemPrompt(for: batch)

            let messages = [
                AIMessage.user(batchPrompt),
            ]

            let request = AICompletionRequest(
                messages: messages,
                model: "claude-sonnet-4-20250514",
                maxTokens: maxTokensPerBatch,
                systemPrompt: combinedSystemPrompt
            )

            let result = try await aiProvider.complete(request)

            // Parse batch response
            let documents = try await parseDFBatchResponse(
                result: result,
                batch: batch,
                requirements: requirements,
                profile: profile
            )

            allDocuments.append(contentsOf: documents)

            // Small delay between batches
            if batchEnd < requests.count {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }

        return allDocuments
    }

    // MARK: - Batch Prompt Creation

    private func createBatchPrompt(for batch: [BatchRequest], profile: UserProfile?) -> String {
        var prompt = """
        You need to generate multiple government acquisition documents in a single response.
        Each document should be complete and properly formatted.

        REQUIREMENTS:
        \(batch.first?.requirements ?? "")

        """

        if let profile {
            prompt += """

            USER PROFILE INFORMATION:
            Full Name: \(profile.fullName)
            Title: \(profile.title)
            Organization: \(profile.organizationName)
            DODAAC: \(profile.organizationalDODAAC)
            Email: \(profile.email)
            Phone: \(profile.phoneNumber)

            """
        }

        prompt += """

        Please generate the following documents:

        """

        for (index, request) in batch.enumerated() {
            prompt += """

            === DOCUMENT \(index + 1): \(request.documentType.rawValue) ===

            """

            if let template = request.template {
                prompt += """
                Use this template:
                \(template)

                """
            }

            prompt += """
            Please generate a complete \(request.documentType.shortName) document.
            Mark the start with: [START_DOCUMENT_\(index + 1)]
            Mark the end with: [END_DOCUMENT_\(index + 1)]

            """
        }

        return prompt
    }

    private func createDFBatchPrompt(for batch: [DFBatchRequest], profile: UserProfile?) -> String {
        var prompt = """
        You need to generate multiple Determination and Findings (D&F) documents in a single response.
        Each document should be complete and properly formatted.

        REQUIREMENTS:
        \(batch.first?.requirements ?? "")

        """

        if let profile {
            prompt += """

            USER PROFILE INFORMATION:
            Full Name: \(profile.fullName)
            Title: \(profile.title)
            Organization: \(profile.organizationName)
            DODAAC: \(profile.organizationalDODAAC)
            Email: \(profile.email)
            Phone: \(profile.phoneNumber)

            """
        }

        prompt += """

        Please generate the following D&F documents:

        """

        for (index, request) in batch.enumerated() {
            prompt += """

            === D&F DOCUMENT \(index + 1): \(request.dfDocumentType.rawValue) ===

            QUICK REFERENCE GUIDE:
            \(request.template.quickReferenceGuide)

            TEMPLATE TO FOLLOW:
            \(request.template.template)

            Please generate a complete \(request.dfDocumentType.shortName) D&F document.
            Mark the start with: [START_DF_DOCUMENT_\(index + 1)]
            Mark the end with: [END_DF_DOCUMENT_\(index + 1)]

            """
        }

        return prompt
    }

    private func createCombinedSystemPrompt(for _: [BatchRequest]) -> String {
        """
        You are an expert federal contracting officer generating multiple acquisition documents.
        Each document must be complete, professional, and compliant with FAR regulations.
        Generate all requested documents in a single response, clearly marking the boundaries of each document.
        Maintain consistency across all documents while ensuring each is tailored to its specific purpose.
        """
    }

    private func createDFCombinedSystemPrompt(for _: [DFBatchRequest]) -> String {
        """
        You are an expert federal contracting officer specializing in Determination and Findings (D&F) documents.
        Generate all requested D&F documents in a single response, ensuring each is legally sound and compliant.
        Each document must follow its specific template and include all required elements.
        Maintain consistency across all documents while ensuring each addresses its specific regulatory requirements.
        """
    }

    // MARK: - Response Parsing

    private func parseBatchResponse(
        result: AICompletionResponse,
        batch: [BatchRequest],
        requirements: String,
        profile: UserProfile?
    ) async throws -> [GeneratedDocument] {
        let fullResponse = result.content

        var documents: [GeneratedDocument] = []

        for (index, request) in batch.enumerated() {
            let startMarker = "[START_DOCUMENT_\(index + 1)]"
            let endMarker = "[END_DOCUMENT_\(index + 1)]"

            if let startRange = fullResponse.range(of: startMarker),
               let endRange = fullResponse.range(of: endMarker) {
                let contentStart = fullResponse.index(startRange.upperBound, offsetBy: 1)
                let contentEnd = fullResponse.index(endRange.lowerBound, offsetBy: -1)

                if contentStart < contentEnd {
                    let content = String(fullResponse[contentStart ..< contentEnd]).trimmingCharacters(in: .whitespacesAndNewlines)

                    // Spell check
                    let correctedContent = await spellCheckService.checkAndCorrect(content)

                    // Cache the result
                    await cache.cacheDocument(
                        correctedContent,
                        for: request.documentType,
                        requirements: requirements,
                        profile: profile
                    )

                    let document = GeneratedDocument(
                        title: "\(request.documentType.shortName) - \(Date().formatted(date: .abbreviated, time: .omitted))",
                        documentType: request.documentType,
                        content: correctedContent
                    )

                    documents.append(document)
                }
            }
        }

        return documents
    }

    private func parseDFBatchResponse(
        result: AICompletionResponse,
        batch: [DFBatchRequest],
        requirements: String,
        profile: UserProfile?
    ) async throws -> [GeneratedDocument] {
        let fullResponse = result.content

        var documents: [GeneratedDocument] = []

        for (index, request) in batch.enumerated() {
            let startMarker = "[START_DF_DOCUMENT_\(index + 1)]"
            let endMarker = "[END_DF_DOCUMENT_\(index + 1)]"

            if let startRange = fullResponse.range(of: startMarker),
               let endRange = fullResponse.range(of: endMarker) {
                let contentStart = fullResponse.index(startRange.upperBound, offsetBy: 1)
                let contentEnd = fullResponse.index(endRange.lowerBound, offsetBy: -1)

                if contentStart < contentEnd {
                    let content = String(fullResponse[contentStart ..< contentEnd]).trimmingCharacters(in: .whitespacesAndNewlines)

                    // Spell check
                    let correctedContent = await spellCheckService.checkAndCorrect(content)

                    // Cache the result
                    await cache.cacheDocument(
                        correctedContent,
                        for: request.dfDocumentType,
                        requirements: requirements,
                        profile: profile
                    )

                    let document = GeneratedDocument(
                        title: "\(request.dfDocumentType.shortName) D&F - \(Date().formatted(date: .abbreviated, time: .omitted))",
                        dfDocumentType: request.dfDocumentType,
                        content: correctedContent
                    )

                    documents.append(document)
                }
            }
        }

        return documents
    }
}

public enum BatchDocumentGeneratorError: Error {
    case noProvider
}

// MARK: - Dependency Key

public struct BatchDocumentGeneratorKey: DependencyKey {
    public static let liveValue = BatchDocumentGenerator()
    public static let testValue = BatchDocumentGenerator()
}

public extension DependencyValues {
    var batchDocumentGenerator: BatchDocumentGenerator {
        get { self[BatchDocumentGeneratorKey.self] }
        set { self[BatchDocumentGeneratorKey.self] = newValue }
    }
}
