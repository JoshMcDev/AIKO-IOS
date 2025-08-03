import Foundation
import AppCore

// MARK: - Test Data Extensions for SAMGov Testing

extension EntityDetail {
    public static func mockCAGEEntity() -> EntityDetail {
        EntityDetail(
            ueiSAM: "ABC123DEF456",
            entityName: "Test Defense Contractor",
            legalBusinessName: "Test Defense Contractor LLC",
            cageCode: "1ABC2",
            registrationStatus: "Active",
            businessTypes: ["Small Business", "Veteran-Owned"],
            hasActiveExclusions: false
        )
    }

    public static func mockUEIEntity() -> EntityDetail {
        EntityDetail(
            ueiSAM: "XYZ789UVW012",
            entityName: "UEI Test Entity",
            legalBusinessName: "UEI Test Entity Inc",
            cageCode: "9XYZ8",
            registrationStatus: "Active",
            businessTypes: ["Large Business"],
            hasActiveExclusions: false
        )
    }

    public static func mockCompanyEntity() -> EntityDetail {
        EntityDetail(
            ueiSAM: "COMP123ENTITY",
            entityName: "Test Defense Contractor",
            legalBusinessName: "Test Defense Contractor Corporation",
            cageCode: "COMP1",
            registrationStatus: "Active",
            businessTypes: ["Small Business", "Woman-Owned"],
            hasActiveExclusions: false
        )
    }

    public static func mockExcludedEntity() -> EntityDetail {
        EntityDetail(
            ueiSAM: "EXCL789ENTITY",
            entityName: "Excluded Contractor",
            legalBusinessName: "Excluded Contractor Inc",
            cageCode: "EXCL9",
            registrationStatus: "Active",
            businessTypes: ["Large Business"],
            hasActiveExclusions: true
        )
    }
}

extension EntitySearchResult {
    public static func mockSearchResult() -> EntitySearchResult {
        EntitySearchResult(
            entities: [
                EntitySummary(
                    ueiSAM: "COMP123ENTITY",
                    entityName: "Test Defense Contractor",
                    registrationStatus: "Active"
                )
            ],
            totalCount: 1
        )
    }

    public var totalRecords: Int {
        return totalCount
    }
}

// MARK: - Test Support
// Note: SAMGovError is defined in SAMGovService.swift - using that definition
