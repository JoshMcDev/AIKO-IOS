import AppCore
import ComposableArchitecture
import Foundation

#if os(iOS)
import UIKit
import AIKOiOS

// MARK: - Phase 4.1 Document Processing Example

/// Demonstrates the enhanced document scanning and processing capabilities
/// introduced in Phase 4.1, including advanced image processing modes,
/// progress reporting, and quality metrics.
public struct Phase4_1_DocumentProcessingExample {
    
    // MARK: - Example Usage
    
    /// Demonstrates basic vs enhanced processing modes
    public static func demonstrateProcessingModes() async {
        print("🚀 Phase 4.1 Document Processing Demo")
        print("=====================================")
        
        // Register iOS dependencies
        await iOSDependencyRegistration.configureForLaunch()
        
        // Create sample image data (in real usage, this would come from camera/scanner)
        guard let sampleImageData = createSampleImageData() else {
            print("❌ Failed to create sample image data")
            return
        }
        
        print("📄 Sample image data created: \(sampleImageData.count) bytes")
        
        await demonstrateBasicProcessing(imageData: sampleImageData)
        await demonstrateEnhancedProcessing(imageData: sampleImageData)
        await demonstrateProgressReporting(imageData: sampleImageData)
        await demonstrateQualityMetrics(imageData: sampleImageData)
    }
    
    // MARK: - Processing Mode Demonstrations
    
    private static func demonstrateBasicProcessing(imageData: Data) async {
        print("\n🔧 Basic Processing Mode")
        print("------------------------")
        
        do {
            @Dependency(\.documentScanner) var documentScanner
            
            // Check if basic mode is available
            let isAvailable = documentScanner.isProcessingModeAvailable(.basic)
            print("Basic mode available: \(isAvailable)")
            
            // Estimate processing time
            let estimatedTime = try await documentScanner.estimateProcessingTime(imageData, .basic)
            print("Estimated processing time: \(String(format: "%.2f", estimatedTime)) seconds")
            
            // Process with basic mode
            let startTime = CFAbsoluteTimeGetCurrent()
            let result = try await documentScanner.enhanceImageAdvanced(
                imageData,
                .basic,
                ProcessingOptions(
                    qualityTarget: .speed,
                    preserveColors: true,
                    optimizeForOCR: true
                )
            )
            let actualTime = CFAbsoluteTimeGetCurrent() - startTime
            
            print("✅ Basic processing completed in \(String(format: "%.2f", actualTime)) seconds")
            print("   - Applied filters: \(result.appliedFilters.joined(separator: ", "))")
            print("   - Overall confidence: \(String(format: "%.2f", result.qualityMetrics.overallConfidence))")
            print("   - Recommended for OCR: \(result.qualityMetrics.recommendedForOCR)")
            
        } catch {
            print("❌ Basic processing failed: \(error.localizedDescription)")
        }
    }
    
    private static func demonstrateEnhancedProcessing(imageData: Data) async {
        print("\n🎯 Enhanced Processing Mode")
        print("---------------------------")
        
        do {
            @Dependency(\.documentScanner) var documentScanner
            
            // Check if enhanced mode is available
            let isAvailable = documentScanner.isProcessingModeAvailable(.enhanced)
            print("Enhanced mode available: \(isAvailable)")
            
            // Estimate processing time
            let estimatedTime = try await documentScanner.estimateProcessingTime(imageData, .enhanced)
            print("Estimated processing time: \(String(format: "%.2f", estimatedTime)) seconds")
            
            // Process with enhanced mode
            let startTime = CFAbsoluteTimeGetCurrent()
            let result = try await documentScanner.enhanceImageAdvanced(
                imageData,
                .enhanced,
                ProcessingOptions(
                    qualityTarget: .quality,
                    preserveColors: false, // Better for OCR
                    optimizeForOCR: true
                )
            )
            let actualTime = CFAbsoluteTimeGetCurrent() - startTime
            
            print("✅ Enhanced processing completed in \(String(format: "%.2f", actualTime)) seconds")
            print("   - Applied filters: \(result.appliedFilters.joined(separator: ", "))")
            print("   - Overall confidence: \(String(format: "%.2f", result.qualityMetrics.overallConfidence))")
            print("   - Sharpness score: \(String(format: "%.2f", result.qualityMetrics.sharpnessScore))")
            print("   - Contrast score: \(String(format: "%.2f", result.qualityMetrics.contrastScore))")
            print("   - Noise level: \(String(format: "%.2f", result.qualityMetrics.noiseLevel))")
            print("   - Text clarity: \(String(format: "%.2f", result.qualityMetrics.textClarity))")
            print("   - Recommended for OCR: \(result.qualityMetrics.recommendedForOCR)")
            
        } catch {
            print("❌ Enhanced processing failed: \(error.localizedDescription)")
        }
    }
    
