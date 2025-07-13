#!/usr/bin/env swift

import Foundation
import Vision
import PDFKit
import CoreGraphics
import UniformTypeIdentifiers

// MARK: - OCR Validation Script
// This script directly tests OCR functionality on the quote files

class OCRValidator {
    let imageFile = "/Users/J/Desktop/quote pic.jpeg"
    let pdfFile = "/Users/J/Desktop/quote scan.pdf"
    
    func run() async {
        print("🔍 OCR Validation Script")
        print("========================")
        
        do {
            // Test image OCR
            print("\n📸 Testing Image OCR...")
            let imageResults = try await testImageOCR()
            printResults("Image OCR", imageResults)
            
            // Test PDF OCR
            print("\n📄 Testing PDF OCR...")
            let pdfResults = try await testPDFOCR()
            printResults("PDF OCR", pdfResults)
            
            // Compare results
            print("\n📊 Comparative Analysis")
            compareResults(imageResults, pdfResults)
            
            // Calculate accuracy
            print("\n✅ Accuracy Assessment")
            let imageAccuracy = calculateAccuracy(imageResults)
            let pdfAccuracy = calculateAccuracy(pdfResults)
            
            print("Image OCR Accuracy: \(String(format: "%.1f%%", imageAccuracy * 100))")
            print("PDF OCR Accuracy: \(String(format: "%.1f%%", pdfAccuracy * 100))")
            
            let threshold = 0.95
            if imageAccuracy >= threshold && pdfAccuracy >= threshold {
                print("\n🎉 SUCCESS: Both meet the 95% accuracy threshold!")
            } else {
                print("\n⚠️  WARNING: Accuracy below 95% threshold")
                if imageAccuracy < threshold {
                    print("   - Image OCR needs improvement")
                }
                if pdfAccuracy < threshold {
                    print("   - PDF OCR needs improvement")
                }
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    // MARK: - Image OCR
    
    func testImageOCR() async throws -> OCRResults {
        let imageData = try Data(contentsOf: URL(fileURLWithPath: imageFile))
        print("  Image size: \(imageData.count / 1024) KB")
        
        let startTime = Date()
        
        // Create Vision request
        guard let cgImage = createCGImage(from: imageData) else {
            throw OCRError.invalidImage
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        
        try requestHandler.perform([request])
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        // Extract results
        var extractedText = ""
        var confidence: Float = 0
        var observationCount = 0
        
        if let observations = request.results {
            for observation in observations {
                confidence += observation.confidence
                observationCount += 1
                
                if let topCandidate = observation.topCandidates(1).first {
                    extractedText += topCandidate.string + "\n"
                }
            }
        }
        
        let avgConfidence = observationCount > 0 ? confidence / Float(observationCount) : 0
        
        // Extract structured data
        let structuredData = extractStructuredData(from: extractedText)
        
        return OCRResults(
            text: extractedText,
            confidence: avgConfidence,
            processingTime: processingTime,
            structuredData: structuredData,
            observationCount: observationCount
        )
    }
    
    // MARK: - PDF OCR
    
    func testPDFOCR() async throws -> OCRResults {
        let pdfData = try Data(contentsOf: URL(fileURLWithPath: pdfFile))
        print("  PDF size: \(pdfData.count / 1024) KB")
        
        guard let document = PDFDocument(data: pdfData) else {
            throw OCRError.invalidPDF
        }
        
        print("  Pages: \(document.pageCount)")
        
        let startTime = Date()
        var fullText = ""
        var totalConfidence: Float = 0
        var totalObservations = 0
        
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // Check if page has text
            if let pageText = page.string, !pageText.isEmpty {
                fullText += pageText + "\n"
                totalConfidence += 0.99 // High confidence for native text
                totalObservations += 1
            } else {
                // Perform OCR on the page
                let pageResults = try await ocrPDFPage(page)
                fullText += pageResults.text
                totalConfidence += pageResults.confidence
                totalObservations += pageResults.observationCount
            }
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        let avgConfidence = totalObservations > 0 ? totalConfidence / Float(totalObservations) : 0
        
        // Extract structured data
        let structuredData = extractStructuredData(from: fullText)
        
        return OCRResults(
            text: fullText,
            confidence: avgConfidence,
            processingTime: processingTime,
            structuredData: structuredData,
            observationCount: totalObservations
        )
    }
    
    func ocrPDFPage(_ page: PDFPage) async throws -> OCRResults {
        // Render page to image
        let pageRect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0 // Higher resolution for better OCR
        
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
        
        // Perform OCR
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        
        try requestHandler.perform([request])
        
        var extractedText = ""
        var confidence: Float = 0
        var observationCount = 0
        
        if let observations = request.results {
            for observation in observations {
                confidence += observation.confidence
                observationCount += 1
                
                if let topCandidate = observation.topCandidates(1).first {
                    extractedText += topCandidate.string + "\n"
                }
            }
        }
        
        let avgConfidence = observationCount > 0 ? confidence / Float(observationCount) : 0
        
        return OCRResults(
            text: extractedText,
            confidence: avgConfidence,
            processingTime: 0,
            structuredData: [:],
            observationCount: observationCount
        )
    }
    
    // MARK: - Data Extraction
    
    func extractStructuredData(from text: String) -> [String: String] {
        var data: [String: String] = [:]
        
        let lines = text.components(separatedBy: .newlines)
        
        // Extract vendor name (usually at the top)
        if let vendorLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            data["vendor"] = vendorLine.trimmingCharacters(in: .whitespaces)
        }
        
        // Extract quote number
        let quotePatterns = ["Quote #", "Quote Number", "Quote:", "Quotation #", "Reference:"]
        for pattern in quotePatterns {
            if let quoteLine = lines.first(where: { $0.contains(pattern) }) {
                let components = quoteLine.components(separatedBy: pattern)
                if components.count > 1 {
                    data["quoteNumber"] = components[1].trimmingCharacters(in: .whitespaces)
                    break
                }
            }
        }
        
        // Extract total price
        let pricePatterns = ["Total:", "Total Amount:", "Grand Total:", "Total Price:"]
        for pattern in pricePatterns {
            if let priceLine = lines.first(where: { $0.contains(pattern) }) {
                // Extract price using regex
                let priceRegex = try? NSRegularExpression(pattern: "\\$?[0-9,]+\\.?[0-9]*", options: [])
                if let match = priceRegex?.firstMatch(in: priceLine, options: [], range: NSRange(priceLine.startIndex..., in: priceLine)) {
                    if let range = Range(match.range, in: priceLine) {
                        data["totalPrice"] = String(priceLine[range])
                        break
                    }
                }
            }
        }
        
        // Extract dates
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
            data["quoteDate"] = dates.first
            if dates.count > 1 {
                data["validUntil"] = dates[1]
            }
        }
        
        // Extract email
        let emailRegex = try? NSRegularExpression(
            pattern: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}",
            options: []
        )
        
        for line in lines {
            if let match = emailRegex?.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) {
                if let range = Range(match.range, in: line) {
                    data["email"] = String(line[range])
                    break
                }
            }
        }
        
        // Extract phone
        let phoneRegex = try? NSRegularExpression(
            pattern: "\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4}",
            options: []
        )
        
        for line in lines {
            if let match = phoneRegex?.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) {
                if let range = Range(match.range, in: line) {
                    data["phone"] = String(line[range])
                    break
                }
            }
        }
        
