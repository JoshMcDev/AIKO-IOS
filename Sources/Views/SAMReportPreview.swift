import AppCore
import ComposableArchitecture
import SwiftUI
import UniformTypeIdentifiers

// Preview showing SAM.gov report with checkmark.circle SF Symbols
struct SAMReportPreview: View {
    @State private var showShareSheet = false
    @State private var showingSATBotAlert = false

    // Dependency injection
    @Dependency(\.imageLoader) var imageLoader
    @Dependency(\.shareService) var shareService
    @Dependency(\.fileService) var fileService
    @Dependency(\.emailService) var emailService
    @Dependency(\.clipboardService) var clipboardService

    // Sample data - in real app this would come from the acquisition
    let acquisitionValue: Double = 150_000 // Example value under SAT
    let companyUEIs: [String] = ["R7TBP9D4VNJ3"] // Example single company

    private func loadSAMIcon() -> Image? {
        // Use dependency-injected image loader
        imageLoader.loadImageFromBundle("SAMIcon", "png", Bundle.module)
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
                        Spacer()
                        Button(action: {
                            showShareSheet = true
                        }, label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        })
                    }
                    .padding(.horizontal)

                    // Report content
                    VStack(alignment: .leading, spacing: 15) {
                        // SAM.gov section
                        HStack(spacing: 10) {
                            if let samIcon = loadSAMIcon() {
                                samIcon
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                            }
                            Text("SAM.gov Checks")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }

                        // Checks
                        VStack(alignment: .leading, spacing: 10) {
                            CheckItem(
                                icon: "checkmark.circle.fill",
                                text: "No Active Exclusions",
                                status: .passed
                            )
                            CheckItem(
                                icon: "checkmark.circle.fill",
                                text: "All registrations are active",
                                status: .passed
                            )
                            CheckItem(
                                icon: "checkmark.circle.fill",
                                text: "No FAPIIS records found",
                                status: .passed
                            )
                        }

                        Divider()
                            .background(Color.gray.opacity(0.3))

                        // Contract Opportunities
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Contract Opportunities")
                                .font(.headline)
                                .foregroundColor(.white)

                            if acquisitionValue < 250_000 {
                                HStack(spacing: 5) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Eligible for Simplified Acquisition Procedures")
                                        .foregroundColor(.white.opacity(0.9))
                                        .font(.subheadline)
                                }
                            }

                            HStack(spacing: 5) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Value: $\(String(format: "%.0f", acquisitionValue))")
                                    .foregroundColor(.white.opacity(0.9))
                                    .font(.subheadline)
                            }
                        }

                        Divider()
                            .background(Color.gray.opacity(0.3))

                        // SAT Bot Recommendation
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "cpu")
                                    .foregroundColor(.purple)
                                Text("SAT Bot Analysis")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }

                            Text("✨ This acquisition qualifies for simplified procedures under FAR Part 13")
                                .foregroundColor(.white.opacity(0.9))
                                .font(.subheadline)
                                .padding(.vertical, 5)

                            Button(action: {
                                showingSATBotAlert = true
                            }, label: {
                                Text("View SAT Bot Details")
                                    .foregroundColor(.purple)
                                    .font(.caption)
                            })
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            // Platform-agnostic navigation title
            #if os(iOS)
            .navigationBarTitle("SAM.gov Report", displayMode: .inline)
            #else
            .navigationTitle("SAM.gov Report")
            #endif
        }
        .sheet(isPresented: $showShareSheet) {
            ShareView(reportContent: generateReportContent())
        }
        .alert("SAT Bot Intelligence", isPresented: $showingSATBotAlert) {
            Button("OK") {}
        } message: {
            Text(getSATBotMessage())
        }
    }

    private func generateReportContent() -> String {
        """
        SAM.gov Responsibility Check Report
        Generated: \(Date().formatted())

        Company UEIs Checked: \(companyUEIs.joined(separator: ", "))

        ✅ No Active Exclusions
        ✅ All registrations are active
        ✅ No FAPIIS records found

        Contract Value: $\(String(format: "%.0f", acquisitionValue))

        Recommendation: This acquisition qualifies for simplified procedures under FAR Part 13.
        """
    }

    private func getSATBotMessage() -> String {
        let message = """
        Based on the contract value of $\(String(format: "%.0f", acquisitionValue)), this acquisition falls under the Simplified Acquisition Threshold (SAT).

        Key Benefits:
        • Streamlined procedures
        • Reduced documentation
        • Faster procurement timeline

        Recommended Actions:
        1. Use simplified acquisition procedures
        2. Consider using purchase cards if applicable
        3. Leverage existing BPAs or IDIQs
        """

        // Platform differences handled by service
        return message
    }
}

