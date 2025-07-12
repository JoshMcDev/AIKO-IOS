import Foundation
import ComposableArchitecture

// Mock SAM.gov service for testing without API key
extension SAMGovService {
    static var mockValue: SAMGovService {
        SAMGovService(
            searchEntity: { query in
                // Mock responses based on query
                if query.lowercased().contains("lockheed") {
                    return EntitySearchResult(totalRecords: 1, entities: [
                        EntitySummary(
                            ueiSAM: "G2Y7W1E3LJK5",
                            cageCode: "1F353",
                            legalBusinessName: "LOCKHEED MARTIN CORPORATION",
                            registrationStatus: "Active",
                            registrationDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()),
                            expirationDate: Calendar.current.date(byAdding: .day, value: 67, to: Date())
                        )
                    ])
                } else if query.lowercased().contains("booz") {
                    return EntitySearchResult(totalRecords: 1, entities: [
                        EntitySummary(
                            ueiSAM: "R3Q8P8B7VNJ3",
                            cageCode: "17038",
                            legalBusinessName: "BOOZ ALLEN HAMILTON INC",
                            registrationStatus: "Active",
                            registrationDate: Calendar.current.date(byAdding: .month, value: -7, to: Date()),
                            expirationDate: Calendar.current.date(byAdding: .day, value: 133, to: Date())
                        )
                    ])
                } else if query.contains("CAGE:1F353") {
                    return EntitySearchResult(totalRecords: 1, entities: [
                        EntitySummary(
                            ueiSAM: "G2Y7W1E3LJK5",
                            cageCode: "1F353",
                            legalBusinessName: "LOCKHEED MARTIN CORPORATION",
                            registrationStatus: "Active",
                            registrationDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()),
                            expirationDate: Calendar.current.date(byAdding: .day, value: 67, to: Date())
                        )
                    ])
                } else if query.contains("CAGE:17038") {
                    return EntitySearchResult(totalRecords: 1, entities: [
                        EntitySummary(
                            ueiSAM: "R3Q8P8B7VNJ3",
                            cageCode: "17038",
                            legalBusinessName: "BOOZ ALLEN HAMILTON INC",
                            registrationStatus: "Active",
                            registrationDate: Calendar.current.date(byAdding: .month, value: -7, to: Date()),
                            expirationDate: Calendar.current.date(byAdding: .day, value: 133, to: Date())
                        )
                    ])
                } else {
                    throw SAMGovError.entityNotFound
                }
            },
            getEntityByCAGE: { cage in
                switch cage {
                case "1F353":
                    return EntityDetail(
                        ueiSAM: "G2Y7W1E3LJK5",
                        cageCode: "1F353",
                        legalBusinessName: "LOCKHEED MARTIN CORPORATION",
                        registrationStatus: "Active",
                        registrationDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()),
                        expirationDate: Calendar.current.date(byAdding: .day, value: 67, to: Date()),
                        cageCodeExpirationDate: Calendar.current.date(byAdding: .day, value: 67, to: Date()),
                        physicalAddress: SAMGovAddress(
                            streetAddress: "6801 Rockledge Drive",
                            city: "Bethesda",
                            state: "MD",
                            zipCode: "20817",
                            country: "USA"
                        ),
                        businessTypes: [
                            BusinessType(code: "2X", description: "For Profit Organization"),
                            BusinessType(code: "OY", description: "Other Than Small Business")
                        ],
                        naicsCodes: [
                            NAICSCode(code: "336411", description: "Aircraft Manufacturing", isPrimary: true),
                            NAICSCode(code: "541330", description: "Engineering Services", isPrimary: false)
                        ],
                        pointsOfContact: [],
                        isSmallBusiness: false,
                        isVeteranOwned: false,
                        isServiceDisabledVeteranOwned: false,
                        isWomanOwned: false,
                        is8aProgram: false,
                        isHUBZone: false,
                        section889Certifications: Section889Status(
                            doesNotProvideProhibitedTelecom: true,
                            doesNotUseProhibitedTelecom: true,
                            certificationDate: Date()
                        ),
                        hasActiveExclusions: false,
                        exclusionURL: nil,
                        responsibilityInformation: ResponsibilityInfo(
                            hasDelinquentFederalDebt: false,
                            hasUnpaidTaxLiability: false,
                            integrityRecords: []
                        ),
                        architectEngineerQualifications: nil,
                        foreignGovtEntities: []
                    )
                case "17038":
                    return EntityDetail(
                        ueiSAM: "R3Q8P8B7VNJ3",
                        cageCode: "17038",
                        legalBusinessName: "BOOZ ALLEN HAMILTON INC",
                        registrationStatus: "Active",
                        registrationDate: Calendar.current.date(byAdding: .month, value: -7, to: Date()),
                        expirationDate: Calendar.current.date(byAdding: .day, value: 133, to: Date()),
                        cageCodeExpirationDate: Calendar.current.date(byAdding: .day, value: 133, to: Date()),
                        physicalAddress: SAMGovAddress(
                            streetAddress: "8283 Greensboro Drive",
                            city: "McLean",
                            state: "VA",
                            zipCode: "22102",
                            country: "USA"
                        ),
                        businessTypes: [
                            BusinessType(code: "2X", description: "For Profit Organization"),
                            BusinessType(code: "OY", description: "Other Than Small Business")
                        ],
                        naicsCodes: [
                            NAICSCode(code: "541511", description: "Custom Computer Programming Services", isPrimary: true),
                            NAICSCode(code: "541512", description: "Computer Systems Design Services", isPrimary: false)
                        ],
                        pointsOfContact: [],
                        isSmallBusiness: false,
                        isVeteranOwned: false,
                        isServiceDisabledVeteranOwned: false,
                        isWomanOwned: false,
                        is8aProgram: false,
                        isHUBZone: false,
                        section889Certifications: Section889Status(
                            doesNotProvideProhibitedTelecom: true,
                            doesNotUseProhibitedTelecom: true,
                            certificationDate: Date()
                        ),
                        hasActiveExclusions: false,
                        exclusionURL: nil,
                        responsibilityInformation: ResponsibilityInfo(
                            hasDelinquentFederalDebt: false,
                            hasUnpaidTaxLiability: false,
                            integrityRecords: []
                        ),
                        architectEngineerQualifications: nil,
                        foreignGovtEntities: []
                    )
                default:
                    throw SAMGovError.entityNotFound
                }
            },
            getEntityByUEI: { uei in
                switch uei {
                case "G2Y7W1E3LJK5":
                    return try await SAMGovService.mockValue.getEntityByCAGE("1F353")
                case "R3Q8P8B7VNJ3":
                    return try await SAMGovService.mockValue.getEntityByCAGE("17038")
                default:
                    throw SAMGovError.entityNotFound
                }
            }
        )
    }
}

// Mock settings manager that returns empty API key
extension SettingsManager {
    static var mockValue: SettingsManager {
        SettingsManager(
            loadSettings: {
                SettingsData()
            },
            saveSettings: { },
            resetToDefaults: { },
            restoreDefaults: { },
            saveAPIKey: { _ in },
            loadAPIKey: { "" },
            validateAPIKey: { _ in true },
            exportData: { _ in URL(fileURLWithPath: "/tmp/export.json") },
            importData: { _ in },
            clearCache: { },
            performBackup: { _ in URL(fileURLWithPath: "/tmp/backup.json") },
            restoreBackup: { _, _ in }
        )
    }
}