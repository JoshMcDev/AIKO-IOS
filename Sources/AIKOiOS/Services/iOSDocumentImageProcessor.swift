#if os(iOS)
    import Accelerate
    import AppCore
    @preconcurrency import CoreImage
    import CoreImage.CIFilterBuiltins
    import Foundation
    import UIKit
    import Vision

    // MARK: - iOS Document Image Processor Implementation

    public extension DocumentImageProcessor {
        static let live: Self = {
            let processor = LiveDocumentImageProcessor()

            return Self(
                processImage: { imageData, mode, options in
                    try await processor.processImage(imageData, mode: mode, options: options)
                },
                estimateProcessingTime: { imageData, mode in
                    try await processor.estimateProcessingTime(imageData, mode: mode)
                },
                isProcessingModeAvailable: { mode in
                    processor.isProcessingModeAvailable(mode)
                }
            )
        }()
    }

    // MARK: - Live Implementation

    private final class LiveDocumentImageProcessor: Sendable {
        private let context: CIContext
        private let queue: DispatchQueue
        private let documentProcessingPipeline: DocumentProcessingPipeline

        init() {
            // Create optimized CIContext for metal rendering if available
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                context = CIContext(mtlDevice: metalDevice)
            } else {
                context = CIContext()
            }
            queue = DispatchQueue(label: "document.image.processor", qos: .userInitiated)
            documentProcessingPipeline = DocumentProcessingPipeline()
        }

        func processImage(_ imageData: Data, mode: ProcessingMode, options: ProcessingOptions) async throws -> ProcessingResult {
            let startTime = CFAbsoluteTimeGetCurrent()
            var appliedFilters: [String] = []

            guard let uiImage = UIImage(data: imageData),
                  let cgImage = uiImage.cgImage
            else {
                throw ProcessingError.invalidImageData
            }

            let ciImage = CIImage(cgImage: cgImage)

            return try await withCheckedThrowingContinuation { continuation in
                queue.async {
                    do {
                        let result = try self.performProcessing(
                            ciImage: ciImage,
                            mode: mode,
                            options: options,
                            appliedFilters: &appliedFilters,
                            startTime: startTime
                        )
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }

        private func performProcessing(
            ciImage: CIImage,
            mode: ProcessingMode,
            options: ProcessingOptions,
            appliedFilters: inout [String],
            startTime: CFAbsoluteTime
        ) throws -> ProcessingResult {
            var processedImage = ciImage
            let totalSteps = mode == .documentScanner ? 8 : (mode == .enhanced ? 6 : 3)
            var currentStepIndex = 0

            func updateProgress(step: ProcessingStep, stepProgress: Double = 1.0) {
                let overallProgress = (Double(currentStepIndex) + stepProgress) / Double(totalSteps)
                let remainingTime = estimateRemainingTime(startTime: startTime, progress: overallProgress)

                options.progressCallback?(ProcessingProgress(
                    currentStep: step,
                    stepProgress: stepProgress,
                    overallProgress: overallProgress,
                    estimatedTimeRemaining: remainingTime
                ))

                if stepProgress >= 1.0 {
                    currentStepIndex += 1
                }
            }

            // Step 1: Preprocessing
            updateProgress(step: .preprocessing, stepProgress: 0.0)
            processedImage = try performPreprocessing(processedImage, options: options)
            appliedFilters.append("preprocessing")
            updateProgress(step: .preprocessing, stepProgress: 1.0)

            // Document Scanner Mode: Edge Detection and Perspective Correction
            if mode == .documentScanner {
                return try await performDocumentScannerProcessing(
                    ciImage: processedImage,
                    originalImage: ciImage,
                    options: options,
                    appliedFilters: &appliedFilters,
                    startTime: startTime,
                    updateProgress: updateProgress
                )
            }

            // Step 2: Basic enhancement (both modes)
            updateProgress(step: .enhancement, stepProgress: 0.0)
            processedImage = try performBasicEnhancement(processedImage, options: options)
            appliedFilters.append("basic_enhancement")
            updateProgress(step: .enhancement, stepProgress: mode == .basic ? 1.0 : 0.5)

            if mode == .enhanced {
                // Step 3: Advanced enhancement
                processedImage = try performAdvancedEnhancement(processedImage, options: options)
                appliedFilters.append("advanced_enhancement")
                updateProgress(step: .enhancement, stepProgress: 1.0)

                // Step 4: Denoising
                updateProgress(step: .denoising, stepProgress: 0.0)
                processedImage = try performDenoising(processedImage, options: options)
                appliedFilters.append("denoising")
                updateProgress(step: .denoising, stepProgress: 1.0)

                // Step 5: Advanced sharpening
                updateProgress(step: .sharpening, stepProgress: 0.0)
                processedImage = try performAdvancedSharpening(processedImage, options: options)
                appliedFilters.append("advanced_sharpening")
                updateProgress(step: .sharpening, stepProgress: 1.0)

                // Step 6: OCR optimization
                if options.optimizeForOCR {
                    updateProgress(step: .optimization, stepProgress: 0.0)
                    processedImage = try performOCROptimization(processedImage, options: options)
                    appliedFilters.append("ocr_optimization")
                    updateProgress(step: .optimization, stepProgress: 1.0)
                }
            } else {
                // Basic mode: simple sharpening
                updateProgress(step: .sharpening, stepProgress: 0.0)
                processedImage = try performBasicSharpening(processedImage, options: options)
                appliedFilters.append("basic_sharpening")
                updateProgress(step: .sharpening, stepProgress: 1.0)
            }

            // Final step: Quality analysis
            updateProgress(step: .qualityAnalysis, stepProgress: 0.0)
            let qualityMetrics = try analyzeQuality(processedImage, originalImage: ciImage)
            updateProgress(step: .qualityAnalysis, stepProgress: 1.0)

            // Convert to data
            guard let finalCGImage = context.createCGImage(processedImage, from: processedImage.extent) else {
                throw ProcessingError.processingFailed("Failed to create final image")
            }

            let finalUIImage = UIImage(cgImage: finalCGImage)
            guard let finalImageData = finalUIImage.jpegData(compressionQuality: 0.92) else {
                throw ProcessingError.processingFailed("Failed to convert to JPEG data")
            }

            let processingTime = CFAbsoluteTimeGetCurrent() - startTime

            return ProcessingResult(
                processedImageData: finalImageData,
                qualityMetrics: qualityMetrics,
                processingTime: processingTime,
                appliedFilters: appliedFilters
            )
        }

        // MARK: - Processing Steps

        private func performPreprocessing(_ image: CIImage, options _: ProcessingOptions) throws -> CIImage {
            var result = image

            // Correct orientation if needed
            let orientationFilter = CIFilter.straighten()
            orientationFilter.inputImage = result
            orientationFilter.angle = 0.0
            if let output = orientationFilter.outputImage {
                result = output
            }

            // Basic exposure correction
            let exposureFilter = CIFilter.exposureAdjust()
            exposureFilter.inputImage = result
            exposureFilter.ev = 0.2
            if let output = exposureFilter.outputImage {
                result = output
            }

            return result
        }

        private func performBasicEnhancement(_ image: CIImage, options: ProcessingOptions) throws -> CIImage {
            var result = image

            // Contrast and brightness adjustment
            let colorFilter = CIFilter.colorControls()
            colorFilter.inputImage = result
            colorFilter.contrast = 1.3
            colorFilter.brightness = 0.1
            colorFilter.saturation = options.preserveColors ? 1.0 : 0.8
            if let output = colorFilter.outputImage {
                result = output
            }

            // Gamma adjustment for better text visibility
            let gammaFilter = CIFilter.gammaAdjust()
            gammaFilter.inputImage = result
            gammaFilter.power = 0.9
            if let output = gammaFilter.outputImage {
                result = output
            }

            return result
        }

        private func performAdvancedEnhancement(_ image: CIImage, options: ProcessingOptions) throws -> CIImage {
            var result = image

            // Advanced tone mapping
            let toneFilter = CIFilter.highlightShadowAdjust()
            toneFilter.inputImage = result
            toneFilter.shadowAmount = 0.3
            toneFilter.highlightAmount = -0.2
            if let output = toneFilter.outputImage {
                result = output
            }

            // Local contrast enhancement using unsharp mask
            let unsharpFilter = CIFilter.unsharpMask()
            unsharpFilter.inputImage = result
            unsharpFilter.radius = 2.5
            unsharpFilter.intensity = 0.5
            if let output = unsharpFilter.outputImage {
                result = output
            }

            // Vibrance adjustment for better color balance
            let vibranceFilter = CIFilter.vibrance()
            vibranceFilter.inputImage = result
            vibranceFilter.amount = options.preserveColors ? 0.2 : 0.0
            if let output = vibranceFilter.outputImage {
                result = output
            }

            return result
        }

        private func performDenoising(_ image: CIImage, options _: ProcessingOptions) throws -> CIImage {
            var result = image

            // Noise reduction using median filter
            let medianFilter = CIFilter.median()
            medianFilter.inputImage = result
            if let output = medianFilter.outputImage {
                result = output
            }

            // Additional noise reduction for enhanced mode
            let noiseFilter = CIFilter.noiseReduction()
            noiseFilter.inputImage = result
            noiseFilter.noiseLevel = 0.02
            noiseFilter.sharpness = 0.4
            if let output = noiseFilter.outputImage {
                result = output
            }

            return result
        }

        private func performBasicSharpening(_ image: CIImage, options _: ProcessingOptions) throws -> CIImage {
            let sharpenFilter = CIFilter.sharpenLuminance()
            sharpenFilter.inputImage = image
            sharpenFilter.sharpness = 0.4

            return sharpenFilter.outputImage ?? image
        }

        private func performAdvancedSharpening(_ image: CIImage, options _: ProcessingOptions) throws -> CIImage {
            var result = image

            // Multi-scale sharpening
            let sharpenFilter = CIFilter.sharpenLuminance()
            sharpenFilter.inputImage = result
            sharpenFilter.sharpness = 0.6
            if let output = sharpenFilter.outputImage {
                result = output
            }

            // Edge enhancement for text
            let edgeFilter = CIFilter.edges()
            edgeFilter.inputImage = result
            edgeFilter.intensity = 3.0
            if let output = edgeFilter.outputImage {
                // Blend with original for subtle enhancement
                let blendFilter = CIFilter.sourceOverCompositing()
                blendFilter.inputImage = output
                blendFilter.backgroundImage = result
                if let blended = blendFilter.outputImage {
                    result = blended
                }
            }

            return result
        }

        private func performOCROptimization(_ image: CIImage, options _: ProcessingOptions) throws -> CIImage {
            var result = image

            // Increase contrast specifically for text recognition
            let colorFilter = CIFilter.colorControls()
            colorFilter.inputImage = result
            colorFilter.contrast = 1.5
            colorFilter.brightness = 0.05
            colorFilter.saturation = 0.0 // Convert to grayscale for better OCR
            if let output = colorFilter.outputImage {
                result = output
            }

            // Apply threshold for binary-like appearance
            let posterizeFilter = CIFilter.colorPosterize()
            posterizeFilter.inputImage = result
            posterizeFilter.levels = 6
            if let output = posterizeFilter.outputImage {
                result = output
            }

            return result
        }

        // MARK: - Document Scanner Processing

        private func performDocumentScannerProcessing(
            ciImage: CIImage,
            originalImage _: CIImage,
            options: ProcessingOptions,
            appliedFilters: inout [String],
            startTime: CFAbsoluteTime,
            updateProgress: (ProcessingStep, Double) -> Void
        ) async throws -> ProcessingResult {
            var processedImage = ciImage

            // Step 2: Edge Detection
            updateProgress(.edgeDetection, 0.0)
            let documentProcessingResult = try await documentProcessingPipeline.processDocument(
                processedImage,
                options: options
            )
            processedImage = documentProcessingResult.processedImage
            appliedFilters.append("edge_detection")
            appliedFilters.append("perspective_correction")
            updateProgress(.perspectiveCorrection, 1.0)

            // Step 3: Enhanced processing for document scanner mode
            updateProgress(.enhancement, 0.0)
            processedImage = try performAdvancedEnhancement(processedImage, options: options)
            appliedFilters.append("advanced_enhancement")
            updateProgress(.enhancement, 1.0)

            // Step 4: Denoising
            updateProgress(.denoising, 0.0)
            processedImage = try performDenoising(processedImage, options: options)
            appliedFilters.append("denoising")
            updateProgress(.denoising, 1.0)

            // Step 5: Advanced sharpening
            updateProgress(.sharpening, 0.0)
            processedImage = try performAdvancedSharpening(processedImage, options: options)
            appliedFilters.append("advanced_sharpening")
            updateProgress(.sharpening, 1.0)

            // Step 6: OCR optimization (always enabled for document scanner)
            updateProgress(.optimization, 0.0)
            processedImage = try performOCROptimization(processedImage, options: options)
            appliedFilters.append("ocr_optimization")
            updateProgress(.optimization, 1.0)

            // Step 7: Quality analysis with enhanced metrics
            updateProgress(.qualityAnalysis, 0.0)
            let qualityMetrics = documentProcessingResult.qualityMetrics
            updateProgress(.qualityAnalysis, 1.0)

            // Convert to data
            guard let finalCGImage = context.createCGImage(processedImage, from: processedImage.extent) else {
                throw ProcessingError.processingFailed("Failed to create final image")
            }

            let finalUIImage = UIImage(cgImage: finalCGImage)
            guard let finalImageData = finalUIImage.jpegData(compressionQuality: 0.92) else {
                throw ProcessingError.processingFailed("Failed to convert to JPEG data")
            }

            let processingTime = CFAbsoluteTimeGetCurrent() - startTime

            return ProcessingResult(
                processedImageData: finalImageData,
                qualityMetrics: qualityMetrics,
                processingTime: processingTime,
                appliedFilters: appliedFilters
            )
        }

        // MARK: - Quality Analysis

        private func analyzeQuality(_ processedImage: CIImage, originalImage _: CIImage) throws -> QualityMetrics {
            // Calculate various quality metrics
            let sharpnessScore = calculateSharpness(processedImage)
            let contrastScore = calculateContrast(processedImage)
            let noiseLevel = calculateNoiseLevel(processedImage)
            let textClarity = calculateTextClarity(processedImage)

            // Overall confidence based on weighted metrics
            let overallConfidence = (
                sharpnessScore * 0.3 +
                    contrastScore * 0.25 +
                    (1.0 - noiseLevel) * 0.2 +
                    textClarity * 0.25
            )

            let recommendedForOCR = overallConfidence > 0.7 && textClarity > 0.6

            return QualityMetrics(
                overallConfidence: overallConfidence,
                sharpnessScore: sharpnessScore,
                contrastScore: contrastScore,
                noiseLevel: noiseLevel,
                textClarity: textClarity,
                recommendedForOCR: recommendedForOCR
            )
        }

        private func calculateSharpness(_ image: CIImage) -> Double {
            // Use Sobel edge detection to measure sharpness
            let sobelFilter = CIFilter.convolution3X3()
            sobelFilter.inputImage = image
            sobelFilter.weights = CIVector(values: [-1, 0, 1, -2, 0, 2, -1, 0, 1], count: 9)
            sobelFilter.bias = 0.5

            guard let edgeImage = sobelFilter.outputImage else { return 0.5 }

            // Calculate average edge strength
            let stats = calculateImageStatistics(edgeImage)
            return min(1.0, stats.mean * 2.0)
        }

        private func calculateContrast(_ image: CIImage) -> Double {
            let stats = calculateImageStatistics(image)
            // Contrast as normalized standard deviation
            return min(1.0, stats.standardDeviation / 0.3)
        }

        private func calculateNoiseLevel(_ image: CIImage) -> Double {
            // Estimate noise using high-frequency components
            let highPassFilter = CIFilter.convolution3X3()
            highPassFilter.inputImage = image
            highPassFilter.weights = CIVector(values: [-1, -1, -1, -1, 8, -1, -1, -1, -1], count: 9)

            guard let noiseImage = highPassFilter.outputImage else { return 0.3 }

            let stats = calculateImageStatistics(noiseImage)
            return min(1.0, stats.standardDeviation)
        }

        private func calculateTextClarity(_ image: CIImage) -> Double {
            // Simplified text clarity assessment based on edge consistency
            let sharpness = calculateSharpness(image)
            let contrast = calculateContrast(image)

            // Text clarity correlates with both sharpness and contrast
            return sharpness * 0.6 + contrast * 0.4
        }

        private func calculateImageStatistics(_ image: CIImage) -> (mean: Double, standardDeviation: Double) {
            // Convert to grayscale for analysis
            let grayscaleFilter = CIFilter.colorControls()
            grayscaleFilter.inputImage = image
            grayscaleFilter.saturation = 0.0

            guard let grayscaleImage = grayscaleFilter.outputImage,
                  let cgImage = context.createCGImage(grayscaleImage, from: grayscaleImage.extent)
            else {
                return (mean: 0.5, standardDeviation: 0.2)
            }

            // Create a smaller sample for performance
            let sampleSize = 100
            let width = min(sampleSize, cgImage.width)
            let height = min(sampleSize, cgImage.height)

            guard let sampleCGImage = context.createCGImage(
                grayscaleImage,
                from: CGRect(x: 0, y: 0, width: width, height: height)
            ) else {
                return (mean: 0.5, standardDeviation: 0.2)
            }

            // Extract pixel data and calculate statistics
            let bytesPerPixel = 4
            let bytesPerRow = width * bytesPerPixel
            let totalBytes = height * bytesPerRow

            var pixelData = [UInt8](repeating: 0, count: totalBytes)

            guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(
                      data: &pixelData,
                      width: width,
                      height: height,
                      bitsPerComponent: 8,
                      bytesPerRow: bytesPerRow,
                      space: colorSpace,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  )
            else {
                return (mean: 0.5, standardDeviation: 0.2)
            }

            context.draw(sampleCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

            // Calculate mean
            var sum: Double = 0
            let pixelCount = width * height

            for i in stride(from: 0, to: totalBytes, by: bytesPerPixel) {
                let gray = Double(pixelData[i]) / 255.0
                sum += gray
            }

            let mean = sum / Double(pixelCount)

            // Calculate standard deviation
            var variance: Double = 0
            for i in stride(from: 0, to: totalBytes, by: bytesPerPixel) {
                let gray = Double(pixelData[i]) / 255.0
                let diff = gray - mean
                variance += diff * diff
            }

            let standardDeviation = sqrt(variance / Double(pixelCount))

            return (mean: mean, standardDeviation: standardDeviation)
        }

        // MARK: - Time Estimation

        func estimateProcessingTime(_ imageData: Data, mode: ProcessingMode) async throws -> TimeInterval {
            let imageSize = Double(imageData.count)
            let megabytes = imageSize / 1_000_000.0

            // Base processing times (in seconds)
            let baseTime: TimeInterval = mode == .enhanced ? 3.0 : 0.8

            // Scale based on image size
            let sizeMultiplier = max(1.0, sqrt(megabytes))

            // Device performance factor (simplified)
            let performanceFactor = 1.0 // Could be adjusted based on device capabilities

            return baseTime * sizeMultiplier * performanceFactor
        }

        func isProcessingModeAvailable(_: ProcessingMode) -> Bool {
            // Both modes are available on iOS with Core Image
            true
        }

        // MARK: - Helper Methods

        private func estimateRemainingTime(startTime: CFAbsoluteTime, progress: Double) -> TimeInterval? {
            guard progress > 0.1 else { return nil }

            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            let totalEstimated = elapsed / progress
            return totalEstimated - elapsed
        }
    }#endif