// Updated ShareView to use dependency injection
struct ShareView: View {
    let reportContent: String
    @Environment(\.dismiss) var dismiss
    @State private var showingSaveAlert = false
    @State private var showingEmailAlert = false
    @State private var saveMessage = ""

    @Dependency(\.shareService) var shareService
    @Dependency(\.fileService) var fileService
    @Dependency(\.emailService) var emailService
    @Dependency(\.clipboardService) var clipboardService

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 20) {
            Text("Share Report")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)

            VStack(spacing: 15) {
                // Save to Files
                Button(action: saveToFiles) {
                    HStack {
                        Image(systemName: "folder")
                            .frame(width: 30)
                        Text("Save to Files")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())

                // Email
                if emailService.canSendEmail() {
                    Button(action: sendEmail) {
                        HStack {
                            Image(systemName: "envelope")
                                .frame(width: 30)
                            Text("Email")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Copy to Clipboard
                Button(action: copyToClipboard) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .frame(width: 30)
                        Text("Copy to Clipboard")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())

                // System Share Sheet
                Button(action: showSystemShare) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 30)
                        Text("More Options")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)

            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .padding()
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .alert("File Saved", isPresented: $showingSaveAlert) {
            Button("OK") {}
        } message: {
            Text(saveMessage)
        }
        .alert("Email", isPresented: $showingEmailAlert) {
            Button("OK") {}
        } message: {
            Text("Email functionality is not available on this device")
        }
    }

    private func saveToFiles() {
        Task {
            let result = await fileService.saveFile(
                reportContent,
                "SAM_Report_\(Date().formatted(.dateTime.year().month().day())).txt",
                ["txt"]
            )

            switch result {
            case let .success(url):
                saveMessage = "Report saved to: \(url.lastPathComponent)"
                showingSaveAlert = true
            case let .failure(error):
                saveMessage = "Failed to save: \(error.localizedDescription)"
                showingSaveAlert = true
            }
        }
    }

    private func sendEmail() {
        Task {
            let result = await emailService.showEmailComposer(
                [],
                "SAM.gov Report",
                reportContent
            )

            if case .failed = result {
                showingEmailAlert = true
            }
        }
    }

    private func copyToClipboard() {
        Task {
            await clipboardService.copyText(reportContent)
            saveMessage = "Report copied to clipboard"
            showingSaveAlert = true
        }
    }

    private func showSystemShare() {
        Task {
            do {
                let fileURL = try await shareService.createShareableFile(
                    reportContent,
                    "SAM_Report.txt"
                )
                let success = await shareService.share([fileURL])
                if !success {
                    saveMessage = "Share cancelled"
                    showingSaveAlert = true
                }
            } catch {
                saveMessage = "Failed to share: \(error.localizedDescription)"
                showingSaveAlert = true
            }
        }
    }
}

// Helper view for check items
struct CheckItem: View {
    let icon: String
    let text: String
    let status: CheckStatus

    enum CheckStatus {
        case passed, failed, warning

        var color: Color {
            switch self {
            case .passed: .green
            case .failed: .red
            case .warning: .orange
            }
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(status.color)
                .font(.system(size: 20))

            Text(text)
                .foregroundColor(.white.opacity(0.9))
                .font(.subheadline)

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// Preview
struct SAMReportPreview_Previews: PreviewProvider {
    static var previews: some View {
        SAMReportPreview()
            .preferredColorScheme(.dark)
    }
}
