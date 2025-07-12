import Foundation
import ComposableArchitecture

// MARK: - Document Template Model

public struct DocumentTemplate: Identifiable, Codable, Equatable {
    public let metadata: UnifiedTemplateMetadata
    public let structure: DocumentStructure
    public let style: DocumentStyle
    
    public var id: String { metadata.id }
    
    public init(metadata: UnifiedTemplateMetadata, structure: DocumentStructure, style: DocumentStyle) {
        self.metadata = metadata
        self.structure = structure
        self.style = style
    }
}

public struct UnifiedTemplateMetadata: Codable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let documentType: DocumentType
    public let version: String
    public let tags: [String]
    public let isEditable: Bool
    public let isFavorite: Bool
    
    public init(
        id: String,
        name: String,
        description: String,
        documentType: DocumentType,
        version: String,
        tags: [String] = [],
        isEditable: Bool = true,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.documentType = documentType
        self.version = version
        self.tags = tags
        self.isEditable = isEditable
        self.isFavorite = isFavorite
    }
}

public struct DocumentStructure: Codable, Equatable {
    public let sections: [DocumentSection]
    
    public init(sections: [DocumentSection]) {
        self.sections = sections
    }
}

public struct DocumentSection: Codable, Equatable {
    public let id: String
    public let title: String
    public let description: String?
    public let fields: [DocumentField]
    public let isRequired: Bool
    public let order: Int
    
    public init(
        id: String,
        title: String,
        description: String? = nil,
        fields: [DocumentField],
        isRequired: Bool = true,
        order: Int
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.fields = fields
        self.isRequired = isRequired
        self.order = order
    }
}

public struct DocumentField: Codable, Equatable {
    public let id: String
    public let label: String
    public let type: FieldType
    public let placeholder: String?
    public let defaultValue: String?
    public let isRequired: Bool
    public let validation: FieldValidation?
    
    public enum FieldType: String, Codable, Equatable {
        case text
        case multilineText
        case number
        case date
        case dropdown
        case checkbox
        case radio
    }
    
    public init(
        id: String,
        label: String,
        type: FieldType,
        placeholder: String? = nil,
        defaultValue: String? = nil,
        isRequired: Bool = true,
        validation: FieldValidation? = nil
    ) {
        self.id = id
        self.label = label
        self.type = type
        self.placeholder = placeholder
        self.defaultValue = defaultValue
        self.isRequired = isRequired
        self.validation = validation
    }
}

public struct FieldValidation: Codable, Equatable {
    public let pattern: String?
    public let minLength: Int?
    public let maxLength: Int?
    public let minValue: Double?
    public let maxValue: Double?
    public let errorMessage: String
}

public struct DocumentStyle: Codable, Equatable {
    public let font: String
    public let fontSize: Double
    public let lineSpacing: Double
    public let margins: Margins
    
    public struct Margins: Codable, Equatable {
        public let top: Double
        public let bottom: Double
        public let left: Double
        public let right: Double
        
        public init(top: Double, bottom: Double, left: Double, right: Double) {
            self.top = top
            self.bottom = bottom
            self.left = left
            self.right = right
        }
    }
    
    public init(
        font: String = "Times New Roman",
        fontSize: Double = 12,
        lineSpacing: Double = 1.5,
        margins: Margins = .init(top: 1, bottom: 1, left: 1, right: 1)
    ) {
        self.font = font
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
        self.margins = margins
    }
}

/// Unified Template Service consolidating all template operations
public struct UnifiedTemplateService {
    // Template loading
    public var loadTemplate: (TemplateIdentifier) async throws -> DocumentTemplate
    public var loadAllTemplates: (TemplateCategory?) async throws -> [DocumentTemplate]
    
    // Template management
    public var saveCustomTemplate: (DocumentTemplate) async throws -> Void
    public var deleteCustomTemplate: (String) async throws -> Void
    public var updateTemplate: (DocumentTemplate) async throws -> Void
    
    // Template search and filtering
    public var searchTemplates: (String, TemplateCategory?) async throws -> [DocumentTemplate]
    public var getTemplatesByCategory: (TemplateCategory) async throws -> [DocumentTemplate]
    public var getRecentTemplates: (Int) async -> [DocumentTemplate]
    public var getFavoriteTemplates: () async -> [DocumentTemplate]
    
