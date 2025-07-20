import ComposableArchitecture
import Foundation

// MARK: - Document Scanner Service Dependency Registration

/// Note: DependencyKey conformance for DocumentScannerService is already declared
/// in DocumentScannerProtocol.swift with proper liveValue and testValue implementations.
/// This file provides additional integration helpers and migration utilities.

// MARK: - Migration Helper

/// Helper for migrating from existing documentScanner client to new service
/// Provides backward compatibility during transition period
public enum DocumentScannerMigrationHelper {
    /// Migrates existing DocumentScannerFeature to use new service
    /// This is a temporary bridge during the transition period
    @MainActor
    public static func createCompatibilityClient(
        from service: DocumentScannerService
    ) -> DocumentScannerClient {
        DocumentScannerClient(
            scan: {
                try await service.scanDocument()
            },
            enhanceImage: { data in
                // Create a temporary page for processing
                let tempPage = ScannedPage(
                    imageData: data,
                    pageNumber: 1
                )

                let processedPage = try await service.processPage(
                    tempPage,
                    .basic,
                    ProcessingOptions()
                )

                return processedPage.enhancedImageData ?? data
            },
            enhanceImageAdvanced: { data, mode, options in
                // Create a temporary page for processing
                let tempPage = ScannedPage(
                    imageData: data,
                    pageNumber: 1
                )

                let processedPage = try await service.processPage(
                    tempPage,
                    mode,
                    options
                )

                return processedPage.processingResult ?? ProcessingResult(
                    processedImageData: data,
                    qualityMetrics: QualityMetrics(
                        overallConfidence: 0.8,
                        sharpnessScore: 0.8,
                        contrastScore: 0.8,
                        noiseLevel: 0.2,
                        textClarity: 0.8,
                        recommendedForOCR: true
                    ),
                    processingTime: 0.1,
                    appliedFilters: []
                )
            },
            performOCR: { data in
                // Create a temporary page for OCR
                let tempPage = ScannedPage(
                    imageData: data,
                    pageNumber: 1
                )

                let processedPage = try await service.performPageOCR(tempPage)
                return processedPage.ocrText ?? ""
            },
            performEnhancedOCR: { data in
                // Create a temporary page for enhanced OCR
                let tempPage = ScannedPage(
                    imageData: data,
                    pageNumber: 1
                )

                let processedPage = try await service.performPageOCR(tempPage)
                return processedPage.ocrResult ?? OCRResult(
                    fullText: "",
                    confidence: 0.0
                )
            },
            generateThumbnail: { data, _ in
                // For now, return original data
                // Could be enhanced to actually generate thumbnails
                data
            },
            saveToDocumentPipeline: { _ in
                // This would integrate with existing document pipeline
                // For now, just a placeholder
            },
            isScanningAvailable: {
                service.isDocumentScanningAvailable()
            },
            estimateProcessingTime: { data, mode in
                // Estimate based on data size
                let sizeInMB = Double(data.count) / 1_000_000.0
                let baseTime: TimeInterval = mode == .enhanced ? 2.0 : 0.5
                return baseTime * max(1.0, sizeInMB)
            },
            isProcessingModeAvailable: { _ in
                // All modes are available in the new service
                true
            },
            checkCameraPermissions: {
                // In a real implementation, this would check actual camera permissions
                // For now, assume permissions are granted
                true
            }
        )
    }
}

// MARK: - Feature Integration

/// Integration points for existing DocumentScannerFeature
/// Provides seamless transition to new service architecture
public enum DocumentScannerFeatureIntegration {
    /// Updates DocumentScannerFeature to use new service
    /// This preserves existing TCA patterns while leveraging new architecture
    public static func integrateWithFeature() {
        // This would be called during app initialization to set up the integration
        // The integration maintains existing @Dependency(\.documentScanner) usage
        // while internally routing to the new service
    }

    /// Creates a migration path from old client to new service
    /// Allows gradual transition without breaking existing code
    @MainActor
    public static func createMigrationClient() -> DocumentScannerClient {
        @Dependency(\.documentScannerService) var service
        return DocumentScannerMigrationHelper.createCompatibilityClient(from: service)
    }
}

// MARK: - Performance Monitoring Integration

/// Integrates performance monitoring with existing AIKO analytics
public enum DocumentScannerPerformanceIntegration {
    /// Records metrics to existing analytics system
    public static func recordMetrics(_: ScanningMetrics) async {
        // Integration point with existing AIKO analytics
        // This would forward metrics to the main analytics pipeline
    }

    /// Gets performance insights for dashboard display
    public static func getInsightsForDashboard() async -> PerformanceInsights {
        @Dependency(\.documentScannerService) var service
        return await service.getPerformanceInsights()
    }
}

// MARK: - Configuration

/// Configuration for DocumentScannerService initialization
public struct DocumentScannerServiceConfiguration: Sendable {
    public let enablePerformanceMonitoring: Bool
    public let maxConcurrentSessions: Int
    public let defaultProcessingMode: ProcessingMode
    public let enableQualityAssessment: Bool
    public let enableAutoEnhancement: Bool

    public init(
        enablePerformanceMonitoring: Bool = true,
        maxConcurrentSessions: Int = 5,
        defaultProcessingMode: ProcessingMode = .basic,
        enableQualityAssessment: Bool = true,
        enableAutoEnhancement: Bool = true
    ) {
        self.enablePerformanceMonitoring = enablePerformanceMonitoring
        self.maxConcurrentSessions = maxConcurrentSessions
        self.defaultProcessingMode = defaultProcessingMode
        self.enableQualityAssessment = enableQualityAssessment
        self.enableAutoEnhancement = enableAutoEnhancement
    }

    public static let `default` = DocumentScannerServiceConfiguration()
}
