import ComposableArchitecture
import Foundation

/// Dependency client for file operations
@DependencyClient
public struct FileServiceClient: Sendable {
    public var saveFile: @Sendable (String, String, [String]) async -> Result<URL, Error> = { _, _, _ in
        .failure(FileServiceError.saveFailed)
    }

    public var openFile: @Sendable ([String]) async -> URL? = { _ in nil }
}

extension FileServiceClient: DependencyKey {
    public static let liveValue: Self = .init()
}

public extension DependencyValues {
    var fileService: FileServiceClient {
        get { self[FileServiceClient.self] }
        set { self[FileServiceClient.self] = newValue }
    }
}
