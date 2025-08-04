#if os(macOS)
import AppCore
import Foundation

public extension ShareServiceClient {
    static let macOSLive = Self(
        share: { items in
            await MacOSShareService().share(items: ShareableItems(items))
        },
        createShareableFile: { text, fileName in
            try MacOSShareService().createShareableFile(from: text, fileName: fileName)
        },
        shareContent: { content, fileName in
            let service = MacOSShareService()
            if let url = try? service.createShareableFile(from: content, fileName: fileName) {
                _ = await service.share(items: ShareableItems([url]))
            }
        }
    )
}

// Convenience static accessor
public enum MacOSShareServiceClient {
    public static let live = ShareServiceClient.macOSLive
}#endif
