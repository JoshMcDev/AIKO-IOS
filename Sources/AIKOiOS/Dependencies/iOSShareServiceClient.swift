#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import Foundation

    public extension ShareServiceClient {
        static let iOS = Self(
            share: { items in
                let service = iOSShareService()
                return await service.share(items: ShareableItems(items))
            },
            createShareableFile: { text, fileName in
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try text.write(to: tempURL, atomically: true, encoding: .utf8)
                return tempURL
            },
            shareContent: { content, fileName in
                do {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                    try content.write(to: tempURL, atomically: true, encoding: .utf8)
                    let service = iOSShareService()
                    _ = await service.share(items: ShareableItems([tempURL]))
                } catch {
                    // Handle error silently for now
                    print("Failed to share content: \(error)")
                }
            }
        )
    }

    public enum iOSShareServiceClient {
        public static let live = ShareServiceClient.iOS
    }
#endif
