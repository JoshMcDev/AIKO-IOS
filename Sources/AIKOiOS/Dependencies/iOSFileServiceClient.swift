#if os(iOS)
    import AppCore
    import Foundation

    /// iOS File Service Client using SimpleServiceTemplate
    public final class IOSFileServiceClient: SimpleServiceTemplate {
        @MainActor
        private lazy var service = IOSFileService()

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
            let client = IOSFileServiceClient()

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
    public enum IOSFileServiceClientAccessor {
        @MainActor
        public static var live: FileServiceClient {
            FileServiceClient.iOSLive
        }
    }
#endif
