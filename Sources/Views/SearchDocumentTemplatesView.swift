import AppCore
import ComposableArchitecture
import SwiftUI

public struct SearchDocumentTemplatesView: View {
    @Environment(\.dismiss) var dismiss
    @Dependency(\.templateStorageService) var storageService

    @State private var searchText = ""
    @State private var selectedCategory: DocumentCategory = .all
    @State private var showingUploadOptions = false
    @State private var showingCreateTemplate = false
    @State private var selectedTemplateType: DocumentType?
    @State private var showingTemplateDetail = false
    @State private var detailTemplateType: DocumentType?
    @State private var customTemplates: [CustomTemplate] = []
    @State private var officeTemplates: [DocumentType: [OfficeTemplate]] = [:]
    @State private var showingCustomTemplateDetail = false
    @State private var selectedCustomTemplate: CustomTemplate?

    public init() {}

    enum DocumentCategory: String, CaseIterable {
        case all = "All Categories"
        case requirements = "Requirements"
        case marketIntelligence = "Market Intelligence"
        case planning = "Acquisition Planning"
        case determinationFindings = "D&F"
        case solicitation = "Solicitation"
        case award = "Award"
        case analytics = "Analytics"

        var icon: String {
            switch self {
            case .all: "square.grid.2x2"
            case .requirements: "doc.text.fill"
            case .marketIntelligence: "chart.line.uptrend.xyaxis"
            case .planning: "calendar"
            case .determinationFindings: "checkmark.seal.fill"
            case .solicitation: "envelope.circle.fill"
            case .award: "rosette"
            case .analytics: "chart.bar.xaxis"
            }
        }
    }

