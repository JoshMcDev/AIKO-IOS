import ComposableArchitecture
import Foundation

/// Dependency client for clipboard operations
@DependencyClient
public struct ClipboardServiceClient: Sendable {
    public var copyText: @Sendable (String) async -> Void = { _ in }
    public var copyData: @Sendable (Data, String) async -> Void = { _, _ in }
    public var getText: @Sendable () async -> String? = { nil }
    public var hasContent: @Sendable (String) async -> Bool = { _ in false }
}

extension ClipboardServiceClient: DependencyKey {
    public static let liveValue: Self = .init()
}

public extension DependencyValues {
    var clipboardService: ClipboardServiceClient {
        get { self[ClipboardServiceClient.self] }
        set { self[ClipboardServiceClient.self] = newValue }
    }
}
