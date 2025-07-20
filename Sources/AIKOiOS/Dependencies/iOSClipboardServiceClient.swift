#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import Foundation

    /// iOS Clipboard Service Client using SimpleServiceTemplate
    public final class iOSClipboardServiceClient: SimpleServiceTemplate {
        private let service = iOSClipboardService()

        override public init() {
            super.init()
        }

        public func copyText(_ text: String) async {
            await executeMainActorOperation {
                self.service.copyText(text)
            }
        }

        public func copyData(_ data: Data, type: String) async {
            await executeMainActorOperation {
                self.service.copyData(data, type: type)
            }
        }

        public func getText() async -> String? {
            await executeMainActorOperation {
                self.service.getText()
            }
        }

        public func hasContent(ofType type: String) async -> Bool {
            await executeMainActorOperation {
                self.service.hasContent(ofType: type)
            }
        }
    }

    public extension ClipboardServiceClient {
        static let iOSLive = Self(
            copyText: { text in
                let client = iOSClipboardServiceClient()
                await client.copyText(text)
            },
            copyData: { data, type in
                let client = iOSClipboardServiceClient()
                await client.copyData(data, type: type)
            },
            getText: {
                let client = iOSClipboardServiceClient()
                return await client.getText()
            },
            hasContent: { type in
                let client = iOSClipboardServiceClient()
                return await client.hasContent(ofType: type)
            }
        )
    }

    // Convenience static accessor
    public enum iOSClipboardServiceClient {
        public static let live = ClipboardServiceClient.iOSLive
    }
#endif
