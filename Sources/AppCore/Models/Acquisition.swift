import Foundation

/// Platform-agnostic Acquisition model for use in AppCore
public struct Acquisition: Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var requirements: String
    public var projectNumber: String?
    public var status: AcquisitionStatus
    public var createdDate: Date
    public var lastModifiedDate: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        requirements: String,
        projectNumber: String? = nil,
        status: AcquisitionStatus = .draft,
        createdDate: Date = Date(),
        lastModifiedDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.requirements = requirements
        self.projectNumber = projectNumber
        self.status = status
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
    }
}

// Extension to provide status information
public extension Acquisition {
    /// Status alias for convenience
    typealias Status = AcquisitionStatus
}