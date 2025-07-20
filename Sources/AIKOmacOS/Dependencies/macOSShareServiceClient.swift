#if os(macOS)
    import AppCore
    import ComposableArchitecture
    import Foundation

    public extension ShareServiceClient {
        static let macOSLive = Self(
            share: { items in
                await macOSShareService().share(items: ShareableItems(items))
            },
            createShareableFile: { text, fileName in
                try macOSShareService().createShareableFile(from: text, fileName: fileName)
            },
            shareContent: { content, fileName in
                let service = macOSShareService()
                if let url = try? service.createShareableFile(from: content, fileName: fileName) {
                    _ = await service.share(items: ShareableItems([url]))
                }
            }
        )
    }

    // Convenience static accessor
    public enum macOSShareServiceClient {
        public static let live = ShareServiceClient.macOSLive
    }#endif
