import AppCore
import ComposableArchitecture
import Foundation

extension ShareServiceClient {
    public static let iOSLive = Self(
        share: { items in
            await withCheckedContinuation { continuation in
                iOSShareService().share(items: items) { success in
                    continuation.resume(returning: success)
                }
            }
        },
        createShareableFile: { text, fileName in
            try iOSShareService().createShareableFile(from: text, fileName: fileName)
        },
        shareContent: { content, fileName in
            let service = iOSShareService()
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
public enum iOSShareServiceClient {
    public static let live = ShareServiceClient.iOSLive
}