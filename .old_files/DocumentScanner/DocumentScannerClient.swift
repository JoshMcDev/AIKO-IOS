import ComposableArchitecture
import Foundation
#if os(iOS)
import UIKit
import Vision
import VisionKit
#endif

// MARK: - Document Scanner Client

#if os(iOS)
@DependencyClient
public struct DocumentScannerClient {
    // Image enhancement
    public var enhanceImage: @Sendable (UIImage) async throws -> UIImage
    
    // OCR processing
    public var performOCR: @Sendable (UIImage) async throws -> String
    
    // Document pipeline integration
    public var saveToDocumentPipeline: @Sendable ([DocumentScannerFeature.ProcessedDocument]) async throws -> Void
}
#else
// macOS placeholder
@DependencyClient
public struct DocumentScannerClient {
    public var enhanceImage: @Sendable (Data) async throws -> Data
    public var performOCR: @Sendable (Data) async throws -> String
    public var saveToDocumentPipeline: @Sendable ([DocumentScannerFeature.ProcessedDocument]) async throws -> Void
}
#endif

// MARK: - Dependency Key

extension DocumentScannerClient: DependencyKey {
    #if os(iOS)
    public static let liveValue = Self(
        enhanceImage: { image in
            try await ImageEnhancementService.shared.enhance(image)
        },
        performOCR: { image in
            try await OCRService.shared.extractText(from: image)
        },
        saveToDocumentPipeline: { documents in
            try await DocumentProcessingService.shared.processScannedDocuments(documents)
        }
    )
    #else
    public static let liveValue = Self()
    #endif
    
    public static let testValue = Self()
}

// MARK: - Dependency Values Extension

extension DependencyValues {
    public var documentScannerClient: DocumentScannerClient {
        get { self[DocumentScannerClient.self] }
        set { self[DocumentScannerClient.self] = newValue }
    }
}

// MARK: - Image Enhancement Service

#if os(iOS)
@MainActor
public final class ImageEnhancementService {
    public static let shared = ImageEnhancementService()
    
    private init() {}
    
    public func enhance(_ image: UIImage) async throws -> UIImage {
        // Apply image filters for document enhancement
        guard let ciImage = CIImage(image: image) else {
            throw ImageEnhancementError.invalidImage
        }
        
        let context = CIContext()
        
        // Apply filters in sequence
        var enhancedImage = ciImage
        
        // 1. Auto-adjust for better contrast
        if let autoAdjustFilter = CIFilter(name: "CIColorControls") {
            autoAdjustFilter.setValue(enhancedImage, forKey: kCIInputImageKey)
            autoAdjustFilter.setValue(1.1, forKey: kCIInputContrastKey)
            autoAdjustFilter.setValue(0.05, forKey: kCIInputBrightnessKey)
            autoAdjustFilter.setValue(1.2, forKey: kCIInputSaturationKey)
            
            if let output = autoAdjustFilter.outputImage {
                enhancedImage = output
            }
        }
        
        // 2. Perspective correction (if needed)
        enhancedImage = try await performPerspectiveCorrection(on: enhancedImage)
        
        // 3. Document-specific filter for black and white enhancement
        if let documentFilter = CIFilter(name: "CIDocumentEnhancer") {
            documentFilter.setValue(enhancedImage, forKey: kCIInputImageKey)
            documentFilter.setValue(1.0, forKey: "inputAmount")
            
            if let output = documentFilter.outputImage {
                enhancedImage = output
            }
        } else {
            // Fallback to exposure adjustment if DocumentEnhancer is not available
            if let exposureFilter = CIFilter(name: "CIExposureAdjust") {
                exposureFilter.setValue(enhancedImage, forKey: kCIInputImageKey)
                exposureFilter.setValue(0.3, forKey: kCIInputEVKey)
                
                if let output = exposureFilter.outputImage {
                    enhancedImage = output
                }
            }
        }
        
        // 4. Sharpen the image
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(enhancedImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.4, forKey: kCIInputSharpnessKey)
            
            if let output = sharpenFilter.outputImage {
                enhancedImage = output
            }
        }
        
        // Convert back to UIImage
        guard let cgImage = context.createCGImage(enhancedImage, from: enhancedImage.extent) else {
            throw ImageEnhancementError.processingFailed
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func performPerspectiveCorrection(on image: CIImage) async throws -> CIImage {
        // Use Vision framework to detect document rectangle
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 0.9
        request.minimumSize = 0.2
        request.maximumObservations = 1
        
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observation = request.results?.first as? VNRectangleObservation else {
                // No rectangle detected, return original
                return image
            }
            
            // Apply perspective correction
            let perspectiveFilter = CIFilter(name: "CIPerspectiveCorrection")!
            perspectiveFilter.setValue(image, forKey: kCIInputImageKey)
            
            let imageSize = image.extent.size
            
            // Convert normalized points to image coordinates
            perspectiveFilter.setValue(CIVector(x: observation.topLeft.x * imageSize.width,
                                               y: observation.topLeft.y * imageSize.height),
                                     forKey: "inputTopLeft")
            perspectiveFilter.setValue(CIVector(x: observation.topRight.x * imageSize.width,
                                               y: observation.topRight.y * imageSize.height),
                                     forKey: "inputTopRight")
            perspectiveFilter.setValue(CIVector(x: observation.bottomRight.x * imageSize.width,
                                               y: observation.bottomRight.y * imageSize.height),
                                     forKey: "inputBottomRight")
            perspectiveFilter.setValue(CIVector(x: observation.bottomLeft.x * imageSize.width,
                                               y: observation.bottomLeft.y * imageSize.height),
                                     forKey: "inputBottomLeft")
            
            return perspectiveFilter.outputImage ?? image
            
        } catch {
            // If detection fails, return original image
            return image
        }
    }
}