    // Template metadata
    public var toggleFavorite: (String) async throws -> Void
    public var recordTemplateUsage: (String) async throws -> Void
    public var getTemplateStatistics: (String) async -> TemplateStatistics?
    
    // Import/Export
    public var exportTemplate: (String) async throws -> Data
    public var importTemplate: (Data) async throws -> DocumentTemplate
    
    // Validation
    public var validateTemplate: (DocumentTemplate) async -> [ValidationIssue]
}

// MARK: - Unified Template Models

public struct TemplateIdentifier: Equatable, Codable {
    public let id: String
    public let category: TemplateCategory
    public let version: String?
    
    public init(id: String, category: TemplateCategory, version: String? = nil) {
        self.id = id
        self.category = category
        self.version = version
    }
}

public enum TemplateCategory: String, CaseIterable, Codable {
    case standard = "standard"
    case dataFreedom = "dataFreedom"
    case custom = "custom"
    case office = "office"
    case sla = "sla"
    case ota = "ota"
    case far = "far"
    case cmmc = "cmmc"
    
    public var displayName: String {
        switch self {
        case .standard: return "Standard Templates"
        case .dataFreedom: return "Data Freedom Templates"
        case .custom: return "Custom Templates"
        case .office: return "Office Templates"
        case .sla: return "Service Level Agreements"
        case .ota: return "Other Transaction Agreements"
        case .far: return "FAR Compliant"
        case .cmmc: return "CMMC Requirements"
        }
    }
}

public struct TemplateStatistics: Equatable {
    public let usageCount: Int
    public let lastUsed: Date?
    public let averageGenerationTime: TimeInterval
    public let successRate: Double
    public let popularFields: [String]
}

public struct ValidationIssue: Equatable {
    public enum Severity: String, Equatable {
        case error
        case warning
        case info
    }
    
    public let severity: Severity
    public let field: String?
    public let message: String
}

// MARK: - Unified Template Storage

