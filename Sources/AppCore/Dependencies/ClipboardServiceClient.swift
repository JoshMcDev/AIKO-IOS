import Foundation

/// Dependency client for clipboard operations
public struct ClipboardServiceClient: Sendable {
    public var copyText: @Sendable (String) async -> Void = { _ in }
    public var copyData: @Sendable (Data, String) async -> Void = { _, _ in }
    public var getText: @Sendable () async -> String? = { nil }
    public var hasContent: @Sendable (String) async -> Bool = { _ in false }

    public init(
        copyText: @escaping @Sendable (String) async -> Void = { _ in },
        copyData: @escaping @Sendable (Data, String) async -> Void = { _, _ in },
        getText: @escaping @Sendable () async -> String? = { nil },
        hasContent: @escaping @Sendable (String) async -> Bool = { _ in false }
    ) {
        self.copyText = copyText
        self.copyData = copyData
        self.getText = getText
        self.hasContent = hasContent
    }
}

extension ClipboardServiceClient {
    public static let liveValue: Self = .init()
}
