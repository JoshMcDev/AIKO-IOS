import Foundation
import ComposableArchitecture

/// Service for managing custom template storage
public struct TemplateStorageService {
    public var saveTemplate: (CustomTemplate) async throws -> Void
    public var loadTemplates: () async throws -> [CustomTemplate]
    public var deleteTemplate: (UUID) async throws -> Void
    public var saveEditedTemplate: (DocumentType, String) async throws -> Void
    public var loadEditedTemplate: (DocumentType) async throws -> String?
    public var saveOfficeTemplate: (OfficeTemplate) async throws -> Void
    public var loadOfficeTemplates: (DocumentType) async throws -> [OfficeTemplate]
    
    public init(
        saveTemplate: @escaping (CustomTemplate) async throws -> Void,
        loadTemplates: @escaping () async throws -> [CustomTemplate],
        deleteTemplate: @escaping (UUID) async throws -> Void,
        saveEditedTemplate: @escaping (DocumentType, String) async throws -> Void,
        loadEditedTemplate: @escaping (DocumentType) async throws -> String?,
        saveOfficeTemplate: @escaping (OfficeTemplate) async throws -> Void,
        loadOfficeTemplates: @escaping (DocumentType) async throws -> [OfficeTemplate]
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

public struct CustomTemplate: Identifiable, Codable, Equatable {
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

public struct OfficeTemplate: Identifiable, Codable, Equatable {
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
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
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
        var savedTemplates: [CustomTemplate] = []
        var editedTemplates: [DocumentType: String] = [:]
        var officeTemplates: [OfficeTemplate] = []
        
        return TemplateStorageService(
            saveTemplate: { template in
                savedTemplates.append(template)
            },
            loadTemplates: {
                return savedTemplates
            },
            deleteTemplate: { id in
                savedTemplates.removeAll { $0.id == id }
            },
            saveEditedTemplate: { documentType, content in
                editedTemplates[documentType] = content
            },
            loadEditedTemplate: { documentType in
                return editedTemplates[documentType]
            },
            saveOfficeTemplate: { template in
                officeTemplates.append(template)
            },
            loadOfficeTemplates: { documentType in
                return officeTemplates.filter { $0.documentType == documentType }
            }
        )
    }
}

// MARK: - DependencyValues Extension

extension DependencyValues {
    public var templateStorageService: TemplateStorageService {
        get { self[TemplateStorageService.self] }
        set { self[TemplateStorageService.self] = newValue }
    }
}