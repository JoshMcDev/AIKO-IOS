import Foundation

/// Dependency client for file operations
public struct FileServiceClient: Sendable {
    public var saveFile: @Sendable (String, String, [String]) async -> Result<URL, Error> = { _, _, _ in
        .failure(FileServiceError.saveFailed)
    }

    public var openFile: @Sendable ([String]) async -> URL? = { _ in nil }

    public init(
        saveFile: @escaping @Sendable (String, String, [String]) async -> Result<URL, Error> = { _, _, _ in
            .failure(FileServiceError.saveFailed)
        },
        openFile: @escaping @Sendable ([String]) async -> URL? = { _ in nil }
    ) {
        self.saveFile = saveFile
        self.openFile = openFile
    }
}

public extension FileServiceClient {
    static let liveValue: Self = .init()
}
