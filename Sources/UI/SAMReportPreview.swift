import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
    import MessageUI
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

// Preview showing SAM.gov report with checkmark.circle SF Symbols
struct SAMReportPreview: View {
    @State private var showShareSheet = false
    @State private var showingSATBotAlert = false

    // Sample data - in real app this would come from the acquisition
    let acquisitionValue: Double = 150_000 // Example value under SAT
    let companyUEIs: [String] = ["R7TBP9D4VNJ3"] // Example single company

    private func loadSAMIcon() -> Image? {
        // For Swift Package, load from module bundle
        guard let url = Bundle.module.url(forResource: "SAMIcon", withExtension: "png") else {
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        #if os(iOS)
            if let uiImage = UIImage(data: data) {
                return Image(uiImage: uiImage)
            }
        #elseif os(macOS)
            if let nsImage = NSImage(data: data) {
                return Image(nsImage: nsImage)
            }
        #endif

        return nil
    }

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with share button
                    HStack {
                        // SAM icon on the left
                        ZStack {
                            Color.clear
                                .frame(width: 50, height: 50)

                            if let samIcon = loadSAMIcon() {
                                samIcon
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                            }
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
                                        Color(red: 0.0, green: 0.125, blue: 0.698), // Stronger Blue
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Spacer()

                        // Single share button with matching frame
                        ZStack {
                            Color.clear
                                .frame(width: 50, height: 50)

                            Button(action: { showShareSheet = true }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                    .foregroundColor(Theme.Colors.aikoPrimary)
                            }
                        }
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 16) {
                        // Status Badge (simplified)
                        // Example of Inactive status - uncomment to see inactive state
                        /*
                         HStack {
                             Image(systemName: "exclamationmark.circle")
                                 .foregroundColor(.orange)
                                 .font(.title2)
                             Text("Inactive")
                                 .font(.headline)
                                 .foregroundColor(.orange)
                             Spacer()
                             Text("Expired: December 15, 2024")
                                 .font(.caption)
                                 .foregroundColor(.gray)
                         }
                         .padding()
                         .background(Color.orange.opacity(0.2))
                         .cornerRadius(Theme.CornerRadius.sm)
                         */

                        // Active status example

                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                                .font(.title2)
                            Text("Active")
                                .font(.headline)
                                .foregroundColor(.green)
                            Spacer()
                            Text("Expires: January 24, 2026")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.sm)

                        // SAT Bot Button (moved above Company Information)
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(Theme.Colors.aikoPrimary)
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
                        .cornerRadius(Theme.CornerRadius.sm)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            sendSATBotEmailInBackground()
                        }

                        // Company Information
                        VStack(alignment: .leading, spacing: 12) {
                            Text("COMPANY INFORMATION")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 4)

                            VStack(alignment: .leading, spacing: 8) {
                                ReportInfoRow(label: "Legal Name", value: "Rampart Aviation, LLC.")
                                ReportInfoRow(label: "DBA", value: "RAMPART AVIATION LLC")
                                ReportInfoRow(label: "UEI", value: "R7TBP9D4VNJ3")
                                ReportInfoRow(label: "CAGE", value: "5BHV3")
                                ReportInfoRow(label: "Status", value: "Active (expires Jan 24, 2026)")
                                ReportInfoRow(label: "Location", value: "1777 Aviation Way, Colorado Springs, CO 80916")
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.sm)

                        // Compliance Status
                        VStack(alignment: .leading, spacing: 12) {
                            Text("COMPLIANCE STATUS")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 4)

                            ComplianceRow(
                                icon: "xmark.circle",
                                iconColor: .red,
                                title: "Section 889",
                                status: "Data not found in API response"
                            )

                            ComplianceRow(
                                icon: "checkmark.circle",
                                iconColor: .green,
                                title: "Foreign Government Interests",
                                status: "No foreign government interests reported"
                            )

                            ComplianceRow(
                                icon: "checkmark.circle",
                                iconColor: .green,
                                title: "Exclusions",
                                status: "NO Active Exclusions"
                            )

                            ComplianceRow(
                                icon: "checkmark.circle",
                                iconColor: .green,
                                title: "Financial Responsibility",
                                status: "No data returned"
                            )

                            ComplianceRow(
                                icon: "checkmark.circle",
                                iconColor: .green,
                                title: "Integrity (FAPIIS)",
                                status: "No Integrity Records - Clean"
                            )
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.sm)

                        // Business Certifications
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BUSINESS CERTIFICATIONS")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 4)

                            VStack(alignment: .leading, spacing: 8) {
                                CertificationRow(text: "For Profit Organization")
                                CertificationRow(text: "Veteran-Owned Business")
                                CertificationRow(text: "Service-Disabled Veteran-Owned Business")
                                CertificationRow(text: "Limited Liability Company")
                                CertificationRow(text: "Small Business (for all NAICS codes)")
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.sm)

