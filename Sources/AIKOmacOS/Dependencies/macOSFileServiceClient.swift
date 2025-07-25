#if os(macOS)
    import AppCore
    import Foundation

    public extension FileServiceClient {
        static let macOSLive = Self(
            saveFile: { content, suggestedFileName, allowedFileTypes in
                await withCheckedContinuation { continuation in
                    MacOSFileService().saveFile(
                        content: content,
                        suggestedFileName: suggestedFileName,
                        allowedFileTypes: allowedFileTypes
                    ) { result in
                        continuation.resume(returning: result)
                    }
                }
            },
            openFile: { allowedFileTypes in
                await withCheckedContinuation { continuation in
                    MacOSFileService().openFile(allowedFileTypes: allowedFileTypes) { url in
                        continuation.resume(returning: url)
                    }
                }
            }
        )
    }

    // Convenience static accessor
    public enum MacOSFileServiceClient {
        public static let live = FileServiceClient.macOSLive
    }#endif