    private static func demonstrateProgressReporting(imageData: Data) async {
        print("\n📊 Progress Reporting")
        print("--------------------")
        
        do {
            @Dependency(\.documentScanner) var documentScanner
            
            actor ProgressTracker {
                private var lastProgress: Double = 0
                
                func shouldReport(_ currentProgress: Double) -> Bool {
                    if currentProgress - lastProgress >= 0.1 { // Report every 10%
                        lastProgress = currentProgress
                        return true
                    }
                    return false
                }
            }
            
            let tracker = ProgressTracker()
            
            let progressCallback: @Sendable (ProcessingProgress) -> Void = { progress in
                Task {
                    if await tracker.shouldReport(progress.overallProgress) {
                        print("   \(progress.currentStep.displayName): \(String(format: "%.0f", progress.overallProgress * 100))%")
                        
                        if let remainingTime = progress.estimatedTimeRemaining {
                            print("     ETA: \(String(format: "%.1f", remainingTime))s")
                        }
                    }
                }
            }
            
            let result = try await documentScanner.enhanceImageAdvanced(
                imageData,
                .enhanced,
                ProcessingOptions(
                    progressCallback: progressCallback,
                    qualityTarget: .balanced,
                    preserveColors: true,
                    optimizeForOCR: true
                )
            )
            
            print("✅ Processing with progress reporting completed")
            print("   - Total processing time: \(String(format: "%.2f", result.processingTime)) seconds")
            
        } catch {
            print("❌ Progress reporting demo failed: \(error.localizedDescription)")
        }
    }
    
