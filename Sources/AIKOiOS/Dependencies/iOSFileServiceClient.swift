import AppCore
import ComposableArchitecture
import Foundation

extension FileServiceClient {
    public static let iOSLive = Self(
        saveFile: { content, suggestedFileName, allowedFileTypes in
            await withCheckedContinuation { continuation in
                iOSFileService().saveFile(
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
                iOSFileService().openFile(allowedFileTypes: allowedFileTypes) { url in
                    continuation.resume(returning: url)
                }
            }
        }
    )
}

// Convenience static accessor
public enum iOSFileServiceClient {
    public static let live = FileServiceClient.iOSLive
}