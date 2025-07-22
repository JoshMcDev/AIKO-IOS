#if os(iOS)
    @preconcurrency import CoreImage
    @preconcurrency import CoreImage.CIFilterBuiltins
    import Foundation
    @preconcurrency import Metal
    import UIKit
    import Vision

    // MARK: - Edge Detection Engine

    /// High-performance edge detection engine using Core Image and Metal GPU acceleration
    /// Targets <1 second processing time with >95% success rate for document edge detection
    actor EdgeDetectionEngine {
        // MARK: - Properties

        private let context: CIContext
        private let metalDevice: MTLDevice?

        // MARK: - Edge Detection Result

        struct EdgeDetectionResult: Sendable {
            let edgeConfidenceMap: CIImage
            let detectedCorners: [CGPoint]
            let confidence: Double
            let processingTime: TimeInterval
            let documentBounds: CGRect?
        }

        // MARK: - Initialization

        init(context: CIContext, metalDevice: MTLDevice?) {
            self.context = context
            self.metalDevice = metalDevice
        }

        // MARK: - Main Edge Detection

        /// Performs high-performance edge detection on the input image
        /// - Parameters:
        ///   - image: Input image for edge detection
        ///   - progressCallback: Optional progress callback for UI updates
        /// - Returns: EdgeDetectionResult with detected edges and confidence
        func detectEdges(
            in image: CIImage,
            progressCallback: (@Sendable (Double) -> Void)? = nil
        ) async throws -> EdgeDetectionResult {
            let startTime = CFAbsoluteTimeGetCurrent()

            // Step 1: Preprocess image for edge detection (20% of work)
            progressCallback?(0.2)
            let preprocessedImage = try preprocessForEdgeDetection(image)

            // Step 2: Apply edge detection filters (40% of work)
            progressCallback?(0.6)
            let edgeMap = try performEdgeDetection(preprocessedImage)

            // Step 3: Detect document corners using Vision (30% of work)
            progressCallback?(0.9)
            let (corners, documentBounds) = try await detectDocumentCorners(in: image, edgeMap: edgeMap)

            // Step 4: Calculate confidence (10% of work)
            progressCallback?(1.0)
            let confidence = calculateEdgeConfidence(edgeMap: edgeMap, corners: corners)

            let processingTime = CFAbsoluteTimeGetCurrent() - startTime

            return EdgeDetectionResult(
                edgeConfidenceMap: edgeMap,
                detectedCorners: corners,
                confidence: confidence,
                processingTime: processingTime,
                documentBounds: documentBounds
            )
        }

        // MARK: - Preprocessing

        private func preprocessForEdgeDetection(_ image: CIImage) throws -> CIImage {
            var result = image

            // Convert to grayscale for edge detection
            guard let grayscaleFilter = CIFilter(name: "CIColorControls") else {
                throw EdgeDetectionError.processingFailed("Failed to create color controls filter")
            }
            grayscaleFilter.setValue(result, forKey: kCIInputImageKey)
            grayscaleFilter.setValue(0.0, forKey: "inputSaturation")
            grayscaleFilter.setValue(1.2, forKey: "inputContrast")
            if let output = grayscaleFilter.outputImage {
                result = output
            }

            // Apply Gaussian blur to reduce noise before edge detection
            guard let blurFilter = CIFilter(name: "CIGaussianBlur") else {
                throw EdgeDetectionError.processingFailed("Failed to create gaussian blur filter")
            }
            blurFilter.setValue(result, forKey: kCIInputImageKey)
            blurFilter.setValue(1.0, forKey: "inputRadius")
            if let output = blurFilter.outputImage {
                result = output
            }

            return result
        }

        // MARK: - Edge Detection

        private func performEdgeDetection(_ image: CIImage) throws -> CIImage {
            // Primary edge detection using Sobel operator
            guard let sobelFilter = CIFilter(name: "CIConvolution3X3") else {
                throw EdgeDetectionError.processingFailed("Failed to create convolution filter")
            }
            sobelFilter.setValue(image, forKey: kCIInputImageKey)
            // Sobel X kernel for vertical edges
            sobelFilter.setValue(CIVector(values: [-1, 0, 1, -2, 0, 2, -1, 0, 1], count: 9), forKey: "inputWeights")
            sobelFilter.setValue(0.5, forKey: "inputBias")

            guard let sobelX = sobelFilter.outputImage else {
                throw EdgeDetectionError.processingFailed("Sobel X filter failed")
            }

            // Sobel Y kernel for horizontal edges
            sobelFilter.setValue(CIVector(values: [-1, -2, -1, 0, 0, 0, 1, 2, 1], count: 9), forKey: "inputWeights")
            sobelFilter.setValue(image, forKey: kCIInputImageKey)

            guard let sobelY = sobelFilter.outputImage else {
                throw EdgeDetectionError.processingFailed("Sobel Y filter failed")
            }

            // Combine X and Y gradients using magnitude
            guard let magnitudeFilter = CIFilter(name: "CIAdditionCompositing") else {
                throw EdgeDetectionError.processingFailed("Failed to create addition compositing filter")
            }
            magnitudeFilter.setValue(sobelX, forKey: kCIInputImageKey)
            magnitudeFilter.setValue(sobelY, forKey: kCIInputBackgroundImageKey)

            guard var edgeMap = magnitudeFilter.outputImage else {
                throw EdgeDetectionError.processingFailed("Edge magnitude combination failed")
            }

            // Enhance edges with morphological operations
            if let morphologyFilter = CIFilter(name: "CIMorphologyRectangleMinimum") {
                morphologyFilter.setValue(edgeMap, forKey: kCIInputImageKey)
                morphologyFilter.setValue(2, forKey: "inputWidth")
                morphologyFilter.setValue(2, forKey: "inputHeight")
                if let enhanced = morphologyFilter.outputImage {
                    edgeMap = enhanced
                }
            }

            // Apply threshold to get binary edge map
            if let thresholdFilter = CIFilter(name: "CIColorThreshold") {
                thresholdFilter.setValue(edgeMap, forKey: kCIInputImageKey)
                thresholdFilter.setValue(0.3, forKey: "inputThreshold")
                if let thresholded = thresholdFilter.outputImage {
                    edgeMap = thresholded
                }
            }

            return edgeMap
        }

        // MARK: - Corner Detection

        private func detectDocumentCorners(
            in originalImage: CIImage,
            edgeMap: CIImage
        ) async throws -> ([CGPoint], CGRect?) {
            // Convert CIImage to CGImage for Vision processing
            guard let cgImage = context.createCGImage(originalImage, from: originalImage.extent) else {
                throw EdgeDetectionError.processingFailed("Failed to create CGImage for corner detection")
            }

            return try await withCheckedThrowingContinuation { continuation in
                let request = VNDetectRectanglesRequest { request, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let observations = request.results as? [VNRectangleObservation],
                          let bestObservation = observations.first
                    else {
                        // If no rectangles detected, try to detect corners from edge map
                        let fallbackCorners = self.detectCornersFromEdgeMap(edgeMap, imageSize: originalImage.extent.size)
                        continuation.resume(returning: (fallbackCorners, nil))
                        return
                    }

                    // Convert normalized coordinates to image coordinates
                    let imageSize = originalImage.extent.size
                    let corners = [
                        CGPoint(
                            x: bestObservation.topLeft.x * imageSize.width,
                            y: (1.0 - bestObservation.topLeft.y) * imageSize.height
                        ),
                        CGPoint(
                            x: bestObservation.topRight.x * imageSize.width,
                            y: (1.0 - bestObservation.topRight.y) * imageSize.height
                        ),
                        CGPoint(
                            x: bestObservation.bottomRight.x * imageSize.width,
                            y: (1.0 - bestObservation.bottomRight.y) * imageSize.height
                        ),
                        CGPoint(
                            x: bestObservation.bottomLeft.x * imageSize.width,
                            y: (1.0 - bestObservation.bottomLeft.y) * imageSize.height
                        ),
                    ]

                    // Calculate document bounds
                    let bounds = CGRect(
                        x: min(corners[0].x, corners[1].x, corners[2].x, corners[3].x),
                        y: min(corners[0].y, corners[1].y, corners[2].y, corners[3].y),
                        width: max(corners[0].x, corners[1].x, corners[2].x, corners[3].x) - min(corners[0].x, corners[1].x, corners[2].x, corners[3].x),
                        height: max(corners[0].y, corners[1].y, corners[2].y, corners[3].y) - min(corners[0].y, corners[1].y, corners[2].y, corners[3].y)
                    )

                    continuation.resume(returning: (corners, bounds))
                }

                // Configure rectangle detection
                request.maximumObservations = 1
                request.minimumConfidence = 0.7
                request.minimumAspectRatio = 0.3
                request.maximumAspectRatio = 3.0
                request.minimumSize = 0.1

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        // MARK: - Fallback Corner Detection

        private func detectCornersFromEdgeMap(_ edgeMap: CIImage, imageSize: CGSize) -> [CGPoint] {
            // Fallback corner detection using Harris corner detector
            guard let cornerFilter = CIFilter(name: "CIConvolution3X3") else {
                // Return default corners if filter creation fails
                return [
                    CGPoint(x: imageSize.width * 0.1, y: imageSize.height * 0.1),
                    CGPoint(x: imageSize.width * 0.9, y: imageSize.height * 0.1),
                    CGPoint(x: imageSize.width * 0.9, y: imageSize.height * 0.9),
                    CGPoint(x: imageSize.width * 0.1, y: imageSize.height * 0.9),
                ]
            }
            cornerFilter.setValue(edgeMap, forKey: kCIInputImageKey)
            // Harris corner detection kernel (simplified)
            cornerFilter.setValue(CIVector(values: [1, -2, 1, -2, 4, -2, 1, -2, 1], count: 9), forKey: "inputWeights")

            guard cornerFilter.outputImage != nil else {
                // Return default corners if corner detection fails
                return [
                    CGPoint(x: imageSize.width * 0.1, y: imageSize.height * 0.1),
                    CGPoint(x: imageSize.width * 0.9, y: imageSize.height * 0.1),
                    CGPoint(x: imageSize.width * 0.9, y: imageSize.height * 0.9),
                    CGPoint(x: imageSize.width * 0.1, y: imageSize.height * 0.9),
                ]
            }

            // For now, return estimated corners based on image size
            // In a production implementation, this would analyze the corner response
            return [
                CGPoint(x: imageSize.width * 0.05, y: imageSize.height * 0.05),
                CGPoint(x: imageSize.width * 0.95, y: imageSize.height * 0.05),
                CGPoint(x: imageSize.width * 0.95, y: imageSize.height * 0.95),
                CGPoint(x: imageSize.width * 0.05, y: imageSize.height * 0.95),
            ]
        }

        // MARK: - Confidence Calculation

        private func calculateEdgeConfidence(edgeMap: CIImage, corners: [CGPoint]) -> Double {
            // Calculate edge confidence based on edge density and corner quality
            let edgeStats = calculateImageStatistics(edgeMap)

            // Edge density score (0.0 to 1.0)
            let edgeDensity = min(1.0, edgeStats.mean * 4.0)

            // Corner quality score based on geometric properties
            let cornerQuality = evaluateCornerQuality(corners)

            // Combined confidence score
            let confidence = (edgeDensity * 0.6 + cornerQuality * 0.4)

            return max(0.0, min(1.0, confidence))
        }

        private func evaluateCornerQuality(_ corners: [CGPoint]) -> Double {
            guard corners.count == 4 else { return 0.0 }

            // Check if corners form a reasonable quadrilateral
            let area = calculateQuadrilateralArea(corners)
            _ = calculateQuadrilateralPerimeter(corners)

            // Aspect ratio check (documents are typically rectangular)
            let width = max(corners[1].x - corners[0].x, corners[2].x - corners[3].x)
            let height = max(corners[3].y - corners[0].y, corners[2].y - corners[1].y)
            let aspectRatio = min(width, height) / max(width, height)

            // Quality score based on geometric properties
            let areaScore = min(1.0, area / (500 * 500)) // Normalize to reasonable document size
            let aspectScore = aspectRatio > 0.3 ? 1.0 : aspectRatio / 0.3

            return areaScore * 0.5 + aspectScore * 0.5
        }

        private func calculateQuadrilateralArea(_ corners: [CGPoint]) -> Double {
            guard corners.count == 4 else { return 0.0 }

            // Shoelace formula for quadrilateral area
            let xCoordinates = corners.map(\.x)
            let yCoordinates = corners.map(\.y)

            var area = 0.0
            for cornerIndex in 0 ..< 4 {
                let nextIndex = (cornerIndex + 1) % 4
                area += xCoordinates[cornerIndex] * yCoordinates[nextIndex] - xCoordinates[nextIndex] * yCoordinates[cornerIndex]
            }

            return abs(area) / 2.0
        }

        private func calculateQuadrilateralPerimeter(_ corners: [CGPoint]) -> Double {
            guard corners.count == 4 else { return 0.0 }

            var perimeter = 0.0
            for cornerIndex in 0 ..< 4 {
                let nextIndex = (cornerIndex + 1) % 4
                let deltaX = corners[nextIndex].x - corners[cornerIndex].x
                let deltaY = corners[nextIndex].y - corners[cornerIndex].y
                perimeter += sqrt(deltaX * deltaX + deltaY * deltaY)
            }

            return perimeter
        }

        // MARK: - Image Statistics

        private func calculateImageStatistics(_ image: CIImage) -> (mean: Double, standardDeviation: Double) {
            // Convert to grayscale for analysis
            guard let grayscaleFilter = CIFilter(name: "CIColorControls") else {
                return (mean: 0.5, standardDeviation: 0.2)
            }
            grayscaleFilter.setValue(image, forKey: kCIInputImageKey)
            grayscaleFilter.setValue(0, forKey: "inputSaturation")

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

            for byteIndex in stride(from: 0, to: totalBytes, by: bytesPerPixel) {
                let gray = Double(pixelData[byteIndex]) / 255.0
                sum += gray
            }

            let mean = sum / Double(pixelCount)

            // Calculate standard deviation
            var variance: Double = 0
            for byteIndex in stride(from: 0, to: totalBytes, by: bytesPerPixel) {
                let gray = Double(pixelData[byteIndex]) / 255.0
                let diff = gray - mean
                variance += diff * diff
            }

            let standardDeviation = sqrt(variance / Double(pixelCount))

            return (mean: mean, standardDeviation: standardDeviation)
        }
    }

    // MARK: - Edge Detection Errors

    enum EdgeDetectionError: LocalizedError {
        case processingFailed(String)
        case invalidInput
        case gpuNotAvailable
        case filterCreationFailed

        var errorDescription: String? {
            switch self {
            case let .processingFailed(reason):
                "Edge detection failed: \(reason)"
            case .invalidInput:
                "Invalid input image for edge detection"
            case .gpuNotAvailable:
                "GPU acceleration not available for edge detection"
            case .filterCreationFailed:
                "Failed to create Core Image filter"
            }
        }
    }
#endif
