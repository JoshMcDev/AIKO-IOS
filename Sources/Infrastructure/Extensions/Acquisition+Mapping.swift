import AppCore
import CoreData
import Foundation

// MARK: - Core Data to AppCore Mapping

// Use explicit namespace to avoid ambiguity
typealias CoreDataAcquisition = Acquisition

extension CoreDataAcquisition {
    /// Convert Core Data Acquisition to AppCore Acquisition model
    func toAppCoreModel() -> AppCore.Acquisition {
        AppCore.Acquisition(
            id: id ?? UUID(),
            title: title ?? "",
            requirements: requirements ?? "",
            projectNumber: projectNumber,
            status: statusEnum.toAppCoreStatus(),
            createdDate: createdDate ?? Date(),
            lastModifiedDate: lastModifiedDate ?? Date(),
            uploadedFiles: uploadedFilesArray.map { $0.toAppCoreModel() },
            generatedFiles: generatedFilesArray.map { $0.toAppCoreModel() }
        )
    }
}

extension CoreDataAcquisition.Status {
    /// Convert Core Data Status to AppCore AcquisitionStatus
    func toAppCoreStatus() -> AcquisitionStatus {
        switch self {
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
        }
    }
}

// MARK: - AppCore to Core Data Mapping

extension AppCore.Acquisition {
    /// Apply AppCore model values to Core Data entity
    func applyTo(_ entity: CoreDataAcquisition) {
        entity.title = title
        entity.requirements = requirements
        entity.projectNumber = projectNumber
        entity.statusEnum = status.toCoreDataStatus()
        // Don't update dates here as they should be managed by Core Data
    }
}

extension AcquisitionStatus {
    /// Convert AppCore AcquisitionStatus to Core Data Status
    func toCoreDataStatus() -> CoreDataAcquisition.Status {
        switch self {
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
            // Map completed to awarded as Core Data doesn't have completed
            .awarded
        case .onHold:
            // Map onHold to inProgress as Core Data doesn't have onHold
            .inProgress
        }
    }
}

// MARK: - UploadedFile Mapping

extension UploadedFile {
    /// Convert Core Data UploadedFile to AppCore UploadedDocument
    func toAppCoreModel() -> UploadedDocument {
        UploadedDocument(
            fileName: fileName ?? "",
            data: data ?? Data(),
            uploadDate: uploadDate ?? Date(),
            contentSummary: contentSummary
        )
    }
}

// MARK: - GeneratedFile Mapping

extension GeneratedFile {
    /// Convert Core Data GeneratedFile to AppCore GeneratedDocument
    func toAppCoreModel() -> GeneratedDocument {
        // Determine document type from fileType
        let documentType: DocumentType
        if let fileType = fileType,
           let docType = DocumentType.allCases.first(where: { $0.rawValue == fileType }) {
            documentType = docType
        } else {
            // Default to SOW if type cannot be determined
            documentType = .sow
        }
        
        return GeneratedDocument(
            id: id ?? UUID(),
            title: fileName ?? "",
            documentType: documentType,
            content: String(data: content ?? Data(), encoding: .utf8) ?? "",
            createdAt: createdDate ?? Date()
        )
    }
}
