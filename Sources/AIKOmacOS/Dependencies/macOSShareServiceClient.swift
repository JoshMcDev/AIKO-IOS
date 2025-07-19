#if os(macOS)
import AppCore
import ComposableArchitecture
import Foundation

extension ShareServiceClient {
    public static let macOSLive = Self(
        share: { items in
            await withCheckedContinuation { continuation in
                macOSShareService().share(items: items) { success in
                    continuation.resume(returning: success)
                }
            }
        },
        createShareableFile: { text, fileName in
            try macOSShareService().createShareableFile(from: text, fileName: fileName)
        },
        shareContent: { content, fileName in
            let service = macOSShareService()
            if let url = try? service.createShareableFile(from: content, fileName: fileName) {
                _ = await withCheckedContinuation { continuation in
                    service.share(items: [url]) { _ in
                        continuation.resume()
                    }
                }
            }
        }
    )
}

// Convenience static accessor
public enum macOSShareServiceClient {
    public static let live = ShareServiceClient.macOSLive
}#endif
