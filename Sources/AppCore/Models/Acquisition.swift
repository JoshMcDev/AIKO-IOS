import Foundation

/// Platform-agnostic Acquisition model for use in AppCore
public struct Acquisition: Identifiable, Equatable, Sendable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var requirements: String
    public var projectNumber: String?
    public var status: AcquisitionStatus
    public var createdDate: Date
    public var lastModifiedDate: Date
    public var uploadedFiles: [UploadedDocument]
    public var generatedFiles: [GeneratedDocument]

    public init(
        id: UUID = UUID(),
        title: String,
        requirements: String,
        projectNumber: String? = nil,
        status: AcquisitionStatus = .draft,
        createdDate: Date = Date(),
        lastModifiedDate: Date = Date(),
        uploadedFiles: [UploadedDocument] = [],
        generatedFiles: [GeneratedDocument] = []
    ) {
        self.id = id
        self.title = title
        self.requirements = requirements
        self.projectNumber = projectNumber
        self.status = status
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
        self.uploadedFiles = uploadedFiles
        self.generatedFiles = generatedFiles
    }
}

// Extension to provide status information
public extension Acquisition {
    /// Status alias for convenience
    typealias Status = AcquisitionStatus

    /// Uploaded files sorted by upload date (most recent first)
    var uploadedFilesArray: [UploadedDocument] {
        uploadedFiles.sorted { $0.uploadDate > $1.uploadDate }
    }

    /// Generated files sorted by creation date (most recent first)
    var generatedFilesArray: [GeneratedDocument] {
        generatedFiles.sorted { $0.createdAt > $1.createdAt }
    }
}
