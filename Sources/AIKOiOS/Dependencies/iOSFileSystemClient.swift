import AppCore
import ComposableArchitecture
import Foundation

/// iOS-specific implementation of FileSystemClient
public struct iOSFileSystemClient: Sendable {
    public init() {}
}

// MARK: - Live Implementation

extension iOSFileSystemClient {
    public static let live: FileSystemClient = {
        let client = iOSFileSystemClient()
        
        return FileSystemClient(
            directoryURL: { directory in
                try client.directoryURL(for: directory)
            },
            listFiles: { url, fileType in
                try await client.listFiles(in: url, filterByType: fileType)
            },
            save: { data, filename, directory in
                try await client.save(data, filename: filename, to: directory)
            },
            load: { url in
                try await client.load(from: url)
            },
            delete: { url in
                try await client.delete(at: url)
            },
            move: { source, destination in
                try await client.move(from: source, to: destination)
            },
            copy: { source, destination in
                try await client.copy(from: source, to: destination)
            },
            fileExists: { url in
                client.fileExists(at: url)
            },
            fileAttributes: { url in
                try await client.fileAttributes(for: url)
            },
            createDirectory: { url in
                try await client.createDirectory(at: url)
            }
        )
    }()
}

// MARK: - Implementation Methods

extension iOSFileSystemClient {
    private func directoryURL(for directory: FileDirectory) throws -> URL {
        switch directory {
        case .documents:
            return try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        case .temporary:
            return FileManager.default.temporaryDirectory
        case .cache:
            return try FileManager.default.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        case .custom(let url):
            return url
        }
    }
    
    private func listFiles(in directory: URL, filterByType fileType: FileType?) async throws -> [FileItem] {
        try await Task.detached {
            guard FileManager.default.fileExists(atPath: directory.path) else {
                throw FileSystemError.directoryNotFound
            }
            
            let contents = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            var fileItems: [FileItem] = []
            
            for url in contents {
                let resourceValues = try url.resourceValues(forKeys: [
                    .fileSizeKey,
                    .creationDateKey,
                    .contentModificationDateKey,
                    .isDirectoryKey,
                    .isReadableKey,
                    .isWritableKey
                ])
                
                let isDirectory = resourceValues.isDirectory ?? false
                guard !isDirectory else { continue }
                
                let type = FileType.from(extension: url.pathExtension)
                
                if let filterType = fileType, type != filterType {
                    continue
                }
                
                let fileItem = FileItem(
                    url: url,
                    name: url.lastPathComponent,
                    size: Int64(resourceValues.fileSize ?? 0),
                    createdAt: resourceValues.creationDate ?? Date(),
                    modifiedAt: resourceValues.contentModificationDate ?? Date(),
                    type: type,
                    attributes: FileAttributes(
                        isReadOnly: !(resourceValues.isWritable ?? true),
                        isHidden: url.lastPathComponent.hasPrefix("."),
                        isDirectory: false
                    )
                )
                
                fileItems.append(fileItem)
            }
            
            return fileItems.sorted { $0.modifiedAt > $1.modifiedAt }
        }.value
    }
    
    private func save(_ data: Data, filename: String, to directory: FileDirectory) async throws -> URL {
        try await Task.detached {
            let directoryURL = try directoryURL(for: directory)
            let fileURL = directoryURL.appendingPathComponent(filename)
            
            do {
                try data.write(to: fileURL)
                return fileURL
            } catch {
                throw FileSystemError.saveFailed(error.localizedDescription)
            }
        }.value
    }
    
    private func load(from url: URL) async throws -> Data {
        try await Task.detached {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw FileSystemError.fileNotFound(url.lastPathComponent)
            }
            
            do {
                return try Data(contentsOf: url)
            } catch {
                throw FileSystemError.loadFailed(error.localizedDescription)
            }
        }.value
    }
    
    private func delete(at url: URL) async throws {
        try await Task.detached {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw FileSystemError.fileNotFound(url.lastPathComponent)
            }
            
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                throw FileSystemError.deleteFailed(error.localizedDescription)
            }
        }.value
    }
    
    private func move(from source: URL, to destination: URL) async throws -> URL {
        try await Task.detached {
            guard FileManager.default.fileExists(atPath: source.path) else {
                throw FileSystemError.fileNotFound(source.lastPathComponent)
            }
            
            do {
                try FileManager.default.moveItem(at: source, to: destination)
                return destination
            } catch {
                throw FileSystemError.moveFailed(error.localizedDescription)
            }
        }.value
    }
    
    private func copy(from source: URL, to destination: URL) async throws -> URL {
        try await Task.detached {
            guard FileManager.default.fileExists(atPath: source.path) else {
                throw FileSystemError.fileNotFound(source.lastPathComponent)
            }
            
            do {
                try FileManager.default.copyItem(at: source, to: destination)
                return destination
            } catch {
                throw FileSystemError.copyFailed(error.localizedDescription)
            }
        }.value
    }
    
    private func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
    
    private func fileAttributes(for url: URL) async throws -> FileAttributes {
        try await Task.detached {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw FileSystemError.fileNotFound(url.lastPathComponent)
            }
            
            let resourceValues = try url.resourceValues(forKeys: [
                .isDirectoryKey,
                .isReadableKey,
                .isWritableKey
            ])
            
            return FileAttributes(
                isReadOnly: !(resourceValues.isWritable ?? true),
                isHidden: url.lastPathComponent.hasPrefix("."),
                isDirectory: resourceValues.isDirectory ?? false
            )
        }.value
    }
    
    private func createDirectory(at url: URL) async throws {
        try await Task.detached {
            do {
                try FileManager.default.createDirectory(
                    at: url,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw FileSystemError.unknownError(error.localizedDescription)
            }
        }.value
    }
}