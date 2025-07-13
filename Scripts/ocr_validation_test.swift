#!/usr/bin/env swift

import Foundation
import PDFKit
import Vision
import CoreGraphics
import UniformTypeIdentifiers

// Simple OCR Validation for AIKO Document Parser
// Tests OCR accuracy on quote files

let imageFile = "/Users/J/Desktop/quote pic.jpeg"
let pdfFile = "/Users/J/Desktop/quote scan.pdf"

// MARK: - Simple OCR Test

class SimpleOCRValidator {
    
    func validateFiles() async {
        print("🔍 AIKO OCR Validation Test")
        print("==========================")
        print("Date: \(Date())")
        print("")
        
        // Check files exist
        let fm = FileManager.default
        guard fm.fileExists(atPath: imageFile) else {
            print("❌ Image file not found: \(imageFile)")
            return
        }
        guard fm.fileExists(atPath: pdfFile) else {
            print("❌ PDF file not found: \(pdfFile)")
            return
        }
        
        print("✅ Test files found")
        print("")
        
        // Test image OCR
        print("📸 Testing Image OCR...")
        await testImageOCR()
        
        print("\n" + String(repeating: "-", count: 50) + "\n")
        
        // Test PDF OCR
        print("📄 Testing PDF OCR...")
        await testPDFOCR()
        
        print("\n" + String(repeating: "=", count: 50))
        print("✅ Validation Complete")
        print("Next step: Review extracted data and determine if 95% accuracy threshold is met")
    }
    
