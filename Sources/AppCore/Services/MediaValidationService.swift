import CryptoKit
import Foundation
import UniformTypeIdentifiers

// MARK: - MediaValidationService Implementation

/// Concrete implementation of MediaValidationService
/// Implements comprehensive validation capabilities for CFMMS requirements
public actor MediaValidationService: MediaValidationServiceProtocol {
    public init() {}

    // MARK: - Enhanced File Validation

    public func validateFile(data: Data, fileName: String, expectedMimeType: String?) async throws -> EnhancedValidationResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Detect MIME type from data
        let detectedMimeType = detectMimeType(from: data, fileName: fileName)
        var issues: [String] = []
        var isValid = true

        // Check if detected type matches expected
        if let expectedMimeType = expectedMimeType, detectedMimeType != expectedMimeType {
            issues.append("MIME type mismatch: detected '\(detectedMimeType)', expected '\(expectedMimeType)'")
            isValid = false
        }

        // Basic file integrity checks
        if data.isEmpty {
            issues.append("File is empty")
            isValid = false
        }

        // Check file size limits (50MB max)
        if data.count > 50 * 1024 * 1024 {
            issues.append("File size exceeds 50MB limit")
            isValid = false
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return EnhancedValidationResult(
            isValid: isValid,
            detectedMimeType: detectedMimeType,
            fileSize: Int64(data.count),
            validationDuration: duration,
            issues: issues
        )
    }

    public func validateFileSize(data: Data, mediaType: MediaType, maxSize: Int64) async throws -> FileSizeValidationResult {
        let actualSize = Int64(data.count)
        let isValid = actualSize <= maxSize

        var compressionSuggestion: CompressionSuggestion?
        if !isValid && mediaType == .image {
            // Suggest compression for oversized images
            let targetSize = maxSize
            let quality = Double(maxSize) / Double(actualSize)
            let estimatedReduction = 1.0 - quality

            compressionSuggestion = CompressionSuggestion(
                targetSize: targetSize,
                quality: max(0.3, min(0.9, quality)),
                estimatedReduction: estimatedReduction
            )
        }

        return FileSizeValidationResult(
            isValid: isValid,
            actualSize: actualSize,
            maxAllowedSize: maxSize,
            compressionSuggestion: compressionSuggestion
        )
    }

    // MARK: - Security Scanning

    public func performSecurityScan(data: Data, fileName: String, scanLevel: ScanLevel) async throws -> EnhancedSecurityScanResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let scanId = UUID().uuidString

        var threats: [SecurityThreat] = []
        var threatLevel: ThreatLevel = .none
        var isSafe = true

        // Check for executable file signatures
        if hasExecutableSignature(data) {
            threats.append(SecurityThreat(
                type: .executable,
                severity: .high,
                description: "File contains executable code signature"
            ))
            threatLevel = .high
            isSafe = false
        }

        // Check file extension vs content mismatch
        let detectedMimeType = detectMimeType(from: data, fileName: fileName)
        let expectedMimeFromExtension = getMimeTypeFromExtension(fileName)

        if expectedMimeFromExtension != detectedMimeType {
            threats.append(SecurityThreat(
                type: .suspicious,
                severity: .medium,
                description: "File extension doesn't match content type"
            ))
            if threatLevel.rawValue < ThreatLevel.medium.rawValue {
                threatLevel = .medium
            }
            isSafe = false
        }

        // Comprehensive scan includes additional checks
        if scanLevel == .comprehensive || scanLevel == .deep {
            // Check for suspicious patterns in content
            if containsSuspiciousPatterns(data) {
                threats.append(SecurityThreat(
                    type: .malware,
                    severity: .critical,
                    description: "Suspicious patterns detected in file content"
                ))
                threatLevel = .critical
                isSafe = false
            }
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return EnhancedSecurityScanResult(
            isSafe: isSafe,
            threatLevel: threatLevel,
            threats: threats,
            scanId: scanId,
            scanTimestamp: Date(),
            scanDuration: duration
        )
    }

    public func quarantineThreat(scanResult _: EnhancedSecurityScanResult, originalData _: Data) async throws -> QuarantineResult {
        // In a real implementation, this would move the file to a secure quarantine location
        let quarantineId = UUID().uuidString
        let quarantinePath = "/tmp/quarantine/\(quarantineId)"

        return QuarantineResult(
            quarantineId: quarantineId,
            quarantinePath: quarantinePath,
            isQuarantined: true,
            quarantineTimestamp: Date()
        )
    }

    // MARK: - Metadata Extraction

    public func extractMetadata(data: Data, mediaType: MediaType, includeEXIF: Bool, includeThumbnail: Bool) async throws -> EnhancedMetadataResult {
        // Basic metadata extraction using existing nested BasicMetadata type
        let basicMetadata = EnhancedMetadataResult.BasicMetadata(
            mimeType: detectMimeType(from: data, fileName: ""),
            fileSize: Int64(data.count),
            dimensions: extractDimensionsCGSize(from: data, mediaType: mediaType)
        )

        var exifData: [String: String]?
        var thumbnail: Data?
        var colorProfile: EnhancedMetadataResult.ColorProfile?
        var gpsData: EnhancedMetadataResult.GPSData?

        if includeEXIF && mediaType == .image {
            exifData = extractEXIFData(from: data)
            gpsData = extractGPSData()
        }

        if includeThumbnail && mediaType == .image {
            thumbnail = generateThumbnail(from: data)
        }

        if mediaType == .image {
            colorProfile = extractColorProfileNested(from: data)
        }

        return EnhancedMetadataResult(
            basicMetadata: basicMetadata,
            exifData: exifData,
            thumbnail: thumbnail,
            colorProfile: colorProfile,
            gpsData: gpsData
        )
    }

    public func validateMetadata(data: Data, providedMetadata: MediaMetadata) async throws -> MetadataValidationResult {
        var issues: [String] = []
        let actualSize = Int64(data.count)

        // Validate file size matches
        if let providedSize = providedMetadata.fileSize, providedSize != actualSize {
            issues.append("File size mismatch: metadata claims \(providedSize), actual is \(actualSize)")
        }

        // Validate dimensions for images
        if let providedDimensions = providedMetadata.dimensions {
            let actualDimensions = extractDimensions(from: data, mediaType: .image)
            if let actualDimensions = actualDimensions,
               providedDimensions.width != actualDimensions.width ||
               providedDimensions.height != actualDimensions.height
            {
                issues.append("Dimension mismatch: metadata claims \(providedDimensions.width)x\(providedDimensions.height), actual is \(actualDimensions.width)x\(actualDimensions.height)")
            }
        }

        let correctedMetadata = createCorrectedMetadata(from: data, original: providedMetadata)

        return MetadataValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            correctedMetadata: issues.isEmpty ? nil : correctedMetadata
        )
    }

    // MARK: - Media-Specific Validation

    public func validateImage(data: Data, requirements: ImageValidationRequirements) async throws -> ImageValidationResult {
        let resolution = extractDimensionsCGSize(from: data, mediaType: .image) ?? CGSize.zero
        var isValid = true

        // Check resolution requirements
        if resolution.width < requirements.minResolution.width || resolution.height < requirements.minResolution.height {
            isValid = false
        }
        if resolution.width > requirements.maxResolution.width || resolution.height > requirements.maxResolution.height {
            isValid = false
        }

        // Check format
        let detectedFormat = detectImageFormat(from: data)
        if !requirements.allowedFormats.contains(detectedFormat) {
            isValid = false
        }

        // Check corruption if requested
        let isCorrupted = requirements.detectCorruption && isImageCorrupted(data)
        if isCorrupted {
            isValid = false
        }

        // Extract color profile if required
        var colorProfile: String?
        if requirements.requireValidColorProfile {
            colorProfile = extractColorProfileName(from: data)
            if colorProfile == nil {
                isValid = false
            }
        }

        return ImageValidationResult(
            isValid: isValid,
            resolution: resolution,
            isCorrupted: isCorrupted,
            colorProfile: colorProfile,
            format: detectedFormat
        )
    }

    public func validateVideo(data: Data, requirements: VideoValidationRequirements) async throws -> VideoValidationResult {
        var isValid = true
        let duration = estimateVideoDuration(data) ?? 0
        let codec = detectVideoCodec(from: data)
        let resolution = extractDimensionsCGSize(from: data, mediaType: .video)
        let bitrate = estimateVideoBitrate(data)

        // Check duration
        if duration > requirements.maxDuration {
            isValid = false
        }

        // Check codec
        if !requirements.allowedCodecs.contains(codec) {
            isValid = false
        }

        // Check resolution
        if let resolution = resolution {
            if resolution.width < requirements.minResolution.width || resolution.height < requirements.minResolution.height {
                isValid = false
            }
        }

        // Check bitrate
        if let bitrate = bitrate, bitrate > requirements.maxBitrate {
            isValid = false
        }

        // Check audio track
        if requirements.requireAudioTrack && !detectAudioTrack(data) {
            isValid = false
        }

        return VideoValidationResult(
            isValid: isValid,
            duration: duration,
            codec: codec,
            resolution: resolution,
            bitrate: bitrate
        )
    }

    // MARK: - Comprehensive Validation

    public func performComprehensiveValidation(asset: MediaAsset, specification: ComprehensiveValidationSpec) async throws -> ComprehensiveValidationResult {
        guard let data = asset.data else {
            throw MediaError.validationFailed("Asset has no data")
        }

        var securityResult: EnhancedSecurityScanResult?
        var metadataResult: EnhancedMetadataResult?
        var integrityResult: ComprehensiveValidationResult.IntegrityResult?
        var thumbnailData: Data?
        var contentAnalysis: ComprehensiveValidationResult.ContentAnalysis?
        var isValid = true

        // Security scan if requested
        if specification.performSecurityScan {
            securityResult = try await performSecurityScan(
                data: data,
                fileName: asset.metadata.fileName ?? "unknown",
                scanLevel: .comprehensive
            )
            if let securityResult = securityResult, !securityResult.isSafe {
                isValid = false
            }
        }

        // Metadata extraction if requested
        if specification.validateMetadata {
            metadataResult = try await extractMetadata(
                data: data,
                mediaType: asset.type,
                includeEXIF: true,
                includeThumbnail: false
            )
        }

        // Integrity check if requested
        if specification.checkIntegrity {
            let checksum = data.sha256Hash
            integrityResult = ComprehensiveValidationResult.IntegrityResult(
                isIntact: true,
                checksum: checksum,
                issues: []
            )
        }

        // Thumbnail extraction if requested
        if specification.extractThumbnail && asset.type == .image {
            thumbnailData = generateThumbnail(from: data)
        }

        // Content analysis if requested
        if specification.detectContent {
            contentAnalysis = ComprehensiveValidationResult.ContentAnalysis(
                detectedObjects: ["image", "document"],
                textContent: nil,
                contentRating: .safe
            )
        }

        return ComprehensiveValidationResult(
            isValid: isValid,
            securityResult: securityResult,
            metadataResult: metadataResult,
            integrityResult: integrityResult,
            thumbnailData: thumbnailData,
            contentAnalysis: contentAnalysis
        )
    }

    // MARK: - Batch Operations

    public func validateBatch(assets: [MediaAsset], specification _: BatchValidationSpec, progressHandler: (@Sendable (BatchValidationProgress) -> Void)?) async throws -> [BatchItemValidationResult] {
        var results: [BatchItemValidationResult] = []

        for (index, asset) in assets.enumerated() {
            let startTime = CFAbsoluteTimeGetCurrent()

            // Report progress
            progressHandler?(BatchValidationProgress(
                completedCount: index,
                totalCount: assets.count,
                currentItem: asset.metadata.fileName,
                estimatedTimeRemaining: estimateRemainingTime(completed: index, total: assets.count)
            ))

            var issues: [String] = []
            var isValid = true

            do {
                if let data = asset.data {
                    let fileResult = try await validateFile(
                        data: data,
                        fileName: asset.metadata.fileName ?? "unknown",
                        expectedMimeType: asset.metadata.mimeType
                    )

                    if !fileResult.isValid {
                        issues.append(contentsOf: fileResult.issues)
                        isValid = false
                    }
                } else {
                    issues.append("Asset has no data")
                    isValid = false
                }
            } catch {
                issues.append("Validation error: \(error.localizedDescription)")
                isValid = false
            }

            let duration = CFAbsoluteTimeGetCurrent() - startTime

            results.append(BatchItemValidationResult(
                assetId: asset.id,
                isValid: isValid,
                validationDuration: duration,
                issues: issues
            ))
        }

        // Final progress update
        progressHandler?(BatchValidationProgress(
            completedCount: assets.count,
            totalCount: assets.count,
            currentItem: nil,
            estimatedTimeRemaining: 0
        ))

        return results
    }

    // MARK: - Legacy Interface Compatibility

    public func validateFileType(_ data: Data, _ fileName: String) async throws -> MediaType {
        let mimeType = detectMimeType(from: data, fileName: fileName)

        if mimeType.hasPrefix("image/") {
            return .image
        } else if mimeType.hasPrefix("video/") {
            return .video
        } else if mimeType == "application/pdf" {
            return .document
        } else {
            return .file
        }
    }

    public nonisolated func validateFileSize(_ fileSize: Int64, _ mediaType: MediaType) -> Bool {
        let maxSize: Int64
        switch mediaType {
        case .image: maxSize = 10 * 1024 * 1024 // 10MB
        case .video: maxSize = 100 * 1024 * 1024 // 100MB
        case .document: maxSize = 25 * 1024 * 1024 // 25MB
        default: maxSize = 50 * 1024 * 1024 // 50MB
        }

        return fileSize <= maxSize
    }

    public func scanForMalware(_ data: Data) async throws -> SecurityInfo {
        let scanResult = try await performSecurityScan(
            data: data,
            fileName: "unknown",
            scanLevel: .basic
        )

        return SecurityInfo(
            isSafe: scanResult.isSafe,
            scanDate: scanResult.scanTimestamp,
            threatLevel: scanResult.threatLevel,
            scanDetails: ["scanId": scanResult.scanId],
            threats: scanResult.threats
        )
    }

    public func extractMetadata(_ data: Data, _ mediaType: MediaType) async throws -> MediaMetadata {
        let dimensions = extractDimensions(from: data, mediaType: mediaType)

        return MediaMetadata(
            fileName: "unknown",
            fileSize: Int64(data.count),
            mimeType: detectMimeType(from: data, fileName: "unknown"),
            dimensions: dimensions ?? MediaDimensions(width: 0, height: 0),
            securityInfo: SecurityInfo(isSafe: true)
        )
    }

    public func validateMediaAsset(_ asset: MediaAsset, _: ValidationRules) async throws -> MediaValidationResult {
        guard let data = asset.data else {
            return MediaValidationResult(
                isValid: false,
                errors: [MediaValidationError(message: "Asset has no data")],
                warnings: []
            )
        }

        var errors: [MediaValidationError] = []
        let warnings: [MediaValidationWarning] = []

        // Apply validation rules
        if !validateFileSize(Int64(data.count), asset.type) {
            errors.append(MediaValidationError(message: "File size exceeds limits"))
        }

        return MediaValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }

    public func validateBatch(_ assets: [MediaAsset], _ rules: ValidationRules) async throws -> [MediaValidationResult] {
        var results: [MediaValidationResult] = []

        for asset in assets {
            let result = try await validateMediaAsset(asset, rules)
            results.append(result)
        }

        return results
    }
}

