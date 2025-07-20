import ComposableArchitecture
import Foundation

/// Dependency client for sharing functionality
@DependencyClient
public struct ShareServiceClient: Sendable {
    public var share: @Sendable ([Any]) async -> Bool = { _ in false }
    public var createShareableFile: @Sendable (String, String) async throws -> URL = { _, _ in
        throw ShareServiceError.notAvailable
    }

    public var shareContent: @Sendable (String, String) async -> Void = { _, _ in }
}

extension ShareServiceClient: DependencyKey {
    public static let liveValue: Self = .init()
}

public extension DependencyValues {
    var shareService: ShareServiceClient {
        get { self[ShareServiceClient.self] }
        set { self[ShareServiceClient.self] = newValue }
    }
}