    public var body: some View {
        SwiftUI.NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: Theme.Spacing.medium) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)

                        TextField("Search templates...", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.vertical, Theme.Spacing.small)
                    .background(Theme.Colors.aikoSecondary)
                    .cornerRadius(Theme.CornerRadius.small)

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.small) {
                            ForEach(DocumentCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    onTap: { selectedCategory = category }
                                )
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.large)
                .background(Color.black)

                // Templates Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: Theme.Spacing.medium),
                        GridItem(.flexible(), spacing: Theme.Spacing.medium)
                    ], spacing: Theme.Spacing.medium) {
                        // Filter and display document types
                        ForEach(filteredDocumentTypes, id: \.self) { documentType in
                            TemplateCard(
                                documentType: documentType,
                                officeTemplateCount: officeTemplates[documentType]?.count ?? 0,
                                onSelect: {
                                    // Show template detail view
                                    detailTemplateType = documentType
                                    showingTemplateDetail = true
                                }
                            )
                        }

                        // Display custom templates
                        ForEach(filteredCustomTemplates) { template in
                            CustomTemplateCard(
                                template: template,
                                onSelect: {
                                    selectedCustomTemplate = template
                                    showingCustomTemplateDetail = true
                                },
                                onDelete: {
                                    deleteCustomTemplate(template)
                                }
                            )
                        }

                        // Add custom template card
                        AddTemplateCard(
                            onUpload: { showingUploadOptions = true },
                            onCreate: {
                                selectedTemplateType = nil
                                showingCreateTemplate = true
                            }
                        )
                    }
                    .padding(Theme.Spacing.large)
                }
                .background(Theme.Colors.aikoBackground)
            }
            .navigationTitle("Document Templates")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            selectedTemplateType = nil
                            showingCreateTemplate = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .sheet(isPresented: $showingUploadOptions) {
                    UploadTemplateView(onComplete: { template in
                        // Handle uploaded template
                        Task {
                            do {
                                let customTemplate = CustomTemplate(
                                    name: template.name,
                                    category: template.category,
                                    description: template.description,
                                    content: String(data: template.data ?? Data(), encoding: .utf8) ?? ""
                                )
                                try await storageService.saveTemplate(customTemplate)
                                loadCustomTemplates()
                                showingUploadOptions = false
                            } catch {
                                print("Failed to save template: \(error)")
                            }
                        }
                    })
                }
                .sheet(isPresented: $showingCreateTemplate) {
                    CreateTemplateView(
                        documentType: selectedTemplateType,
                        onComplete: { template in
                            // Handle created template
                            Task {
                                do {
                                    let customTemplate = CustomTemplate(
                                        name: template.name,
                                        category: template.category,
                                        description: template.description,
                                        content: String(data: template.data ?? Data(), encoding: .utf8) ?? ""
                                    )
                                    try await storageService.saveTemplate(customTemplate)
                                    loadCustomTemplates()
                                    showingCreateTemplate = false
                                } catch {
                                    print("Failed to save template: \(error)")
                                }
                            }
                        }
                    )
                }
                .sheet(isPresented: $showingTemplateDetail) {
                    if let templateType = detailTemplateType {
                        TemplateDetailView(documentType: templateType)
                    }
                }
                .sheet(isPresented: $showingCustomTemplateDetail) {
                    if let template = selectedCustomTemplate {
                        CustomTemplateDetailView(template: template)
                    }
                }
                .onAppear {
                    loadCustomTemplates()
                    loadOfficeTemplates()
                }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Helper Methods

    private func loadCustomTemplates() {
        Task {
            do {
                let templates = try await storageService.loadTemplates()
                await MainActor.run {
                    customTemplates = templates
                }
            } catch {
                print("Failed to load custom templates: \(error)")
            }
        }
    }

    private func loadOfficeTemplates() {
        Task {
            do {
                var templates: [DocumentType: [OfficeTemplate]] = [:]
                for documentType in DocumentType.allCases {
                    let officeTemplatesList = try await storageService.loadOfficeTemplates(documentType)
                    if !officeTemplatesList.isEmpty {
                        templates[documentType] = officeTemplatesList
                    }
                }
                await MainActor.run {
                    officeTemplates = templates
                }
            } catch {
                print("Failed to load office templates: \(error)")
            }
        }
    }

    private func deleteCustomTemplate(_ template: CustomTemplate) {
        Task {
            do {
                try await storageService.deleteTemplate(template.id)
                loadCustomTemplates()
            } catch {
                print("Failed to delete template: \(error)")
            }
        }
    }

    private var filteredDocumentTypes: [DocumentType] {
        let allTypes = DocumentType.allCases

        // Filter by category
        let categoryFiltered: [DocumentType] = switch selectedCategory {
        case .all:
            allTypes
        case .requirements:
            allTypes.filter { docType in
                [DocumentType.sow, DocumentType.pws, DocumentType.soo, DocumentType.rrd, DocumentType.qasp].contains(docType)
            }
        case .marketIntelligence:
            allTypes.filter { docType in
                [DocumentType.marketResearch, DocumentType.sourcesSought, DocumentType.industryRFI, DocumentType.costEstimate, DocumentType.procurementSourcing].contains(docType)
            }
        case .planning:
            allTypes.filter { docType in
                [DocumentType.acquisitionPlan, DocumentType.competitionAnalysis, DocumentType.fiscalLawReview].contains(docType)
            }
        case .determinationFindings:
            allTypes.filter { docType in
                [DocumentType.justificationApproval].contains(docType)
            }
        case .solicitation:
            allTypes.filter { docType in
                [DocumentType.requestForQuoteSimplified, DocumentType.requestForQuote, DocumentType.requestForProposal, DocumentType.evaluationPlan].contains(docType)
            }
        case .award:
            allTypes.filter { docType in
                [DocumentType.contractScaffold, DocumentType.corAppointment, DocumentType.otherTransactionAgreement].contains(docType)
            }
        case .analytics:
            allTypes.filter { docType in
                [DocumentType.analytics, DocumentType.codes, DocumentType.opsecReview].contains(docType)
            }
        }

        // Filter by search text
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { type in
                type.shortName.localizedCaseInsensitiveContains(searchText) ||
                    type.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private var filteredCustomTemplates: [CustomTemplate] {
        let categoryFiltered: [CustomTemplate] = if selectedCategory == .all {
            customTemplates
        } else {
            customTemplates.filter { $0.category == selectedCategory.rawValue }
        }

        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                    template.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct CategoryChip: View {
    let category: SearchDocumentTemplatesView.DocumentCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.caption)

                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.vertical, Theme.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(isSelected ? Theme.Colors.aikoAccent : Theme.Colors.aikoSecondary)
            )
        }
    }
}

