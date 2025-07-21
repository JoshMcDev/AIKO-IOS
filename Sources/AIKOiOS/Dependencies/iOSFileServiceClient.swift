#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import Foundation

    /// iOS File Service Client using SimpleServiceTemplate
    public final class iOSFileServiceClient: SimpleServiceTemplate {
        @MainActor
        private lazy var service = iOSFileService()

        override public init() {
            super.init()
        }

        public func saveFile(
            content: String,
            suggestedFileName: String,
            allowedFileTypes: [String]
        ) async -> Result<URL, Error> {
            await executeMainActorOperation {
                await withCheckedContinuation { continuation in
                    self.service.saveFile(
                        content: content,
                        suggestedFileName: suggestedFileName,
                        allowedFileTypes: allowedFileTypes
                    ) { result in
                        continuation.resume(returning: result)
                    }
                }
            }
        }

        public func openFile(allowedFileTypes: [String]) async -> URL? {
            await executeMainActorOperation {
                await withCheckedContinuation { continuation in
                    self.service.openFile(allowedFileTypes: allowedFileTypes) { url in
                        continuation.resume(returning: url)
                    }
                }
            }
        }
    }

    public extension FileServiceClient {
        @MainActor
        static var iOSLive: Self {
            let client = iOSFileServiceClient()

            return Self(
                saveFile: { content, suggestedFileName, allowedFileTypes in
                    await client.saveFile(
                        content: content,
                        suggestedFileName: suggestedFileName,
                        allowedFileTypes: allowedFileTypes
                    )
                },
                openFile: { allowedFileTypes in
                    await client.openFile(allowedFileTypes: allowedFileTypes)
                }
            )
        }
    }

    // Convenience static accessor
    public enum iOSFileServiceClientAccessor {
        @MainActor
        public static var live: FileServiceClient {
            FileServiceClient.iOSLive
        }
    }
#endif
