import AppCore
import CoreData
import Foundation

// No need to import AIKO as we're part of it

/// Document service leveraging base service functionality
public final class DocumentService: BaseService, @unchecked Sendable {
    private let parser: DocumentParserInterface
    private let generator: DocumentGeneratorInterface
    private let validator: DocumentValidatorInterface

    // MARK: - Initialization

    let repository: DocumentRepository

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

    public func findDocumentsByType(_ type: DocumentType) async throws -> [DocumentInfo] {
        try await repository.findByType(type)
    }

    public func findRecentDocuments(limit: Int = 10) async throws -> [DocumentInfo] {
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

public final class AcquisitionServiceImpl: BaseService, @unchecked Sendable {
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

    public func create(_ acquisition: AppCore.Acquisition) async throws -> AppCore.Acquisition {
        // Add business logic before creation
        let enrichedAcquisition = acquisition

        // Determine required documents based on regulations
        let statusString = acquisition.status.rawValue
        let requiredDocuments = try await regulationEngine.determineRequiredDocuments(
            for: statusString,
            amount: Decimal(0) // Default amount since Acquisition doesn't have estimatedValue
        )
        
        // Store required documents in acquisition metadata
        var metadata: [String: Any] = [:]
        metadata["requiredDocuments"] = requiredDocuments.map { $0.rawValue }
        metadata["determinedAt"] = Date()
        metadata["determinedBy"] = "RegulationEngine"

        // Create acquisition with empty documents initially
        let acquisition = try await repository.createWithDocuments(
            title: enrichedAcquisition.title,
            requirements: enrichedAcquisition.requirements,
            uploadedDocuments: []
        )

        // Post-creation tasks
        let acquisitionId = acquisition.id
        Task { @Sendable in
            await notifyStakeholders(id: acquisitionId)
        }

        return acquisition
    }

    // MARK: - Domain-Specific Operations

    public func generateDocumentChain(for acquisitionId: UUID) async throws -> [GeneratedDocument] {
        guard let acquisition = try await repository.findById(acquisitionId) else {
            throw DocumentError.acquisitionNotFound
        }

        return try await measurePerformance(operation: "generateDocumentChain") {
            var documents: [GeneratedDocument] = []

            // Determine required documents based on acquisition status and regulations
            let requiredDocuments = try await regulationEngine.determineRequiredDocuments(
                for: acquisition.status.rawValue,
                amount: Decimal(0) // Default amount since Acquisition doesn't have estimatedValue
            )
            
            // Get applicable regulations for this acquisition
            let regulations = try await regulationEngine.applicableRegulations(for: acquisition)

            for docType in requiredDocuments {
                let context = GenerationContext(
                    acquisition: acquisition,
                    previousDocuments: documents,
                    regulations: regulations
                )

                let document = try await documentService.generateDocument(
                    type: docType,
                    requirements: acquisition.requirements,
                    context: context
                )

                documents.append(document)
            }

            // Update acquisition status to completed
            var updatedAcquisition = acquisition
            updatedAcquisition.status = .completed
            try await repository.update(updatedAcquisition)

            return documents
        }
    }

    public func findByStatus(_ status: String) async throws -> [AppCore.Acquisition] {
        guard let acquisitionStatus = AcquisitionStatus(rawValue: status) else {
            throw DocumentError.invalidStatus
        }
        return try await repository.findByStatus(acquisitionStatus)
    }

    public func findByDateRange(from startDate: Date, to endDate: Date) async throws -> [AppCore.Acquisition] {
        try await repository.findByDateRange(from: startDate, to: endDate)
    }

    private func notifyStakeholders(id: UUID) async {
        log("Notifying stakeholders of new acquisition: \(id.uuidString)")
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
        case let .validationFailed(errors):
            "Document validation failed: \(errors.map(\.message).joined(separator: ", "))"
        case let .generationFailed(reason):
            "Document generation failed: \(reason)"
        case let .parsingFailed(reason):
            "Document parsing failed: \(reason)"
        case .acquisitionNotFound:
            "Acquisition not found"
        case .invalidStatus:
            "Invalid acquisition status"
        }
    }
}

// MARK: - Protocol Stubs (to be implemented)

public protocol DocumentParserInterface: Sendable {
    func parse(_ source: URL) async throws -> ParsedContent
}

public protocol DocumentGeneratorInterface: Sendable {
    func generate(input: String, context: GenerationContext) async throws -> GeneratedDocument
}

public protocol DocumentValidatorInterface: Sendable {
    func validate(_ content: Any) async throws -> ValidationResult
}

public protocol RegulationEngineProtocol: Sendable {
    func determineRequiredDocuments(for type: String, amount: Decimal) async throws -> [DocumentType]
    func applicableRegulations(for acquisition: AppCore.Acquisition) async throws -> [Regulation]
}

// Type aliases for clarity
public typealias ParsedContent = [String: Any]

public struct GenerationContext {
    let acquisition: AppCore.Acquisition
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

public struct DocumentValidationError: Sendable {
    let code: String
    let message: String
    let fix: DocumentValidationFix?
}

public struct DocumentValidationWarning {
    let code: String
    let message: String
}

public struct DocumentValidationFix: Sendable {
    let description: String
    func apply(to document: GeneratedDocument) async throws -> GeneratedDocument {
        // Implementation would go here
        document
    }
}

// Using existing enums from Models folder
