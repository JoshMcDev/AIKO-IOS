import Foundation

/// Platform-agnostic protocol for acquisition management
public protocol AcquisitionServiceProtocol: Sendable {
    /// Create a new acquisition
    func createAcquisition(title: String, requirements: String, uploadedDocuments: [UploadedDocument]) async throws -> Acquisition

    /// Fetch all acquisitions
    func fetchAcquisitions() async throws -> [Acquisition]

    /// Fetch a specific acquisition
    func fetchAcquisition(id: UUID) async throws -> Acquisition?

    /// Update an acquisition
    func updateAcquisition(id: UUID, update: (Acquisition) -> Void) async throws

    /// Delete an acquisition
    func deleteAcquisition(id: UUID) async throws

    /// Add uploaded files to an acquisition
    func addUploadedFiles(to acquisitionId: UUID, files: [UploadedDocument]) async throws

    /// Add generated documents to an acquisition
    func addGeneratedDocuments(to acquisitionId: UUID, documents: [GeneratedDocument]) async throws

    /// Update acquisition status
    func updateStatus(of acquisitionId: UUID, to status: Acquisition.Status) async throws
}
