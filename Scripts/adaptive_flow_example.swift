#!/usr/bin/env swift

import Foundation

// MARK: - Adaptive Prompting Flow Example

print("🚀 AIKO Adaptive Prompting Engine - Full Flow Example")
print("=" * 60)
print("\nScenario: Government user needs to acquire specialized communications equipment\n")

// Step 1: Document Upload
print("STEP 1: Document Upload")
print("-" * 30)
print("User uploads: quote_scan.pdf")
print("📄 Processing document...")
Thread.sleep(forTimeInterval: 0.5)
print("✅ Document processed successfully!\n")

// Step 2: Data Extraction
print("STEP 2: Automatic Data Extraction")
print("-" * 30)
print("🔍 Extracting information using Vision framework...")
let extractedData = [
    "Vendor": "Morgan Technical Offerings LLC",
    "Product": "Voyager 2 Plus Chassis (HAIPE Compatible)",
    "Quantity": "11 units",
    "Unit Price": "$9,358.12",
    "Total Price": "$114,439.38",
    "Delivery": "ARO 120 days",
    "Quote Date": "December 15, 2024",
    "Quote Valid": "30 days"
]

for (key, value) in extractedData {
    print("  ✓ \(key): \(value)")
}
print("\n💡 Extracted 8 key data points with 96% confidence")

// Step 3: Pattern Recognition
print("\n\nSTEP 3: User Pattern Recognition")
print("-" * 30)
print("🧠 Analyzing your acquisition history...")
Thread.sleep(forTimeInterval: 0.5)

let patterns = [
    "Location": "Joint Communications Unit (used 12 times)",
    "Funding": "O&M FY25 (used 8 times)",
    "Approver": "Col. Smith (used 10 times)",
    "Priority": "Routine (75% of similar acquisitions)"
]

print("\nRecognized patterns from your history:")
for (field, pattern) in patterns {
    print("  📊 \(field): \(pattern)")
}

// Step 4: Smart Defaults
print("\n\nSTEP 4: Applying Smart Defaults")
print("-" * 30)
print("🎯 Pre-filling form with intelligent defaults...")
Thread.sleep(forTimeInterval: 0.5)

let smartDefaults = [
    ("Vendor", "Morgan Technical Offerings LLC", "Document", "90%"),
    ("Product", "Voyager 2 Plus Chassis", "Document", "90%"),
    ("Quantity", "11 units", "Document", "90%"),
    ("Total Price", "$114,439.38", "Document", "90%"),
    ("Delivery Location", "Joint Communications Unit", "Pattern", "85%"),
    ("Funding Source", "O&M FY25", "Context", "80%"),
    ("Contract Type", "Fixed Price", "Pattern", "70%"),
    ("Approver", "Col. Smith", "Pattern", "80%"),
    ("Required Date", "February 12, 2025", "Inference", "75%"),
    ("Priority", "Routine", "Context", "75%"),
    ("Justification", "Mission Essential Equipment", "Rule", "85%")
]

print("\nAuto-populated fields:")
for (field, value, source, confidence) in smartDefaults {
    print("  ✅ \(field): \(value)")
    print("     Source: \(source) | Confidence: \(confidence)")
}

// Step 5: Minimal Adaptive Questioning
print("\n\nSTEP 5: Adaptive Conversational Flow")
print("-" * 30)
print("💬 AIKO needs to ask only 3 questions:\n")

// Question 1
print("🤖 AIKO: I see you're ordering Voyager 2 Plus units. Is this to")
print("         replace existing equipment or expand capability?\n")
print("👤 User: Expand capability for new mission requirements\n")
Thread.sleep(forTimeInterval: 0.5)

// Question 2
print("🤖 AIKO: The delivery is listed as 120 days. Do you need")
print("         expedited delivery? (Standard processing selected)\n")
print("👤 User: No, standard delivery is fine\n")
Thread.sleep(forTimeInterval: 0.5)

// Question 3
print("🤖 AIKO: Any special security or installation requirements")
print("         I should note for HAIPE equipment?\n")
print("👤 User: Yes, requires secure facility installation and")
print("         cleared personnel for setup\n")

// Step 6: Document Generation
print("\n\nSTEP 6: Automated Document Generation")
print("-" * 30)
print("📝 Generating acquisition documents...")
Thread.sleep(forTimeInterval: 1)

let documents = [
    "Purchase Request (DD Form 1348-6)",
    "Sole Source Justification",
    "Security Requirements Addendum",
    "Funding Certification",
    "Technical Specifications"
]

print("\n✅ Generated documents:")
for doc in documents {
    print("  📄 \(doc)")
}

// Step 7: Compliance Check
print("\n\nSTEP 7: FAR/DFAR Compliance Validation")
print("-" * 30)
print("⚖️ Running compliance checks...")
Thread.sleep(forTimeInterval: 0.5)

let complianceChecks = [
    ("FAR 6.302-1", "Sole Source Justification", "✅ Pass"),
    ("FAR 12.301", "Commercial Item Determination", "✅ Pass"),
    ("DFAR 204.73", "CAGE Code Verification", "✅ Pass"),
    ("FAR 9.104", "Vendor Responsibility", "✅ Pass"),
    ("Security", "HAIPE Compliance Requirements", "✅ Pass")
]

for (regulation, check, status) in complianceChecks {
    print("  \(status) \(regulation): \(check)")
}

// Results Summary
print("\n\n📊 EFFICIENCY METRICS")
print("=" * 60)

let metrics = [
    ("Traditional Form Fields", "25", ""),
    ("Questions Asked by AIKO", "3", "🎯 88% reduction"),
    ("", "", ""),
    ("Manual Entry Time", "20-30 min", ""),
    ("AIKO Completion Time", "3 min", "⚡ 85% faster"),
    ("", "", ""),
    ("Data Accuracy", "92%", "🎯 8% error rate → 2%"),
    ("Compliance Issues", "0", "✅ 100% compliant")
]

for (metric, value, improvement) in metrics {
    if metric.isEmpty {
        print("")
    } else {
        print("\(metric.padding(toLength: 25, withPad: " ", startingAt: 0)): \(value.padding(toLength: 12, withPad: " ", startingAt: 0)) \(improvement)")
    }
}

// Learning Update
print("\n\n🧠 LEARNING & ADAPTATION")
print("=" * 60)
print("✓ Pattern confidence increased: +5% for communications equipment")
print("✓ New pattern learned: HAIPE equipment → Secure facility requirement")
print("✓ Workflow saved: Expand capability → Standard processing path")
print("✓ Next time: 0 questions needed for similar acquisition")

// Final Summary
print("\n\n✨ SUMMARY")
print("=" * 60)
print("From document upload to compliant acquisition package in 3 minutes!")
print("\nKey Benefits Demonstrated:")
print("  • 96% accurate OCR extraction")
print("  • 75% of form auto-populated")
print("  • 88% fewer questions asked")
print("  • 100% FAR/DFAR compliant")
print("  • Continuous learning for future improvements")
print("\n🚀 Ready to transform government acquisitions!\n")

// Helper
extension String {
    static func * (lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}