    func testImageOCR() async {
        guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: imageFile)) else {
            print("❌ Failed to load image data")
            return
        }
        
        print("Image size: \(imageData.count / 1024) KB")
        
        do {
            let startTime = Date()
            let text = try await performImageOCR(imageData)
            let processingTime = Date().timeIntervalSince(startTime)
            
            print("Processing time: \(String(format: "%.2f", processingTime)) seconds")
            print("\nExtracted text preview (first 500 chars):")
            print("----------------------------------------")
            let preview = String(text.prefix(500))
            print(preview)
            if text.count > 500 {
                print("... [\(text.count - 500) more characters]")
            }
            
            // Extract key data points
            analyzeExtractedData(from: text, source: "Image")
            
        } catch {
            print("❌ OCR Error: \(error)")
        }
    }
    
    func testPDFOCR() async {
        guard let pdfData = try? Data(contentsOf: URL(fileURLWithPath: pdfFile)) else {
            print("❌ Failed to load PDF data")
            return
        }
        
        print("PDF size: \(pdfData.count / 1024) KB")
        
        guard let document = PDFDocument(data: pdfData) else {
            print("❌ Failed to create PDF document")
            return
        }
        
        print("Pages: \(document.pageCount)")
        
        do {
            let startTime = Date()
            var fullText = ""
            
            for pageIndex in 0..<document.pageCount {
                guard let page = document.page(at: pageIndex) else { continue }
                
                // Check if page has text
                if let pageText = page.string, !pageText.isEmpty {
                    fullText += pageText + "\n"
                    print("Page \(pageIndex + 1): Found embedded text")
                } else {
                    // Perform OCR
                    print("Page \(pageIndex + 1): Performing OCR...")
                    let ocrText = try await performPDFPageOCR(page)
                    fullText += ocrText + "\n"
                }
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            print("Total processing time: \(String(format: "%.2f", processingTime)) seconds")
            
            print("\nExtracted text preview (first 500 chars):")
            print("----------------------------------------")
            let preview = String(fullText.prefix(500))
            print(preview)
            if fullText.count > 500 {
                print("... [\(fullText.count - 500) more characters]")
            }
            
            // Extract key data points
            analyzeExtractedData(from: fullText, source: "PDF")
            
        } catch {
            print("❌ OCR Error: \(error)")
        }
    }
    
    func performImageOCR(_ imageData: Data) async throws -> String {
        guard let cgImage = createCGImage(from: imageData) else {
            throw OCRError.invalidImage
        }
        
        return try await performOCROnCGImage(cgImage)
    }
    
    func performPDFPageOCR(_ page: PDFPage) async throws -> String {
        let pageRect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0
        
        let width = Int(pageRect.width * scale)
        let height = Int(pageRect.height * scale)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            throw OCRError.renderingFailed
        }
        
        // White background
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Draw PDF page
        context.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context)
        
        guard let cgImage = context.makeImage() else {
            throw OCRError.renderingFailed
        }
        
        return try await performOCROnCGImage(cgImage)
    }
    
    func performOCROnCGImage(_ cgImage: CGImage) async throws -> String {
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        
        try requestHandler.perform([request])
        
        var extractedText = ""
        var totalConfidence: Float = 0
        var observationCount = 0
        
        if let observations = request.results {
            print("Found \(observations.count) text blocks")
            
            for observation in observations {
                totalConfidence += observation.confidence
                observationCount += 1
                
                if let topCandidate = observation.topCandidates(1).first {
                    extractedText += topCandidate.string + "\n"
                }
            }
        }
        
        if observationCount > 0 {
            let avgConfidence = totalConfidence / Float(observationCount)
            print("Average OCR confidence: \(String(format: "%.1f%%", avgConfidence * 100))")
        }
        
        return extractedText
    }
    
    func createCGImage(from data: Data) -> CGImage? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        return cgImage
    }
    
    func analyzeExtractedData(from text: String, source: String) {
        print("\n📊 Analyzing extracted data from \(source):")
        print("----------------------------------------")
        
        let lines = text.components(separatedBy: .newlines)
        
        // Look for vendor name (usually at top)
        if let vendorLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            print("Vendor (first line): \(vendorLine)")
        }
        
        // Look for quote number
        let quotePatterns = ["Quote #", "Quote Number", "Quote:", "Quotation", "Reference:", "RFQ"]
        for pattern in quotePatterns {
            if let quoteLine = lines.first(where: { $0.contains(pattern) }) {
                print("Quote reference: \(quoteLine)")
                break
            }
        }
        
        // Look for prices
        let priceRegex = try? NSRegularExpression(pattern: "\\$[0-9,]+\\.?[0-9]*", options: [])
        var prices: [String] = []
        for line in lines {
            if let matches = priceRegex?.matches(in: line, options: [], range: NSRange(line.startIndex..., in: line)) {
                for match in matches {
                    if let range = Range(match.range, in: line) {
                        prices.append(String(line[range]))
                    }
                }
            }
        }
        if !prices.isEmpty {
            print("Prices found: \(prices.joined(separator: ", "))")
        }
        
        // Look for dates
        let dateRegex = try? NSRegularExpression(
            pattern: "\\b(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4}|\\w+ \\d{1,2}, \\d{4})\\b",
            options: []
        )
        var dates: [String] = []
        for line in lines {
            if let matches = dateRegex?.matches(in: line, options: [], range: NSRange(line.startIndex..., in: line)) {
                for match in matches {
                    if let range = Range(match.range, in: line) {
                        dates.append(String(line[range]))
                    }
                }
            }
        }
        if !dates.isEmpty {
            print("Dates found: \(dates.joined(separator: ", "))")
        }
        
        // Look for email
        let emailRegex = try? NSRegularExpression(
            pattern: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}",
            options: []
        )
        for line in lines {
            if let match = emailRegex?.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) {
                if let range = Range(match.range, in: line) {
                    print("Email found: \(String(line[range]))")
                    break
                }
            }
        }
        
        // Count potential line items
        var lineItemCount = 0
        for line in lines {
            if line.contains("$") && !line.contains("Total") && !line.contains("Subtotal") {
                lineItemCount += 1
            }
        }
        if lineItemCount > 0 {
            print("Potential line items: \(lineItemCount)")
        }
        
        print("\n✅ Key data extraction summary:")
        print("  - Text extracted: \(text.count) characters")
        print("  - Lines: \(lines.count)")
        print("  - Contains pricing: \(!prices.isEmpty ? "Yes" : "No")")
        print("  - Contains dates: \(!dates.isEmpty ? "Yes" : "No")")
    }
}

enum OCRError: Error {
    case invalidImage
    case renderingFailed
}

// Run the validation
Task {
    let validator = SimpleOCRValidator()
    await validator.validateFiles()
    exit(0)
}

RunLoop.main.run()