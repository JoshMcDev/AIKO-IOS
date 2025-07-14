import Foundation

// MARK: - Example Usage of Adaptive Prompting Engine

/// This example demonstrates how the adaptive prompting engine integrates with document parsing
/// to minimize user questions while gathering complete acquisition requirements
public class AdaptivePromptingExample {
    
    public static func demonstrateUsage() async {
        print("=== Adaptive Prompting Engine Demo ===\n")
        
        // Initialize components
        let documentParser = DocumentParserEnhanced()
        let promptingEngine = AdaptivePromptingEngine()
        
        // Simulate a user uploading a vendor quote PDF
        print("1. User uploads a vendor quote PDF...")
        let mockPDFData = createMockQuotePDF()
        
        do {
            // Parse the document
            let parsedDocument = try await documentParser.parse(mockPDFData, type: .pdf)
            print("   ✓ Document parsed successfully")
            print("   - Extracted text length: \(parsedDocument.extractedText.count) characters")
            print("   - Confidence: \(parsedDocument.confidence)")
            
            // Extract context from the document
            print("\n2. Extracting context from document...")
            let extractedContext = try await promptingEngine.extractContextFromDocuments([parsedDocument])
            
            if let vendor = extractedContext.vendorInfo {
                print("   ✓ Found vendor: \(vendor.name ?? "Unknown")")
                if let uei = vendor.uei {
                    print("   - UEI: \(uei)")
                }
            }
            
            if let pricing = extractedContext.pricing {
                if let total = pricing.totalPrice {
                    print("   ✓ Found total price: $\(total)")
                }
                print("   - Line items: \(pricing.unitPrices.count)")
            }
            
            // Start adaptive conversation
            print("\n3. Starting adaptive conversation...")
            let conversationContext = ConversationContext(
                acquisitionType: .supplies,
                uploadedDocuments: [parsedDocument],
                userProfile: nil,
                historicalData: getHistoricalData()
            )
            
            let session = await promptingEngine.startConversation(with: conversationContext)
            print("   ✓ Conversation started")
            print("   - Initial questions: \(session.remainingQuestions.count)")
            print("   - Confidence level: \(session.confidence)")
            
            // Show how pre-filled data reduces questions
            print("\n4. Pre-filled data from document:")
            if let vendorInfo = session.collectedData.vendorInfo {
                print("   - Vendor: \(vendorInfo.name ?? "Unknown")")
            }
            if let value = session.collectedData.estimatedValue {
                print("   - Estimated value: $\(value)")
            }
            
            // Simulate user responses
            print("\n5. Simulating user interaction...")
            let currentSession = session
            
            // Answer first question
            if let firstQuestion = currentSession.remainingQuestions.first {
                print("\n   Question: \(firstQuestion.prompt)")
                print("   Priority: \(firstQuestion.priority)")
                
                // Simulate user response
                let userResponse = UserResponse(
                    questionId: firstQuestion.id.uuidString,
                    responseType: .text,
                    value: "Office Supplies for Q1 2025 - Headquarters"
                )
                
                if let nextPrompt = try await promptingEngine.processUserResponse(userResponse, in: currentSession) {
                    print("   ✓ Response processed")
                    
                    // Show smart defaults if available
                    if let suggestion = nextPrompt.suggestedAnswer {
                        print("\n   Next question: \(nextPrompt.question.prompt)")
                        print("   Suggested answer: \(suggestion)")
                        print("   Confidence: \(nextPrompt.confidenceInSuggestion)")
                    }
                }
            }
            
            // Demonstrate learning
            print("\n6. Learning from user patterns...")
            let interaction = APEUserInteraction(
                sessionId: session.id,
                field: .vendorName,
                suggestedValue: "ACME Corp",
                acceptedSuggestion: true,
                finalValue: "ACME Corp",
                timeToRespond: 1.5,
                documentContext: true
            )
            
            await promptingEngine.learnFromInteraction(interaction)
            print("   ✓ Pattern recorded for future sessions")
            
            // Check for smart defaults
            if let defaults = await promptingEngine.getSmartDefaults(for: .vendorName) {
                print("   - Smart default available: \(defaults.value)")
                print("   - Source: \(defaults.source)")
                print("   - Confidence: \(defaults.confidence)")
            }
            
        } catch {
            print("Error: \(error)")
        }
        
        print("\n=== Demo Complete ===")
    }
    
    // MARK: - Helper Methods
    
    private static func createMockQuotePDF() -> Data {
        // In a real scenario, this would be actual PDF data
        // For demo purposes, we'll create mock data that simulates a parsed PDF
        let mockContent = """
        VENDOR QUOTE
        
        Company: ACME Office Supplies Corp
        UEI: ACMECORP1234
        Email: sales@acmecorp.com
        Phone: (555) 123-4567
        
        Quote #: Q-2025-001
        Date: January 15, 2025
        Valid Until: February 15, 2025
        
        Items:
        1. Executive Desk Chair - Qty: 10 @ $450.00 = $4,500.00
        2. Standing Desk Converter - Qty: 15 @ $250.00 = $3,750.00
        3. Monitor Arms - Qty: 20 @ $85.00 = $1,700.00
        4. Ergonomic Keyboard - Qty: 25 @ $120.00 = $3,000.00
        5. Office Supplies Bundle - Qty: 5 @ $200.00 = $1,000.00
        
        Subtotal: $13,950.00
        Tax (8.5%): $1,185.75
        
        TOTAL: $15,135.75
        
        Delivery: 30 days from order confirmation
        Terms: Net 30
        
        Special Conditions:
        - Free delivery for orders over $10,000
        - 2-year warranty on all furniture items
        - Volume discount applied (10% off list price)
        
        Thank you for your business!
        """
        
        return Data(mockContent.utf8)
    }
    
    private static func getHistoricalData() -> [HistoricalAcquisition] {
        // Simulate historical acquisition data
        return [
            HistoricalAcquisition(
                date: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
                type: .supplies,
                data: RequirementsData(
                    projectTitle: "Q4 2024 Office Supplies",
                    estimatedValue: 12500.00,
                    vendorInfo: APEVendorInfo(name: "ACME Office Supplies Corp")
                ),
                vendor: APEVendorInfo(name: "ACME Office Supplies Corp")
            ),
            HistoricalAcquisition(
                date: Date().addingTimeInterval(-60 * 24 * 60 * 60), // 60 days ago
                type: .supplies,
                data: RequirementsData(
                    projectTitle: "Emergency PPE Supplies",
                    estimatedValue: 5000.00,
                    vendorInfo: APEVendorInfo(name: "SafetyFirst Inc")
                ),
                vendor: APEVendorInfo(name: "SafetyFirst Inc")
            )
        ]
    }
}

// MARK: - Usage in App

extension AdaptivePromptingEngine {
    /// Convenience method to check if engine is reducing questions effectively
    public func calculateQuestionReduction(
        withDocuments: Int,
        withoutDocuments: Int,
        historicalPatterns: Int
    ) -> Double {
        let baseReduction = Double(withoutDocuments - withDocuments) / Double(withoutDocuments)
        let patternBonus = min(Double(historicalPatterns) * 0.05, 0.2) // Up to 20% additional reduction
        return min(baseReduction + patternBonus, 0.8) // Cap at 80% reduction
    }
}

// Example metrics:
// - Without documents: ~15-20 questions
// - With good document: ~5-8 questions (60-75% reduction)
// - With patterns learned: ~3-5 questions (80% reduction)