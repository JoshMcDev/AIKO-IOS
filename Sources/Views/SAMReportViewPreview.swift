import SwiftUI

// MARK: - SAM Report View Preview Helper
/// Helper view for previewing SAMReportView in Xcode with sample data

#if DEBUG
struct SAMReportViewPreview: View {
    var body: some View {
        NavigationView {
            SAMReportView()
        }
        .preferredColorScheme(.dark)
    }
}

struct SAMReportViewPreview_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default preview
            SAMReportViewPreview()
                .previewDisplayName("SAM Report - Default")

            // With expired CAGE code
            NavigationView {
                SAMReportView(
                    entity: createExpiredEntity(),
                    acquisitionValue: 300_000
                )
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("SAM Report - Expired CAGE")

            // Large acquisition value
            NavigationView {
                SAMReportView(
                    entity: createSampleEntity(),
                    acquisitionValue: 1_000_000
                )
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("SAM Report - Large Value")

            // Expiring soon (within 30 days)
            NavigationView {
                SAMReportView(
                    entity: createExpiringSoonEntity(),
                    acquisitionValue: 150_000
                )
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("SAM Report - Expiring Soon")
        }
    }

    // MARK: - Sample Data Helpers

    private static func createSampleEntity() -> EntityDetail {
        EntityDetail(
            ueiSAM: "R7TBP9D4VNJ3",
            entityName: "Test Contractor for CAGE 5BVH3",
            legalBusinessName: "RAMPART AVIATION, LLC.",
            cageCode: "5BVH3",
            registrationStatus: "Active",
            registrationDate: Date(),
            expirationDate: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 24)),
            businessTypes: [
                "For Profit Organization",
                "Limited Liability Company",
                "Veteran-Owned Business"
            ],
            address: EntityAddress(
                line1: "1777 Aviation Way",
                city: "Colorado Springs",
                state: "CO",
                zipCode: "80916"
            ),
            pointOfContact: PointOfContact(
                firstName: "John",
                lastName: "Smith",
                title: "Chief Executive Officer",
                email: "john.smith@rampartaviation.com",
                phone: "(719) 555-0123"
            ),
            isSmallBusiness: true,
            isVeteranOwned: true,
            isServiceDisabledVeteranOwned: true
        )
    }

    private static func createExpiringSoonEntity() -> EntityDetail {
        EntityDetail(
            ueiSAM: "EXPIRING123456",
            entityName: "Expiring Soon Test Entity",
            legalBusinessName: "YELLOW WARNING, LLC.",
            cageCode: "WARN1",
            registrationStatus: "Active",
            registrationDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
            businessTypes: [
                "For Profit Organization",
                "Small Business"
            ],
            address: EntityAddress(
                line1: "456 Warning Street",
                city: "Alert City",
                state: "TX",
                zipCode: "54321"
            ),
            pointOfContact: PointOfContact(
                firstName: "Sarah",
                lastName: "Johnson",
                title: "Operations Manager",
                email: "sarah.johnson@yellowwarning.com",
                phone: "(512) 555-0987"
            ),
            isSmallBusiness: true
        )
    }

    private static func createExpiredEntity() -> EntityDetail {
        EntityDetail(
            ueiSAM: "EXPIRED123456",
            entityName: "Expired Test Entity",
            legalBusinessName: "EXPIRED CONTRACTOR, LLC.",
            cageCode: "EXP01",
            registrationStatus: "Inactive",
            registrationDate: Date(),
            expirationDate: Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 15)),
            businessTypes: [
                "For Profit Organization",
                "Small Business"
            ],
            address: EntityAddress(
                line1: "123 Expired Street",
                city: "Old City",
                state: "VA",
                zipCode: "12345"
            ),
            pointOfContact: PointOfContact(
                firstName: "Jane",
                lastName: "Doe",
                title: "General Manager",
                email: "jane.doe@expiredcontractor.com",
                phone: "(555) 123-4567"
            ),
            hasActiveExclusions: true,
            isSmallBusiness: true
        )
    }
}
#endif
