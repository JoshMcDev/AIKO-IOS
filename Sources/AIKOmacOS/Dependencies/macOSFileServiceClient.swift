#if os(macOS)
import AppCore
import ComposableArchitecture
import Foundation

extension FileServiceClient {
    public static let macOSLive = Self(
        saveFile: { content, suggestedFileName, allowedFileTypes in
            await withCheckedContinuation { continuation in
                macOSFileService().saveFile(
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
                macOSFileService().openFile(allowedFileTypes: allowedFileTypes) { url in
                    continuation.resume(returning: url)
                }
            }
        }
    )
}

// Convenience static accessor
public enum macOSFileServiceClient {
    public static let live = FileServiceClient.macOSLive
}#endif
