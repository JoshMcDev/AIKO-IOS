import Foundation

// MARK: - Adaptive Extraction Example

/// Example showing how AIKO learns from the MTO quote
class AdaptiveExtractionExample {
    
    func demonstrateMTOQuoteProcessing() async throws {
        let extractor = AdaptiveDataExtractor()
        
        // 1. First time seeing this type of quote
        print("🔍 Processing MTO Quote - First Time")
        print("=" * 50)
        
        // Simulate the parsed document from OCR
        let mtoDocument = ParsedDocument(
            sourceType: .pdf,
            extractedText: """
            Morgan Technical Offerings LLC (MTO)
            295 Highgrove Dr
            Spring Lake, NC 28390 US
            josh@morgantech.cloud
            
            Estimate
            
            ADDRESS
            Joint Communications Unit
            
            SHIP TO
            Joint Communications Unit
            
            ARO
            120
            
            DESCRIPTION
            NAME
            Voyager 2 Plus Chassis is a rugged backplane chassis that holds any combination of two (2) Voyager network modules, or four (4) Voyager m-Series modules, and a GFE HAIPE device, with additional 12V output for a second HAIPE device. Features include:
            - 160W Power Pooled between 2 module slots and Dual
            - 12VDC Power for GFE or HAIPE device
            - Red/Black audio and PTT between modules
            - Supports independent ethernet/power/audio on UPS
            - Supports M&C via BOSS (centralized config & status)
            - Designed for 0U-2U rackmount
            
            Voyager 2 Plus Chassis
            
            SKU: MJ-ASTO-K-CHS25P
            Qty: 11
            Unit Price: $10,263.56
            Total: $112,899.16
            
            Shipping: $110.00
            TOTAL: $114,439.38
            
            Estimate Date: 05/21/2025
            """,
            metadata: ParsedDocumentMetadata(
                fileName: "quote_scan.pdf",
                fileSize: 412000,
                pageCount: 1
            ),
            extractedData: ExtractedData(),
            confidence: 0.96
        )
        
        // Process with adaptive extraction
        let result = try await extractor.extractAdaptively(from: mtoDocument)
        
        print("\n📊 Extraction Results:")
        print("Document Signature: \(result.documentSignature)")
        print("Confidence: \(String(format: "%.1f%%", result.confidence * 100))")
        print("\nExtracted Value Objects:")
        
        for object in result.valueObjects.sorted(by: { $0.fieldName < $1.fieldName }) {
            print("  [\(object.dataType)] \(object.fieldName): \(object.value)")
        }
        
        // 2. System learns the pattern
        print("\n🧠 Pattern Learning:")
        print("- Identified government/military document type")
        print("- Learned vendor quote structure")
        print("- Recognized technical equipment patterns")
        print("- Stored field mappings for future use")
        
        // 3. Second similar quote would be processed faster
        print("\n🚀 Future Processing Benefits:")
        print("Next time AIKO sees a similar quote:")
        
        let benefits = [
            "✓ Automatically identifies as 'Government Technical Equipment Quote'",
            "✓ Knows to look for ARO (Awaiting Receipt of Order) field",
            "✓ Recognizes HAIPE/encryption device mentions",
            "✓ Extracts vendor structured address format",
            "✓ Identifies military/government customer patterns",
            "✓ Parses technical specifications with bullet points",
            "✓ Handles government SKU formats (MJ-ASTO-K-CHS25P)",
            "✓ Processes quantity/unit price/total calculations"
        ]
        
        for benefit in benefits {
            print("  \(benefit)")
        }
        
        // 4. Show database storage
        print("\n💾 Database Storage:")
        print("Flexible JSON structure stored:")
        
        let exampleJSON = """
        {
          "vendor": {
            "value": "Morgan Technical Offerings LLC (MTO)",
            "type": "text",
            "confidence": 0.95
          },
          "vendor_address": {
            "value": "295 Highgrove Dr, Spring Lake, NC 28390 US",
            "type": "text",
            "confidence": 0.92
          },
          "vendor_email": {
            "value": "josh@morgantech.cloud",
            "type": "email",
            "confidence": 0.98
          },
          "customer": {
            "value": "Joint Communications Unit",
            "type": "text",
            "confidence": 0.94
          },
          "aro_days": {
            "value": "120",
            "type": "number",
            "confidence": 0.99
          },
          "product_name": {
            "value": "Voyager 2 Plus Chassis",
            "type": "text",
            "confidence": 0.97
          },
          "technical_features": {
            "value": ["160W Power Pooled", "12VDC Power for HAIPE", "Red/Black audio"],
            "type": "array",
            "confidence": 0.88
          },
          "sku": {
            "value": "MJ-ASTO-K-CHS25P",
            "type": "text",
            "confidence": 0.99
          },
          "quantity": {
            "value": "11",
            "type": "number",
            "confidence": 0.99
          },
          "unit_price": {
            "value": "10263.56",
            "type": "currency",
            "confidence": 0.99
          },
          "total_price": {
            "value": "114439.38",
            "type": "currency",
            "confidence": 0.99
          },
          "haipe_compatible": {
            "value": true,
            "type": "boolean",
            "confidence": 0.95
          },
          "estimate_date": {
            "value": "05/21/2025",
            "type": "date",
            "confidence": 0.98
          }
        }
        """
        
        print(exampleJSON)
        
        // 5. Query capabilities
        print("\n🔎 Query Examples:")
        print("Users can now search for:")
        print("  • All quotes with HAIPE devices")
        print("  • Quotes from Morgan Technical Offerings")
        print("  • Orders with ARO > 90 days")
        print("  • Technical equipment over $100,000")
        print("  • All government communications equipment")
        
        // 6. Document generation
        print("\n📄 Document Generation:")
        print("These value objects can populate:")
        print("  • Sole Source Justifications")
        print("  • Purchase Requests")
        print("  • Market Research Reports")
        print("  • Technical Evaluations")
        print("  • Contract Modifications")
    }
    
