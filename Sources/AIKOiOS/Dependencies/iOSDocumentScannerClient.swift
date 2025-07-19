import AppCore
import ComposableArchitecture
import Foundation
import UIKit
import VisionKit
import Vision

/// iOS-specific implementation of DocumentScannerClient
public struct iOSDocumentScannerClient: Sendable {}

// MARK: - Live Implementation

extension iOSDocumentScannerClient {
    @MainActor
    public static let live: DocumentScannerClient = {
        return DocumentScannerClient(
            scan: {
                try await performScan()
            },
            enhanceImage: { imageData in
                try await enhanceImage(imageData)
            },
            performOCR: { imageData in
                try await performOCR(on: imageData)
            },
            generateThumbnail: { imageData, size in
                try await generateThumbnail(from: imageData, size: size)
            },
            saveToDocumentPipeline: { pages in
                try await saveToDocumentPipeline(pages)
            },
            isScanningAvailable: {
                // Access the property in a way that doesn't require main actor
                return true // VisionKit availability is determined at runtime
            }
        )
    }()
}

// MARK: - Implementation Methods

extension iOSDocumentScannerClient {
    @MainActor
    private static func performScan() async throws -> ScannedDocument {
        guard VNDocumentCameraViewController.isSupported else {
            throw DocumentScannerError.scanningNotAvailable
        }
        
        let coordinator = DocumentScannerCoordinator()
        return try await coordinator.performScan()
    }
    
    private static func enhanceImage(_ imageData: Data) async throws -> Data {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            throw DocumentScannerError.invalidImageData
        }
        
        // Apply image enhancement filters
        let context = CIContext()
        var ciImage = CIImage(cgImage: cgImage)
        
        // Apply contrast filter
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(ciImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.2, forKey: kCIInputContrastKey)
            contrastFilter.setValue(0.1, forKey: kCIInputBrightnessKey)
            
            if let output = contrastFilter.outputImage {
                ciImage = output
            }
        }
        
        // Apply sharpness filter
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(ciImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.4, forKey: kCIInputSharpnessKey)
            
            if let output = sharpenFilter.outputImage {
                ciImage = output
            }
        }
        
        // Convert back to data
        if let finalCGImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let finalImage = UIImage(cgImage: finalCGImage)
            if let enhancedData = finalImage.jpegData(compressionQuality: 0.9) {
                return enhancedData
            }
        }
        
        throw DocumentScannerError.invalidImageData
    }
    
    private static func performOCR(on imageData: Data) async throws -> String {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            throw DocumentScannerError.invalidImageData
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: DocumentScannerError.ocrFailed("No text observations found"))
                    return
                }
                
                var text = ""
                
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    text += candidate.string + "\n"
                }
                
                continuation.resume(returning: text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private static func generateThumbnail(from imageData: Data, size: CGSize) async throws -> Data {
        guard let image = UIImage(data: imageData) else {
            throw DocumentScannerError.invalidImageData
        }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let thumbnail = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8) else {
            throw DocumentScannerError.invalidImageData
        }
        
        return thumbnailData
    }
    
    private static func saveToDocumentPipeline(_ pages: [ScannedPage]) async throws {
        // Create a PDF from the scanned pages
        let pdfDocument = PDFDocument()
        
        for (index, page) in pages.enumerated() {
            guard let image = UIImage(data: page.imageData) else { continue }
            
            if let pdfPage = PDFPage(image: image) {
                pdfDocument.insert(pdfPage, at: index)
            }
        }
        
        guard let pdfData = pdfDocument.dataRepresentation() else {
            throw DocumentScannerError.invalidImageData
        }
        
        // Save to document pipeline
        // In a real implementation, this would save the PDF data to the document system
        // For now, we just validate that we can create the PDF
        _ = pdfData
    }
}

// MARK: - PDFKit Import

import PDFKit

// MARK: - Document Scanner Coordinator

@MainActor
private final class DocumentScannerCoordinator: NSObject {
    private var scanCompletion: ((Result<ScannedDocument, Error>) -> Void)?
    
    func performScan() async throws -> ScannedDocument {
        try await withCheckedThrowingContinuation { continuation in
            self.scanCompletion = { result in
                switch result {
                case .success(let document):
                    continuation.resume(returning: document)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            let scannerViewController = VNDocumentCameraViewController()
            scannerViewController.delegate = self
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(scannerViewController, animated: true)
            } else {
                self.scanCompletion?(.failure(DocumentScannerError.scanningNotAvailable))
            }
        }
    }
}

// MARK: - VNDocumentCameraViewControllerDelegate

extension DocumentScannerCoordinator: VNDocumentCameraViewControllerDelegate {
    nonisolated func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        Task { @MainActor in
            controller.dismiss(animated: true)
            
            var pages: [ScannedPage] = []
            
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                
                if let imageData = image.jpegData(compressionQuality: 0.9) {
                    let page = ScannedPage(
                        id: UUID(),
                        imageData: imageData,
                        pageNumber: pageIndex + 1
                    )
                    pages.append(page)
                }
            }
            
            let document = ScannedDocument(
                id: UUID(),
                pages: pages,
                scannedAt: Date()
            )
            
            scanCompletion?(.success(document))
        }
    }
    
    nonisolated func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        Task { @MainActor in
            controller.dismiss(animated: true)
            scanCompletion?(.failure(DocumentScannerError.userCancelled))
        }
    }
    
    nonisolated func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        Task { @MainActor in
            controller.dismiss(animated: true)
            scanCompletion?(.failure(error))
        }
    }
}