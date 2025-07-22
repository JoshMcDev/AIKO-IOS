import ComposableArchitecture
import Foundation

// MARK: - Document Context Extractor

/// Advanced document context extraction engine using sophisticated analysis
@DependencyClient
public struct DocumentContextExtractor: Sendable {
    /// Extracts comprehensive context from OCR results and images
    public var extractComprehensiveContext: @Sendable (
        _ ocrResults: [OCRResult],
        _ pageImageData: [Data],
        _ hints: [String: Any]
    ) async throws -> ScannerDocumentContext

    /// Analyzes document structure and relationships
    public var analyzeDocumentStructure: @Sendable ([OCRResult]) async throws -> DocumentStructure

    /// Extracts entities and relationships from document text
    public var extractEntitiesAndRelationships: @Sendable (String) async throws -> ([DocumentEntity], [EntityRelationship])

    /// Performs compliance analysis against regulations
    public var analyzeCompliance: @Sendable (ScannerDocumentContext) async throws -> ComplianceAnalysis

    /// Identifies risk factors in document content
    public var identifyRiskFactors: @Sendable (ScannerDocumentContext) async throws -> [RiskFactor]

    /// Generates recommendations based on analysis
    public var generateRecommendations: @Sendable (ScannerDocumentContext) async throws -> [Recommendation]
}

// MARK: - Dependency Registration

extension DocumentContextExtractor: DependencyKey {
    public static let liveValue: Self = .init(
        extractComprehensiveContext: { ocrResults, pageImageData, hints in
            // Live implementation would perform sophisticated ML/AI analysis
            // For now, return mock comprehensive context based on OCR results

            let sessionId = hints["session_id"] as? String ?? UUID().uuidString
            let source = hints["source"] as? String ?? "unknown"
            let totalPages = hints["total_pages"] as? Int ?? pageImageData.count

            // Combine all OCR text for analysis
            let combinedText = ocrResults.map(\.fullText).joined(separator: "\n")

            // Extract basic entities
            let entities = extractBasicEntities(from: combinedText)

            // Determine document type based on content
            let documentType = determineDocumentType(from: combinedText)

            // Create basic compliance analysis
            let compliance = ComplianceAnalysis(
                overallCompliance: .unknown,
                farCompliance: RegulationCompliance(regulation: "FAR"),
                dfarsCompliance: RegulationCompliance(regulation: "DFARS")
            )

            // Basic risk assessment
            let riskFactors = identifyBasicRisks(from: combinedText)

            // Generate basic recommendations
            let recommendations = generateBasicRecommendations(for: documentType)

            return ScannerDocumentContext(
                documentType: documentType,
                extractedEntities: entities,
                relationships: [],
                compliance: compliance,
                riskFactors: riskFactors,
                recommendations: recommendations,
                confidence: 0.75,
                processingTime: 0.5
            )
        },
        analyzeDocumentStructure: { ocrResults in
            guard let firstResult = ocrResults.first else {
                return DocumentStructure()
            }
            return firstResult.documentStructure
        },
        extractEntitiesAndRelationships: { text in
            let entities = extractBasicEntities(from: text)
            let relationships: [EntityRelationship] = []
            return (entities, relationships)
        },
        analyzeCompliance: { context in
            context.compliance
        },
        identifyRiskFactors: { context in
            context.riskFactors
        },
        generateRecommendations: { context in
            context.recommendations
        }
    )

    public static let testValue: Self = .init(
        extractComprehensiveContext: { _, _, _ in
            ScannerDocumentContext(
                documentType: .contract,
                extractedEntities: [
                    DocumentEntity(
                        type: .vendor,
                        value: "Test Vendor Corp",
                        confidence: 0.9
                    ),
                    DocumentEntity(
                        type: .amount,
                        value: "$100,000",
                        confidence: 0.85
                    ),
                ],
                relationships: [
                    EntityRelationship(
                        fromEntityId: "vendor-1",
                        toEntityId: "amount-1",
                        relationshipType: .contractedBy,
                        confidence: 0.8
                    ),
                ],
                compliance: ComplianceAnalysis(
                    overallCompliance: .compliant,
                    farCompliance: RegulationCompliance(
                        regulation: "FAR",
                        compliance: .compliant,
                        confidence: 0.9
                    )
                ),
                riskFactors: [
                    RiskFactor(
                        type: .financial,
                        severity: .medium,
                        description: "Test risk factor",
                        probability: 0.3,
                        impact: 0.5
                    ),
                ],
                recommendations: [
                    Recommendation(
                        type: .process,
                        priority: .medium,
                        title: "Test Recommendation",
                        description: "Test description",
                        action: "Test action",
                        rationale: "Test rationale"
                    ),
                ],
                confidence: 0.85,
                processingTime: 0.1
            )
        },
        analyzeDocumentStructure: { _ in
            DocumentStructure(
                paragraphs: [
                    TextRegion(
                        text: "Test paragraph",
                        boundingBox: CGRect(x: 0, y: 0, width: 100, height: 20),
                        confidence: 0.9
                    ),
                ],
                layout: .document
            )
        },
        extractEntitiesAndRelationships: { _ in
            let entities = [
                DocumentEntity(
                    type: .vendor,
                    value: "Test Entity",
                    confidence: 0.9
                ),
            ]
            let relationships: [EntityRelationship] = []
            return (entities, relationships)
        },
        analyzeCompliance: { _ in
            ComplianceAnalysis(overallCompliance: .compliant)
        },
        identifyRiskFactors: { _ in
            [
                RiskFactor(
                    type: .financial,
                    severity: .low,
                    description: "Test risk",
                    probability: 0.2,
                    impact: 0.3
                ),
            ]
        },
        generateRecommendations: { _ in
            [
                Recommendation(
                    type: .efficiency,
                    priority: .low,
                    title: "Test Recommendation",
                    description: "Test description",
                    action: "Test action",
                    rationale: "Test rationale"
                ),
            ]
        }
    )
}

