import AppCore
import ComposableArchitecture
import SwiftUI

public struct TemplateDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Dependency(\.standardTemplateService) var templateService
    @Dependency(\.templateStorageService) var storageService

    let documentType: DocumentType
    @State private var isEditing = false
    @State private var showingUploadOfficeTemplate = false
    @State private var templateContent: String = ""
    @State private var editedContent: String = ""
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var officeTemplates: [OfficeTemplate] = []
    @State private var showingSaveConfirmation = false

    public init(documentType: DocumentType) {
        self.documentType = documentType
    }

    public var body: some View {
        SwiftUI.NavigationView {
            VStack(spacing: 0) {
                // Template Info Header
                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    HStack {
                        Image(systemName: documentType.icon)
                            .font(.title)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(documentType.shortName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text(documentType.description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Spacer()

                        // Template status
                        VStack(alignment: .trailing, spacing: 4) {
                            Label("FAR Compliant", systemImage: "checkmark.shield.fill")
                                .font(.caption)
                                .foregroundColor(.green)

                            if !officeTemplates.isEmpty {
                                Label("\(officeTemplates.count) Office Variant\(officeTemplates.count == 1 ? "" : "s")", systemImage: "building.2")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }

                            Text("Version 2.1")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    // FAR References
                    farReferencesSection

                    // Action buttons
                    HStack(spacing: Theme.Spacing.medium) {
                        Button(action: { showingUploadOfficeTemplate = true }) {
                            Label("Upload Office Template", systemImage: "square.and.arrow.up")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.horizontal, Theme.Spacing.medium)
                                .padding(.vertical, Theme.Spacing.small)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        .fill(Theme.Colors.aikoSecondary)
                                )
                        }

                        // Share button
                        if !isEditing {
                            ShareButton(
                                content: generateTemplateShareContent(),
                                fileName: DocumentShareHelper.generateFileName(for: .template),
                                buttonStyle: .icon
                            )
                            .padding(.horizontal, Theme.Spacing.small)
                        }

                        Spacer()

                        Button(action: {
                            if isEditing {
                                saveChanges()
                            } else {
                                startEditing()
                            }
                        }) {
                            Label(isEditing ? "Save Changes" : "Edit Template",
                                  systemImage: isEditing ? "checkmark.circle" : "pencil.circle")
                                .font(.subheadline)
                                .foregroundColor(isEditing ? .green : .blue)
                                .padding(.horizontal, Theme.Spacing.medium)
                                .padding(.vertical, Theme.Spacing.small)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        .fill(isEditing ? Color.green.opacity(0.2) : Theme.Colors.aikoSecondary)
                                )
                        }

                        if isEditing {
                            Button(action: cancelEditing) {
                                Label("Cancel", systemImage: "xmark.circle")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, Theme.Spacing.medium)
                                    .padding(.vertical, Theme.Spacing.small)
                                    .background(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                            .fill(Color.red.opacity(0.2))
                                    )
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.large)
                .background(Color.black)

                Divider()

                // Template Content
                ScrollView {
                    if isLoading {
                        VStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(1.5)
                            Text("Loading template...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 100)
                    } else if let error = loadError {
                        VStack(spacing: Theme.Spacing.large) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)

                            Text("Failed to load template")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Button("Retry") {
                                loadTemplateContent()
                            }
                            .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else if isEditing {
                        TextEditor(text: $editedContent)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(Theme.Spacing.large)
                            .background(Theme.Colors.aikoSecondary)
                            .cornerRadius(Theme.CornerRadius.md)
                            .padding(Theme.Spacing.large)
                    } else {
                        Text(templateContent)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(Theme.Spacing.large)
                            .background(Theme.Colors.aikoSecondary)
                            .cornerRadius(Theme.CornerRadius.md)
                            .padding(Theme.Spacing.large)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .background(Theme.Colors.aikoBackground)
            }
            .navigationTitle("Template Details")
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
                .onAppear {
                    loadTemplateContent()
                }
                .sheet(isPresented: $showingUploadOfficeTemplate) {
                    UploadOfficeTemplateView(
                        documentType: documentType,
                        storageService: storageService,
                        onComplete: { officeTemplate in
                            // Handle office template upload
                            Task {
                                do {
                                    try await storageService.saveOfficeTemplate(officeTemplate)
                                    await MainActor.run {
                                        officeTemplates.append(officeTemplate)
                                        showingUploadOfficeTemplate = false
                                    }
                                } catch {
                                    // Handle error
                                    print("Failed to save office template: \(error)")
                                }
                            }
                        }
                    )
                }
        }
        .preferredColorScheme(.dark)
        .overlay(
            // Save confirmation overlay
            showingSaveConfirmation ?
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Template saved successfully")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.2))
                            .background(
                                Capsule()
                                    .stroke(Color.green, lineWidth: 1)
                            )
                    )
                    .padding(.bottom, 50)
                }
                .animation(.easeInOut, value: showingSaveConfirmation)
                : nil
        )
    }

    private func loadTemplateContent() {
        isLoading = true
        loadError = nil

        Task {
            do {
                // First check if there's an edited version
                if let editedTemplate = try await storageService.loadEditedTemplate(documentType) {
                    // Load the edited template
                    await MainActor.run {
                        templateContent = editedTemplate
                        isLoading = false
                    }
                } else {
                    // Load the original template from the template service
                    let template = try await templateService.loadTemplate(documentType)

                    await MainActor.run {
                        templateContent = template
                        isLoading = false
                    }
                }

                // Load office templates
                let officeTemplatesList = try await storageService.loadOfficeTemplates(documentType)
                await MainActor.run {
                    officeTemplates = officeTemplatesList
                }
            } catch {
                await MainActor.run {
                    loadError = error.localizedDescription
                    isLoading = false

                    // Fallback to a basic template if loading fails
                    templateContent = createFallbackTemplate()
                }
            }
        }
    }

    private func createFallbackTemplate() -> String {
        """
        # \(documentType.shortName) Template

        **Note:** The actual template could not be loaded. This is a basic fallback template.

        ## Document Information
        - Type: \(documentType.rawValue)
        - Description: \(documentType.description)

        ## Template Structure

        ### 1. Overview
        [Provide an overview of the \(documentType.shortName)]

        ### 2. Requirements
        [Detail the specific requirements]

        ### 3. Deliverables
        [List expected deliverables]

        ### 4. Terms and Conditions
        [Include relevant terms]

        ### 5. Appendices
        [Add supporting documentation]

        ---
        *This is a fallback template. Please contact support if you need the full FAR-compliant template.*
        """
    }

    private func startEditing() {
        editedContent = templateContent
        isEditing = true
    }

    private func saveChanges() {
        Task {
            do {
                try await storageService.saveEditedTemplate(documentType, editedContent)
                await MainActor.run {
                    templateContent = editedContent
                    isEditing = false
                    showingSaveConfirmation = true

                    // Hide confirmation after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showingSaveConfirmation = false
                    }
                }
            } catch {
                // Handle error
                await MainActor.run {
                    loadError = "Failed to save changes: \(error.localizedDescription)"
                }
            }
        }
    }

    private func cancelEditing() {
        editedContent = ""
        isEditing = false
    }

    private func generateTemplateShareContent() -> String {
        """
        Document Template: \(documentType.rawValue)
        Generated: \(Date().formatted())

        TEMPLATE INFORMATION:
        - Name: \(documentType.shortName)
        - Description: \(documentType.description)

        CONTENT:
        \(templateContent)
        """
    }

    @ViewBuilder
    private var farReferencesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraSmall) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("FAR/DFAR References")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            Text(documentType.farReference)
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, Theme.Spacing.extraSmall)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.1))
                )
        }
        .padding(.top, Theme.Spacing.small)
    }
}

