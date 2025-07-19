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
    public static var liveValue: Self = Self()
}

extension DependencyValues {
    public var fileService: FileServiceClient {
        get { self[FileServiceClient.self] }
        set { self[FileServiceClient.self] = newValue }
    }
}