// MARK: - OCR Service

@MainActor
public final class OCRService {
    public static let shared = OCRService()
    
    private init() {}
    
    public func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                // Extract text from observations
                let text = observations
                    .compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }
                    .joined(separator: "\n")
                
                if text.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: text)
                }
            }
            
            // Configure recognition
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            
            // Perform request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }
}

// MARK: - Document Processing Service

@MainActor
public final class DocumentProcessingService {
    public static let shared = DocumentProcessingService()
    
    private init() {}
    
    public func processScannedDocuments(_ documents: [DocumentScannerFeature.ProcessedDocument]) async throws {
        // Convert scanned documents to UploadedDocument format for consistency
        var uploadedDocuments: [(Data, String)] = []
        
        for document in documents {
            guard let imageData = document.image.jpegData(compressionQuality: 0.8) else {
                throw ImageEnhancementError.processingFailed
            }
            
            let fileName = document.title.isEmpty ? "Scanned_Document_Page_\(document.pageNumber).jpg" : "\(document.title)_Page_\(document.pageNumber).jpg"
            uploadedDocuments.append((imageData, fileName))
        }
        
        // Store the documents using the existing document service infrastructure
        // For now, we'll just save them - integration with the full pipeline can be added later
        try await saveDocumentsLocally(uploadedDocuments)
    }
    
    private func processDocument(_ document: DocumentData) async throws {
        // This would integrate with the existing document processing pipeline
        // For now, we'll create a placeholder implementation
        
        // 1. Save to local storage
        try await saveToLocalStorage(document)
        
        // 2. Extract metadata
        let metadata = try await extractMetadata(from: document)
        
        // 3. Categorize document
        let category = try await categorizeDocument(document, with: metadata)
        
        // 4. Index for search
        try await indexDocument(document, metadata: metadata, category: category)
        
        // 5. Trigger any follow-on actions
        try await triggerFollowOnActions(for: document, category: category)
    }
    
    private func saveToLocalStorage(_ document: DocumentData) async throws {
        // Implementation would save to Core Data or file system
    }
    
    private func extractMetadata(from document: DocumentData) async throws -> DocumentMetadata {
        // Extract dates, amounts, parties, etc. from the document
        return DocumentMetadata(
            documentId: document.id,
            extractedDate: Date(),
            documentDate: nil,
            parties: [],
            amounts: [],
            keywords: []
        )
    }
    
    private func categorizeDocument(_ document: DocumentData, with metadata: DocumentMetadata) async throws -> DocumentCategory {
        // Use AI or rules to categorize the document
        return .contract
    }
    
    private func indexDocument(_ document: DocumentData, metadata: DocumentMetadata, category: DocumentCategory) async throws {
        // Add to search index
    }
    
    private func triggerFollowOnActions(for document: DocumentData, category: DocumentCategory) async throws {
        // Trigger any automated workflows based on document type
    }
    
    private func saveDocumentsLocally(_ documents: [(Data, String)]) async throws {
        // Get the documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let scannedDocsPath = documentsPath.appendingPathComponent("ScannedDocuments")
        
        // Create directory if it doesn't exist
        try FileManager.default.createDirectory(at: scannedDocsPath, withIntermediateDirectories: true)
        
        // Save each document
        for (data, fileName) in documents {
            let filePath = scannedDocsPath.appendingPathComponent(fileName)
            try data.write(to: filePath)
        }
    }
}

// MARK: - Error Types

public enum ImageEnhancementError: LocalizedError {
    case invalidImage
    case processingFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image could not be processed"
        case .processingFailed:
            return "Image enhancement failed"
        }
    }
}

public enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed(Error)
    case noTextFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image is not valid for OCR"
        case .recognitionFailed(let error):
            return "Text recognition failed: \(error.localizedDescription)"
        case .noTextFound:
            return "No text was found in the image"
        }
    }
}

// MARK: - Supporting Types

public struct DocumentData {
    let id: UUID
    let title: String
    let type: DocumentType
    let content: String
    let pageNumber: Int
    let imageData: Data?
    let createdAt: Date
}

public struct DocumentMetadata {
    let documentId: UUID
    let extractedDate: Date
    let documentDate: Date?
    let parties: [String]
    let amounts: [Decimal]
    let keywords: [String]
}

public enum DocumentCategory {
    case contract
    case invoice
    case receipt
    case form
    case report
    case other
}
#endif // os(iOS)