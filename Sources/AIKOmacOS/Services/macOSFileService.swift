#if os(macOS)
    import AppCore
    import AppKit
    import Foundation

    /// macOS implementation of FileServiceProtocol
    public final class MacOSFileService: FileServiceProtocol {
        public init() {}

        public func saveFile(
            content: String,
            suggestedFileName: String,
            allowedFileTypes: [String],
            completion: @escaping @Sendable (Result<URL, Error>) -> Void
        ) {
            Task { @MainActor in
                let savePanel = NSSavePanel()
                savePanel.allowedContentTypes = allowedFileTypes.compactMap { ext in
                    switch ext {
                    case "txt":
                        .plainText
                    case "md":
                        .init(filenameExtension: "md")
                    case "json":
                        .json
                    default:
                        .init(filenameExtension: ext)
                    }
                }
                savePanel.nameFieldStringValue = suggestedFileName
                savePanel.canCreateDirectories = true
                savePanel.showsTagField = false

                let response = savePanel.runModal()

                if response == .OK, let url = savePanel.url {
                    do {
                        try content.write(to: url, atomically: true, encoding: .utf8)
                        await MainActor.run {
                            completion(.success(url))
                        }
                    } catch {
                        await MainActor.run {
                            completion(.failure(FileServiceError.saveFailure(error)))
                        }
                    }
                } else {
                    await MainActor.run {
                        completion(.failure(FileServiceError.saveCancelled))
                    }
                }
            }
        }

        public func openFile(
            allowedFileTypes: [String],
            completion: @escaping @Sendable (URL?) -> Void
        ) {
            Task { @MainActor in
                let openPanel = NSOpenPanel()
                openPanel.allowedContentTypes = allowedFileTypes.compactMap { ext in
                    switch ext {
                    case "txt":
                        .plainText
                    case "md":
                        .init(filenameExtension: "md")
                    case "json":
                        .json
                    default:
                        .init(filenameExtension: ext)
                    }
                }
                openPanel.canChooseFiles = true
                openPanel.canChooseDirectories = false
                openPanel.allowsMultipleSelection = false

                let response = openPanel.runModal()

                if response == .OK {
                    await MainActor.run {
                        completion(openPanel.url)
                    }
                } else {
                    await MainActor.run {
                        completion(nil)
                    }
                }
            }
        }
    }#endif