actor UnifiedTemplateStorage {
    // Storage containers
    private var templateCache: [String: CachedTemplate] = [:]
    private var customTemplates: [String: DocumentTemplate] = [:]
    private var templateMetadata: [String: TemplateMetadata] = [:]
    
    // Standard template sources
    private let standardTemplates: [DocumentTemplate]
    private let dataFreedomTemplates: [DocumentTemplate]
    private let officeTemplates: [OfficeTemplate]
    
    // Configuration
    private let cacheExpiration: TimeInterval = 3600 // 1 hour
    private let maxCacheSize: Int = 100
    
    struct CachedTemplate {
        let template: DocumentTemplate
        let cachedAt: Date
        let category: TemplateCategory
    }
    
    struct TemplateMetadata: Codable {
        var isFavorite: Bool
        var usageCount: Int
        var lastUsed: Date?
        var totalGenerationTime: TimeInterval
        var successfulGenerations: Int
        var failedGenerations: Int
        var popularFields: [String: Int]
        
        var successRate: Double {
            let total = successfulGenerations + failedGenerations
            return total > 0 ? Double(successfulGenerations) / Double(total) : 1.0
        }
        
        var averageGenerationTime: TimeInterval {
            return successfulGenerations > 0 ? totalGenerationTime / Double(successfulGenerations) : 0
        }
    }
    
    init() async throws {
        // Load standard templates
        self.standardTemplates = try await Self.loadStandardTemplates()
        self.dataFreedomTemplates = try await Self.loadDataFreedomTemplates()
        self.officeTemplates = try await Self.loadOfficeTemplates()
        
        // Load custom templates from storage
        self.customTemplates = try await Self.loadCustomTemplates()
        
        // Load metadata
        self.templateMetadata = try await Self.loadTemplateMetadata()
    }
    
    // MARK: - Template Loading
    
    func loadTemplate(identifier: TemplateIdentifier) async throws -> DocumentTemplate {
        // Check cache first
        if let cached = templateCache[identifier.id],
           Date().timeIntervalSince(cached.cachedAt) < cacheExpiration {
            return cached.template
        }
        
        // Load based on category
        let template: DocumentTemplate
        
        switch identifier.category {
        case .standard:
            guard let standardTemplate = standardTemplates.first(where: { $0.metadata.id == identifier.id }) else {
                throw TemplateError.templateNotFound(identifier.id)
            }
            template = standardTemplate
            
        case .dataFreedom:
            guard let dfTemplate = dataFreedomTemplates.first(where: { $0.metadata.id == identifier.id }) else {
                throw TemplateError.templateNotFound(identifier.id)
            }
            template = dfTemplate
            
        case .custom:
            guard let customTemplate = customTemplates[identifier.id] else {
                throw TemplateError.templateNotFound(identifier.id)
            }
            template = customTemplate
            
        case .office:
            guard let officeData = officeTemplates.first(where: { $0.id == UUID(uuidString: identifier.id) }) else {
                throw TemplateError.templateNotFound(identifier.id)
            }
            template = try convertOfficeTemplate(officeData)
            
        case .sla:
            template = try await loadSLATemplate(identifier.id)
            
        case .ota:
            template = try await loadOTATemplate(identifier.id)
            
        case .far:
            template = try await loadFARTemplate(identifier.id)
            
        case .cmmc:
            template = try await loadCMMCTemplate(identifier.id)
        }
        
        // Cache the template
        await cacheTemplate(template, category: identifier.category)
        
        return template
    }
    
    func loadAllTemplates(category: TemplateCategory?) async throws -> [DocumentTemplate] {
        if let category = category {
            return try await loadTemplatesByCategory(category)
        }
        
        // Load all templates
        var allTemplates: [DocumentTemplate] = []
        
        for category in TemplateCategory.allCases {
            let categoryTemplates = try await loadTemplatesByCategory(category)
            allTemplates.append(contentsOf: categoryTemplates)
        }
        
        return allTemplates
    }
    
    private func loadTemplatesByCategory(_ category: TemplateCategory) async throws -> [DocumentTemplate] {
        switch category {
        case .standard:
            return standardTemplates
        case .dataFreedom:
            return dataFreedomTemplates
        case .custom:
            return Array(customTemplates.values)
        case .office:
            return try officeTemplates.map { try convertOfficeTemplate($0) }
        case .sla:
            return try await loadAllSLATemplates()
        case .ota:
            return try await loadAllOTATemplates()
        case .far:
            return try await loadAllFARTemplates()
        case .cmmc:
            return try await loadAllCMMCTemplates()
        }
    }
    
    // MARK: - Template Management
    
    func saveCustomTemplate(_ template: DocumentTemplate) async throws {
        // Validate template
        let issues = await validateTemplate(template)
        if issues.contains(where: { $0.severity == .error }) {
            throw TemplateError.validationFailed(issues)
        }
        
        // Save to custom templates
        customTemplates[template.metadata.id] = template
        
        // Initialize metadata if needed
        if templateMetadata[template.metadata.id] == nil {
            templateMetadata[template.metadata.id] = TemplateMetadata(
                isFavorite: false,
                usageCount: 0,
                lastUsed: nil,
                totalGenerationTime: 0,
                successfulGenerations: 0,
                failedGenerations: 0,
                popularFields: [:]
            )
        }
        
        // Persist to storage
        try await persistCustomTemplates()
    }
    
    func deleteCustomTemplate(_ templateId: String) async throws {
        guard customTemplates[templateId] != nil else {
            throw TemplateError.templateNotFound(templateId)
        }
        
        customTemplates.removeValue(forKey: templateId)
        templateMetadata.removeValue(forKey: templateId)
        
        // Remove from cache
        templateCache.removeValue(forKey: templateId)
        
        // Persist changes
        try await persistCustomTemplates()
        try await persistTemplateMetadata()
    }
    
    // MARK: - Search and Filter
    
    func searchTemplates(query: String, category: TemplateCategory?) async throws -> [DocumentTemplate] {
        let allTemplates = try await loadAllTemplates(category: category)
        
        guard !query.isEmpty else { return allTemplates }
        
        let lowercasedQuery = query.lowercased()
        
        return allTemplates.filter { template in
            template.metadata.name.lowercased().contains(lowercasedQuery) ||
            template.metadata.description.lowercased().contains(lowercasedQuery) ||
            template.metadata.tags.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }
    
    func getRecentTemplates(limit: Int) async -> [DocumentTemplate] {
        let recentIds = templateMetadata
            .compactMap { (id, metadata) -> (String, Date)? in
                guard let lastUsed = metadata.lastUsed else { return nil }
                return (id, lastUsed)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
        
        var recentTemplates: [DocumentTemplate] = []
        
        for id in recentIds {
            // Try to find template in any category
            if let template = try? await findTemplateById(id) {
                recentTemplates.append(template)
            }
        }
        
        return recentTemplates
    }
    
    func getFavoriteTemplates() async -> [DocumentTemplate] {
        let favoriteIds = templateMetadata
            .filter { $0.value.isFavorite }
            .map { $0.key }
        
        var favoriteTemplates: [DocumentTemplate] = []
        
        for id in favoriteIds {
            if let template = try? await findTemplateById(id) {
                favoriteTemplates.append(template)
            }
        }
        
        return favoriteTemplates
    }
    
    // MARK: - Metadata Operations
    
    func toggleFavorite(_ templateId: String) async throws {
        guard var metadata = templateMetadata[templateId] else {
            throw TemplateError.templateNotFound(templateId)
        }
        
        metadata.isFavorite.toggle()
        templateMetadata[templateId] = metadata
        
        try await persistTemplateMetadata()
    }
    
    func recordTemplateUsage(_ templateId: String, generationTime: TimeInterval, success: Bool) async throws {
        var metadata = templateMetadata[templateId] ?? TemplateMetadata(
            isFavorite: false,
            usageCount: 0,
            lastUsed: nil,
            totalGenerationTime: 0,
            successfulGenerations: 0,
            failedGenerations: 0,
            popularFields: [:]
        )
        
        metadata.usageCount += 1
        metadata.lastUsed = Date()
        
        if success {
            metadata.successfulGenerations += 1
            metadata.totalGenerationTime += generationTime
        } else {
            metadata.failedGenerations += 1
        }
        
        templateMetadata[templateId] = metadata
        
        try await persistTemplateMetadata()
    }
    
    func getTemplateStatistics(_ templateId: String) async -> TemplateStatistics? {
        guard let metadata = templateMetadata[templateId] else { return nil }
        
        return TemplateStatistics(
            usageCount: metadata.usageCount,
            lastUsed: metadata.lastUsed,
            averageGenerationTime: metadata.averageGenerationTime,
            successRate: metadata.successRate,
            popularFields: Array(metadata.popularFields.keys.sorted { 
                metadata.popularFields[$0]! > metadata.popularFields[$1]! 
            }.prefix(5))
        )
    }
    
    // MARK: - Validation
    
    func validateTemplate(_ template: DocumentTemplate) async -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // Check required fields
        if template.metadata.name.isEmpty {
            issues.append(ValidationIssue(
                severity: .error,
                field: "name",
                message: "Template name is required"
            ))
        }
        
        if template.metadata.description.isEmpty {
            issues.append(ValidationIssue(
                severity: .warning,
                field: "description",
                message: "Template description is recommended"
            ))
        }
        
        // Validate template structure
        if template.structure.sections.isEmpty {
            issues.append(ValidationIssue(
                severity: .error,
                field: "sections",
                message: "Template must have at least one section"
            ))
        }
        
        // Check for duplicate field IDs
        var fieldIds = Set<String>()
        for section in template.structure.sections {
            for field in section.fields {
                if fieldIds.contains(field.id) {
                    issues.append(ValidationIssue(
                        severity: .error,
                        field: field.id,
                        message: "Duplicate field ID: \(field.id)"
                    ))
                }
                fieldIds.insert(field.id)
            }
        }
        
        return issues
    }
    
    // MARK: - Helper Methods
    
    private func cacheTemplate(_ template: DocumentTemplate, category: TemplateCategory) async {
        let cached = CachedTemplate(
            template: template,
            cachedAt: Date(),
            category: category
        )
        
        templateCache[template.metadata.id] = cached
        
        // Enforce cache size limit
        if templateCache.count > maxCacheSize {
            // Remove oldest cached items
            let sortedCache = templateCache.sorted { $0.value.cachedAt < $1.value.cachedAt }
            let itemsToRemove = sortedCache.prefix(templateCache.count - maxCacheSize)
            
            for (key, _) in itemsToRemove {
                templateCache.removeValue(forKey: key)
            }
        }
    }
    
    private func findTemplateById(_ id: String) async throws -> DocumentTemplate? {
        // Check all categories
        for category in TemplateCategory.allCases {
            let identifier = TemplateIdentifier(id: id, category: category)
            if let template = try? await loadTemplate(identifier: identifier) {
                return template
            }
        }
        return nil
    }
    
    // MARK: - Template Conversion
    
    private func convertOfficeTemplate(_ officeData: OfficeTemplate) throws -> DocumentTemplate {
        // Convert office template format to unified format
        return DocumentTemplate(
            metadata: UnifiedTemplateMetadata(
                id: officeData.id.uuidString,
                name: officeData.officeName,
                description: officeData.description,
                documentType: officeData.documentType,
                version: "1.0",
                tags: [],
                isEditable: true,
                isFavorite: false
            ),
            structure: DocumentStructure(
                sections: [] // Convert office template sections
            ),
            style: DocumentStyle()
        )
    }
    
    // MARK: - Specialized Template Loading
    
    private func loadSLATemplate(_ id: String) async throws -> DocumentTemplate {
        // Load from SLATemplates
        throw TemplateError.categoryNotImplemented(.sla)
    }
    
    private func loadOTATemplate(_ id: String) async throws -> DocumentTemplate {
        // Load from OTAgreementTemplates
        throw TemplateError.categoryNotImplemented(.ota)
    }
    
    private func loadFARTemplate(_ id: String) async throws -> DocumentTemplate {
        // Load from FAR templates
        throw TemplateError.categoryNotImplemented(.far)
    }
    
    private func loadCMMCTemplate(_ id: String) async throws -> DocumentTemplate {
        // Load from CMMC templates
        throw TemplateError.categoryNotImplemented(.cmmc)
    }
    
    private func loadAllSLATemplates() async throws -> [DocumentTemplate] {
        return []
    }
    
    private func loadAllOTATemplates() async throws -> [DocumentTemplate] {
        return []
    }
    
    private func loadAllFARTemplates() async throws -> [DocumentTemplate] {
        return []
    }
    
    private func loadAllCMMCTemplates() async throws -> [DocumentTemplate] {
        return []
    }
    
    // MARK: - Persistence
    
    private static func loadStandardTemplates() async throws -> [DocumentTemplate] {
        // Create service instance
        let service = StandardTemplateService.liveValue
        var templates: [DocumentTemplate] = []
        
        // Convert each document type to a unified template
        for documentType in DocumentType.allCases {
            do {
                let _ = try await service.loadTemplate(documentType)
                let template = DocumentTemplate(
                    metadata: UnifiedTemplateMetadata(
                        id: "standard-\(documentType.rawValue)",
                        name: documentType.shortName,
                        description: documentType.description,
                        documentType: documentType,
                        version: "1.0",
                        tags: ["standard", documentType.rawValue],
                        isEditable: false,
                        isFavorite: false
                    ),
                    structure: DocumentStructure(sections: []), // Would need to parse template content
                    style: DocumentStyle()
                )
                templates.append(template)
            } catch {
                // Skip templates that fail to load
                print("Failed to load standard template for \(documentType.rawValue): \(error)")
            }
        }
        
        return templates
    }
    
    private static func loadDataFreedomTemplates() async throws -> [DocumentTemplate] {
        // Create service instance
        let service = DFTemplateService.liveValue
        let dfTemplates = try await service.loadAllTemplates()
        
        // Convert DF templates to unified format
        return dfTemplates.map { dfTemplate in
            DocumentTemplate(
                metadata: UnifiedTemplateMetadata(
                    id: "df-\(dfTemplate.type.rawValue)",
                    name: dfTemplate.type.rawValue,
                    description: dfTemplate.type.description,
                    documentType: .sow, // Map to appropriate document type
                    version: "1.0",
                    tags: ["dataFreedom", dfTemplate.type.rawValue],
                    isEditable: false,
                    isFavorite: false
                ),
                structure: DocumentStructure(sections: []), // Would need to parse template content
                style: DocumentStyle()
            )
        }
    }
    
    private static func loadOfficeTemplates() async throws -> [OfficeTemplate] {
        // Load office templates
        return []
    }
    
    private static func loadCustomTemplates() async throws -> [String: DocumentTemplate] {
        // Load from UserDefaults or file storage
        return [:]
    }
    
    private static func loadTemplateMetadata() async throws -> [String: TemplateMetadata] {
        // Load from UserDefaults
        return [:]
    }
    
    private func persistCustomTemplates() async throws {
        // Save to storage
    }
    
    private func persistTemplateMetadata() async throws {
        // Save to UserDefaults
    }
}

// MARK: - Template Errors

enum TemplateError: LocalizedError {
    case templateNotFound(String)
    case validationFailed([ValidationIssue])
    case categoryNotImplemented(TemplateCategory)
    case importFailed(String)
    case exportFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound(let id):
            return "Template not found: \(id)"
        case .validationFailed(let issues):
            let errors = issues.filter { $0.severity == .error }
            return "Template validation failed with \(errors.count) errors"
        case .categoryNotImplemented(let category):
            return "Template category not implemented: \(category.displayName)"
        case .importFailed(let reason):
            return "Failed to import template: \(reason)"
        case .exportFailed(let reason):
            return "Failed to export template: \(reason)"
        }
    }
}

