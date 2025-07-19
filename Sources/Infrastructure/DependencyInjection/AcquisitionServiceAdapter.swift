import ComposableArchitecture
import CoreData
import Foundation
import AppCore

/// Adapter that bridges the TCA AcquisitionService dependency with the new AcquisitionRepository
/// This allows gradual migration of UI features from AcquisitionService to AcquisitionRepository
public extension AcquisitionService {
    static var repositoryBased: AcquisitionService {
        let repository = AcquisitionRepository(context: CoreDataStack.shared.viewContext)
        // Document repository is created when needed in the actual methods
        
        return AcquisitionService(
            createAcquisition: { title, requirements, uploadedDocuments in
                // Convert to tuples for repository
                let repoDocuments = uploadedDocuments.map { doc in
                    (fileName: doc.fileName, data: doc.data, contentSummary: doc.contentSummary)
                }
                
                let aggregate = try await repository.createWithDocuments(
                    title: title,
                    requirements: requirements,
                    uploadedDocuments: repoDocuments
                )
                
                return aggregate.managedObject
            },
            
            fetchAcquisitions: {
                let aggregates = try await repository.findAll()
                return aggregates.map { $0.managedObject }
            },
            
            fetchAcquisition: { id in
                guard let aggregate = try await repository.findById(id) else {
                    return nil
                }
                return aggregate.managedObject
            },
            
            updateAcquisition: { id, update in
                guard let aggregate = try await repository.findById(id) else {
                    throw AcquisitionError.notFound
                }
                
                // Apply the update to the managed object
                update(aggregate.managedObject)
                
                // Update through repository to ensure business rules
                try await repository.update(aggregate)
            },
            
            deleteAcquisition: { id in
                try await repository.delete(id)
            },
            
            addUploadedFiles: { acquisitionId, uploadedDocuments in
                guard let aggregate = try await repository.findById(acquisitionId) else {
                    throw AcquisitionError.notFound
                }
                
                // Convert and add files
                for doc in uploadedDocuments {
                    let uploadedFile = UploadedFile(context: aggregate.managedObject.managedObjectContext!)
                    uploadedFile.fileName = doc.fileName
                    uploadedFile.data = doc.data
                    uploadedFile.contentSummary = doc.contentSummary
                    aggregate.managedObject.addToUploadedFiles(uploadedFile)
                }
                
                aggregate.updateLastModified()
                try await repository.update(aggregate)
            },
            
            addGeneratedDocuments: { acquisitionId, generatedDocuments in
                // Convert our GeneratedDocument to repository's GeneratedDocument
                let repoDocuments = generatedDocuments.map { doc in
                    (title: doc.title, content: doc.content, documentCategory: mapGeneratedDocumentToRepositoryCategory(doc))
                }
                
                try await repository.addGeneratedDocuments(
                    to: acquisitionId,
                    documents: repoDocuments
                )
            },
            
            updateStatus: { acquisitionId, status in
                let repositoryStatus = mapToRepositoryStatus(status)
                try await repository.updateStatus(
                    acquisitionId: acquisitionId,
                    to: repositoryStatus
                )
            }
        )
    }
}

// MARK: - Type Mappings

// Using the DTOs from AcquisitionRepository for document types

/// Maps DocumentType to repository DocumentCategory based on the document's displayName
private func mapDocumentTypeToRepositoryCategory(_ documentType: DocumentType) -> DocumentCategory {
    switch documentType {
    case .rrd, .soo, .sow, .pws, .qasp:
        return .requirements
    case .marketResearch, .codes, .competitionAnalysis, .industryRFI, .sourcesSought, .costEstimate, .procurementSourcing:
        return .marketIntelligence
    case .acquisitionPlan, .evaluationPlan, .fiscalLawReview, .opsecReview, .justificationApproval:
        return .planning
    case .requestForQuoteSimplified, .requestForQuote, .requestForProposal:
        return .solicitation
    case .contractScaffold, .corAppointment, .otherTransactionAgreement:
        return .award
    case .analytics:
        return .analytics
    case .farUpdates:
        return .analytics
    }
}

/// Maps GeneratedDocument to repository category
private func mapGeneratedDocumentToRepositoryCategory(_ document: GeneratedDocument) -> DocumentCategory {
    switch document.documentCategory {
    case .standard(let documentType):
        return mapDocumentTypeToRepositoryCategory(documentType)
    case .determinationFinding(_):
        // Map D&F documents to the determinationFindings category
        return .determinationFindings
    }
}

/// Maps UI layer status to repository status
private func mapToRepositoryStatus(_ status: Acquisition.Status) -> AcquisitionStatus {
    switch status {
    case .draft:
        return .draft
    case .inProgress:
        return .inProgress
    case .underReview:
        return .underReview
    case .approved:
        return .approved
    case .awarded:
        return .awarded
    case .cancelled:
        return .cancelled
    case .archived:
        return .archived
    }
}

// MARK: - Dependency Registration

