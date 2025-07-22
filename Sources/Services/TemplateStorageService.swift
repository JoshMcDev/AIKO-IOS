import AppCore
import ComposableArchitecture
import Foundation

/// Service for managing custom template storage
public struct TemplateStorageService: Sendable {
    public var saveTemplate: @Sendable (CustomTemplate) async throws -> Void
    public var loadTemplates: @Sendable () async throws -> [CustomTemplate]
    public var deleteTemplate: @Sendable (UUID) async throws -> Void
    public var saveEditedTemplate: @Sendable (DocumentType, String) async throws -> Void
    public var loadEditedTemplate: @Sendable (DocumentType) async throws -> String?
    public var saveOfficeTemplate: @Sendable (OfficeTemplate) async throws -> Void
    public var loadOfficeTemplates: @Sendable (DocumentType) async throws -> [OfficeTemplate]

    public init(
        saveTemplate: @escaping @Sendable (CustomTemplate) async throws -> Void,
        loadTemplates: @escaping @Sendable () async throws -> [CustomTemplate],
        deleteTemplate: @escaping @Sendable (UUID) async throws -> Void,
        saveEditedTemplate: @escaping @Sendable (DocumentType, String) async throws -> Void,
        loadEditedTemplate: @escaping @Sendable (DocumentType) async throws -> String?,
        saveOfficeTemplate: @escaping @Sendable (OfficeTemplate) async throws -> Void,
        loadOfficeTemplates: @escaping @Sendable (DocumentType) async throws -> [OfficeTemplate]
    ) {
        self.saveTemplate = saveTemplate
        self.loadTemplates = loadTemplates
        self.deleteTemplate = deleteTemplate
        self.saveEditedTemplate = saveEditedTemplate
        self.loadEditedTemplate = loadEditedTemplate
        self.saveOfficeTemplate = saveOfficeTemplate
        self.loadOfficeTemplates = loadOfficeTemplates
    }
}

// MARK: - Models

public struct CustomTemplate: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let category: String
    public let description: String
    public let content: String
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        description: String,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct OfficeTemplate: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let documentType: DocumentType
    public let officeName: String
    public let description: String
    public let content: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        documentType: DocumentType,
        officeName: String,
        description: String,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.documentType = documentType
        self.officeName = officeName
        self.description = description
        self.content = content
        self.createdAt = createdAt
    }
}

// MARK: - Dependency Implementation

extension TemplateStorageService: DependencyKey {
    public static var liveValue: TemplateStorageService {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access documents directory")
        }
        let templatesPath = documentsPath.appendingPathComponent("Templates")
        let customTemplatesPath = templatesPath.appendingPathComponent("Custom")
        let editedTemplatesPath = templatesPath.appendingPathComponent("Edited")
        let officeTemplatesPath = templatesPath.appendingPathComponent("Office")

        // Create directories if they don't exist
        try? FileManager.default.createDirectory(at: customTemplatesPath, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: editedTemplatesPath, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: officeTemplatesPath, withIntermediateDirectories: true)

        return TemplateStorageService(
            saveTemplate: { template in
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(template)
                let fileURL = customTemplatesPath.appendingPathComponent("\(template.id.uuidString).json")
                try data.write(to: fileURL)
            },

            loadTemplates: {
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: customTemplatesPath,
                    includingPropertiesForKeys: nil
                ).filter { $0.pathExtension == "json" }

                let decoder = JSONDecoder()
                return try fileURLs.compactMap { url in
                    let data = try Data(contentsOf: url)
                    return try decoder.decode(CustomTemplate.self, from: data)
                }.sorted { $0.createdAt > $1.createdAt }
            },

            deleteTemplate: { id in
                let fileURL = customTemplatesPath.appendingPathComponent("\(id.uuidString).json")
                try FileManager.default.removeItem(at: fileURL)
            },

            saveEditedTemplate: { documentType, content in
                let fileURL = editedTemplatesPath.appendingPathComponent("\(documentType.rawValue).txt")
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
            },

            loadEditedTemplate: { documentType in
                let fileURL = editedTemplatesPath.appendingPathComponent("\(documentType.rawValue).txt")
                guard FileManager.default.fileExists(atPath: fileURL.path) else {
                    return nil
                }
                return try String(contentsOf: fileURL, encoding: .utf8)
            },

            saveOfficeTemplate: { template in
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(template)
                let fileURL = officeTemplatesPath.appendingPathComponent("\(template.id.uuidString).json")
                try data.write(to: fileURL)
            },

            loadOfficeTemplates: { documentType in
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: officeTemplatesPath,
                    includingPropertiesForKeys: nil
                ).filter { $0.pathExtension == "json" }

                let decoder = JSONDecoder()
                return try fileURLs.compactMap { url in
                    let data = try Data(contentsOf: url)
                    return try decoder.decode(OfficeTemplate.self, from: data)
                }.filter { $0.documentType == documentType }
                    .sorted { $0.createdAt > $1.createdAt }
            }
        )
    }

    public static var testValue: TemplateStorageService {
        let storage = TestTemplateStorage()

        return TemplateStorageService(
            saveTemplate: { template in
                await storage.saveTemplate(template)
            },
            loadTemplates: {
                await storage.loadTemplates()
            },
            deleteTemplate: { id in
                await storage.deleteTemplate(id)
            },
            saveEditedTemplate: { documentType, content in
                await storage.saveEditedTemplate(documentType, content)
            },
            loadEditedTemplate: { documentType in
                await storage.loadEditedTemplate(documentType)
            },
            saveOfficeTemplate: { template in
                await storage.saveOfficeTemplate(template)
            },
            loadOfficeTemplates: { documentType in
                await storage.loadOfficeTemplates(documentType)
            }
        )
    }
}

// MARK: - Test Storage Actor

actor TestTemplateStorage {
    private var savedTemplates: [CustomTemplate] = []
    private var editedTemplates: [DocumentType: String] = [:]
    private var officeTemplates: [OfficeTemplate] = []

    func saveTemplate(_ template: CustomTemplate) {
        savedTemplates.append(template)
    }

    func loadTemplates() -> [CustomTemplate] {
        savedTemplates
    }

    func deleteTemplate(_ id: UUID) {
        savedTemplates.removeAll { $0.id == id }
    }

    func saveEditedTemplate(_ documentType: DocumentType, _ content: String) {
        editedTemplates[documentType] = content
    }

    func loadEditedTemplate(_ documentType: DocumentType) -> String? {
        editedTemplates[documentType]
    }

    func saveOfficeTemplate(_ template: OfficeTemplate) {
        officeTemplates.append(template)
    }

    func loadOfficeTemplates(_ documentType: DocumentType) -> [OfficeTemplate] {
        officeTemplates.filter { $0.documentType == documentType }
    }
}

// MARK: - DependencyValues Extension

public extension DependencyValues {
    var templateStorageService: TemplateStorageService {
        get { self[TemplateStorageService.self] }
        set { self[TemplateStorageService.self] = newValue }
    }
}
