import Foundation
import AppCore
import CoreData
// No need to import AIKO as we're part of it

/// Document service leveraging base service functionality
public final class DocumentService: BaseService {
    
    private let parser: DocumentParserInterface
    private let generator: DocumentGeneratorInterface
    private let validator: DocumentValidatorInterface
    
    // MARK: - Initialization
    
    internal let repository: DocumentRepository
    
    public init(
        repository: DocumentRepository,
        parser: DocumentParserInterface,
        generator: DocumentGeneratorInterface,
        validator: DocumentValidatorInterface
    ) {
        self.repository = repository
        self.parser = parser
        self.generator = generator
        self.validator = validator
        super.init()
    }
    
    // MARK: - Document Operations
    
    public func parseDocument(at url: URL) async throws -> ParsedContent {
        try await measurePerformance(operation: "parseDocument") {
            let content = try await parser.parse(url)
            
            // Validate parsed content
            let validationResult = try await validator.validate(content)
            if !validationResult.isValid {
                throw DocumentError.validationFailed(validationResult.errors)
            }
            
            return content
        }
    }
    
    public func generateDocument(
        type: DocumentType,
        requirements: String,
        context: GenerationContext
    ) async throws -> GeneratedDocument {
        try await measurePerformance(operation: "generateDocument(\(type))") {
            // Generate document
            let document = try await generator.generate(
                input: requirements,
                context: context
            )
            
            // Validate generated document
            let validationResult = try await validator.validate(document)
            if !validationResult.isValid {
                log("Document validation failed: \(validationResult.errors)", level: .warning)
                // Attempt to fix validation errors
                if let fixedDocument = try await attemptAutoFix(document, errors: validationResult.errors) {
                    return fixedDocument
                }
                throw DocumentError.validationFailed(validationResult.errors)
            }
            
            // Save to repository
            // For now, just return the generated document
            // In real implementation, would save to Core Data
            let savedDocument = document
            
            return savedDocument
        }
    }
    
    public func findDocumentsByType(_ type: DocumentType) async throws -> [AcquisitionDocument] {
        try await repository.findByType(type)
    }
    
    public func findRecentDocuments(limit: Int = 10) async throws -> [AcquisitionDocument] {
        try await repository.findRecent(limit: limit)
    }
    
    // MARK: - Private Methods
    
    private func attemptAutoFix(
        _ document: GeneratedDocument,
        errors: [DocumentValidationError]
    ) async throws -> GeneratedDocument? {
        guard errors.allSatisfy({ $0.fix != nil }) else {
            return nil
        }
        
        var fixedDocument = document
        for error in errors {
            if let fix = error.fix {
                fixedDocument = try await fix.apply(to: fixedDocument)
            }
        }
        
        // Re-validate fixed document
        let revalidation = try await validator.validate(fixedDocument)
        return revalidation.isValid ? fixedDocument : nil
    }
}

// MARK: - Acquisition Service

public final class AcquisitionServiceImpl: BaseService {
    
    private let repository: AcquisitionRepository
    private let documentService: DocumentService
    private let regulationEngine: RegulationEngineProtocol
    
    public init(
        repository: AcquisitionRepository,
        documentService: DocumentService,
        regulationEngine: RegulationEngineProtocol
    ) {
        self.repository = repository
        self.documentService = documentService
        self.regulationEngine = regulationEngine
        super.init()
    }
    
    // MARK: - CRUD Operations
    
    public func create(_ acquisition: Acquisition) async throws -> Acquisition {
        // Add business logic before creation
        let enrichedAcquisition = acquisition
        
        // Determine required documents based on regulations
        let _ = try await regulationEngine.determineRequiredDocuments(
            for: acquisition.status ?? "draft",
            amount: acquisition.estimatedValue
        )
        // TODO: Store required documents in metadata when Core Data model is updated
        // This will be implemented when we enhance the domain model
        
        // Create acquisition with empty documents initially
        let aggregate = try await repository.createWithDocuments(
            title: enrichedAcquisition.title ?? "",
            requirements: enrichedAcquisition.requirements ?? "",
            uploadedDocuments: []
        )
        let created = aggregate.managedObject
        
        // Post-creation tasks
        Task {
            await notifyStakeholders(of: created)
        }
        
        return created
    }
    