// MARK: - Upload Office Template View

struct UploadOfficeTemplateView: View {
    @Environment(\.dismiss) var dismiss
    let documentType: DocumentType
    let storageService: TemplateStorageService
    let onComplete: (OfficeTemplate) -> Void

    @State private var officeName = ""
    @State private var templateDescription = ""
    @State private var showingDocumentPicker = false
    @State private var uploadedDocument: Data?
    @State private var documentName = ""

    var body: some View {
        SwiftUI.NavigationView {
            Form {
                Section("Office Information") {
                    TextField("Office/Department Name", text: $officeName)
                    TextField("Template Description", text: $templateDescription, axis: .vertical)
                        .lineLimit(3 ... 6)
                }

                Section("Template Type") {
                    HStack {
                        Image(systemName: documentType.icon)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(documentType.shortName)
                                .font(.headline)
                            Text("This will create an office-specific variant")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Upload Template File") {
                    if let _ = uploadedDocument {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                            Text(documentName)
                            Spacer()
                            Button("Remove") {
                                uploadedDocument = nil
                                documentName = ""
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        Button(action: { showingDocumentPicker = true }) {
                            Label("Select Document", systemImage: "arrow.up.doc")
                        }
                    }
                }

                Section {
                    Text("This template will be saved as a user-defined variant and will appear alongside the standard template.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Upload Office Template")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if let data = uploadedDocument {
                                let content = String(data: data, encoding: .utf8) ?? ""
                                let template = OfficeTemplate(
                                    documentType: documentType,
                                    officeName: officeName,
                                    description: templateDescription,
                                    content: content
                                )
                                onComplete(template)
                            }
                        }
                        .disabled(officeName.isEmpty || uploadedDocument == nil)
                    }
                }
        }
    }
}

// MARK: - Models

// Note: OfficeTemplate is now defined in TemplateStorageService.swift

// MARK: - Preview

#if DEBUG
    struct TemplateDetailView_Previews: PreviewProvider {
        static var previews: some View {
            SwiftUI.NavigationView {
                TemplateDetailView(documentType: .sow)
            }
            .preferredColorScheme(.dark)
        }
    }
#endif
