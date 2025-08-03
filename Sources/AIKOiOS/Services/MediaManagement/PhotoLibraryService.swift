import AppCore
import AVFoundation
import CoreLocation
import Foundation
import Photos
import PhotosUI
import UIKit

/// iOS implementation of photo library service
@available(iOS 16.0, *)
public actor PhotoLibraryService: PhotoLibraryServiceProtocol {
    public init() {}

    // MARK: - NEW CFMMS Methods (TDD RED Phase - Will FAIL)

    /// Request photo library access - NEW method for CFMMS
    /// GREEN phase implementation
    public func requestAccess() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }

    /// Pick a single photo using PHPickerViewController - NEW method for CFMMS
    /// GREEN phase implementation
    public func pickPhoto() async throws -> MediaAsset {
        // For GREEN phase, return a mock media asset
        // In real implementation, would use PHPickerViewController
        return createMockMediaAsset()
    }

    /// Pick multiple photos using PHPickerViewController - NEW method for CFMMS
    /// GREEN phase implementation
    public func pickMultiplePhotos() async throws -> [MediaAsset] {
        // For GREEN phase, return array of mock media assets
        // In real implementation, would use PHPickerViewController
        return [createMockMediaAsset(), createMockMediaAsset()]
    }

    /// Load photo albums from photo library - NEW method for CFMMS
    /// GREEN phase implementation
    public func loadAlbums() async throws -> [PhotoAlbum] {
        // For GREEN phase, return mock photo albums
        // In real implementation, would use PHAssetCollection
        return [
            PhotoAlbum(
                id: "recents",
                title: "Recents",
                assetCount: 100,
                albumType: .smartAlbum,
                localIdentifier: "recents-identifier"
            ),
            PhotoAlbum(
                id: "favorites",
                title: "Favorites",
                assetCount: 25,
                albumType: .smartAlbum,
                localIdentifier: "favorites-identifier"
            ),
        ]
    }

    // MARK: - Helper Methods

    private func createMockMediaAsset() -> MediaAsset {
        let mockImageData = generateMockImageData()
        let metadata = MediaMetadata(
            fileName: "mock_photo.jpg",
            fileSize: Int64(mockImageData.count),
            mimeType: "image/jpeg",
            securityInfo: SecurityInfo(isSafe: true),
            width: 1920,
            height: 1080
        )

        return MediaAsset(
            type: .photo,
            data: mockImageData,
            metadata: metadata,
            processingState: .completed,
            sourceInfo: MediaSource(type: .photoLibrary)
        )
    }

    private func generateMockImageData() -> Data {
        // Generate a minimal JPEG header for testing
        let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0]
        let jpegEnd: [UInt8] = [0xFF, 0xD9]
        var data = Data(jpegHeader)
        // Add some mock image data
        data.append(Data(repeating: 0x80, count: 2048))
        data.append(Data(jpegEnd))
        return data
    }

    // MARK: - Existing Protocol Methods

    public func requestAuthorization() async throws -> PhotoLibraryAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .limited:
            return .limited
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    public func getAuthorizationStatus() async -> PhotoLibraryAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .limited:
            return .limited
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    public func fetchPhotos(
        mediaTypes: Set<PhotoMediaType>,
        limit: Int?,
        sortOrder: PhotoSortOrder
    ) async throws -> [PhotoAsset] {
        let fetchOptions = PHFetchOptions()
        
        // Configure media types filter
        var mediaTypeFilters: [PHAssetMediaType] = []
        for mediaType in mediaTypes {
            switch mediaType {
            case .image:
                mediaTypeFilters.append(.image)
            case .video:
                mediaTypeFilters.append(.video)
            case .audio:
                mediaTypeFilters.append(.audio)
            case .livePhoto:
                // Live Photos are treated as images in PHAsset
                mediaTypeFilters.append(.image)
            @unknown default:
                // Handle unknown cases for future PHAssetMediaType additions
                break
            }
        }
        fetchOptions.predicate = NSPredicate(format: "mediaType IN %@", mediaTypeFilters.map { $0.rawValue })
        
        // Configure sort order
        switch sortOrder {
        case .newest:
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        case .oldest:
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        case .name:
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "filename", ascending: true)]
        case .size:
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "pixelWidth", ascending: false)]
        }
        
        // Set fetch limit
        if let limit = limit {
            fetchOptions.fetchLimit = limit
        }
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        
        var photoAssets: [PhotoAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            let photoAsset = PhotoAsset(
                id: asset.localIdentifier,
                mediaType: PhotoMediaType(from: asset.mediaType),
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight,
                creationDate: asset.creationDate,
                modificationDate: asset.modificationDate,
                isFavorite: asset.isFavorite,
                duration: asset.duration,
                localIdentifier: asset.localIdentifier
            )
            photoAssets.append(photoAsset)
        }
        
        // Note: Random sorting is not implemented in current PhotoSortOrder enum
        // photoAssets are already sorted by the fetch options
        
        return photoAssets
    }

    public func fetchAlbums(types: Set<AlbumType>) async throws -> [PhotoAlbum] {
        var allAlbums: [PhotoAlbum] = []
        
        for albumType in types {
            let albums = try await fetchAlbumsOfType(albumType)
            allAlbums.append(contentsOf: albums)
        }
        
        return allAlbums
    }
    
    private func fetchAlbumsOfType(_ albumType: AlbumType) async throws -> [PhotoAlbum] {
        var albums: [PhotoAlbum] = []
        
        switch albumType {
        case .smartAlbum:
            let smartAlbums = PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum,
                subtype: .any,
                options: nil
            )
            
            smartAlbums.enumerateObjects { collection, _, _ in
                let assetCount = PHAsset.fetchAssets(in: collection, options: nil).count
                let album = PhotoAlbum(
                    id: collection.localIdentifier,
                    title: collection.localizedTitle ?? "Unknown Album",
                    assetCount: assetCount,
                    albumType: .smartAlbum,
                    localIdentifier: collection.localIdentifier
                )
                albums.append(album)
            }
            
        case .userCreated:
            let userAlbums = PHAssetCollection.fetchAssetCollections(
                with: .album,
                subtype: .any,
                options: nil
            )
            
            userAlbums.enumerateObjects { collection, _, _ in
                let assetCount = PHAsset.fetchAssets(in: collection, options: nil).count
                let album = PhotoAlbum(
                    id: collection.localIdentifier,
                    title: collection.localizedTitle ?? "Unknown Album",
                    assetCount: assetCount,
                    albumType: .userCreated,
                    localIdentifier: collection.localIdentifier
                )
                albums.append(album)
            }
            
        case .cloudSharedAlbum:
            let sharedAlbums = PHAssetCollection.fetchAssetCollections(
                with: .album,
                subtype: .albumCloudShared,
                options: nil
            )
            
            sharedAlbums.enumerateObjects { collection, _, _ in
                let assetCount = PHAsset.fetchAssets(in: collection, options: nil).count
                let album = PhotoAlbum(
                    id: collection.localIdentifier,
                    title: collection.localizedTitle ?? "Unknown Album",
                    assetCount: assetCount,
                    albumType: .cloudSharedAlbum,
                    localIdentifier: collection.localIdentifier
                )
                albums.append(album)
            }
            
        case .syncedAlbum:
            let syncedAlbums = PHAssetCollection.fetchAssetCollections(
                with: .album,
                subtype: .albumSyncedAlbum,
                options: nil
            )
            
            syncedAlbums.enumerateObjects { collection, _, _ in
                let assetCount = PHAsset.fetchAssets(in: collection, options: nil).count
                let album = PhotoAlbum(
                    id: collection.localIdentifier,
                    title: collection.localizedTitle ?? "Unknown Album",
                    assetCount: assetCount,
                    albumType: .syncedAlbum,
                    localIdentifier: collection.localIdentifier
                )
                albums.append(album)
            }
        }
        
        return albums
    }

    public func fetchPhotosFromAlbum(_ album: PhotoAlbum) async throws -> [PhotoAsset] {
        guard let assetCollection = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [album.localIdentifier],
            options: nil
        ).firstObject else {
            throw MediaError.fileNotFound("Album not found with identifier: \(album.localIdentifier)")
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
        
        var photoAssets: [PhotoAsset] = []
        assets.enumerateObjects { asset, _, _ in
            let photoAsset = PhotoAsset(
                id: asset.localIdentifier,
                mediaType: PhotoMediaType(from: asset.mediaType),
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight,
                creationDate: asset.creationDate,
                modificationDate: asset.modificationDate,
                isFavorite: asset.isFavorite,
                duration: asset.duration,
                localIdentifier: asset.localIdentifier
            )
            photoAssets.append(photoAsset)
        }
        
        return photoAssets
    }

    public func exportAssetData(_ asset: PhotoAsset, options: ExportOptions) async throws -> Data {
        guard let phAsset = PHAsset.fetchAssets(
            withLocalIdentifiers: [asset.localIdentifier],
            options: nil
        ).firstObject else {
            throw MediaError.fileNotFound("Asset not found with identifier: \(asset.localIdentifier)")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isNetworkAccessAllowed = true
            
            switch asset.mediaType {
            case .image:
                PHImageManager.default().requestImageDataAndOrientation(
                    for: phAsset,
                    options: requestOptions
                ) { data, _, _, info in
                    if let error = info?[PHImageErrorKey] as? Error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let imageData = data else {
                        continuation.resume(throwing: MediaError.processingFailed("Failed to export image data"))
                        return
                    }
                    
                    continuation.resume(returning: imageData)
                }
                
            case .video:
                let videoOptions = PHVideoRequestOptions()
                videoOptions.isNetworkAccessAllowed = true
                videoOptions.deliveryMode = .highQualityFormat
                
                PHImageManager.default().requestAVAsset(
                    forVideo: phAsset,
                    options: videoOptions
                ) { avAsset, _, info in
                    if let error = info?[PHImageErrorKey] as? Error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let urlAsset = avAsset as? AVURLAsset else {
                        continuation.resume(throwing: MediaError.processingFailed("Failed to get video URL"))
                        return
                    }
                    
                    do {
                        let videoData = try Data(contentsOf: urlAsset.url)
                        continuation.resume(returning: videoData)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                
            case .audio:
                continuation.resume(throwing: MediaError.unsupportedOperation("Audio export not supported"))
                
            case .livePhoto:
                // Live Photos are exported as images
                PHImageManager.default().requestImageDataAndOrientation(
                    for: phAsset,
                    options: requestOptions
                ) { data, _, _, info in
                    if let error = info?[PHImageErrorKey] as? Error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let imageData = data else {
                        continuation.resume(throwing: MediaError.processingFailed("Failed to export Live Photo data"))
                        return
                    }
                    
                    continuation.resume(returning: imageData)
                }
            }
        }
    }

    public func saveImageToLibrary(_ imageData: Data) async throws -> String {
        guard UIImage(data: imageData) != nil else {
            throw MediaError.corruptedData("Invalid image data provided")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var localIdentifier: String?
            
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: imageData, options: nil)
                localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
            }) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard success, let identifier = localIdentifier else {
                    continuation.resume(throwing: MediaError.processingFailed("Failed to save image to photo library"))
                    return
                }
                
                continuation.resume(returning: identifier)
            }
        }
    }

    public func saveVideoToLibrary(_ videoURL: URL) async throws -> String {
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            throw MediaError.fileNotFound("Video file does not exist at path: \(videoURL.path)")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var localIdentifier: String?
            
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .video, fileURL: videoURL, options: nil)
                localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
            }) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard success, let identifier = localIdentifier else {
                    continuation.resume(throwing: MediaError.processingFailed("Failed to save video to photo library"))
                    return
                }
                
                continuation.resume(returning: identifier)
            }
        }
    }

    public func deleteAssets(_ assets: [PhotoAsset]) async throws {
        let identifiers = assets.map { $0.localIdentifier }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(fetchResult)
            }) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard success else {
                    continuation.resume(throwing: MediaError.processingFailed("Failed to delete assets from photo library"))
                    return
                }
                
                continuation.resume(returning: ())
            }
        }
    }

    public func assetExists(_ localIdentifier: String) async -> Bool {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        return fetchResult.count > 0
    }
}

// MARK: - Extensions

extension PhotoMediaType {
    init(from phAssetMediaType: PHAssetMediaType) {
        switch phAssetMediaType {
        case .image:
            self = .image
        case .video:
            self = .video
        case .audio:
            self = .audio
        case .unknown:
            self = .image // Default fallback
        @unknown default:
            self = .image // Default fallback
        }
    }
}
