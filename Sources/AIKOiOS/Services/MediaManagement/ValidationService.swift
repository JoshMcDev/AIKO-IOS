import AppCore
import CryptoKit
import Foundation
import UIKit
import UniformTypeIdentifiers

/// iOS implementation of validation service
@available(iOS 16.0, *)
public actor ValidationService: ValidationServiceProtocol {
    private let maxFileSizeBytes: Int64 = 100 * 1024 * 1024 // 100MB default limit
    private let supportedImageFormats = ["image/jpeg", "image/png", "image/gif", "image/bmp", "image/tiff", "image/heic"]
    private let supportedVideoFormats = ["video/mp4", "video/quicktime", "video/avi", "video/mkv"]
    private let supportedAudioFormats = ["audio/mpeg", "audio/wav", "audio/aac", "audio/flac", "audio/m4a"]
    private let supportedDocumentFormats = ["application/pdf", "text/plain", "application/rtf"]

    public init() {}

    public func validateFile(_ data: Data, rules: ValidationRules) async throws -> Bool {
        // Comprehensive file validation against provided rules

        // 1. Size validation
        if let sizeConstraints = rules.sizeConstraints {
            let sizeValid = try await validateSize(data, constraints: sizeConstraints)
            if !sizeValid {
                return false
            }
        }

        // 2. Format validation
        if !rules.allowedMimeTypes.isEmpty {
            let detectedMimeType = detectMimeType(from: data)
            if !rules.allowedMimeTypes.contains(detectedMimeType) {
                return false
            }
        }

        // 3. Security validation (always perform for comprehensive validation)
        let securityResult = try await performSecurityScan(data)
        if !securityResult.isSafe {
            return false
        }

        // 4. Integrity validation (always perform for comprehensive validation)
        let integrityResult = try await performIntegrityCheck(data)
        if !integrityResult.isValid {
            return false
        }

        // 5. Content-specific validation
        let mimeType = detectMimeType(from: data)
        return try await validateContentSpecific(data, mimeType: mimeType, rules: rules)
    }

    public func validateFormat(_ data: Data, expectedMimeType: String) async throws -> Bool {
        let detectedMimeType = detectMimeType(from: data)

        // Direct MIME type comparison
        if detectedMimeType == expectedMimeType {
            return true
        }

        // Check for compatible types (e.g., image/jpg vs image/jpeg)
        return areCompatibleMimeTypes(detected: detectedMimeType, expected: expectedMimeType)
    }

    public func validateSize(_ data: Data, constraints: SizeConstraints) async throws -> Bool {
        let fileSize = Int64(data.count)

        // Check minimum size
        if fileSize < constraints.minSize {
            return false
        }

        // Check maximum size
        if fileSize > constraints.maxSize {
            return false
        }

        // Additional size validation for specific content types
        return validateSizeByContent(data, fileSize: fileSize)
    }

    public func validateDimensions(_ dimensions: MediaDimensions, constraints: DimensionConstraints) async throws -> Bool {
        // Validate width constraints
        if dimensions.width < constraints.minWidth {
            return false
        }
        if dimensions.width > constraints.maxWidth {
            return false
        }

        // Validate height constraints
        if dimensions.height < constraints.minHeight {
            return false
        }
        if dimensions.height > constraints.maxHeight {
            return false
        }

        // Validate aspect ratio constraints
        if let aspectRatios = constraints.aspectRatios, !aspectRatios.isEmpty {
            let actualAspectRatio = Double(dimensions.width) / Double(dimensions.height)
            let tolerance = 0.01 // 1% tolerance

            let matchesAnyRatio = aspectRatios.contains { requiredRatio in
                let aspectRatioDiff = abs(actualAspectRatio - requiredRatio)
                return aspectRatioDiff <= tolerance
            }

            if !matchesAnyRatio {
                return false
            }
        }

        return true
    }

    public func performIntegrityCheck(_ data: Data) async throws -> IntegrityCheckResult {
        var issues: [IntegrityCheckResult.IntegrityIssue] = []

        // 1. Basic data integrity
        if data.isEmpty {
            issues.append(IntegrityCheckResult.IntegrityIssue(severity: .error, description: "File data is empty"))
            return IntegrityCheckResult(isValid: false, issues: issues)
        }

        // 2. Check for truncated files
        let mimeType = detectMimeType(from: data)
        if try checkForTruncation(data, mimeType: mimeType) {
            issues.append(IntegrityCheckResult.IntegrityIssue(severity: .error, description: "File appears to be truncated or corrupted"))
        }

        // 3. Format-specific integrity checks
        try await performFormatSpecificIntegrityCheck(data, mimeType: mimeType, issues: &issues)

        // 4. Calculate and verify checksums
        let checksumResult = calculateFileChecksum(data)

        return IntegrityCheckResult(
            isValid: issues.isEmpty,
            issues: issues,
            checksum: checksumResult.checksum
        )
    }

    public func performSecurityScan(_ data: Data) async throws -> SecurityScanResult {
        var threats: [SecurityThreat] = []
        let startTime = Date()

        // 1. File size bomb detection
        if data.count > maxFileSizeBytes {
            threats.append(SecurityThreat(
                type: .suspicious,
                severity: .high,
                description: "File exceeds maximum safe size limit"
            ))
        }

        // 2. Magic byte validation
        let mimeType = detectMimeType(from: data)
        if !isValidMagicBytes(data, expectedMimeType: mimeType) {
            threats.append(SecurityThreat(
                type: .suspicious,
                severity: .medium,
                description: "File header doesn't match claimed file type"
            ))
        }

        // 3. Embedded content detection
        if containsSuspiciousEmbeddedContent(data) {
            threats.append(SecurityThreat(
                type: .suspicious,
                severity: .low,
                description: "File contains embedded scripts or suspicious content"
            ))
        }

        // 4. Format-specific security checks
        try await performFormatSpecificSecurityCheck(data, mimeType: mimeType, threats: &threats)

        let scanDuration = Date().timeIntervalSince(startTime)

        return SecurityScanResult(
            isSafe: threats.isEmpty,
            threats: threats,
            scanDuration: scanDuration
        )
    }

    public func generateRulesForContentType(_ contentType: String) async -> ValidationRules {
        switch contentType.lowercased() {
        case let type where type.hasPrefix("image/"):
            ValidationRules(
                maxFileSize: 50 * 1024 * 1024, // 50MB maximum
                allowedMimeTypes: Set(supportedImageFormats),
                requireMetadata: true,
                enforceDimensions: false,
                sizeConstraints: SizeConstraints(
                    minSize: 1024, // 1KB minimum
                    maxSize: 50 * 1024 * 1024 // 50MB maximum
                )
            )

        case let type where type.hasPrefix("video/"):
            ValidationRules(
                maxFileSize: 500 * 1024 * 1024, // 500MB maximum
                allowedMimeTypes: Set(supportedVideoFormats),
                requireMetadata: false,
                enforceDimensions: false,
                sizeConstraints: SizeConstraints(
                    minSize: 1024 * 1024, // 1MB minimum
                    maxSize: 500 * 1024 * 1024 // 500MB maximum
                )
            )

        case let type where type.hasPrefix("audio/"):
            ValidationRules(
                maxFileSize: 100 * 1024 * 1024, // 100MB maximum
                allowedMimeTypes: Set(supportedAudioFormats),
                requireMetadata: false,
                enforceDimensions: false,
                sizeConstraints: SizeConstraints(
                    minSize: 1024, // 1KB minimum
                    maxSize: 100 * 1024 * 1024 // 100MB maximum
                )
            )

        case let type where type.hasPrefix("application/") || type.hasPrefix("text/"):
            ValidationRules(
                maxFileSize: 50 * 1024 * 1024, // 50MB maximum
                allowedMimeTypes: Set(supportedDocumentFormats),
                requireMetadata: false,
                enforceDimensions: false,
                sizeConstraints: SizeConstraints(
                    minSize: 1, // Any size for documents
                    maxSize: 50 * 1024 * 1024 // 50MB maximum
                )
            )

        default:
            // Generic rules for unknown content types
            ValidationRules(
                maxFileSize: 10 * 1024 * 1024, // 10MB conservative limit
                allowedMimeTypes: Set(["application/octet-stream"]),
                requireMetadata: false,
                enforceDimensions: false,
                sizeConstraints: SizeConstraints(
                    minSize: 1,
                    maxSize: 10 * 1024 * 1024 // 10MB conservative limit
                )
            )
        }
    }

    public func getDefaultRules() async -> ValidationRules {
        // Conservative default rules
        let allFormats = supportedImageFormats + supportedVideoFormats + supportedAudioFormats + supportedDocumentFormats

        return ValidationRules(
            maxFileSize: maxFileSizeBytes,
            allowedMimeTypes: Set(allFormats),
            requireMetadata: false,
            enforceDimensions: false,
            sizeConstraints: SizeConstraints(
                minSize: 1,
                maxSize: maxFileSizeBytes
            )
        )
    }

    public func validateBatch(_ batch: [(Data, ValidationRules)]) async throws -> [Bool] {
        var results: [Bool] = []

        for (data, rules) in batch {
            do {
                let isValid = try await validateFile(data, rules: rules)
                results.append(isValid)
            } catch {
                // Mark as invalid if validation throws an error
                results.append(false)
            }
        }

        return results
    }

    // MARK: - Helper Methods

    private func detectMimeType(from data: Data) -> String {
        guard !data.isEmpty else { return "application/octet-stream" }

        // Check magic bytes for common formats
        let bytes = data.prefix(16).map { $0 }

        // Image formats
        if bytes.count >= 4 {
            if bytes[0] == 0xFF, bytes[1] == 0xD8, bytes[2] == 0xFF {
                return "image/jpeg"
            }
            if bytes[0] == 0x89, bytes[1] == 0x50, bytes[2] == 0x4E, bytes[3] == 0x47 {
                return "image/png"
            }
            if bytes[0] == 0x47, bytes[1] == 0x49, bytes[2] == 0x46 {
                return "image/gif"
            }
        }

        // Video formats
        if bytes.count >= 8 {
            if bytes[4] == 0x66, bytes[5] == 0x74, bytes[6] == 0x79, bytes[7] == 0x70 {
                return "video/mp4"
            }
        }

        // PDF
        if bytes.count >= 4, bytes[0] == 0x25, bytes[1] == 0x50, bytes[2] == 0x44, bytes[3] == 0x46 {
            return "application/pdf"
        }

        return "application/octet-stream"
    }

    private func areCompatibleMimeTypes(detected: String, expected: String) -> Bool {
        let compatibilityMap = [
            "image/jpg": "image/jpeg",
            "image/jpeg": "image/jpg",
        ]

        if let compatible = compatibilityMap[detected] {
            return compatible == expected
        }

        if let compatible = compatibilityMap[expected] {
            return compatible == detected
        }

        return false
    }

    private func validateSizeByContent(_ data: Data, fileSize: Int64) -> Bool {
        let mimeType = detectMimeType(from: data)

        // Format-specific size validation
        if mimeType.hasPrefix("image/") {
            return fileSize <= 50 * 1024 * 1024 // 50MB for images
        } else if mimeType.hasPrefix("video/") {
            return fileSize <= 500 * 1024 * 1024 // 500MB for videos
        } else if mimeType.hasPrefix("audio/") {
            return fileSize <= 100 * 1024 * 1024 // 100MB for audio
        }

        return fileSize <= maxFileSizeBytes
    }

    private func validateContentSpecific(_ data: Data, mimeType: String, rules _: ValidationRules) async throws -> Bool {
        // Additional validation specific to content type

        if mimeType.hasPrefix("image/") {
            // Validate image can be loaded
            return UIImage(data: data) != nil
        }

        // For other types, basic validation is sufficient
        return true
    }

    private func checkForTruncation(_ data: Data, mimeType: String) throws -> Bool {
        // Basic truncation detection based on file format

        if mimeType == "image/jpeg" {
            // JPEG should end with FFD9
            if data.count >= 2 {
                let lastBytes = data.suffix(2)
                return !(lastBytes[0] == 0xFF && lastBytes[1] == 0xD9)
            }
        }

        if mimeType == "application/pdf" {
            // PDF should contain "%%EOF"
            let eofMarker = "%%EOF".data(using: .ascii) ?? Data()
            return !data.suffix(1024).contains(eofMarker)
        }

        return false
    }

    private func performFormatSpecificIntegrityCheck(_ data: Data, mimeType: String, issues: inout [IntegrityCheckResult.IntegrityIssue]) async throws {
        if mimeType.hasPrefix("image/") {
            // Validate image can be decoded
            if UIImage(data: data) == nil {
                issues.append(IntegrityCheckResult.IntegrityIssue(severity: .error, description: "Image data cannot be decoded"))
            }
        }

        if mimeType == "application/pdf" {
            // Basic PDF structure validation
            if !data.prefix(8).starts(with: "%PDF-".data(using: .ascii) ?? Data()) {
                issues.append(IntegrityCheckResult.IntegrityIssue(severity: .error, description: "Invalid PDF header"))
            }
        }
    }

    private func calculateFileChecksum(_ data: Data) -> (checksum: String, algorithm: String) {
        let hash = SHA256.hash(data: data)
        return (checksum: hash.compactMap { String(format: "%02x", $0) }.joined(), algorithm: "SHA256")
    }

    private func isValidMagicBytes(_ data: Data, expectedMimeType: String) -> Bool {
        let detectedType = detectMimeType(from: data)
        return detectedType == expectedMimeType || areCompatibleMimeTypes(detected: detectedType, expected: expectedMimeType)
    }

    private func containsSuspiciousEmbeddedContent(_ data: Data) -> Bool {
        // Look for common script patterns or suspicious content
        let suspiciousPatterns = [
            "<script".data(using: .ascii),
            "javascript:".data(using: .ascii),
            "eval(".data(using: .ascii),
            "document.cookie".data(using: .ascii),
        ]

        for pattern in suspiciousPatterns {
            if let pattern, data.range(of: pattern) != nil {
                return true
            }
        }

        return false
    }

    private func performFormatSpecificSecurityCheck(_ data: Data, mimeType: String, threats: inout [SecurityThreat]) async throws {
        if mimeType == "application/pdf" {
            // Check for embedded JavaScript in PDF
            if data.range(of: "/JavaScript".data(using: .ascii) ?? Data()) != nil {
                threats.append(SecurityThreat(
                    type: .suspicious,
                    severity: .medium,
                    description: "PDF contains embedded JavaScript"
                ))
            }

            // Check for forms
            if data.range(of: "/AcroForm".data(using: .ascii) ?? Data()) != nil {
                threats.append(SecurityThreat(
                    type: .suspicious,
                    severity: .low,
                    description: "PDF contains forms"
                ))
            }
        }

        if mimeType.hasPrefix("image/") {
            // Check for suspiciously large images that might be bombs
            if let image = UIImage(data: data) {
                let pixelCount = image.size.width * image.size.height
                if pixelCount > 100_000_000 { // 100 megapixels
                    threats.append(SecurityThreat(
                        type: .suspicious,
                        severity: .medium,
                        description: "Image has unusually high resolution"
                    ))
                }
            }
        }
    }
}
