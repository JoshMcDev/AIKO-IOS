import AppCore
import ComposableArchitecture
import CoreData
import Foundation

/// Adapter that bridges the TCA AcquisitionService dependency with the new AcquisitionRepository
/// This allows gradual migration of UI features from AcquisitionService to AcquisitionRepository
public extension AcquisitionService {
    static var repositoryBased: AcquisitionService {
        let repository = AcquisitionRepository(coreDataActor: CoreDataStack.shared.actor)
        // Document repository is created when needed in the actual methods

        return AcquisitionService(
            createAcquisition: { title, requirements, uploadedDocuments in
                // Convert to tuples for repository
                let repoDocuments = uploadedDocuments.map { doc in
                    (fileName: doc.fileName, data: doc.data, contentSummary: doc.contentSummary)
                }

                let acquisition = try await repository.createWithDocuments(
                    title: title,
                    requirements: requirements,
                    uploadedDocuments: repoDocuments
                )

                return acquisition
            },

            fetchAcquisitions: {
                let acquisitions = try await repository.findAll()
                return acquisitions
            },

            fetchAcquisition: { id in
                let acquisition = try await repository.findById(id)
                return acquisition
            },

            updateAcquisition: { id, update in
                guard var acquisition = try await repository.findById(id) else {
                    throw AcquisitionError.notFound
                }

                // Apply update and save through repository
                update(&acquisition)
                try await repository.update(acquisition)
            },

            deleteAcquisition: { id in
                try await repository.delete(id)
            },

            addUploadedFiles: { acquisitionId, uploadedDocuments in
                // For now, use Core Data actor directly for file operations
                // This could be moved to a dedicated method in the repository
                try await CoreDataStack.shared.actor.performBackgroundTask { context in
                    let request = CoreDataAcquisition.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", acquisitionId as CVarArg)

                    guard let acquisition = try context.fetch(request).first else {
                        throw AcquisitionError.notFound
                    }

                    // Convert and add files
                    for doc in uploadedDocuments {
                        let uploadedFile = UploadedFile(context: context)
                        uploadedFile.fileName = doc.fileName
                        uploadedFile.data = doc.data
                        uploadedFile.contentSummary = doc.contentSummary
                        acquisition.addToUploadedFiles(uploadedFile)
                    }

                    acquisition.lastModifiedDate = Date()
                    try context.save()
                }
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
        .requirements
    case .marketResearch, .codes, .competitionAnalysis, .industryRFI, .sourcesSought, .costEstimate, .procurementSourcing:
        .marketIntelligence
    case .acquisitionPlan, .evaluationPlan, .fiscalLawReview, .opsecReview, .justificationApproval:
        .planning
    case .requestForQuoteSimplified, .requestForQuote, .requestForProposal:
        .solicitation
    case .contractScaffold, .corAppointment, .otherTransactionAgreement:
        .award
    case .analytics:
        .analytics
    case .farUpdates:
        .analytics
    }
}

/// Maps GeneratedDocument to repository category
private func mapGeneratedDocumentToRepositoryCategory(_ document: GeneratedDocument) -> DocumentCategory {
    switch document.documentCategory {
    case let .standard(documentType):
        mapDocumentTypeToRepositoryCategory(documentType)
    case .determinationFinding:
        // Map D&F documents to the determinationFindings category
        .determinationFindings
    }
}

/// Maps UI layer status to repository status
private func mapToRepositoryStatus(_ status: AcquisitionStatus) -> AcquisitionStatus {
    switch status {
    case .draft:
        .draft
    case .inProgress:
        .inProgress
    case .underReview:
        .underReview
    case .approved:
        .approved
    case .awarded:
        .awarded
    case .cancelled:
        .cancelled
    case .archived:
        .archived
    case .completed:
        .completed
    case .onHold:
        .onHold
    }
}

// MARK: - Dependency Registration
