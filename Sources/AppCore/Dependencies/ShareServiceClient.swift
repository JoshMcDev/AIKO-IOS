import Foundation

/// Dependency client for sharing functionality
public struct ShareServiceClient: Sendable {
    public var share: @Sendable ([Any]) async -> Bool = { _ in false }
    public var createShareableFile: @Sendable (String, String) async throws -> URL = { _, _ in
        throw ShareServiceError.notAvailable
    }

    public var shareContent: @Sendable (String, String) async -> Void = { _, _ in }

    public init(
        share: @escaping @Sendable ([Any]) async -> Bool = { _ in false },
        createShareableFile: @escaping @Sendable (String, String) async throws -> URL = { _, _ in
            throw ShareServiceError.notAvailable
        },
        shareContent: @escaping @Sendable (String, String) async -> Void = { _, _ in }
    ) {
        self.share = share
        self.createShareableFile = createShareableFile
        self.shareContent = shareContent
    }
}

public extension ShareServiceClient {
    static let liveValue: Self = .init()
}
