import AppCore
@preconcurrency import AVFoundation
import CoreImage
import Foundation
import Vision

public typealias ValidationResult = AppCore.ValidationResult

/// iOS implementation of media metadata service
@available(iOS 16.0, *)
public actor MediaMetadataService: MediaMetadataServiceProtocol {
    public init() {}

    // MARK: - MediaMetadataServiceProtocol Methods

    public func extractMetadata(from data: Data, type: MediaType) async throws -> [MetadataField] {
        switch type {
        case .image:
            return try await extractImageMetadata(from: data)
        case .video:
            return try await extractVideoMetadata(from: data)
        case .document:
            return try await extractDocumentMetadata(from: data)
        default:
            return try await extractDocumentMetadata(from: data)
        }
    }

    public func getImageDimensions(from data: Data) async throws -> AppCore.CGSize {
        guard let cgImage = createCGImage(from: data) else {
            throw MediaError.invalidInput("Could not create CGImage from data")
        }
        return AppCore.CGSize(width: Double(cgImage.width), height: Double(cgImage.height))
    }

    public func extractText(from data: Data) async throws -> [ExtractedText] {
        guard let cgImage = createCGImage(from: data) else {
            throw MediaError.invalidInput("Could not create CGImage from data")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                var extractedTexts: [ExtractedText] = []
                for observation in request.results as? [VNRecognizedTextObservation] ?? [] {
                    if let topCandidate = observation.topCandidates(1).first {
                        let bounds = observation.boundingBox
                        extractedTexts.append(ExtractedText(
                            text: topCandidate.string,
                            confidence: Double(topCandidate.confidence),
                            boundingBox: CGRect(
                                x: bounds.origin.x,
                                y: bounds.origin.y,
                                width: bounds.size.width,
                                height: bounds.size.height
                            )
                        ))
                    }
                }
                continuation.resume(returning: extractedTexts)
            }
            
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }

    public func detectFaces(in data: Data) async throws -> [DetectedFace] {
        guard let cgImage = createCGImage(from: data) else {
            throw MediaError.invalidInput("Could not create CGImage from data")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                var detectedFaces: [DetectedFace] = []
                for observation in request.results as? [VNFaceObservation] ?? [] {
                    let bounds = observation.boundingBox
                    detectedFaces.append(DetectedFace(
                        boundingBox: CGRect(
                            x: bounds.origin.x,
                            y: bounds.origin.y,
                            width: bounds.size.width,
                            height: bounds.size.height
                        ),
                        confidence: Double(observation.confidence)
                    ))
                }
                continuation.resume(returning: detectedFaces)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }

    public func analyzeImage(_ data: Data) async throws -> ImageAnalysis {
        guard let cgImage = createCGImage(from: data) else {
            throw MediaError.invalidInput("Could not create CGImage from data")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                var labels: [String] = []
                for observation in request.results?.prefix(5) as? [VNClassificationObservation] ?? [] {
                    if observation.confidence > 0.1 {
                        labels.append(observation.identifier)
                    }
                }
                
                let analysis = ImageAnalysis(
                    sceneClassification: labels.map { SceneLabel(label: $0, confidence: 0.8) },
                    dominantColors: [], // Would require additional processing
                    qualityMetrics: ImageQualityMetrics(
                        brightness: 0.5,
                        contrast: 0.5,
                        saturation: 0.5,
                        overallQuality: 0.8
                    )
                )
                continuation.resume(returning: analysis)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }

    public func validateMetadata(_ fields: [MetadataField]) async -> MediaValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        for field in fields {
            // Validate field values based on type
            switch field.name {
            case "width", "height":
                if let value = Int(field.value), value <= 0 {
                    errors.append("Invalid dimension value for \(field.name): \(value)")
                }
            case "fileSize":
                if let value = Int64(field.value), value < 0 {
                    errors.append("Invalid file size: \(value)")
                }
            case "duration":
                if let value = Double(field.value), value < 0 {
                    errors.append("Invalid duration: \(value)")
                }
            default:
                // Check for empty required fields
                if field.value.isEmpty {
                    warnings.append("Missing value for field: \(field.name)")
                }
            }
        }
        
        return MediaValidationResult(
            isValid: errors.isEmpty,
            errors: errors.map { MediaValidationError(message: $0) },
            warnings: warnings.map { MediaValidationWarning(message: $0) }
        )
    }

    // MARK: - Extended Methods

    public func extractMetadata(from url: URL) async throws -> MediaMetadata {
        let data = try Data(contentsOf: url)
        let pathExtension = url.pathExtension.lowercased()
        
        let mediaType: MediaType
        switch pathExtension {
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic":
            mediaType = .image
        case "mp4", "mov", "avi", "mkv", "wmv":
            mediaType = .video
        case "mp3", "wav", "aac", "flac", "m4a":
            mediaType = .document
        default:
            mediaType = .document
        }
        
        let fields = try await extractMetadata(from: data, type: mediaType) as [MetadataField]
        // Convert MetadataField array back to MediaMetadata structure
        var width: Int?
        var height: Int?
        var fileSize: Int64?
        let fileName = url.lastPathComponent
        
        for field in fields {
            switch field.name {
            case "width":
                width = Int(field.value)
            case "height":
                height = Int(field.value)
            case "fileSize":
                fileSize = Int64(field.value)
            default:
                break
            }
        }
        
        return MediaMetadata(
            fileName: fileName,
            fileSize: fileSize ?? 0,
            mimeType: "application/octet-stream",
            securityInfo: SecurityInfo(isSafe: true),
            width: width,
            height: height
        )
    }

    public func extractMetadata(from data: Data, type: MediaType) async throws -> MediaMetadata {
        let fields = try await extractMetadata(from: data, type: type) as [MetadataField]
        // Convert MetadataField array back to MediaMetadata structure
        var width: Int?
        var height: Int?
        var fileSize: Int64?
        
        for field in fields {
            switch field.name {
            case "width":
                width = Int(field.value)
            case "height":
                height = Int(field.value)
            case "fileSize":
                fileSize = Int64(field.value)
            default:
                break
            }
        }
        
        return MediaMetadata(
            fileName: "unknown",
            fileSize: fileSize ?? Int64(data.count),
            mimeType: "application/octet-stream",
            securityInfo: SecurityInfo(isSafe: true),
            width: width,
            height: height
        )
    }

    public func writeMetadata(_ metadata: MediaMetadata, to url: URL) async throws {
        // For iOS, metadata writing is limited due to file system restrictions
        // This would typically require third-party libraries or specific file formats
        guard url.pathExtension.lowercased() == "jpg" || url.pathExtension.lowercased() == "jpeg" else {
            throw MediaError.unsupportedOperation("Metadata writing only supported for JPEG files")
        }
        
        // Basic implementation for JPEG metadata writing
        // In production, would use ImageIO framework for comprehensive metadata writing
        let data = try Data(contentsOf: url)
        guard let cgImage = createCGImage(from: data) else {
            throw MediaError.invalidInput("Could not create CGImage from file")
        }
        
        // Create new image data with metadata
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, "public.jpeg" as CFString, 1, nil) else {
            throw MediaError.processingFailed("Could not create image destination")
        }
        
        var properties: [String: Any] = [:]
        // Extract basic metadata properties
        if let fileName = metadata.fileName {
            properties["FileName"] = fileName
        }
        if let fileSize = metadata.fileSize {
            properties["FileSize"] = fileSize
        }
        if let mimeType = metadata.mimeType {
            properties["MIMEType"] = mimeType
        }
        
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw MediaError.processingFailed("Could not finalize image destination")
        }
        
        try mutableData.write(to: url)
    }

    public func removeMetadata(from url: URL, fields: Set<MetadataField>?) async throws -> URL {
        let data = try Data(contentsOf: url)
        guard let cgImage = createCGImage(from: data) else {
            throw MediaError.invalidInput("Could not create CGImage from file")
        }
        
        // Create clean image without metadata
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "." + url.pathExtension)
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, "public.jpeg" as CFString, 1, nil) else {
            throw MediaError.processingFailed("Could not create image destination")
        }
        
        // Add image without metadata or with filtered metadata
        var properties: [String: Any] = [:]
        if fields != nil {
            // Keep metadata that's not in the removal set
            // This is a simplified implementation
            properties = [:] // Remove all for simplicity
        }
        
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw MediaError.processingFailed("Could not finalize image destination")
        }
        
        try mutableData.write(to: tempURL)
        return tempURL
    }

    public func generateThumbnail(
        from url: URL,
        size: AppCore.CGSize,
        time: TimeInterval?
    ) async throws -> Data {
        let pathExtension = url.pathExtension.lowercased()
        
        if ["mp4", "mov", "avi", "mkv"].contains(pathExtension) {
            // Video thumbnail
            return try await generateVideoThumbnail(from: url, size: size, time: time ?? 0)
        } else {
            // Image thumbnail
            return try await generateImageThumbnail(from: url, size: size)
        }
    }

    public func extractText(from data: Data) async throws -> ExtractedText {
        let extractedTexts = try await extractText(from: data) as [ExtractedText]
        let combinedText = extractedTexts.map { $0.text }.joined(separator: " ")
        let averageConfidence = extractedTexts.isEmpty ? 0 : extractedTexts.map { $0.confidence }.reduce(0, +) / Double(extractedTexts.count)
        
        return ExtractedText(
            text: combinedText,
            confidence: Double(averageConfidence),
            boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1)
        )
    }

    public func analyzeImageContent(_ data: Data) async throws -> ImageAnalysis {
        return try await analyzeImage(data)
    }

    public func extractWaveform(from url: URL, samples: Int) async throws -> [Float] {
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw MediaError.processingFailed("Could not create audio buffer")
        }
        
        try audioFile.read(into: buffer)
        
        guard let channelData = buffer.floatChannelData?[0] else {
            throw MediaError.processingFailed("Could not access audio channel data")
        }
        
        // Downsample to requested number of samples
        let stride = Int(frameCount) / samples
        var waveform: [Float] = []
        
        for i in 0..<samples {
            let startIndex = i * stride
            let endIndex = min(startIndex + stride, Int(frameCount))
            
            var sum: Float = 0
            for j in startIndex..<endIndex {
                sum += abs(channelData[j])
            }
            waveform.append(sum / Float(endIndex - startIndex))
        }
        
        return waveform
    }

    public func extractVideoFrame(from url: URL, at time: TimeInterval) async throws -> Data {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        
        return try await withCheckedThrowingContinuation { continuation in
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: cmTime)]) { _, cgImage, _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let cgImage = cgImage else {
                    continuation.resume(throwing: MediaError.processingFailed("Could not generate frame"))
                    return
                }
                
                let mutableData = NSMutableData()
                guard let destination = CGImageDestinationCreateWithData(mutableData, "public.jpeg" as CFString, 1, nil) else {
                    continuation.resume(throwing: MediaError.processingFailed("Could not create image destination"))
                    return
                }
                
                CGImageDestinationAddImage(destination, cgImage, nil)
                
                guard CGImageDestinationFinalize(destination) else {
                    continuation.resume(throwing: MediaError.processingFailed("Could not finalize image destination"))
                    return
                }
                
                continuation.resume(returning: mutableData as Data)
            }
        }
    }

    public func getAllMetadata(from url: URL) async throws -> [String: Any] {
        let metadata = try await extractMetadata(from: url)
        var result: [String: Any] = [:]
        
        // Extract metadata properties into dictionary
        if let fileName = metadata.fileName {
            result["fileName"] = fileName
        }
        if let fileSize = metadata.fileSize {
            result["fileSize"] = fileSize
        }
        if let mimeType = metadata.mimeType {
            result["mimeType"] = mimeType
        }
        if let width = metadata.width {
            result["width"] = width
        }
        if let height = metadata.height {
            result["height"] = height
        }
        
        // Add EXIF data
        for (key, value) in metadata.exifData {
            result[key] = value
        }
        
        return result
    }
    
    // MARK: - Helper Methods
    
    private func createCGImage(from data: Data) -> CGImage? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        return cgImage
    }
    
    private func extractImageMetadata(from data: Data) async throws -> [MetadataField] {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw MediaError.invalidInput("Could not create image source")
        }
        
        var fields: [MetadataField] = []
        
        if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
            // Extract basic image properties
            if let width = properties[kCGImagePropertyPixelWidth as String] as? Int {
                fields.append(MetadataField(name: "width", type: .dimension, value: String(width), source: .exif))
            }
            if let height = properties[kCGImagePropertyPixelHeight as String] as? Int {
                fields.append(MetadataField(name: "height", type: .dimension, value: String(height), source: .exif))
            }
            if let colorModel = properties[kCGImagePropertyColorModel as String] as? String {
                fields.append(MetadataField(name: "colorModel", type: .text, value: colorModel, source: .exif))
            }
            
            // Extract EXIF data if available
            if let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
                for (key, value) in exifDict {
                    fields.append(MetadataField(name: "exif_\(key)", type: .text, value: String(describing: value), source: .exif))
                }
            }
        }
        
        // Add file size
        fields.append(MetadataField(name: "fileSize", type: .number, value: String(data.count), source: .system))
        
        return fields
    }
    
    private func extractVideoMetadata(from data: Data) async throws -> [MetadataField] {
        // Create temporary file for AVAsset (AVAsset requires file URL)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        try data.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let asset = AVAsset(url: tempURL)
        var fields: [MetadataField] = []
        
        // Extract duration
        let duration = try await asset.load(.duration)
        fields.append(MetadataField(name: "duration", type: .duration, value: String(CMTimeGetSeconds(duration)), source: .system))
        
        // Extract tracks info
        let tracks = try await asset.load(.tracks)
        fields.append(MetadataField(name: "trackCount", type: .number, value: String(tracks.count), source: .system))
        
        // Extract video tracks info
        for track in tracks {
            let mediaType = track.mediaType
            if mediaType == AVMediaType.video {
                let naturalSize = try await track.load(.naturalSize)
                fields.append(MetadataField(name: "videoWidth", type: .dimension, value: String(Int(naturalSize.width)), source: .system))
                fields.append(MetadataField(name: "videoHeight", type: .dimension, value: String(Int(naturalSize.height)), source: .system))
            }
        }
        
        fields.append(MetadataField(name: "fileSize", type: .number, value: String(data.count), source: .system))
        
        return fields
    }
    
    private func extractAudioMetadata(from data: Data) async throws -> [MetadataField] {
        // Create temporary file for AVAudioFile
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        try data.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let audioFile = try AVAudioFile(forReading: tempURL)
        var fields: [MetadataField] = []
        
        fields.append(MetadataField(name: "duration", type: .duration, value: String(TimeInterval(audioFile.length) / audioFile.fileFormat.sampleRate), source: .system))
        fields.append(MetadataField(name: "sampleRate", type: .number, value: String(audioFile.fileFormat.sampleRate), source: .system))
        fields.append(MetadataField(name: "channelCount", type: .number, value: String(audioFile.fileFormat.channelCount), source: .system))
        fields.append(MetadataField(name: "fileSize", type: .number, value: String(data.count), source: .system))
        
        return fields
    }
    
    private func extractDocumentMetadata(from data: Data) async throws -> [MetadataField] {
        var fields: [MetadataField] = []
        
        // Basic document metadata
        fields.append(MetadataField(name: "fileSize", type: .number, value: String(data.count), source: .system))
        fields.append(MetadataField(name: "type", type: .text, value: "document", source: .system))
        
        // Try to detect if it's a PDF or other structured document
        if data.starts(with: Data([0x25, 0x50, 0x44, 0x46])) { // PDF signature
            fields.append(MetadataField(name: "format", type: .text, value: "PDF", source: .system))
        }
        
        return fields
    }
    
    private func generateImageThumbnail(from url: URL, size: AppCore.CGSize) async throws -> Data {
        let data = try Data(contentsOf: url)
        guard let cgImage = createCGImage(from: data) else {
            throw MediaError.invalidInput("Could not create CGImage from file")
        }
        
        // Calculate aspect-fit size
        let originalSize = CoreGraphics.CGSize(width: cgImage.width, height: cgImage.height)
        let targetSize = CoreGraphics.CGSize(width: size.width, height: size.height)
        let aspectRatio = min(targetSize.width / originalSize.width, targetSize.height / originalSize.height)
        let scaledSize = CoreGraphics.CGSize(width: originalSize.width * aspectRatio, height: originalSize.height * aspectRatio)
        
        // Create scaled image
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil, width: Int(scaledSize.width), height: Int(scaledSize.height),
                                    bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw MediaError.processingFailed("Could not create graphics context")
        }
        
        context.draw(cgImage, in: CGRect(origin: .zero, size: scaledSize))
        
        guard let scaledImage = context.makeImage() else {
            throw MediaError.processingFailed("Could not create scaled image")
        }
        
        // Convert to JPEG data
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, "public.jpeg" as CFString, 1, nil) else {
            throw MediaError.processingFailed("Could not create image destination")
        }
        
        CGImageDestinationAddImage(destination, scaledImage, nil)
        
        guard CGImageDestinationFinalize(destination) else {
            throw MediaError.processingFailed("Could not finalize image destination")
        }
        
        return mutableData as Data
    }
    
    private func generateVideoThumbnail(from url: URL, size: AppCore.CGSize, time: TimeInterval) async throws -> Data {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CoreGraphics.CGSize(width: size.width, height: size.height)
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        
        return try await withCheckedThrowingContinuation { continuation in
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: cmTime)]) { _, cgImage, _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let cgImage = cgImage else {
                    continuation.resume(throwing: MediaError.processingFailed("Could not generate video thumbnail"))
                    return
                }
                
                let mutableData = NSMutableData()
                guard let destination = CGImageDestinationCreateWithData(mutableData, "public.jpeg" as CFString, 1, nil) else {
                    continuation.resume(throwing: MediaError.processingFailed("Could not create image destination"))
                    return
                }
                
                CGImageDestinationAddImage(destination, cgImage, nil)
                
                guard CGImageDestinationFinalize(destination) else {
                    continuation.resume(throwing: MediaError.processingFailed("Could not finalize image destination"))
                    return
                }
                
                continuation.resume(returning: mutableData as Data)
            }
        }
    }
}
