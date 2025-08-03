#!/usr/bin/env swift

import Foundation

// Generate the ACTUAL original custom SAM report format from original_sam_report_before_migration.swift
// This is the REAL format that includes CAGE expiration date, PSC codes, and small business sizes

struct RealOriginalSAMReport {
    static func main() async {
        print("🎯 ORIGINAL CUSTOM SAM REPORT - EXACT FORMAT")
        print("📊 Using CAGE Code: 5BVH3 (Real Custom Template)")
        print(String(repeating: "═", count: 80))

        // Simulate the real EntityDetail with expiration date
        let mockEntity = createMockEntityWithExpiration()

        // Generate the EXACT original report format
        displaySAMGovHeader()
        displayCageExpirationCard(entity: mockEntity)
        displaySATBotSection()
        displayCompanyInformation(entity: mockEntity)
        displayComplianceStatus()
        displayBusinessCertifications()
        displayNAICSCodes()
        displayPSCCodes()

        print(String(repeating: "═", count: 80))
        print("✅ This is the EXACT original custom SAM report format!")
        print("🎯 Features: CAGE expiration, PSC codes, small business sizes")
        print("🔍 CAGE Code 5BVH3 with expiration validation")
    }

    // Create mock entity with expiration date (the key feature!)
    static func createMockEntityWithExpiration() -> MockEntity {
        // CAGE expires in January 2026 (VALID - GREEN card)
        let expirationDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 24))!
        let isExpired = expirationDate < Date()

        return MockEntity(
            entityName: "Test Contractor for CAGE 5BVH3",
            legalBusinessName: "RAMPART AVIATION, LLC.",
            dba: "RAMPART AVIATION LLC",
            uei: "R7TBP9D4VNJ3",
            cageCode: "5BVH3",
            registrationStatus: isExpired ? "Inactive" : "Active",
            expirationDate: expirationDate,
            location: "1777 Aviation Way, Colorado Springs, CO 80916",
            isSmallBusiness: true,
            isVeteranOwned: true,
            businessTypes: [
                "For Profit Organization",
                "Veteran-Owned Business",
                "Service-Disabled Veteran-Owned Business",
                "Limited Liability Company",
                "Small Business (for all NAICS codes)"
            ]
        )
    }

    // SAM.gov Header with patriotic gradient (original design)
    static func displaySAMGovHeader() {
        print("\n🇺🇸 ════════════════════════════════════════════════════════════════════════ 🇺🇸")
        print("   [SAM Icon]          SAM.gov (Red/White/Blue Gradient)          [Share ↗]")
        print("══════════════════════════════════════════════════════════════════════════════")
    }

    // CAGE Expiration Card - THE KEY FEATURE (first thing on the view!)
    static func displayCageExpirationCard(entity: MockEntity) {
        let isExpired = entity.expirationDate < Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        if isExpired {
            // RED CARD for expired
            print("\n🔴 ┌─ CAGE CODE STATUS (EXPIRED) ──────────────────────────────────────┐ 🔴")
            print("🔴 │ ⚠️  INACTIVE                     Expired: \(formatter.string(from: entity.expirationDate)) │ 🔴")
            print("🔴 └──────────────────────────────────────────────────────────────────┘ 🔴")
            print("   ■ RED BACKGROUND - CAGE Code is EXPIRED")
        } else {
            // GREEN CARD for valid
            print("\n🟢 ┌─ CAGE CODE STATUS (ACTIVE) ───────────────────────────────────────┐ 🟢")
            print("🟢 │ ✅ ACTIVE                       Expires: \(formatter.string(from: entity.expirationDate)) │ 🟢")
            print("🟢 └──────────────────────────────────────────────────────────────────┘ 🟢")
            print("   ■ GREEN BACKGROUND - CAGE Code is VALID")
        }
    }

    // SAT Bot Section (original feature)
    static func displaySATBotSection() {
        print("\n┌─ SAT BOT AUTO-SEND ────────────────────────────────────────────────────┐")
        print("│ 📧 SAT Bot                    Auto send              UnderSATBot       │")
        print("│ (Tap to send SAT Bot email automatically)                            │")
        print("└───────────────────────────────────────────────────────────────────────┘")
    }

    // Company Information (original layout)
    static func displayCompanyInformation(entity: MockEntity) {
        print("\n┌─ COMPANY INFORMATION ──────────────────────────────────────────────────┐")
        print("│ Legal Name: \(entity.legalBusinessName)")
        print("│ DBA:        \(entity.dba)")
        print("│ UEI:        \(entity.uei)")
        print("│ CAGE:       \(entity.cageCode)")
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        print("│ Status:     \(entity.registrationStatus) (expires \(formatter.string(from: entity.expirationDate)))")
        print("│ Location:   \(entity.location)")
        print("└────────────────────────────────────────────────────────────────────────┘")
    }

    // Compliance Status (original format)
    static func displayComplianceStatus() {
        print("\n┌─ COMPLIANCE STATUS ────────────────────────────────────────────────────┐")
        print("│ ❌ Section 889          Data not found in API response                │")
        print("│ ✅ Foreign Govt         No foreign government interests reported      │")
        print("│ ✅ Exclusions           NO Active Exclusions                          │")
        print("│ ✅ Financial Resp       No data returned                              │")
        print("│ ✅ Integrity (FAPIIS)   No Integrity Records - Clean                  │")
        print("└────────────────────────────────────────────────────────────────────────┘")
    }

    // Business Certifications (original layout)
    static func displayBusinessCertifications() {
        print("\n┌─ BUSINESS CERTIFICATIONS ──────────────────────────────────────────────┐")
        print("│ ✓ For Profit Organization                                              │")
        print("│ ✓ Veteran-Owned Business                                               │")
        print("│ ✓ Service-Disabled Veteran-Owned Business                             │")
        print("│ ✓ Limited Liability Company                                            │")
        print("│ ✓ Small Business (for all NAICS codes)                                │")
        print("└────────────────────────────────────────────────────────────────────────┘")
    }

    // NAICS Codes with Small Business Sizes (KEY FEATURE!)
    static func displayNAICSCodes() {
        print("\n┌─ NAICS CODES ──────────────────────────────────────────────────────────┐")
        print("│ SB   Code     Description                              Size           │")
        print("├────┼─────────┼───────────────────────────────────────┼───────────────┤")
        print("│ Y   │ 481211 │ Nonscheduled Chartered Passenger     │ 1,500         │")
        print("│     │        │ Air Transportation (PRIMARY)          │ employees     │")
        print("├────┼─────────┼───────────────────────────────────────┼───────────────┤")
        print("│ Y   │ 488190 │ Other Support Activities for Air      │ $41.5 million │")
        print("│     │        │ Transportation                        │               │")
        print("├────┼─────────┼───────────────────────────────────────┼───────────────┤")
        print("│ N   │ 336411 │ Aircraft Manufacturing                │ 1,500         │")
        print("│     │        │                                       │ employees     │")
        print("└────┴─────────┴───────────────────────────────────────┴───────────────┘")
        print("  ⚬ SB = Small Business qualification for each NAICS code")
        print("  ⚬ Size = Small Business size standard for each NAICS")
    }

    // PSC Codes (KEY FEATURE the user mentioned!)
    static func displayPSCCodes() {
        print("\n┌─ PSC CODES (Product Service Codes) ───────────────────────────────────┐")
        print("│ Code  │ Description                                                   │")
        print("├───────┼───────────────────────────────────────────────────────────────┤")
        print("│ V1A1  │ Air Charter for Things                                        │")
        print("│ V1A2  │ Air Charter for People                                        │")
        print("│ R425  │ Engineering Support                                           │")
        print("│ J019  │ Maintenance and Repair of Aircraft                           │")
        print("└───────┴───────────────────────────────────────────────────────────────┘")
        print("  ⚬ PSC = Product Service Codes for federal contracting")
        print("  ⚬ Used for market research and opportunity identification")
    }
}

// Supporting data structures from original
struct MockEntity {
    let entityName: String
    let legalBusinessName: String
    let dba: String
    let uei: String
    let cageCode: String
    let registrationStatus: String
    let expirationDate: Date
    let location: String
    let isSmallBusiness: Bool
    let isVeteranOwned: Bool
    let businessTypes: [String]
}

// Run the actual preview
Task {
    await RealOriginalSAMReport.main()
    exit(0)
}

RunLoop.main.run()