// Dependency registration moved to DocumentContextExtractionService.swift to avoid conflicts

// MARK: - Helper Functions

private func extractBasicEntities(from text: String) -> [DocumentEntity] {
    var entities: [DocumentEntity] = []

    // Extract vendor names (simple heuristic)
    let vendorPatterns = ["Inc\\.|Corp\\.|LLC|Company|Corporation"]
    for pattern in vendorPatterns {
        let regex = try? NSRegularExpression(pattern: "\\b\\w+\\s+\\w*\\s*\(pattern)\\b")
        let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches ?? [] {
            if let range = Range(match.range, in: text) {
                let vendorName = String(text[range])
                entities.append(DocumentEntity(
                    type: .vendor,
                    value: vendorName.trimmingCharacters(in: .whitespaces),
                    confidence: 0.8
                ))
            }
        }
    }

    // Extract contract numbers
    let contractRegex = try? NSRegularExpression(pattern: "\\b[A-Z]{2,}-\\d{4,}\\b")
    let contractMatches = contractRegex?.matches(in: text, range: NSRange(text.startIndex..., in: text))

    for match in contractMatches ?? [] {
        if let range = Range(match.range, in: text) {
            let contractNumber = String(text[range])
            entities.append(DocumentEntity(
                type: .contract,
                value: contractNumber,
                confidence: 0.9
            ))
        }
    }

    // Extract amounts
    let amountRegex = try? NSRegularExpression(pattern: "\\$[\\d,]+(?:\\.\\d{2})?")
    let amountMatches = amountRegex?.matches(in: text, range: NSRange(text.startIndex..., in: text))

    for match in amountMatches ?? [] {
        if let range = Range(match.range, in: text) {
            let amount = String(text[range])
            entities.append(DocumentEntity(
                type: .amount,
                value: amount,
                confidence: 0.85
            ))
        }
    }

    return entities
}

private func determineDocumentType(from text: String) -> ScannerDocumentType {
    let lowercasedText = text.lowercased()

    if lowercasedText.contains("solicitation") || lowercasedText.contains("rfp") || lowercasedText.contains("rfq") {
        return .solicitation
    } else if lowercasedText.contains("contract") || lowercasedText.contains("agreement") {
        return .contract
    } else if lowercasedText.contains("amendment") || lowercasedText.contains("modification") {
        return .amendment
    } else if lowercasedText.contains("invoice") || lowercasedText.contains("bill") {
        return .invoice
    } else if lowercasedText.contains("specification") || lowercasedText.contains("spec") {
        return .specification
    } else if lowercasedText.contains("statement of work") || lowercasedText.contains("sow") {
        return .statement
    } else if lowercasedText.contains("evaluation") || lowercasedText.contains("assessment") {
        return .evaluation
    } else {
        return .unknown
    }
}

private func identifyBasicRisks(from text: String) -> [RiskFactor] {
    var risks: [RiskFactor] = []
    let lowercasedText = text.lowercased()

    // Financial risks
    if lowercasedText.contains("cost overrun") || lowercasedText.contains("budget") {
        risks.append(RiskFactor(
            type: .financial,
            severity: .medium,
            description: "Potential financial risk identified in document",
            probability: 0.4,
            impact: 0.6
        ))
    }

    // Schedule risks
    if lowercasedText.contains("delay") || lowercasedText.contains("schedule") {
        risks.append(RiskFactor(
            type: .schedule,
            severity: .medium,
            description: "Potential schedule risk identified in document",
            probability: 0.3,
            impact: 0.5
        ))
    }

    // Compliance risks
    if lowercasedText.contains("compliance") || lowercasedText.contains("regulation") {
        risks.append(RiskFactor(
            type: .compliance,
            severity: .high,
            description: "Compliance considerations identified",
            probability: 0.6,
            impact: 0.8
        ))
    }

    return risks
}

private func generateBasicRecommendations(for documentType: ScannerDocumentType) -> [Recommendation] {
    switch documentType {
    case .contract:
        [
            Recommendation(
                type: .compliance,
                priority: .high,
                title: "Contract Compliance Review",
                description: "Review contract for regulatory compliance",
                action: "Conduct thorough FAR/DFARS compliance check",
                rationale: "Ensure all contract terms meet regulatory requirements"
            ),
        ]
    case .solicitation:
        [
            Recommendation(
                type: .process,
                priority: .medium,
                title: "Solicitation Analysis",
                description: "Analyze solicitation requirements",
                action: "Extract and validate all requirements",
                rationale: "Comprehensive understanding needed for response"
            ),
        ]
    default:
        [
            Recommendation(
                type: .documentation,
                priority: .low,
                title: "Document Classification",
                description: "Classify document for proper filing",
                action: "Determine appropriate document category",
                rationale: "Proper classification improves organization"
            ),
        ]
    }
}
