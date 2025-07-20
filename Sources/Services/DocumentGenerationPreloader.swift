import AppCore
import ComposableArchitecture
import Foundation

/// Pre-loads templates, system prompts, and user profile in parallel to optimize document generation
public struct DocumentGenerationPreloader: Sendable {
    // MARK: - Dependencies

    @Dependency(\.documentGenerationCache) var cache
    @Dependency(\.standardTemplateService) var templateService
    @Dependency(\.dfTemplateService) var dfTemplateService
    @Dependency(\.userProfileService) var userProfileService

    // MARK: - Preload Data Structure

    public struct PreloadedData: Sendable {
        public let profile: UserProfile?
        public let templates: [DocumentType: String]
        public let dfTemplates: [DFDocumentType: DFTemplate]
        public let systemPrompts: [DocumentType: String]
        public let dfSystemPrompts: [DFDocumentType: String]

        public init(
            profile: UserProfile? = nil,
            templates: [DocumentType: String] = [:],
            dfTemplates: [DFDocumentType: DFTemplate] = [:],
            systemPrompts: [DocumentType: String] = [:],
            dfSystemPrompts: [DFDocumentType: String] = [:]
        ) {
            self.profile = profile
            self.templates = templates
            self.dfTemplates = dfTemplates
            self.systemPrompts = systemPrompts
            self.dfSystemPrompts = dfSystemPrompts
        }
    }

    // MARK: - Preload Methods

    /// Pre-load all required data for document generation in parallel
    public func preloadData(
        for documentTypes: Set<DocumentType>,
        dfDocumentTypes: Set<DFDocumentType>
    ) async throws -> PreloadedData {
        // Use TaskGroup to load everything in parallel
        try await withThrowingTaskGroup(of: PreloadComponent.self) { group in
            // Load user profile
            group.addTask {
                let profile = try? await userProfileService.loadProfile()
                return .profile(profile)
            }

            // Load templates in parallel
            for documentType in documentTypes {
                group.addTask {
                    let template = await loadTemplate(for: documentType)
                    return .template(documentType, template)
                }
            }

            // Load D&F templates in parallel
            for dfDocumentType in dfDocumentTypes {
                group.addTask {
                    let template = try? await dfTemplateService.loadTemplate(dfDocumentType)
                    return .dfTemplate(dfDocumentType, template)
                }
            }

            // Pre-generate system prompts in parallel
            for documentType in documentTypes {
                group.addTask {
                    let prompt = await loadSystemPrompt(for: documentType)
                    return .systemPrompt(documentType, prompt)
                }
            }

            // Pre-generate D&F system prompts in parallel
            for dfDocumentType in dfDocumentTypes {
                group.addTask {
                    let prompt = await loadDFSystemPrompt(for: dfDocumentType)
                    return .dfSystemPrompt(dfDocumentType, prompt)
                }
            }

            // Collect results
            var preloadedData = PreloadedData()

            for try await component in group {
                switch component {
                case let .profile(profile):
                    preloadedData = PreloadedData(
                        profile: profile,
                        templates: preloadedData.templates,
                        dfTemplates: preloadedData.dfTemplates,
                        systemPrompts: preloadedData.systemPrompts,
                        dfSystemPrompts: preloadedData.dfSystemPrompts
                    )

                case let .template(documentType, template):
                    if let template {
                        var templates = preloadedData.templates
                        templates[documentType] = template
                        preloadedData = PreloadedData(
                            profile: preloadedData.profile,
                            templates: templates,
                            dfTemplates: preloadedData.dfTemplates,
                            systemPrompts: preloadedData.systemPrompts,
                            dfSystemPrompts: preloadedData.dfSystemPrompts
                        )
                    }

                case let .dfTemplate(dfDocumentType, template):
                    if let template {
                        var dfTemplates = preloadedData.dfTemplates
                        dfTemplates[dfDocumentType] = template
                        preloadedData = PreloadedData(
                            profile: preloadedData.profile,
                            templates: preloadedData.templates,
                            dfTemplates: dfTemplates,
                            systemPrompts: preloadedData.systemPrompts,
                            dfSystemPrompts: preloadedData.dfSystemPrompts
                        )
                    }

                case let .systemPrompt(documentType, prompt):
                    var systemPrompts = preloadedData.systemPrompts
                    systemPrompts[documentType] = prompt
                    preloadedData = PreloadedData(
                        profile: preloadedData.profile,
                        templates: preloadedData.templates,
                        dfTemplates: preloadedData.dfTemplates,
                        systemPrompts: systemPrompts,
                        dfSystemPrompts: preloadedData.dfSystemPrompts
                    )

                case let .dfSystemPrompt(dfDocumentType, prompt):
                    var dfSystemPrompts = preloadedData.dfSystemPrompts
                    dfSystemPrompts[dfDocumentType] = prompt
                    preloadedData = PreloadedData(
                        profile: preloadedData.profile,
                        templates: preloadedData.templates,
                        dfTemplates: preloadedData.dfTemplates,
                        systemPrompts: preloadedData.systemPrompts,
                        dfSystemPrompts: dfSystemPrompts
                    )
                }
            }

            return preloadedData
        }
    }