    private static func demonstrateQualityMetrics(imageData: Data) async {
        print("\n📈 Quality Metrics Comparison")
        print("-----------------------------")
        
        do {
            @Dependency(\.documentScanner) var documentScanner
            
            // Process with both modes to compare quality
            let basicResult = try await documentScanner.enhanceImageAdvanced(
                imageData,
                .basic,
                ProcessingOptions(qualityTarget: .speed)
            )
            
            let enhancedResult = try await documentScanner.enhanceImageAdvanced(
                imageData,
                .enhanced,
                ProcessingOptions(qualityTarget: .quality)
            )
            
            print("Quality Comparison:")
            print("                    Basic    Enhanced")
            print("Overall Confidence: \(String(format: "%.2f", basicResult.qualityMetrics.overallConfidence))     \(String(format: "%.2f", enhancedResult.qualityMetrics.overallConfidence))")
            print("Sharpness Score:    \(String(format: "%.2f", basicResult.qualityMetrics.sharpnessScore))     \(String(format: "%.2f", enhancedResult.qualityMetrics.sharpnessScore))")
            print("Contrast Score:     \(String(format: "%.2f", basicResult.qualityMetrics.contrastScore))     \(String(format: "%.2f", enhancedResult.qualityMetrics.contrastScore))")
            print("Noise Level:        \(String(format: "%.2f", basicResult.qualityMetrics.noiseLevel))     \(String(format: "%.2f", enhancedResult.qualityMetrics.noiseLevel))")
            print("Text Clarity:       \(String(format: "%.2f", basicResult.qualityMetrics.textClarity))     \(String(format: "%.2f", enhancedResult.qualityMetrics.textClarity))")
            print("OCR Ready:          \(basicResult.qualityMetrics.recommendedForOCR ? "Yes" : "No")      \(enhancedResult.qualityMetrics.recommendedForOCR ? "Yes" : "No")")
            
            // Determine which mode performed better
            if enhancedResult.qualityMetrics.overallConfidence > basicResult.qualityMetrics.overallConfidence {
                let improvement = ((enhancedResult.qualityMetrics.overallConfidence - basicResult.qualityMetrics.overallConfidence) / basicResult.qualityMetrics.overallConfidence) * 100
                print("🎉 Enhanced mode achieved \(String(format: "%.1f", improvement))% better quality")
            } else {
                print("⚡ Basic mode was sufficient for this image")
            }
            
        } catch {
            print("❌ Quality metrics demo failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Document Pipeline Integration
    
    /// Demonstrates how to integrate enhanced processing into the document pipeline
    public static func demonstrateDocumentPipelineIntegration() async {
        print("\n🔄 Document Pipeline Integration")
        print("================================")
        
        do {
            @Dependency(\.documentScanner) var documentScanner
            
            guard let sampleImageData = createSampleImageData() else {
                print("❌ Failed to create sample image data")
                return
            }
            
            // Create a scanned page with enhanced processing
            var scannedPage = ScannedPage(
                imageData: sampleImageData,
                pageNumber: 1,
                processingState: .pending
            )
            
            // Update processing state
            scannedPage.processingState = .processing
            print("📄 Processing page \(scannedPage.pageNumber)...")
            
            // Process with enhanced mode
            let result = try await documentScanner.enhanceImageAdvanced(
                scannedPage.imageData,
                .enhanced,
                ProcessingOptions(
                    progressCallback: { progress in
                        print("   Processing: \(String(format: "%.0f", progress.overallProgress * 100))%")
                    },
                    qualityTarget: .balanced,
                    optimizeForOCR: true
                )
            )
            
            // Update page with results
            scannedPage.enhancedImageData = result.processedImageData
            scannedPage.qualityMetrics = result.qualityMetrics
            scannedPage.processingMode = .enhanced
            scannedPage.processingResult = result
            scannedPage.enhancementApplied = true
            scannedPage.processingState = .completed
            
            print("✅ Page processing completed")
            print("   - Quality confidence: \(String(format: "%.2f", result.qualityMetrics.overallConfidence))")
            print("   - OCR ready: \(result.qualityMetrics.recommendedForOCR)")
            
            // Perform OCR if quality is sufficient
            if result.qualityMetrics.recommendedForOCR {
                let ocrText = try await documentScanner.performOCR(result.processedImageData)
                scannedPage.ocrText = ocrText
                print("   - OCR extracted: \(ocrText.prefix(50))...")
            }
            
            // Create document and save to pipeline
            let document = ScannedDocument(
                pages: [scannedPage],
                title: "Enhanced Document"
            )
            
            try await documentScanner.saveToDocumentPipeline(document.pages)
            print("💾 Document saved to pipeline")
            
        } catch {
            print("❌ Pipeline integration failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private static func createSampleImageData() -> Data? {
        // Create a simple test image with text-like patterns
        let size = CGSize(width: 800, height: 600)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        // White background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Draw some text-like rectangles to simulate document content
        context.setFillColor(UIColor.black.cgColor)
        
        // Title area
        context.fill(CGRect(x: 50, y: 50, width: 300, height: 30))
        
        // Paragraph lines
        for i in 0..<10 {
            let y = 120 + (i * 25)
            let width = i == 9 ? 200 : 700 // Last line shorter
            context.fill(CGRect(x: 50, y: y, width: width, height: 15))
        }
        
        // Another paragraph
        for i in 0..<6 {
            let y = 400 + (i * 25)
            let width = i == 5 ? 150 : 650
            context.fill(CGRect(x: 50, y: y, width: width, height: 15))
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image?.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Demo Runner

#if DEBUG
/// Convenience function to run the Phase 4.1 demo
public func runPhase4_1_Demo() async {
    await Phase4_1_DocumentProcessingExample.demonstrateProcessingModes()
    await Phase4_1_DocumentProcessingExample.demonstrateDocumentPipelineIntegration()
}
#endif

#endif