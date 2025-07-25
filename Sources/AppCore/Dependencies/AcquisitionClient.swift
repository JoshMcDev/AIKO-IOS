import Foundation

/// Dependency client for acquisition management
public struct AcquisitionClient: Sendable {
    public var createAcquisition: @Sendable (String, String, [UploadedDocument]) async throws -> Acquisition
    public var fetchAcquisitions: @Sendable () async throws -> [Acquisition]
    public var fetchAcquisition: @Sendable (UUID) async throws -> Acquisition?
    public var updateAcquisition: @Sendable (UUID, @escaping (inout Acquisition) -> Void) async throws -> Void
    public var deleteAcquisition: @Sendable (UUID) async throws -> Void
    public var addUploadedFiles: @Sendable (UUID, [UploadedDocument]) async throws -> Void
    public var addGeneratedDocuments: @Sendable (UUID, [GeneratedDocument]) async throws -> Void
    public var updateStatus: @Sendable (UUID, Acquisition.Status) async throws -> Void
}

extension AcquisitionClient {
    public static let testValue = Self(
        createAcquisition: { title, requirements, _ in
            Acquisition(title: title, requirements: requirements)
        },
        fetchAcquisitions: { [] },
        fetchAcquisition: { _ in nil },
        updateAcquisition: { _, _ in },
        deleteAcquisition: { _ in },
        addUploadedFiles: { _, _ in },
        addGeneratedDocuments: { _, _ in },
        updateStatus: { _, _ in }
    )

    public static let previewValue = Self(
        createAcquisition: { title, requirements, _ in
            Acquisition(title: title, requirements: requirements)
        },
        fetchAcquisitions: { [] },
        fetchAcquisition: { _ in nil },
        updateAcquisition: { _, _ in },
        deleteAcquisition: { _ in },
        addUploadedFiles: { _, _ in },
        addGeneratedDocuments: { _, _ in },
        updateStatus: { _, _ in }
    )
}