    func showPatternEvolution() {
        print("\n📈 Pattern Evolution Example:")
        print("=" * 50)
        
        print("\nAfter 5 similar quotes, AIKO learns:")
        print("  • 'ARO' always means 'Awaiting Receipt of Order'")
        print("  • Government quotes often have HAIPE/encryption mentions")
        print("  • Technical specs follow a bullet-point pattern")
        print("  • SKUs follow pattern: XX-XXXX-X-XXXXXX")
        
        print("\nAfter 20 quotes, AIKO can:")
        print("  • Auto-categorize by equipment type")
        print("  • Predict missing fields with defaults")
        print("  • Suggest similar past purchases")
        print("  • Flag unusual pricing patterns")
        print("  • Identify preferred vendors by category")
        
        print("\nAfter 100 quotes, AIKO becomes:")
        print("  • Expert at government procurement patterns")
        print("  • Able to validate quote completeness")
        print("  • Capable of suggesting alternates")
        print("  • Smart about seasonal pricing trends")
        print("  • Predictive for budget planning")
    }
}

// MARK: - How Different Quotes Create Different Patterns

extension AdaptiveExtractionExample {
    
    func showDifferentQuoteTypes() {
        print("\n🎯 Different Quote Types = Different Patterns")
        print("=" * 50)
        
        // Pattern 1: Government Technical Equipment
        print("\n1️⃣ Government Technical Equipment (like MTO):")
        print("   Key identifiers: HAIPE, GFE, Red/Black, Military specs")
        print("   Learned fields: ARO, SKU, Technical features, Security clearance")
        
        // Pattern 2: Commercial Office Supplies
        print("\n2️⃣ Commercial Office Supplies:")
        print("   Key identifiers: Simple items, bulk quantities, standard terms")
        print("   Learned fields: Item codes, Bulk discounts, Delivery dates")
        
        // Pattern 3: Professional Services
        print("\n3️⃣ Professional Services:")
        print("   Key identifiers: Hourly rates, Labor categories, Period of performance")
        print("   Learned fields: LCAT, Hours, Rates, Task descriptions")
        
        // Pattern 4: Construction/Renovation
        print("\n4️⃣ Construction/Renovation:")
        print("   Key identifiers: Materials, Labor, Permits, Timeline")
        print("   Learned fields: Phase milestones, Material specs, Compliance codes")
        
        print("\n✨ The Magic: AIKO automatically creates the right pattern!")
    }
}