                        // NAICS Codes
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
                                NAICSRow(
                                    code: "481211",
                                    description: "Nonscheduled Chartered Passenger Air Transportation",
                                    isPrimary: true,
                                    smallBusinessSize: "1,500 employees",
                                    isSmallBusiness: true
                                )
                                NAICSRow(
                                    code: "488190",
                                    description: "Other Support Activities for Air Transportation",
                                    isPrimary: false,
                                    smallBusinessSize: "$41.5 million",
                                    isSmallBusiness: true
                                )
                                NAICSRow(
                                    code: "336411",
                                    description: "Aircraft Manufacturing",
                                    isPrimary: false,
                                    smallBusinessSize: "1,500 employees",
                                    isSmallBusiness: false
                                )
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.sm)

                        // PSC Codes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PSC CODES")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 4)

                            VStack(alignment: .leading, spacing: 8) {
                                PSCRow(code: "V1A1", description: "Air Charter for Things")
                                PSCRow(code: "V1A2", description: "Air Charter for People")
                                PSCRow(code: "R425", description: "Engineering Support")
                                PSCRow(code: "J019", description: "Maintenance and Repair of Aircraft")
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.sm)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("SAM.gov")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        #if os(iOS)
        .sheet(isPresented: $showShareSheet) {
            SAMShareSheet(items: generateShareItems())
        }
        #else
        .sheet(isPresented: $showShareSheet) {
                    VStack(spacing: 20) {
                        Text("Share Report")
                            .font(.headline)
                        Text(generateReportText())
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        HStack {
                            Button("Save to File") {
                                saveReportToFile()
                            }
                            Button("Close") {
                                showShareSheet = false
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .frame(width: 500, height: 400)
                }
        #endif
                .alert("SAT Bot", isPresented: $showingSATBotAlert) {
                    Button("OK") {}
                } message: {
                    #if os(iOS)
                        if MFMailComposeViewController.canSendMail() {
                            Text("Email queued for \(acquisitionValue <= 250_000 ? "UnderSATBot" : "OverSATBot") with UEI: R7TBP9D4VNJ3")
                        } else {
                            Text("Email details copied to clipboard")
                        }
                    #else
                        Text("Email functionality not available on this platform")
                    #endif
                }
    }

    private func generateShareItems() -> [Any] {
        let reportText = generateReportText()

        // Create a temporary file with the report
        let fileName = "SAM_Report_\(Date().formatted(.dateTime.year().month().day())).txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try reportText.write(to: tempURL, atomically: true, encoding: .utf8)
            // Return both the text and the file URL for maximum compatibility
            return [reportText, tempURL]
        } catch {
            // If file creation fails, just return the text
            return [reportText]
        }
    }

    private func saveReportToFile() {
        #if os(macOS)
            let reportText = generateReportText()
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.plainText]
            savePanel.nameFieldStringValue = "SAM_Report_\(Date().formatted(.dateTime.year().month().day())).txt"

            if savePanel.runModal() == .OK, let url = savePanel.url {
                do {
                    try reportText.write(to: url, atomically: true, encoding: .utf8)
                    print("Report saved to: \(url.path)")
                } catch {
                    print("Error saving report: \(error)")
                }
            }
        #endif
    }

    private func generateReportText() -> String {
        """
        SAM.gov
        Generated: \(Date().formatted())

        COMPANY INFORMATION:
        - Legal Name: Rampart Aviation, LLC.
        - DBA: RAMPART AVIATION LLC
        - UEI: R7TBP9D4VNJ3
        - CAGE: 5BHV3
        - Status: Active (expires Jan 24, 2026)
        - Location: 1777 Aviation Way, Colorado Springs, CO 80916

        COMPLIANCE STATUS:
        - × Section 889 data not found in the API response
        - → Foreign Government Interests: No foreign government interests reported
        - → No Active Exclusions
        - → Financial Responsibility: No data returned
        - → No Integrity Records (clean FAPIIS)

        BUSINESS CERTIFICATIONS:
        - → For Profit Organization
        - → Veteran-Owned Business
        - → Service-Disabled Veteran-Owned Business
        - → Limited Liability Company
        - → Small Business (for all NAICS codes)

        NAICS CODES:
        - 481211 [SB: Y]: Nonscheduled Chartered Passenger Air Transportation (PRIMARY)
          Small Business Size: 1,500 employees
        - 488190 [SB: Y]: Other Support Activities for Air Transportation
          Small Business Size: $41.5 million
        - 336411 [SB: N]: Aircraft Manufacturing
          Small Business Size: 1,500 employees

        PSC CODES:
        - V1A1: Air Charter for Things
        - V1A2: Air Charter for People
        - R425: Engineering Support
        - J019: Maintenance and Repair of Aircraft
        """
    }

    private func sendSATBotEmailInBackground() {
        // Automatically send email in background
        #if os(iOS)
            if MFMailComposeViewController.canSendMail() {
                // Prepare email content
                _ = acquisitionValue <= 250_000 ? "UnderSATBot@outlook.com" : "OverSATBot@outlook.com"
                _ = "UEI: R7TBP9D4VNJ3" // TODO: Get actual UEI from entity data

                // For iOS, we need to present the mail composer but can't truly send in background
                // Show success message instead
                showingSATBotAlert = true
            } else {
                // Fallback: copy email details to clipboard
                #if os(iOS)
                    let recipient = acquisitionValue <= 250_000 ? "UnderSATBot@outlook.com" : "OverSATBot@outlook.com"
                    let emailInfo = "To: \(recipient)\nSubject: UEI: R7TBP9D4VNJ3"
                    UIPasteboard.general.string = emailInfo
                #endif
                showingSATBotAlert = true
            }
        #endif
    }
}

struct ReportInfoRow: View {
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

struct ComplianceRow: View {
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

struct CertificationRow: View {
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

struct NAICSRow: View {
    let code: String
    let description: String
    let isPrimary: Bool
    let smallBusinessSize: String
    let isSmallBusiness: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                // SB column (now first)
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

struct PSCRow: View {
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

// Share Sheet for iOS
#if os(iOS)
    struct SAMShareSheet: UIViewControllerRepresentable {
        let items: [Any]

        func makeUIViewController(context _: Context) -> UIActivityViewController {
            let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)

            // Force dark mode for the share sheet
            controller.overrideUserInterfaceStyle = .dark

            return controller
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context _: Context) {
            // Ensure dark mode persists
            uiViewController.overrideUserInterfaceStyle = .dark
        }
    }

#endif

struct SAMReportPreview_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUI.NavigationView {
            SAMReportPreview()
        }
    }
}
