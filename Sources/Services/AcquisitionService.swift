import AppCore
import CoreData
import Foundation

public struct AcquisitionService: Sendable {
    public var createAcquisition: @Sendable (String, String, [UploadedDocument]) async throws -> AppCore.Acquisition
    public var fetchAcquisitions: @Sendable () async throws -> [AppCore.Acquisition]
    public var fetchAcquisition: @Sendable (UUID) async throws -> AppCore.Acquisition?
    public var updateAcquisition: @Sendable (UUID, @Sendable (inout AppCore.Acquisition) -> Void) async throws -> Void
    public var deleteAcquisition: @Sendable (UUID) async throws -> Void
    public var addUploadedFiles: @Sendable (UUID, [UploadedDocument]) async throws -> Void
    public var addGeneratedDocuments: @Sendable (UUID, [GeneratedDocument]) async throws -> Void
    public var updateStatus: @Sendable (UUID, AcquisitionStatus) async throws -> Void

    public init(
        createAcquisition: @escaping @Sendable (String, String, [UploadedDocument]) async throws -> AppCore.Acquisition,
        fetchAcquisitions: @escaping @Sendable () async throws -> [AppCore.Acquisition],
        fetchAcquisition: @escaping @Sendable (UUID) async throws -> AppCore.Acquisition?,
        updateAcquisition: @escaping @Sendable (UUID, @Sendable (inout AppCore.Acquisition) -> Void) async throws -> Void,
        deleteAcquisition: @escaping @Sendable (UUID) async throws -> Void,
        addUploadedFiles: @escaping @Sendable (UUID, [UploadedDocument]) async throws -> Void,
        addGeneratedDocuments: @escaping @Sendable (UUID, [GeneratedDocument]) async throws -> Void,
        updateStatus: @escaping @Sendable (UUID, AcquisitionStatus) async throws -> Void
    ) {
        self.createAcquisition = createAcquisition
        self.fetchAcquisitions = fetchAcquisitions
        self.fetchAcquisition = fetchAcquisition
        self.updateAcquisition = updateAcquisition
        self.deleteAcquisition = deleteAcquisition
        self.addUploadedFiles = addUploadedFiles
        self.addGeneratedDocuments = addGeneratedDocuments
        self.updateStatus = updateStatus
    }
}

extension AcquisitionService {
    public nonisolated static var liveValue: AcquisitionService {
        // Always use repository-based implementation as part of Phase 4 migration
        .repositoryBased
    }

    public static var testValue: AcquisitionService {
        liveValue
    }
}

// MARK: - Helper Functions

private func generateProjectNumber() -> String {
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    let dateString = formatter.string(from: date)
    let randomNumber = Int.random(in: 1000 ... 9999)
    return "ACQ-\(dateString)-\(randomNumber)"
}

// MARK: - Errors

enum AcquisitionError: LocalizedError, Sendable {
    case notFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notFound:
            "Acquisition not found"
        case .invalidData:
            "Invalid acquisition data"
        }
    }
}