// MARK: - Dependency Implementation

extension UnifiedTemplateService: DependencyKey {
    public static var liveValue: UnifiedTemplateService {
        let storage = Task {
            try await UnifiedTemplateStorage()
        }
        
        func getStorage() async throws -> UnifiedTemplateStorage {
            try await storage.value
        }
        
        return UnifiedTemplateService(
            loadTemplate: { identifier in
                let storage = try await getStorage()
                return try await storage.loadTemplate(identifier: identifier)
            },
            loadAllTemplates: { category in
                let storage = try await getStorage()
                return try await storage.loadAllTemplates(category: category)
            },
            saveCustomTemplate: { template in
                let storage = try await getStorage()
                try await storage.saveCustomTemplate(template)
            },
            deleteCustomTemplate: { templateId in
                let storage = try await getStorage()
                try await storage.deleteCustomTemplate(templateId)
            },
            updateTemplate: { template in
                let storage = try await getStorage()
                try await storage.saveCustomTemplate(template)
            },
            searchTemplates: { query, category in
                let storage = try await getStorage()
                return try await storage.searchTemplates(query: query, category: category)
            },
            getTemplatesByCategory: { category in
                let storage = try await getStorage()
                return try await storage.loadAllTemplates(category: category)
            },
            getRecentTemplates: { limit in
                guard let storage = try? await getStorage() else { return [] }
                return await storage.getRecentTemplates(limit: limit)
            },
            getFavoriteTemplates: {
                guard let storage = try? await getStorage() else { return [] }
                return await storage.getFavoriteTemplates()
            },
            toggleFavorite: { templateId in
                let storage = try await getStorage()
                try await storage.toggleFavorite(templateId)
            },
            recordTemplateUsage: { templateId in
                let storage = try await getStorage()
                try await storage.recordTemplateUsage(templateId, generationTime: 0, success: true)
            },
            getTemplateStatistics: { templateId in
                guard let storage = try? await getStorage() else { return nil }
                return await storage.getTemplateStatistics(templateId)
            },
            exportTemplate: { templateId in
                // Implementation for export
                return Data()
            },
            importTemplate: { data in
                // Implementation for import
                throw TemplateError.importFailed("Not implemented")
            },
            validateTemplate: { template in
                guard let storage = try? await getStorage() else { return [] }
                return await storage.validateTemplate(template)
            }
        )
    }
}

extension DependencyValues {
    public var unifiedTemplateService: UnifiedTemplateService {
        get { self[UnifiedTemplateService.self] }
        set { self[UnifiedTemplateService.self] = newValue }
    }
}