import AppCore
import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// iOS implementation of file picker service
@available(iOS 16.0, *)
public actor FilePickerService: FilePickerServiceProtocol {
    private var recentlyPicked: [URL] = []

    public init() {}

    // MARK: - FilePickerServiceProtocol Methods

    public func presentFilePicker(options _: FilePickerOptions) async throws -> FilePickerResult {
        // TODO: Implement file picker presentation
        throw MediaError.unsupportedOperation("Not implemented")
    }

    public func getSupportedTypes() async -> [AppCore.UTType] {
        // TODO: Return supported UTTypes
        return []
    }

    public func isTypeSupported(_: AppCore.UTType) async -> Bool {
        // TODO: Check if type is supported
        return false
    }

    public func setDefaultOptions(_: FilePickerOptions) async {
        // TODO: Set default options
    }

    public func getCurrentOptions() async -> FilePickerOptions {
        // TODO: Get current options
        return FilePickerOptions(
            allowedTypes: [],
            allowsMultipleSelection: false,
            maxFileSize: nil
        )
    }

    // MARK: - Extended Methods

    public func pickFiles(
        allowedTypes _: [MediaType],
        allowsMultiple _: Bool,
        maxFileSize _: Int64?
    ) async throws -> [URL] {
        // TODO: Implement file picking with UIDocumentPickerViewController
        throw MediaError.unsupportedOperation("Not implemented")
    }

    public func pickFolder() async throws -> URL {
        // TODO: Implement folder picking
        throw MediaError.unsupportedOperation("Not implemented")
    }

    public func saveFile(
        _: URL,
        suggestedName _: String?,
        allowedTypes _: [MediaType]
    ) async throws -> URL {
        // TODO: Implement file saving
        throw MediaError.unsupportedOperation("Not implemented")
    }

    public nonisolated var isAvailable: Bool {
        true
    }

    public func getRecentlyPicked(limit: Int) async -> [URL] {
        Array(recentlyPicked.prefix(limit))
    }

    public func clearRecentlyPicked() async {
        recentlyPicked.removeAll()
    }
}
