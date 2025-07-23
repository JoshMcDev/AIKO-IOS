import AppCore
import Foundation
import Photos
import PhotosUI

/// iOS implementation of photo library service
@available(iOS 16.0, *)
public actor PhotoLibraryService: PhotoLibraryServiceProtocol {
    public init() {}

    public func requestAuthorization() async throws -> PhotoLibraryAuthorizationStatus {
        // TODO: Implement PHPhotoLibrary authorization
        throw MediaError.unsupportedOperation("Not implemented")
    }

    public func getAuthorizationStatus() async -> PhotoLibraryAuthorizationStatus {
        // TODO: Check PHPhotoLibrary.authorizationStatus
        .notDetermined
    }

    public func fetchPhotos(
        mediaTypes _: Set<PhotoMediaType>,
        limit _: Int?,
        sortOrder _: PhotoSortOrder
    ) async throws -> [PhotoAsset] {
        // TODO: Implement PHAsset fetching
        throw MediaError.unsupportedOperation("Not implemented")
    }

    public func fetchAlbums(types _: Set<AlbumType>) async throws -> [PhotoAlbum] {
        // TODO: Implement PHAssetCollection fetching
        throw MediaError.unsupportedOperation("Not implemented")
    }

    public func fetchPhotosFromAlbum(_: PhotoAlbum) async throws -> [PhotoAsset] {
        // TODO: Implement album photo fetching
        throw MediaError.unsupportedOperation("Not implemented")
    }

    public func exportAssetData(_: PhotoAsset, options _: ExportOptions) async throws -> Data {
        // TODO: Implement PHAsset export
        throw MediaError.unsupportedOperation("Not implemented")
    }

    public func saveImageToLibrary(_: Data) async throws -> String {
        // TODO: Implement PHPhotoLibrary image saving
        throw MediaError.unsupportedOperation("Not implemented")
    }

    public func saveVideoToLibrary(_: URL) async throws -> String {
        // TODO: Implement PHPhotoLibrary video saving
        throw MediaError.unsupportedOperation("Not implemented")
    }

    public func deleteAssets(_: [PhotoAsset]) async throws {
        // TODO: Implement PHAsset deletion
        throw MediaError.unsupportedOperation("Not implemented")
    }

    public func assetExists(_: String) async -> Bool {
        // TODO: Check if PHAsset exists
        false
    }
}
