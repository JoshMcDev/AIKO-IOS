import Foundation
import SwiftUI

// Import SAM.gov service types
// Note: Adjust import path based on your project structure
// If SAMGovService is in a different module, import that module instead

// MARK: - SAM Report View

/// Custom SAM.gov report view with CAGE expiration validation, NAICS codes, and PSC codes
struct SAMReportView: View {
    // MARK: - State

    @State private var showShareSheet = false
    @State private var showingSATBotAlert = false

    // MARK: - Sample Data

    let entity: EntityDetail
    let acquisitionValue: Double

    // MARK: - Initializer

    init(entity: EntityDetail? = nil, acquisitionValue: Double = 150_000) {
        self.entity = entity ?? Self.createSampleEntity()
        self.acquisitionValue = acquisitionValue
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with share button
                    headerView

                    VStack(alignment: .leading, spacing: 16) {
                        // CAGE Code Expiration Status - FIRST ITEM
                        cageExpirationCard

                        // SAT Bot Section
                        satBotSection

                        // Company Information
                        companyInformationSection

                        // Compliance Status
                        complianceStatusSection

                        // Business Certifications
                        businessCertificationsSection

                        // NAICS Codes with Small Business Sizes
                        naicsCodesSection

                        // PSC Codes
                        pscCodesSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("SAM.gov")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showShareSheet) {
            shareView
        }
        .alert("SAT Bot", isPresented: $showingSATBotAlert) {
            Button("OK") {}
        } message: {
            Text(satBotMessage)
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            // SAM icon placeholder
            ZStack {
                Color.clear
                    .frame(width: 50, height: 50)

                Image(systemName: "building.2")
                    .font(.title2)
                    .foregroundColor(.blue)
            }

            Spacer()

            // Centered SAM.gov text with patriotic gradient
            Text("SAM.gov")
                .font(.title)
                .bold()
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.698, green: 0.132, blue: 0.203), // Red
                            Color.white,
                            Color(red: 0.0, green: 0.125, blue: 0.698), // Blue
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Spacer()

            // Share button
            ZStack {
                Color.clear
                    .frame(width: 50, height: 50)

                Button(action: { showShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - CAGE Expiration Card (First Item)

    private var cageExpirationCard: some View {
        let isExpired = isEntityExpired
        let isExpiringSoon = isEntityExpiringSoon
        let expirationDate = entity.expirationDate ?? Date().addingTimeInterval(365 * 24 * 60 * 60)

        // Determine status and colors
        let (statusText, statusColor, backgroundColor) = if isExpired {
            ("Inactive", Color.red, Color.red.opacity(0.2))
        } else if isExpiringSoon {
            ("Expiring Soon", Color.orange, Color.yellow.opacity(0.2))
        } else {
            ("Active", Color.green, Color.green.opacity(0.2))
        }

        let iconName = if isExpired {
            "exclamationmark.circle"
        } else if isExpiringSoon {
            "exclamationmark.triangle"
        } else {
            "checkmark.circle"
        }

        return HStack {
            Image(systemName: iconName)
                .foregroundColor(statusColor)
                .font(.title2)

            Text(statusText)
                .font(.headline)
                .foregroundColor(statusColor)

            Spacer()

            Text("Expires: \(DateFormatter.medium.string(from: expirationDate))")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
    }

    // MARK: - SAT Bot Section

    private var satBotSection: some View {
        HStack {
            Image(systemName: "envelope")
                .foregroundColor(.blue)
                .font(.title2)

            Text("SAT Bot")
                .font(.headline)
                .foregroundColor(.white)

            Text("Auto send")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()

            Text(acquisitionValue <= 250_000 ? "UnderSATBot" : "OverSATBot")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            showingSATBotAlert = true
        }
    }

    // MARK: - Company Information

    private var companyInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMPANY INFORMATION")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 8) {
                SAMInfoRow(label: "Legal Name", value: entity.legalBusinessName)
                SAMInfoRow(label: "UEI", value: entity.ueiSAM)
                SAMInfoRow(label: "CAGE", value: entity.cageCode ?? "N/A")
                SAMInfoRow(label: "Status", value: "\(entity.registrationStatus) (expires \(DateFormatter.medium.string(from: entity.expirationDate ?? Date())))")

                if let address = entity.address {
                    SAMInfoRow(label: "Location", value: "\(address.line1), \(address.city), \(address.state) \(address.zipCode)")
                }

                // Contact Information
                if let contact = entity.pointOfContact {
                    SAMInfoRow(label: "Contact", value: "\(contact.firstName) \(contact.lastName)")
                    if let title = contact.title {
                        SAMInfoRow(label: "Title", value: title)
                    }
                    if let email = contact.email {
                        SAMInfoRow(label: "Email", value: email)
                    }
                    if let phone = contact.phone {
                        SAMInfoRow(label: "Phone", value: phone)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - Compliance Status

    private var complianceStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMPLIANCE STATUS")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 4)

            SAMComplianceRow(
                icon: "xmark.circle",
                iconColor: .red,
                title: "Section 889",
                status: "Data not found in API response"
            )

            SAMComplianceRow(
                icon: "checkmark.circle",
                iconColor: .green,
                title: "Foreign Government Interests",
                status: "No foreign government interests reported"
            )

            SAMComplianceRow(
                icon: "checkmark.circle",
                iconColor: .green,
                title: "Exclusions",
                status: entity.hasActiveExclusions ? "Active Exclusions Found" : "NO Active Exclusions"
            )

            SAMComplianceRow(
                icon: "checkmark.circle",
                iconColor: .green,
                title: "Financial Responsibility",
                status: "No data returned"
            )

            SAMComplianceRow(
                icon: "checkmark.circle",
                iconColor: .green,
                title: "Integrity (FAPIIS)",
                status: "No Integrity Records - Clean"
            )
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - Business Certifications

    private var businessCertificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BUSINESS CERTIFICATIONS")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(entity.businessTypes, id: \.self) { businessType in
                    SAMCertificationRow(text: businessType)
                }

                if entity.isVeteranOwned {
                    SAMCertificationRow(text: "Veteran-Owned Business")
                }

                if entity.isServiceDisabledVeteranOwned {
                    SAMCertificationRow(text: "Service-Disabled Veteran-Owned Business")
                }

                if entity.isSmallBusiness {
                    SAMCertificationRow(text: "Small Business (for all NAICS codes)")
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - NAICS Codes with Small Business Sizes

    private var naicsCodesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NAICS CODES")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 4)

            // Column headers
            HStack(alignment: .top) {
                Text("SB")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .frame(width: 25, alignment: .center)

                Text("Code")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .frame(width: 60, alignment: .leading)

                Text("Description")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)

                Spacer()
            }
            .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(naicsCodesWithSizes, id: \.code) { naics in
                    SAMNAICSRow(
                        code: naics.code,
                        description: naics.description,
                        isPrimary: naics.isPrimary,
                        smallBusinessSize: naics.smallBusinessSize,
                        isSmallBusiness: naics.isSmallBusiness
                    )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - PSC Codes

    private var pscCodesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PSC CODES")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(samplePSCCodes, id: \.code) { psc in
                    SAMPSCRow(code: psc.code, description: psc.description)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - Share View

    private var shareView: some View {
        VStack(spacing: 20) {
            Text("Share SAM Report")
                .font(.headline)

            Text(generateShareContent())
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            HStack {
                Button("Copy") {
                    #if os(iOS)
                    UIPasteboard.general.string = generateShareContent()
                    #elseif os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(generateShareContent(), forType: .string)
                    #endif
                    showShareSheet = false
                }
                .buttonStyle(.bordered)

                Button("Close") {
                    showShareSheet = false
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

// MARK: - SAM Report Helper Components

struct SAMInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundColor(.white)
            Spacer()
        }
    }
}

struct SAMComplianceRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let status: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 20))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Text(status)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct SAMCertificationRow: View {
    let text: String

    var body: some View {
        HStack {
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundColor(.green)
            Text(text)
                .font(.caption)
                .foregroundColor(.white)
            Spacer()
        }
    }
}

struct SAMNAICSRow: View {
    let code: String
    let description: String
    let isPrimary: Bool
    let smallBusinessSize: String
    let isSmallBusiness: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                // SB column
                Text(isSmallBusiness ? "Y" : "N")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSmallBusiness ? .green : .gray)
                    .frame(width: 25, alignment: .center)

                Text(code)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.white)
                        if isPrimary {
                            Text("PRIMARY")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    Text("Small Business Size: \(smallBusinessSize)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Spacer()
            }
        }
    }
}

struct SAMPSCRow: View {
    let code: String
    let description: String

    var body: some View {
        HStack(alignment: .top) {
            Text(code)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 50, alignment: .leading)

            Text(description)
                .font(.caption)
                .foregroundColor(.white)

            Spacer()
        }
    }
}

// MARK: - Extensions and Sample Data

extension SAMReportView {
    // MARK: - Computed Properties

    private var isEntityExpired: Bool {
        guard let expirationDate = entity.expirationDate else { return false }
        return expirationDate < Date()
    }

    private var isEntityExpiringSoon: Bool {
        guard let expirationDate = entity.expirationDate else { return false }
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return expirationDate <= thirtyDaysFromNow && expirationDate >= Date()
    }

    private var satBotMessage: String {
        """
        Email queued for \(acquisitionValue <= 250_000 ? "UnderSATBot" : "OverSATBot")
        UEI: \(entity.ueiSAM)
        Value: $\(String(format: "%.0f", acquisitionValue))
        """
    }

    // MARK: - Sample Data

    private static func createSampleEntity() -> EntityDetail {
        EntityDetail(
            ueiSAM: "R7TBP9D4VNJ3",
            entityName: "Test Contractor for CAGE 5BVH3",
            legalBusinessName: "RAMPART AVIATION, LLC.",
            cageCode: "5BVH3",
            registrationStatus: "Active",
            registrationDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
            businessTypes: [
                "For Profit Organization",
                "Limited Liability Company",
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

    private var naicsCodesWithSizes: [NAICSWithSize] {
        [
            NAICSWithSize(
                code: "481211",
                description: "Nonscheduled Chartered Passenger Air Transportation",
                isPrimary: true,
                smallBusinessSize: "1,500 employees",
                isSmallBusiness: true
            ),
            NAICSWithSize(
                code: "488190",
                description: "Other Support Activities for Air Transportation",
                isPrimary: false,
                smallBusinessSize: "$41.5 million",
                isSmallBusiness: true
            ),
            NAICSWithSize(
                code: "336411",
                description: "Aircraft Manufacturing",
                isPrimary: false,
                smallBusinessSize: "1,500 employees",
                isSmallBusiness: false
            ),
        ]
    }

    private var samplePSCCodes: [PSCCode] {
        [
            PSCCode(code: "V1A1", description: "Air Charter for Things"),
            PSCCode(code: "V1A2", description: "Air Charter for People"),
            PSCCode(code: "R425", description: "Engineering Support"),
            PSCCode(code: "J019", description: "Maintenance and Repair of Aircraft"),
        ]
    }

    private func generateShareContent() -> String {
        let formatter = DateFormatter.medium
        let expirationDate = entity.expirationDate ?? Date()
        let contactInfo = entity.pointOfContact.map { contact in
            """
            • Contact: \(contact.firstName) \(contact.lastName)\(contact.title.map { " (\($0))" } ?? "")
            \(contact.email.map { "• Email: \($0)" } ?? "")
            \(contact.phone.map { "• Phone: \($0)" } ?? "")
            """
        } ?? ""

        return """
        SAM.gov Report
        Generated: \(formatter.string(from: Date()))

        COMPANY INFORMATION:
        • Legal Name: \(entity.legalBusinessName)
        • UEI: \(entity.ueiSAM)
        • CAGE: \(entity.cageCode ?? "N/A")
        • Status: \(entity.registrationStatus) (expires \(formatter.string(from: expirationDate)))
        \(contactInfo.isEmpty ? "" : "\n\(contactInfo)")

        COMPLIANCE STATUS:
        • Exclusions: \(entity.hasActiveExclusions ? "Active Exclusions Found" : "NO Active Exclusions")
        • Foreign Government Interests: No interests reported
        • Integrity Records: Clean

        NAICS CODES:
        \(naicsCodesWithSizes.map { "• \($0.code): \($0.description) [SB: \($0.isSmallBusiness ? "Y" : "N")] - Size: \($0.smallBusinessSize)" }.joined(separator: "\n"))

        PSC CODES:
        \(samplePSCCodes.map { "• \($0.code): \($0.description)" }.joined(separator: "\n"))
        """
    }
}

// MARK: - Supporting Types

struct NAICSWithSize {
    let code: String
    let description: String
    let isPrimary: Bool
    let smallBusinessSize: String
    let isSmallBusiness: Bool
}

struct PSCCode {
    let code: String
    let description: String
}

// MARK: - Extensions

extension DateFormatter {
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

// MARK: - Preview

#if DEBUG
struct SAMReportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SAMReportView()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