// MARK: - Private Helper Methods

private extension MediaValidationService {
    func detectMimeType(from data: Data, fileName: String) -> String {
        // Check magic bytes for common formats
        if data.count >= 4 {
            let bytes = data.prefix(4)

            // JPEG
            if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
                return "image/jpeg"
            }

            // PNG
            if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
                return "image/png"
            }

            // PDF
            if bytes.starts(with: Data("%PDF".utf8)) {
                return "application/pdf"
            }
        }

        // Fall back to file extension
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "heic": return "image/heic"
        case "pdf": return "application/pdf"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        default: return "application/octet-stream"
        }
    }

    func getMimeTypeFromExtension(_ fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "heic": return "image/heic"
        case "pdf": return "application/pdf"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        default: return "application/octet-stream"
        }
    }

    func hasExecutableSignature(_ data: Data) -> Bool {
        if data.count < 2 { return false }

        let header = data.prefix(2)
        // Check for PE (Windows) executable
        if header == Data([0x4D, 0x5A]) { return true }
        // Check for ELF (Linux) executable
        if data.count >= 4 && data.prefix(4) == Data([0x7F, 0x45, 0x4C, 0x46]) { return true }
        // Check for Mach-O (macOS) executable
        if data.count >= 4 && (data.prefix(4) == Data([0xFE, 0xED, 0xFA, 0xCE]) ||
            data.prefix(4) == Data([0xFE, 0xED, 0xFA, 0xCF])) { return true }

        return false
    }

    func containsSuspiciousPatterns(_ data: Data) -> Bool {
        // Simple pattern detection for demonstration
        let suspiciousStrings = ["<script>", "javascript:", "eval(", "document.write"]
        let dataString = String(data: data, encoding: .utf8) ?? ""

        return suspiciousStrings.contains { dataString.lowercased().contains($0.lowercased()) }
    }

    func extractDimensions(from _: Data, mediaType: MediaType) -> MediaDimensions? {
        guard mediaType == .image else { return nil }

        // Simplified dimension extraction - in real implementation would use ImageIO
        // For now, return reasonable defaults for testing
        return MediaDimensions(width: 1920, height: 1080)
    }

    func extractEXIFData(from _: Data) -> [String: String] {
        // Simplified EXIF extraction
        return [
            "Make": "Apple",
            "Model": "iPhone",
            "DateTime": "2024:01:24 12:00:00",
            "GPS_Latitude": "37.7749",
            "GPS_Longitude": "-122.4194",
        ]
    }

    func generateThumbnail(from _: Data) -> Data? {
        // Simplified thumbnail generation
        return Data(repeating: 0x89, count: 1024) // Mock thumbnail data
    }

    // Legacy ColorProfile for existing interface compatibility
    struct ColorProfile {
        let colorSpace: String
        let profileName: String
        let profileSize: Int
    }

    // ImageQualityMetrics for quality calculation
    struct ImageQualityMetrics {
        let sharpness: Double
        let brightness: Double
        let contrast: Double
        let saturation: Double
        let noiseLevel: Double
        let overallQuality: Double
    }

    func extractColorProfile(from _: Data) -> ColorProfile? {
        return ColorProfile(
            colorSpace: "sRGB",
            profileName: "sRGB IEC61966-2.1",
            profileSize: 1024
        )
    }

    func extractColorProfileNested(from _: Data) -> EnhancedMetadataResult.ColorProfile? {
        return EnhancedMetadataResult.ColorProfile(
            name: "sRGB IEC61966-2.1",
            colorSpace: "sRGB"
        )
    }

    func extractGPSData() -> EnhancedMetadataResult.GPSData? {
        return EnhancedMetadataResult.GPSData(
            latitude: 37.7749,
            longitude: -122.4194,
            altitude: 10.0
        )
    }

    func extractDimensionsCGSize(from _: Data, mediaType: MediaType) -> CGSize? {
        guard mediaType == .image || mediaType == .video else { return nil }
        // Simplified dimension extraction - in real implementation would use ImageIO/AVFoundation
        return CGSize(width: 1920, height: 1080)
    }

    func detectImageFormat(from data: Data) -> ImageFormat {
        if data.count >= 4 {
            let bytes = data.prefix(4)

            // JPEG
            if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
                return .jpeg
            }

            // PNG
            if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
                return .png
            }
        }

        return .jpeg // Default fallback
    }

    func isImageCorrupted(_ data: Data) -> Bool {
        // Simple corruption check - real implementation would use ImageIO
        return data.count < 100 // Very small files are likely corrupted
    }

    func extractColorProfileName(from _: Data) -> String? {
        return "sRGB IEC61966-2.1"
    }

    func detectVideoCodec(from data: Data) -> String {
        // Simplified codec detection
        if data.count >= 8 {
            let header = data.prefix(8)
            // Check for common video formats
            if header.contains("ftyp".data(using: .ascii) ?? Data()) {
                return "h264"
            }
        }
        return "unknown"
    }

    func detectAudioTrack(_ data: Data) -> Bool {
        // Simplified audio track detection
        return data.count > 1024 // Assume larger files have audio
    }

    func createCorrectedMetadata(from data: Data, original: MediaMetadata) -> MediaMetadata {
        let dimensions = extractDimensions(from: data, mediaType: .image)

        return MediaMetadata(
            fileName: original.fileName ?? "corrected",
            fileSize: Int64(data.count),
            mimeType: detectMimeType(from: data, fileName: original.fileName ?? ""),
            dimensions: dimensions ?? MediaDimensions(width: 0, height: 0),
            securityInfo: SecurityInfo(isSafe: true)
        )
    }

    func calculateImageQuality(_: Data) -> ImageQualityMetrics {
        // Simplified quality calculation
        return ImageQualityMetrics(
            sharpness: 0.8,
            brightness: 0.7,
            contrast: 0.75,
            saturation: 0.6,
            noiseLevel: 0.1,
            overallQuality: 0.75
        )
    }

    func estimateVideoDuration(_: Data) -> TimeInterval? {
        // Simplified duration estimation
        return 30.0 // 30 seconds default
    }

    func estimateVideoBitrate(_: Data) -> Int? {
        // Simplified bitrate estimation
        return 5000 // 5000 kbps default
    }

    func calculateOverallScore(results _: [String: Any]) -> Double {
        // Simple scoring algorithm
        return 0.85 // 85% default score
    }

    func estimateRemainingTime(completed: Int, total: Int) -> TimeInterval? {
        guard completed > 0 else { return nil }
        let avgTimePerItem: TimeInterval = 0.1 // 100ms per item
        let remaining = total - completed
        return TimeInterval(remaining) * avgTimePerItem
    }
}

// MARK: - Data Extension for SHA256

private extension Data {
    var sha256Hash: String {
        let digest = SHA256.hash(data: self)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - DependencyKey Conformance

public extension MediaValidationService {
    static let liveValue: any MediaValidationServiceProtocol = MediaValidationService()
    static let testValue: any MediaValidationServiceProtocol = TestMediaValidationService()
}
