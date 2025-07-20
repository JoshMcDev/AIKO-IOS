import AppCore
import ComposableArchitecture
import SwiftUI

public struct FormSelectionView: View {
    @State private var formMappingService = FormMappingService.shared
    @Environment(\.dismiss) var dismiss

    let documentType: DocumentType
    let templateData: TemplateData
    @Binding var selectedForm: FormType?
    @State private var showingFormPreview = false
    @State private var previewFormType: FormType?
    @State private var downloadProgress: Double = 0
    @State private var isDownloading = false
    @State private var downloadError: String?
    @State private var availableForms: [FormSelection] = []

    public init(documentType: DocumentType, templateData: TemplateData, selectedForm: Binding<FormType?>) {
        self.documentType = documentType
        self.templateData = templateData
        _selectedForm = selectedForm
    }

    public var body: some View {
        SwiftUI.NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Select Output Format")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Choose how you want to generate this \(documentType.shortName)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(Theme.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black)

                Divider()

                // Form Options
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // AIKO Template Option
                        aikoTemplateOption

                        // Official Form Options
                        if !availableForms.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                                HStack {
                                    Image(systemName: "doc.badge.gearshape")
                                        .foregroundColor(.blue)
                                    Text("Official Government Forms")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, Theme.Spacing.lg)

                                ForEach(availableForms) { formSelection in
                                    formOptionCard(formSelection)
                                }
                            }
                        } else {
                            // No forms available
                            VStack(spacing: Theme.Spacing.md) {
                                Image(systemName: "doc.badge.ellipsis")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)

                                Text("No official forms available")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text("This template type doesn't have corresponding government forms")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.lg)
                }
                .background(Theme.Colors.aikoBackground)
            }
            .navigationTitle("Output Format")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .sheet(isPresented: $showingFormPreview) {
                    if let formType = previewFormType {
                        FormPreviewView(formType: formType)
                    }
                }
                .alert("Download Error", isPresented: .constant(downloadError != nil)) {
                    Button("OK") {
                        downloadError = nil
                    }
                } message: {
                    Text(downloadError ?? "")
                }
                .task {
                    await loadAvailableForms()
                }
        }
    }

    // MARK: - Computed Properties
    
    private func loadAvailableForms() async {
        let forms = await formMappingService.getFormsForTemplate(documentType)
        let formSelections = forms.map { form in
            let isRecommended = isFormRecommended(form)
            let complianceScore = calculateComplianceScore(form)
            let notes = generateFormNotes(form)

            return FormSelection(
                formType: form.formType,
                isRecommended: isRecommended,
                complianceScore: complianceScore,
                notes: notes
            )
        }
        await MainActor.run {
            self.availableForms = formSelections
        }
    }

    // MARK: - View Components

    private var aikoTemplateOption: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AIKO Enhanced Template")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Button(action: {
                selectedForm = nil // nil means use AIKO template
                dismiss()
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.title2)
                                .foregroundColor(.purple)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("AIKO Template")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text("AI-enhanced with smart formatting")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }

                            Spacer()

                            // Recommended badge
                            Text("RECOMMENDED")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.purple)
                                )
                        }

                        HStack(spacing: Theme.Spacing.md) {
                            Label("FAR Compliant", systemImage: "checkmark.shield")
                                .font(.caption)
                                .foregroundColor(.green)

                            Label("Smart Fields", systemImage: "brain")
                                .font(.caption)
                                .foregroundColor(.blue)

                            Label("Export Ready", systemImage: "square.and.arrow.up")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(Theme.Spacing.lg)

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .padding(.trailing, Theme.Spacing.lg)
                }
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(Theme.Colors.aikoSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                .stroke(Color.purple.opacity(0.5), lineWidth: 2)
                        )
                )
                .padding(.horizontal, Theme.Spacing.lg)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func formOptionCard(_ formSelection: FormSelection) -> some View {
        Button(action: {
            selectedForm = formSelection.formType
            dismiss()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Image(systemName: formSelection.formType.icon)
                            .font(.title2)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(formSelection.formType.shortName)
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(formSelection.formType.description)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(2)
                        }

                        Spacer()

                        if formSelection.isRecommended {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }

                    // Compliance indicator
                    HStack {
                        ProgressView(value: formSelection.complianceScore)
                            .progressViewStyle(LinearProgressViewStyle())
                            .tint(complianceColor(for: formSelection.complianceScore))
                            .frame(width: 100)

                        Text("\(Int(formSelection.complianceScore * 100))% Match")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer()

                        // Action buttons
                        HStack(spacing: Theme.Spacing.sm) {
                            Button(action: {
                                previewFormType = formSelection.formType
                                showingFormPreview = true
                            }) {
                                Image(systemName: "eye")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(BorderlessButtonStyle())

                            Button(action: {
                                downloadBlankForm(formSelection.formType)
                            }) {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }

                    if let notes = formSelection.notes {
                        Text(notes)
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.top, 4)
                    }
                }
                .padding(Theme.Spacing.lg)

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .padding(.trailing, Theme.Spacing.lg)
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.aikoSecondary)
            )
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Methods

    private func isFormRecommended(_ form: FormDefinition) -> Bool {
        // Logic to determine if form is recommended
        switch (documentType, form.formType) {
        case (.requestForQuoteSimplified, .sf18),
             (.contractScaffold, .sf1449),
             (.requestForProposal, .sf1449):
            true
        default:
            false
        }
    }

    private func calculateComplianceScore(_ form: FormDefinition) -> Double {
        // Calculate how well the template matches the form
        let requiredFieldsCount = form.requiredFields.count
        let matchingFields = form.requiredFields.filter { field in
            templateData.data[field] != nil
        }.count

        return requiredFieldsCount > 0 ? Double(matchingFields) / Double(requiredFieldsCount) : 0.5
    }

    private func generateFormNotes(_ form: FormDefinition) -> String? {
        if let threshold = form.threshold,
           let amount = templateData.data["totalAmount"] as? Double,
           amount > threshold
        {
            return "Amount exceeds form threshold of \(formatCurrency(threshold))"
        }
        return nil
    }

    private func complianceColor(for score: Double) -> Color {
        switch score {
        case 0.8 ... 1.0:
            .green
        case 0.5 ..< 0.8:
            .orange
        default:
            .red
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func downloadBlankForm(_ formType: FormType) {
        isDownloading = true
        downloadError = nil

        Task {
            do {
                let data = try await formMappingService.generateBlankForm(formType)

                // Save to documents
                await MainActor.run {
                    saveFormToDocuments(data, formType: formType)
                    isDownloading = false
                }
            } catch {
                await MainActor.run {
                    downloadError = error.localizedDescription
                    isDownloading = false
                }
            }
        }
    }

    private func saveFormToDocuments(_: Data, formType: FormType) {
        // Implementation would save to documents directory
        // For now, just show success
        print("Form \(formType.shortName) downloaded successfully")
    }
}

// MARK: - Form Preview View

struct FormPreviewView: View {
    let formType: FormType
    @Environment(\.dismiss) var dismiss
    @State private var previewURL: URL?

    var body: some View {
        SwiftUI.NavigationView {
            VStack {
                if let url = previewURL {
                    // In a real app, this would show a web view or PDF viewer
                    VStack(spacing: Theme.Spacing.lg) {
                        Image(systemName: formType.icon)
                            .font(.system(size: 64))
                            .foregroundColor(.blue)

                        Text(formType.fullName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(formType.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Link("Open in Browser", destination: url)
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.top)
                    }
                    .padding()
                } else {
                    Text("Preview not available")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Form Preview")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .task {
            previewURL = await FormMappingService.shared.getFormPreviewURL(formType)
        }
    }
}
