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
        @Dependency(\.documentImageProcessor) var imageProcessor
        
        return DocumentScannerClient(
            scan: {
                try await performScan()
            },
            enhanceImage: { imageData in
                // Maintain backward compatibility - use basic mode
                let result = try await imageProcessor.processImage(
                    imageData,
                    .basic,
                    ProcessingOptions()
                )
                return result.processedImageData
            },
            enhanceImageAdvanced: { imageData, mode, options in
                try await imageProcessor.processImage(imageData, mode, options)
            },
            performOCR: { imageData in
                try await performOCR(on: imageData)
            },
            performEnhancedOCR: { imageData in
                try await performEnhancedOCR(on: imageData)
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
            },
            estimateProcessingTime: { imageData, mode in
                try await imageProcessor.estimateProcessingTime(imageData, mode)
            },
            isProcessingModeAvailable: { mode in
                imageProcessor.isProcessingModeAvailable(mode)
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
    
    // Legacy enhanceImage method removed - now handled by DocumentImageProcessor
    
    private static func performOCR(on imageData: Data) async throws -> String {
        let result = try await performEnhancedOCR(on: imageData)
        return result.fullText
    }
    
    private static func performEnhancedOCR(on imageData: Data) async throws -> OCRResult {
        @Dependency(\.documentImageProcessor) var imageProcessor
        
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            throw DocumentScannerError.invalidImageData
        }
        
        let startTime = Date()
        
        // First, enhance the image for OCR if it's not already enhanced
        let enhancedImageData: Data
        if imageData.count > 1_000_000 { // Use enhanced mode for larger images
            let processingResult = try await imageProcessor.processImage(
                imageData,
                .enhanced,
                ProcessingOptions(optimizeForOCR: true)
            )
            enhancedImageData = processingResult.processedImageData
        } else {
            let processingResult = try await imageProcessor.processImage(
                imageData,
                .basic,
                ProcessingOptions(optimizeForOCR: true)
            )
            enhancedImageData = processingResult.processedImageData
        }
        
        guard let enhancedImage = UIImage(data: enhancedImageData),
              let enhancedCGImage = enhancedImage.cgImage else {
            // Fall back to original image if enhancement fails
            return try await performBasicOCR(on: cgImage, startTime: startTime)
        }
        
        return try await performAdvancedOCR(on: enhancedCGImage, startTime: startTime)
    }
    
    private static func performBasicOCR(on cgImage: CGImage, startTime: Date) async throws -> OCRResult {
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
                
                var fullText = ""
                var textRegions: [TextRegion] = []
                var confidenceScores: [Double] = []
                
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    
                    fullText += candidate.string + "\n"
                    confidenceScores.append(Double(candidate.confidence))
                    
                    textRegions.append(TextRegion(
                        text: candidate.string,
                        boundingBox: observation.boundingBox,
                        confidence: Double(candidate.confidence),
                        textType: .body
                    ))
                }
                
                let processingTime = Date().timeIntervalSince(startTime)
                let overallConfidence = confidenceScores.isEmpty ? 0.0 : confidenceScores.reduce(0, +) / Double(confidenceScores.count)
                
                let result = OCRResult(
                    fullText: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
                    confidence: overallConfidence,
                    recognizedFields: [],
                    documentStructure: DocumentStructure(
                        paragraphs: textRegions,
                        layout: .document
                    ),
                    extractedMetadata: ExtractedMetadata(),
                    processingTime: processingTime
                )
                
                continuation.resume(returning: result)
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
    
    private static func performAdvancedOCR(on cgImage: CGImage, startTime: Date) async throws -> OCRResult {
        return try await withCheckedThrowingContinuation { continuation in
            // Create multiple Vision requests for comprehensive analysis
            let textRequest = VNRecognizeTextRequest()
            let rectangleRequest = VNDetectRectanglesRequest()
            
            var textObservations: [VNRecognizedTextObservation] = []
            var rectangleObservations: [VNRectangleObservation] = []
            
            // Configure text recognition request
            textRequest.recognitionLevel = .accurate
            textRequest.recognitionLanguages = ["en-US"]
            textRequest.usesLanguageCorrection = true
            textRequest.automaticallyDetectsLanguage = true
            
            // Configure rectangle detection for forms/tables
            rectangleRequest.maximumObservations = 20
            rectangleRequest.minimumConfidence = 0.7
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([textRequest, rectangleRequest])
                
                // Get results from the requests
                if let textResults = textRequest.results {
                    textObservations = textResults
                }
                
                if let rectangleResults = rectangleRequest.results {
                    rectangleObservations = rectangleResults
                }
                
                // Process results
                let result = processVisionResults(
                    textObservations: textObservations,
                    rectangleObservations: rectangleObservations,
                    startTime: startTime
                )
                
                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private static func processVisionResults(
        textObservations: [VNRecognizedTextObservation],
        rectangleObservations: [VNRectangleObservation],
        startTime: Date
    ) -> OCRResult {
        
        var fullText = ""
        var textRegions: [TextRegion] = []
        var confidenceScores: [Double] = []
        var formFields: [FormField] = []
        
        // Collect metadata components
        var allDates: [ExtractedDate] = []
        var allPhoneNumbers: [String] = []
        var allEmailAddresses: [String] = []
        var allCurrencies: [ExtractedCurrency] = []
        
        // Process text observations
        for observation in textObservations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            
            let text = candidate.string
            fullText += text + "\n"
            confidenceScores.append(Double(candidate.confidence))
            
            // Determine text type based on position and content
            let textType = determineTextType(text: text, boundingBox: observation.boundingBox)
            
            textRegions.append(TextRegion(
                text: text,
                boundingBox: observation.boundingBox,
                confidence: Double(candidate.confidence),
                textType: textType
            ))
            
            // Extract metadata from text
            let metadata = extractMetadataFromText(text)
            allDates.append(contentsOf: metadata.dates)
            allPhoneNumbers.append(contentsOf: metadata.phoneNumbers)
            allEmailAddresses.append(contentsOf: metadata.emailAddresses)
            allCurrencies.append(contentsOf: metadata.currencies)
        }
        
        // Create the extracted metadata with all collected data
        let extractedMetadata = ExtractedMetadata(
            dates: allDates,
            phoneNumbers: allPhoneNumbers,
            emailAddresses: allEmailAddresses,
            currencies: allCurrencies
        )
        
        // Process form fields from rectangles and text
        formFields = detectFormFields(
            textObservations: textObservations,
            rectangleObservations: rectangleObservations
        )
        
        // Determine document layout
        let layout = determineDocumentLayout(
            textRegions: textRegions,
            rectangleObservations: rectangleObservations
        )
        
        // Detect tables if present
        let tables = detectTables(
            textObservations: textObservations,
            rectangleObservations: rectangleObservations
        )
        
        let processingTime = Date().timeIntervalSince(startTime)
        let overallConfidence = confidenceScores.isEmpty ? 0.0 : confidenceScores.reduce(0, +) / Double(confidenceScores.count)
        
        return OCRResult(
            fullText: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
            confidence: overallConfidence,
            recognizedFields: formFields,
            documentStructure: DocumentStructure(
                paragraphs: textRegions.filter { $0.textType == .body },
                tables: tables,
                lists: detectLists(from: textRegions),
                headers: textRegions.filter { $0.textType == .header || $0.textType == .title },
                layout: layout
            ),
            extractedMetadata: extractedMetadata,
            processingTime: processingTime
        )
    }
    
    private static func determineTextType(text: String, boundingBox: CGRect) -> TextRegion.TextType {
        // Simple heuristics for text type detection
        let normalizedY = boundingBox.origin.y
        
        if normalizedY > 0.9 {
            return .footer
        } else if normalizedY < 0.1 {
            return .header
        } else if text.count < 50 && text.range(of: "\\b[A-Z][A-Z ]+\\b", options: .regularExpression) != nil {
            return .header
        } else if text.count < 20 {
            return .caption
        } else {
            return .body
        }
    }
    
    private static func extractMetadataFromText(_ text: String) -> (dates: [ExtractedDate], phoneNumbers: [String], emailAddresses: [String], currencies: [ExtractedCurrency]) {
        var dates: [ExtractedDate] = []
        var phoneNumbers: [String] = []
        var emailAddresses: [String] = []
        var currencies: [ExtractedCurrency] = []
        // Extract dates
        let datePatterns = [
            "\\d{1,2}/\\d{1,2}/\\d{4}",
            "\\d{1,2}-\\d{1,2}-\\d{4}",
            "\\b\\w+ \\d{1,2}, \\d{4}\\b"
        ]
        
        for pattern in datePatterns {
            let regex = try? NSRegularExpression(pattern: pattern)
            let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in matches ?? [] {
                if let range = Range(match.range, in: text) {
                    let dateString = String(text[range])
                    if let date = parseDate(dateString) {
                        dates.append(ExtractedDate(
                            date: date,
                            originalText: dateString,
                            confidence: 0.8
                        ))
                    }
                }
            }
        }
        
        // Extract phone numbers
        let phoneRegex = try? NSRegularExpression(pattern: "\\b\\d{3}[-.]?\\d{3}[-.]?\\d{4}\\b")
        let phoneMatches = phoneRegex?.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in phoneMatches ?? [] {
            if let range = Range(match.range, in: text) {
                phoneNumbers.append(String(text[range]))
            }
        }
        
        // Extract email addresses
        let emailRegex = try? NSRegularExpression(pattern: "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b")
        let emailMatches = emailRegex?.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in emailMatches ?? [] {
            if let range = Range(match.range, in: text) {
                emailAddresses.append(String(text[range]))
            }
        }
        
        // Extract currency values
        let currencyRegex = try? NSRegularExpression(pattern: "\\$[\\d,]+\\.?\\d*")
        let currencyMatches = currencyRegex?.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in currencyMatches ?? [] {
            if let range = Range(match.range, in: text) {
                let currencyText = String(text[range])
                let cleanedText = currencyText.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
                
                if let amount = Decimal(string: cleanedText) {
                    currencies.append(ExtractedCurrency(
                        amount: amount,
                        currency: "USD",
                        originalText: currencyText,
                        confidence: 0.9
                    ))
                }
            }
        }
        
        return (dates: dates, phoneNumbers: phoneNumbers, emailAddresses: emailAddresses, currencies: currencies)
    }
    
    private static func detectFormFields(
        textObservations: [VNRecognizedTextObservation],
        rectangleObservations: [VNRectangleObservation]
    ) -> [FormField] {
        var formFields: [FormField] = []
        
        // Simple form field detection based on text patterns
        for observation in textObservations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let text = candidate.string
            
            // Look for label:value patterns
            if text.contains(":") {
                let components = text.components(separatedBy: ":")
                if components.count == 2 {
                    let label = components[0].trimmingCharacters(in: .whitespaces)
                    let value = components[1].trimmingCharacters(in: .whitespaces)
                    
                    if !label.isEmpty && !value.isEmpty {
                        formFields.append(FormField(
                            label: label,
                            value: value,
                            confidence: Double(candidate.confidence),
                            boundingBox: observation.boundingBox,
                            fieldType: determineFieldType(value)
                        ))
                    }
                }
            }
        }
        
        return formFields
    }
    
    private static func determineFieldType(_ value: String) -> FormField.FieldType {
        // Email pattern
        if value.contains("@") && value.contains(".") {
            return .email
        }
        
        // Phone pattern
        if value.range(of: "\\b\\d{3}[-.]?\\d{3}[-.]?\\d{4}\\b", options: .regularExpression) != nil {
            return .phone
        }
        
        // Currency pattern
        if value.hasPrefix("$") || value.range(of: "\\$[\\d,]+\\.?\\d*", options: .regularExpression) != nil {
            return .currency
        }
        
        // Date pattern
        if value.range(of: "\\d{1,2}/\\d{1,2}/\\d{4}", options: .regularExpression) != nil {
            return .date
        }
        
        // Number pattern
        if Double(value.replacingOccurrences(of: ",", with: "")) != nil {
            return .number
        }
        
        return .text
    }
    
    private static func determineDocumentLayout(
        textRegions: [TextRegion],
        rectangleObservations: [VNRectangleObservation]
    ) -> DocumentStructure.LayoutType {
        
        // Check for form-like patterns
        let colonCount = textRegions.reduce(0) { count, region in
            count + region.text.components(separatedBy: ":").count - 1
        }
        
        if colonCount > 3 {
            return .form
        }
        
        // Check for table patterns
        if rectangleObservations.count > 5 {
            return .table
        }
        
        // Check for invoice/receipt patterns
        let containsCurrency = textRegions.contains { region in
            region.text.range(of: "\\$[\\d,]+\\.?\\d*", options: .regularExpression) != nil
        }
        
        let containsTotal = textRegions.contains { region in
            region.text.lowercased().contains("total")
        }
        
        if containsCurrency && containsTotal {
            return .invoice
        }
        
        return .document
    }
    
    private static func detectTables(
        textObservations: [VNRecognizedTextObservation],
        rectangleObservations: [VNRectangleObservation]
    ) -> [Table] {
        // Simple table detection - this could be enhanced with more sophisticated algorithms
        var tables: [Table] = []
        
        if rectangleObservations.count > 4 {
            // Group rectangles that could form a table
            let sortedRectangles = rectangleObservations.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
            
            // Simple row detection based on Y position similarity
            var rows: [[TableCell]] = []
            var currentRow: [TableCell] = []
            var lastY: CGFloat = -1
            
            for rectangle in sortedRectangles {
                let y = rectangle.boundingBox.origin.y
                
                if abs(y - lastY) > 0.05 { // New row threshold
                    if !currentRow.isEmpty {
                        rows.append(currentRow)
                        currentRow = []
                    }
                }
                
                // Find text within this rectangle
                let matchingText = textObservations.first { textObs in
                    rectangle.boundingBox.intersects(textObs.boundingBox)
                }
                
                let cellContent = matchingText?.topCandidates(1).first?.string ?? ""
                
                currentRow.append(TableCell(
                    content: cellContent,
                    boundingBox: rectangle.boundingBox,
                    confidence: Double(matchingText?.topCandidates(1).first?.confidence ?? 0.5)
                ))
                
                lastY = y
            }
            
            if !currentRow.isEmpty {
                rows.append(currentRow)
            }
            
            if rows.count > 1 {
                let tableBounds = rectangleObservations.reduce(CGRect.null) { result, rect in
                    result.union(rect.boundingBox)
                }
                
                tables.append(Table(
                    rows: rows,
                    boundingBox: tableBounds,
                    confidence: 0.7
                ))
            }
        }
        
        return tables
    }
    
    private static func detectLists(from textRegions: [TextRegion]) -> [List] {
        var lists: [List] = []
        
        let bulletPatterns = ["•", "◦", "▪", "▫", "‣", "-", "*"]
        let numberPatterns = ["\\d+\\.", "\\d+\\)", "[a-zA-Z]\\.", "[a-zA-Z]\\)"]
        
        var listItems: [ListItem] = []
        var currentListType: List.ListType?
        
        for region in textRegions.sorted(by: { $0.boundingBox.origin.y > $1.boundingBox.origin.y }) {
            let text = region.text.trimmingCharacters(in: .whitespaces)
            var isListItem = false
            var detectedType: List.ListType?
            
            // Check for bullet points
            for bullet in bulletPatterns {
                if text.hasPrefix(bullet) {
                    isListItem = true
                    detectedType = .unordered
                    break
                }
            }
            
            // Check for numbered lists
            if !isListItem {
                for pattern in numberPatterns {
                    if text.range(of: "^" + pattern, options: .regularExpression) != nil {
                        isListItem = true
                        detectedType = .ordered
                        break
                    }
                }
            }
            
            if isListItem {
                if currentListType == nil {
                    currentListType = detectedType
                } else if currentListType != detectedType {
                    // End current list and start new one
                    if !listItems.isEmpty {
                        let listBounds = listItems.reduce(CGRect.null) { result, item in
                            result.union(item.boundingBox)
                        }
                        
                        lists.append(List(
                            items: listItems,
                            boundingBox: listBounds,
                            listType: currentListType!
                        ))
                        
                        listItems = []
                    }
                    currentListType = detectedType
                }
                
                listItems.append(ListItem(
                    text: text,
                    boundingBox: region.boundingBox,
                    confidence: region.confidence,
                    level: 0 // Could be enhanced to detect indentation levels
                ))
            } else if !listItems.isEmpty {
                // End current list
                let listBounds = listItems.reduce(CGRect.null) { result, item in
                    result.union(item.boundingBox)
                }
                
                lists.append(List(
                    items: listItems,
                    boundingBox: listBounds,
                    listType: currentListType ?? .unordered
                ))
                
                listItems = []
                currentListType = nil
            }
        }
        
        // Add final list if exists
        if !listItems.isEmpty {
            let listBounds = listItems.reduce(CGRect.null) { result, item in
                result.union(item.boundingBox)
            }
            
            lists.append(List(
                items: listItems,
                boundingBox: listBounds,
                listType: currentListType ?? .unordered
            ))
        }
        
        return lists
    }
    
    private static func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            "MM/dd/yyyy",
            "MM-dd-yyyy",
            "MMMM dd, yyyy",
            "MMM dd, yyyy"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
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