    /// Batch pre-load cached documents
    public func preloadCachedDocuments(
        for documentTypes: Set<DocumentType>,
        requirements: String,
        profile: UserProfile?
    ) async -> [DocumentType: String] {
        let types = documentTypes.map { ($0, requirements) }
        let cachedResults = await cache.getCachedDocuments(for: types, profile: profile)

        return cachedResults.compactMapValues { $0 }
    }

    /// Batch pre-load cached D&F documents
    public func preloadCachedDFDocuments(
        for dfDocumentTypes: Set<DFDocumentType>,
        requirements: String,
        profile: UserProfile?
    ) async -> [DFDocumentType: String] {
        let types = dfDocumentTypes.map { ($0, requirements) }
        let cachedResults = await cache.getCachedDFDocuments(for: types, profile: profile)

        return cachedResults.compactMapValues { $0 }
    }

    // MARK: - Private Helper Methods

    private func loadTemplate(for documentType: DocumentType) async -> String? {
        // Check cache first
        if let cached = await cache.getCachedTemplate(for: documentType) {
            return cached
        }

        // Load from service
        if let template = try? await templateService.loadTemplate(documentType) {
            await cache.cacheTemplate(template, for: documentType)
            return template
        }

        return nil
    }

    private func loadSystemPrompt(for documentType: DocumentType) async -> String {
        // Check cache first
        if let cached = await cache.getCachedSystemPrompt(for: documentType) {
            return cached
        }

        // Generate and cache
        let prompt = AIDocumentGenerator.getSystemPrompt(for: documentType)
        await cache.cacheSystemPrompt(prompt, for: documentType)
        return prompt
    }

    private func loadDFSystemPrompt(for dfDocumentType: DFDocumentType) async -> String {
        // Check cache first
        if let cached = await cache.getCachedSystemPrompt(for: dfDocumentType) {
            return cached
        }

        // Generate and cache
        let prompt = AIDocumentGenerator.getDFSystemPrompt(for: dfDocumentType)
        await cache.cacheSystemPrompt(prompt, for: dfDocumentType)
        return prompt
    }

    // MARK: - Supporting Types

    private enum PreloadComponent: Sendable {
        case profile(UserProfile?)
        case template(DocumentType, String?)
        case dfTemplate(DFDocumentType, DFTemplate?)
        case systemPrompt(DocumentType, String)
        case dfSystemPrompt(DFDocumentType, String)
    }
}

// MARK: - Dependency Key

public struct DocumentGenerationPreloaderKey: DependencyKey, Sendable {
    public static let liveValue = DocumentGenerationPreloader()
    public static let testValue = DocumentGenerationPreloader()
}

public extension DependencyValues {
    var documentGenerationPreloader: DocumentGenerationPreloader {
        get { self[DocumentGenerationPreloaderKey.self] }
        set { self[DocumentGenerationPreloaderKey.self] = newValue }
    }
}
