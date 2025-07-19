import Foundation
import AppKit
import AppCore

/// macOS implementation of FileServiceProtocol
public final class macOSFileService: FileServiceProtocol {
    public init() {}
    
    public func saveFile(
        content: String,
        suggestedFileName: String,
        allowedFileTypes: [String],
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        Task { @MainActor in
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = allowedFileTypes.compactMap { ext in
                switch ext {
                case "txt":
                    return .plainText
                case "md":
                    return .init(filenameExtension: "md")
                case "json":
                    return .json
                default:
                    return .init(filenameExtension: ext)
                }
            }
            savePanel.nameFieldStringValue = suggestedFileName
            savePanel.canCreateDirectories = true
            savePanel.showsTagField = false
            
            let response = savePanel.runModal()
            
            if response == .OK, let url = savePanel.url {
                do {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                    completion(.success(url))
                } catch {
                    completion(.failure(FileServiceError.saveFailure(error)))
                }
            } else {
                completion(.failure(FileServiceError.saveCancelled))
            }
        }
    }
    
    public func openFile(
        allowedFileTypes: [String],
        completion: @escaping (URL?) -> Void
    ) {
        Task { @MainActor in
            let openPanel = NSOpenPanel()
            openPanel.allowedContentTypes = allowedFileTypes.compactMap { ext in
                switch ext {
                case "txt":
                    return .plainText
                case "md":
                    return .init(filenameExtension: "md")
                case "json":
                    return .json
                default:
                    return .init(filenameExtension: ext)
                }
            }
            openPanel.canChooseFiles = true
            openPanel.canChooseDirectories = false
            openPanel.allowsMultipleSelection = false
            
            let response = openPanel.runModal()
            
            if response == .OK {
                completion(openPanel.url)
            } else {
                completion(nil)
            }
        }
    }
}