    // MARK: - Domain-Specific Operations
    
    public func generateDocumentChain(for acquisitionId: UUID) async throws -> [GeneratedDocument] {
        guard let aggregate = try await repository.findById(acquisitionId) else {
            throw DocumentError.acquisitionNotFound
        }
        let acquisition = aggregate.managedObject
        
        return try await measurePerformance(operation: "generateDocumentChain") {
            var documents: [GeneratedDocument] = []
            
            for docType in acquisition.requiredDocuments {
                let context = GenerationContext(
                    acquisition: acquisition,
                    previousDocuments: documents,
                    regulations: try await regulationEngine.applicableRegulations(for: acquisition)
                )
                
                let document = try await documentService.generateDocument(
                    type: docType,
                    requirements: acquisition.requirements ?? "",
                    context: context
                )
                
                documents.append(document)
            }
            
            // Update acquisition with generated documents
            // This would be stored in relationships or metadata
            aggregate.status = .completed
            _ = try await repository.update(aggregate)
            
            return documents
        }
    }
    
    public func findByStatus(_ status: String) async throws -> [Acquisition] {
        guard let acquisitionStatus = AcquisitionStatus(rawValue: status) else {
            throw DocumentError.invalidStatus
        }
        let aggregates = try await repository.findByStatus(acquisitionStatus)
        return aggregates.map { $0.managedObject }
    }
    
    public func findByDateRange(from startDate: Date, to endDate: Date) async throws -> [Acquisition] {
        let aggregates = try await repository.findByDateRange(from: startDate, to: endDate)
        return aggregates.map { $0.managedObject }
    }
    
    private func notifyStakeholders(of acquisition: Acquisition) async {
        log("Notifying stakeholders of new acquisition: \(acquisition.id?.uuidString ?? "unknown")")
        // Implementation for notifications
    }
}

// MARK: - Supporting Types

public enum DocumentError: LocalizedError {
    case validationFailed([DocumentValidationError])
    case generationFailed(String)
    case parsingFailed(String)
    case acquisitionNotFound
    case invalidStatus
    
    public var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return "Document validation failed: \(errors.map { $0.message }.joined(separator: ", "))"
        case .generationFailed(let reason):
            return "Document generation failed: \(reason)"
        case .parsingFailed(let reason):
            return "Document parsing failed: \(reason)"
        case .acquisitionNotFound:
            return "Acquisition not found"
        case .invalidStatus:
            return "Invalid acquisition status"
        }
    }
}


// MARK: - Protocol Stubs (to be implemented)

public protocol DocumentParserInterface {
    func parse(_ source: URL) async throws -> ParsedContent
}

public protocol DocumentGeneratorInterface {
    func generate(input: String, context: GenerationContext) async throws -> GeneratedDocument
}

public protocol DocumentValidatorInterface {
    func validate(_ content: Any) async throws -> ValidationResult
}

public protocol RegulationEngineProtocol {
    func determineRequiredDocuments(for type: String, amount: Decimal) async throws -> [DocumentType]
    func applicableRegulations(for acquisition: Acquisition) async throws -> [Regulation]
}

// Type aliases for clarity
public typealias ParsedContent = [String: Any]

public struct GenerationContext {
    let acquisition: Acquisition
    let previousDocuments: [GeneratedDocument]
    let regulations: [Regulation]
}

public struct Regulation {
    let id: String
    let title: String
    let requirements: [String]
}

// Missing types
public struct ValidationResult {
    let isValid: Bool
    let errors: [DocumentValidationError]
    let warnings: [DocumentValidationWarning]
}

public struct DocumentValidationError {
    let code: String
    let message: String
    let fix: DocumentValidationFix?
}

public struct DocumentValidationWarning {
    let code: String
    let message: String
}

public struct DocumentValidationFix {
    let description: String
    func apply(to document: GeneratedDocument) async throws -> GeneratedDocument {
        // Implementation would go here
        return document
    }
}

// Using existing enums from Models folder
