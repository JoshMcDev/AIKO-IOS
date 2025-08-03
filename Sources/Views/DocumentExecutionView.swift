import SwiftUI
import AppCore
#if os(macOS)
import AppKit
#endif

/// DocumentExecutionView - Federal Document Generation & Execution Interface
/// PHASE 2: Business Logic View for document workflow management
/// Handles document generation, progress tracking, and document lifecycle
public struct DocumentExecutionView: View {
    @State private var viewModel: DocumentExecutionViewModel

    public init(acquisition: AppCore.Acquisition) {
        self._viewModel = State(wrappedValue: DocumentExecutionViewModel(acquisition: acquisition))
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
                headerSection

                // Document Types Section
                documentTypesSection

                // Generated Documents Section
                if viewModel.hasGeneratedDocuments {
                    generatedDocumentsSection
                }

                // Content Area
                contentView
            }
            .navigationTitle("Document Execution")
            .toolbar {
                ToolbarItem(placement: toolbarPlacement) {
                    toolbarContent
                }
            }
            .task {
                await viewModel.loadAvailableDocumentTypes()
                await viewModel.loadGeneratedDocuments()
            }
            .sheet(isPresented: $viewModel.showingDocumentPreview) {
                if let document = viewModel.selectedDocumentForPreview {
                    DocumentPreviewView(document: document)
                }
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Acquisition: \(viewModel.acquisition.title)")
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let projectNumber = viewModel.acquisition.projectNumber {
                        Text("Project: \(projectNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Status Badge
                HStack(spacing: 4) {
                    Image(systemName: viewModel.acquisition.status.icon)
                        .font(.caption)
                    Text(viewModel.acquisition.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(viewModel.acquisition.status.color))
                .foregroundColor(.white)
                .clipShape(Capsule())
            }

            // Generation Status
            HStack {
                if viewModel.isGenerating {
                    ProgressView(value: viewModel.generationProgress)
                        .progressViewStyle(.linear)
                    Text(viewModel.generationStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(viewModel.generationStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(PlatformColors.headerBackground)
    }

    private var documentTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Available Document Types")
                    .font(.headline)
                Spacer()
                Button("Generate All") {
                    Task {
                        await viewModel.generateDocumentChain()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isGenerating)
            }

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(viewModel.availableDocumentTypes, id: \.self) { documentType in
                    DocumentTypeCard(documentType: documentType) {
                        Task {
                            await viewModel.generateDocument(documentType)
                        }
                    }
                    .disabled(viewModel.isGenerating)
                }
            }
        }
        .padding()
    }

    private var generatedDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Generated Documents (\(viewModel.generatedDocuments.count))")
                    .font(.headline)
                Spacer()
                Button("Clear All") {
                    viewModel.clearAllGeneratedDocuments()
                }
                .foregroundColor(.red)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.generatedDocuments) { document in
                        GeneratedDocumentCard(document: document) {
                            viewModel.showDocumentPreview(document)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(PlatformColors.generatedDocsBackground)
    }

    @ViewBuilder
    private var contentView: some View {
        if let errorMessage = viewModel.errorMessage {
            errorView(errorMessage)
        } else if viewModel.isGenerating {
            generatingView
        } else if !viewModel.hasGeneratedDocuments && viewModel.availableDocumentTypes.isEmpty {
            emptyStateView
        } else {
            // Main content area - placeholder for now
            VStack {
                Text("Select a document type to generate")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("Or generate all documents for this acquisition")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Error")
                .font(.headline)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                viewModel.clearError()
                Task {
                    await viewModel.loadAvailableDocumentTypes()
                    await viewModel.loadGeneratedDocuments()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var generatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)

            Text("Generating Documents...")
                .font(.headline)

            Text(viewModel.generationStatusText)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.below.ecg")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Document Types Available")
                .font(.headline)

            Text("Check acquisition status or try refreshing")
                .font(.body)
                .foregroundColor(.secondary)

            Button("Refresh") {
                Task {
                    await viewModel.loadAvailableDocumentTypes()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var toolbarContent: some View {
        HStack {
            if viewModel.hasGeneratedDocuments {
                Text("\(viewModel.generatedDocuments.count) Generated")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }

            Menu {
                Button("Refresh Types") {
                    Task {
                        await viewModel.loadAvailableDocumentTypes()
                    }
                }
                Button("Reload Documents") {
                    Task {
                        await viewModel.loadGeneratedDocuments()
                    }
                }
                if viewModel.hasGeneratedDocuments {
                    Divider()
                    Button("Clear All", role: .destructive) {
                        viewModel.clearAllGeneratedDocuments()
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Platform-Specific Properties

    private var gridColumns: [GridItem] {
        #if os(iOS)
        [GridItem(.adaptive(minimum: 150, maximum: 200))]
        #else
        [GridItem(.adaptive(minimum: 180, maximum: 240))]
        #endif
    }

    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #else
        return .automatic
        #endif
    }

    // MARK: - Platform-Specific Colors

    enum PlatformColors {
        static var headerBackground: Color {
            #if os(iOS)
            Color(.systemGroupedBackground)
            #else
            Color(NSColor.controlBackgroundColor)
            #endif
        }

        static var generatedDocsBackground: Color {
            #if os(iOS)
            Color(.systemGray6)
            #else
            Color(NSColor.separatorColor)
            #endif
        }

        static var cardBackground: Color {
            #if os(iOS)
            Color(.systemBackground)
            #else
            Color(NSColor.controlBackgroundColor)
            #endif
        }
    }
}

// MARK: - Supporting Views

/// Document type card for selection and generation
private struct DocumentTypeCard: View {
    let documentType: DocumentType
    let onGenerate: () -> Void

    var body: some View {
        Button(action: onGenerate) {
            VStack(spacing: 8) {
                Image(systemName: documentType.icon)
                    .font(.title2)
                    .foregroundColor(.blue)

                Text(documentType.shortName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(documentType.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(DocumentExecutionView.PlatformColors.cardBackground)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

/// Generated document card for preview
private struct GeneratedDocumentCard: View {
    let document: GeneratedDocument
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if let docType = document.documentType {
                        Image(systemName: docType.icon)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    Text(document.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text(document.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(document.content.count) characters")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .frame(width: 150, height: 80)
            .background(DocumentExecutionView.PlatformColors.cardBackground)
            .cornerRadius(6)
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 0.5)
        }
        .buttonStyle(.plain)
    }
}

/// Document preview view
private struct DocumentPreviewView: View {
    let document: GeneratedDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Document metadata
                    VStack(alignment: .leading, spacing: 8) {
                        if let docType = document.documentType {
                            HStack {
                                Image(systemName: docType.icon)
                                    .foregroundColor(.blue)
                                Text(docType.rawValue)
                                    .font(.headline)
                            }
                        }

                        Text("Created: \(document.createdAt, style: .date) at \(document.createdAt, style: .time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Document content
                    Text(document.content)
                        .font(.body)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle(document.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