struct TemplateCard: View {
    let documentType: DocumentType
    let officeTemplateCount: Int
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                // Icon and status
                HStack {
                    Image(systemName: documentType.icon)
                        .font(.title2)
                        .foregroundColor(.blue)

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }

                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(documentType.shortName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(documentType.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Template info
                VStack(alignment: .leading, spacing: Theme.Spacing.extraSmall) {
                    // FAR Reference
                    HStack {
                        Image(systemName: "book.closed")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(String(documentType.farReference.split(separator: ",").first ?? Substring(documentType.farReference)))
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }

                    HStack {
                        Label("FAR Compliant", systemImage: "checkmark.shield")
                            .font(.caption2)
                            .foregroundColor(.green)

                        Spacer()

                        if officeTemplateCount > 0 {
                            Label("\(officeTemplateCount)", systemImage: "building.2")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }

                        Text("v2.1")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(Theme.Spacing.large)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .fill(Theme.Colors.aikoSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CustomTemplateCard: View {
    let template: CustomTemplate
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                // Icon and status
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .font(.title2)
                        .foregroundColor(.purple)

                    Spacer()

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Template info
                HStack {
                    Label("Custom Template", systemImage: "person.circle")
                        .font(.caption2)
                        .foregroundColor(.purple)

                    Spacer()

                    Text(template.category)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(Theme.Spacing.large)
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .fill(Theme.Colors.aikoSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct AddTemplateCard: View {
    let onUpload: () -> Void
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("Add Custom Template")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: Theme.Spacing.small) {
                Button(action: onUpload) {
                    Label("Upload Template", systemImage: "arrow.up.doc")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                Button(action: onCreate) {
                    Label("Create with AI", systemImage: "brain")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .fill(Theme.Colors.aikoSecondary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(.blue.opacity(0.5))
                )
        )
    }
}

// MARK: - Upload Template View

struct UploadTemplateView: View {
    @Environment(\.dismiss) var dismiss
    let onComplete: (SimpleCustomTemplate) -> Void

    @State private var templateName = ""
    @State private var templateCategory = SearchDocumentTemplatesView.DocumentCategory.requirements
    @State private var templateDescription = ""
    @State private var showingDocumentPicker = false
    @State private var uploadedDocument: Data?
    @State private var documentName = ""

    var body: some View {
        SwiftUI.NavigationView {
            Form {
                Section("Template Information") {
                    TextField("Template Name", text: $templateName)

                    Picker("Category", selection: $templateCategory) {
                        ForEach(SearchDocumentTemplatesView.DocumentCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }

                    TextField("Description", text: $templateDescription, axis: .vertical)
                        .lineLimit(3 ... 6)
                }

                Section("Upload Document") {
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
            }
            .navigationTitle("Upload Template")
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
                            // Create and save template
                            let template = SimpleCustomTemplate(
                                name: templateName,
                                category: templateCategory.rawValue,
                                description: templateDescription,
                                data: uploadedDocument
                            )
                            onComplete(template)
                        }
                        .disabled(templateName.isEmpty || uploadedDocument == nil)
                    }
                }
        }
    }
}

// MARK: - Create Template View

struct CreateTemplateView: View {
    @Environment(\.dismiss) var dismiss
    let documentType: DocumentType?
    let onComplete: (SimpleCustomTemplate) -> Void

    @State private var templateName = ""
    @State private var templateCategory = SearchDocumentTemplatesView.DocumentCategory.requirements
    @State private var templateDescription = ""
    @State private var templateContent = ""
    @State private var isGenerating = false

    var body: some View {
        SwiftUI.NavigationView {
            VStack(spacing: 0) {
                // AI Assistant Header
                VStack(spacing: Theme.Spacing.medium) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)

                    Text("AI Template Creator")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("I'll help you create a custom document template")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, Theme.Spacing.extraLarge)

                // Form
                Form {
                    Section("Template Details") {
                        TextField("Template Name", text: $templateName)

                        Picker("Category", selection: $templateCategory) {
                            ForEach(SearchDocumentTemplatesView.DocumentCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                                Label(category.rawValue, systemImage: category.icon)
                                    .tag(category)
                            }
                        }

                        TextField("What should this template do?", text: $templateDescription, axis: .vertical)
                            .lineLimit(3 ... 6)
                    }

                    Section("Template Requirements") {
                        TextField("Describe the specific requirements for this template...", text: $templateContent, axis: .vertical)
                            .lineLimit(5 ... 10)
                    }

                    Section {
                        Button(action: generateTemplate) {
                            if isGenerating {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                    Text("Generating template...")
                                }
                            } else {
                                Label("Generate Template", systemImage: "sparkles")
                            }
                        }
                        .disabled(templateName.isEmpty || templateDescription.isEmpty || isGenerating)
                    }
                }
            }
            .navigationTitle("Create Template")
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
                            // Create and save template
                            let template = SimpleCustomTemplate(
                                name: templateName,
                                category: templateCategory.rawValue,
                                description: templateDescription,
                                data: templateContent.data(using: .utf8)
                            )
                            onComplete(template)
                        }
                        .disabled(templateName.isEmpty || templateContent.isEmpty)
                    }
                }
        }
    }

    private func generateTemplate() {
        isGenerating = true

        // Simulate AI generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            templateContent = """
            [Generated template content based on requirements]

            This template includes:
            - Section 1: Overview
            - Section 2: Requirements
            - Section 3: Compliance
            - Section 4: Deliverables

            [Template will be customized based on your specific needs]
            """
            isGenerating = false
        }
    }
}

// MARK: - Models

struct SimpleCustomTemplate {
    let name: String
    let category: String
    let description: String
    let data: Data?
}

// MARK: - Preview

#if DEBUG
    struct SearchDocumentTemplatesView_Previews: PreviewProvider {
        static var previews: some View {
            SearchDocumentTemplatesView()
                .preferredColorScheme(.dark)
        }
    }
#endif