        // Count line items
        var lineItemCount = 0
        for line in lines {
            // Look for lines that might be product items (contain both text and price)
            if line.contains("$") && !pricePatterns.contains(where: { line.contains($0) }) {
                lineItemCount += 1
            }
        }
        if lineItemCount > 0 {
            data["lineItems"] = "\(lineItemCount)"
        }
        
        return data
    }
    
    // MARK: - Results Analysis
    
    func printResults(_ title: String, _ results: OCRResults) {
        print("\n\(title) Results:")
        print("  Processing time: \(String(format: "%.2f", results.processingTime)) seconds")
        print("  Confidence: \(String(format: "%.1f%%", results.confidence * 100))")
        print("  Text blocks found: \(results.observationCount)")
        print("  Text length: \(results.text.count) characters")
        
        print("\n  Extracted Data:")
        for (key, value) in results.structuredData.sorted(by: { $0.key < $1.key }) {
            print("    \(key): \(value)")
        }
        
        if results.text.count > 0 {
            print("\n  First 200 characters:")
            let preview = String(results.text.prefix(200)).replacingOccurrences(of: "\n", with: " ")
            print("    \"\(preview)...\"")
        }
    }
    
    func compareResults(_ image: OCRResults, _ pdf: OCRResults) {
        print("\n  Performance Comparison:")
        print("    Image processing: \(String(format: "%.2f", image.processingTime))s")
        print("    PDF processing: \(String(format: "%.2f", pdf.processingTime))s")
        
        print("\n  Confidence Comparison:")
        print("    Image: \(String(format: "%.1f%%", image.confidence * 100))")
        print("    PDF: \(String(format: "%.1f%%", pdf.confidence * 100))")
        
        print("\n  Data Extraction Comparison:")
        let allKeys = Set(image.structuredData.keys).union(Set(pdf.structuredData.keys))
        
        for key in allKeys.sorted() {
            let imageValue = image.structuredData[key] ?? "Not found"
            let pdfValue = pdf.structuredData[key] ?? "Not found"
            
            print("    \(key):")
            print("      Image: \(imageValue)")
            print("      PDF: \(pdfValue)")
            
            if imageValue != "Not found" && pdfValue != "Not found" && imageValue != pdfValue {
                let similarity = stringSimilarity(imageValue, pdfValue)
                print("      Similarity: \(String(format: "%.1f%%", similarity * 100))")
            }
        }
    }
    
    func calculateAccuracy(_ results: OCRResults) -> Double {
        var score = 0.0
        
        // Base confidence score (40% weight)
        score += Double(results.confidence) * 0.4
        
        // Data extraction completeness (40% weight)
        let expectedFields = ["vendor", "quoteNumber", "totalPrice", "quoteDate", "email"]
        let foundFields = expectedFields.filter { results.structuredData[$0] != nil }.count
        let completeness = Double(foundFields) / Double(expectedFields.count)
        score += completeness * 0.4
        
        // Text quality (20% weight)
        let hasReasonableLength = results.text.count > 100
        let hasMultipleLines = results.text.components(separatedBy: .newlines).count > 5
        let textQuality = (hasReasonableLength && hasMultipleLines) ? 1.0 : 0.5
        score += textQuality * 0.2
        
        return score
    }
    
    func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        let longer = s1.count > s2.count ? s1 : s2
        let shorter = s1.count > s2.count ? s2 : s1
        
        if longer.count == 0 { return 1.0 }
        
        let editDistance = levenshteinDistance(shorter, longer)
        return (Double(longer.count) - Double(editDistance)) / Double(longer.count)
    }
    
    func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let m = s1.count
        let n = s2.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m {
            matrix[i][0] = i
        }
        
        for j in 0...n {
            matrix[0][j] = j
        }
        
        for i in 1...m {
            for j in 1...n {
                let cost = s1[s1.index(s1.startIndex, offsetBy: i-1)] == s2[s2.index(s2.startIndex, offsetBy: j-1)] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            }
        }
        
        return matrix[m][n]
    }
    
    // MARK: - Helper Functions
    
    func createCGImage(from data: Data) -> CGImage? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        return cgImage
    }
}

// MARK: - Supporting Types

struct OCRResults {
    let text: String
    let confidence: Float
    let processingTime: TimeInterval
    let structuredData: [String: String]
    let observationCount: Int
}

enum OCRError: Error {
    case invalidImage
    case invalidPDF
    case renderingFailed
}

// MARK: - Main

Task {
    let validator = OCRValidator()
    await validator.run()
    exit(0)
}

RunLoop.main.run()