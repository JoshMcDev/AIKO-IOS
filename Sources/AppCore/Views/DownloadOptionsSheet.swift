import SwiftUI

// MARK: - Download Options Sheet

public struct DownloadOptionsSheet: View {
    let acquisition: Acquisition
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedDocuments: Set<UUID> = []
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0.0
    @State private var downloadError: DocumentManagerError?
    @State private var downloadResults: [DocumentDownloadResult] = []
    @State private var generatedDocuments: [GeneratedDocument] = []
    @State private var isLoadingDocuments = true
    
    // Inject document manager based on platform
    private let documentManager: DocumentManagerProtocol?
    
    public init(
        acquisition: Acquisition, 
        onDismiss: @escaping () -> Void,
        documentManager: DocumentManagerProtocol? = nil
    ) {
        self.acquisition = acquisition
        self.onDismiss = onDismiss
        
        // Use provided document manager or nil (will be properly injected via dependency container)
        self.documentManager = documentManager
    }

    @ViewBuilder
    private var documentList: some View {
        SwiftUI.List {
            Section {
                if generatedDocuments.isEmpty {
                    EmptyView()
                } else {
                    ForEach(generatedDocuments) { document in
                        DocumentDownloadRow(
                            document: document,
                            isSelected: selectedDocuments.contains(document.id),
                            onToggle: {
                                toggleDocumentSelection(document.id)
                            }
                        )
                    }
                }
            } header: {
                HStack {
                    Text("Available Documents")
                    Spacer()
                    if !generatedDocuments.isEmpty {
                        Button(selectedDocuments.count == generatedDocuments.count ? "Deselect All" : "Select All") {
                            toggleAllSelection()
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }

    public var body: some View {
        SwiftUI.NavigationView {
            VStack(spacing: 0) {
                if isLoadingDocuments {
                    ProgressView("Loading documents...")
                        .frame(maxHeight: .infinity)
                } else if generatedDocuments.isEmpty {
                    DocumentsEmptyStateView()
                } else {
                    VStack(spacing: 0) {
                        documentList
                        #if os(iOS)
                        .listStyle(InsetGroupedListStyle())
                        #else
                        .listStyle(PlainListStyle())
                        #endif

                        // Download buttons
                        VStack(spacing: Theme.Spacing.medium) {
                            if !selectedDocuments.isEmpty {
                                Button(action: downloadSelected) {
                                    Label(
                                        selectedDocuments.count == 1 ? "Download Selected Document" : "Download \(selectedDocuments.count) Documents",
                                        systemImage: "arrow.down.doc"
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.Colors.aikoPrimary)
                                    .foregroundColor(.white)
                                    .cornerRadius(Theme.CornerRadius.medium)
                                }
                                .disabled(isDownloading)
                            }

                            Button(action: downloadAll) {
                                Label("Download All Documents", systemImage: "arrow.down.doc.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.Colors.aikoAccent)
                                    .foregroundColor(.white)
                                    .cornerRadius(Theme.CornerRadius.medium)
                            }
                            .disabled(isDownloading)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Download Documents")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            if !isDownloading {
                                dismiss()
                            }
                        }
                        .disabled(isDownloading)
                    }
                }
                .alert("Download Error", isPresented: .init(
                    get: { downloadError != nil },
                    set: { _ in downloadError = nil }
                )) {
                    Button("OK") {
                        downloadError = nil
                    }
                } message: {
                    if let error = downloadError {
                        Text(error.localizedDescription)
                    }
                }
                .alert("Download Complete", isPresented: .init(
                    get: { !downloadResults.isEmpty && !isDownloading },
                    set: { _ in downloadResults = [] }
                )) {
                    Button("OK") {
                        downloadResults = []
                        onDismiss()
                    }
                } message: {
                    Text("Successfully downloaded \(downloadResults.filter(\.success).count) of \(downloadResults.count) documents.")
                }
                .overlay {
                    if isDownloading {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .overlay {
                                VStack(spacing: 16) {
                                    ProgressView(value: downloadProgress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle())
                                    
                                    Text("Downloading... \(Int(downloadProgress * 100))%")
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(Theme.CornerRadius.medium)
                            }
                    }
                }
        }
        .task {
            await loadDocuments()
        }
    }

    // MARK: - Document Loading
    
    private func loadDocuments() async {
        isLoadingDocuments = true
        
        // Generate sample documents for the acquisition
        // In a real implementation, this would fetch from Core Data or API
        let sampleDocuments = generateSampleDocuments(for: acquisition)
        
        await MainActor.run {
            generatedDocuments = sampleDocuments
            isLoadingDocuments = false
        }
    }
    
    private func generateSampleDocuments(for acquisition: Acquisition) -> [GeneratedDocument] {
        // Create sample documents based on acquisition data
        var documents: [GeneratedDocument] = []
        
        // Add standard acquisition documents
        documents.append(GeneratedDocument(
            title: "\(acquisition.title)_Summary.pdf",
            documentType: .acquisitionPlan,
            content: "Acquisition summary document"
        ))
        
        documents.append(GeneratedDocument(
            title: "\(acquisition.title)_Details.docx",
            documentType: .rrd,
            content: "Detailed acquisition information"
        ))
        
        // Add requirements document if available
        if !acquisition.requirements.isEmpty {
            documents.append(GeneratedDocument(
                title: "\(acquisition.title)_Requirements.txt",
                documentType: .rrd,
                content: acquisition.requirements
            ))
        }
        
        return documents
    }
    
    private func generatePDFContent(title: String, content: String) -> Data {
        // Simplified PDF-like content generation
        let pdfContent = """
        %PDF-1.4
        1 0 obj
        <<
        /Type /Catalog
        /Pages 2 0 R
        >>
        endobj
        
        2 0 obj
        <<
        /Type /Pages
        /Kids [3 0 R]
        /Count 1
        >>
        endobj
        
        3 0 obj
        <<
        /Type /Page
        /Parent 2 0 R
        /MediaBox [0 0 612 792]
        /Contents 4 0 R
        >>
        endobj
        
        4 0 obj
        <<
        /Length 44
        >>
        stream
        BT
        /F1 12 Tf
        100 700 Td
        (\(title)) Tj
        0 -20 Td
        (\(content)) Tj
        ET
        endstream
        endobj
        
        xref
        0 5
        0000000000 65535 f 
        0000000010 00000 n 
        0000000079 00000 n 
        0000000173 00000 n 
        0000000301 00000 n 
        trailer
        <<
        /Size 5
        /Root 1 0 R
        >>
        startxref
        380
        %%EOF
        """
        return Data(pdfContent.utf8)
    }
    
    private func generateWordContent(title: String, content: String) -> Data {
        // Simplified Word-like content (actually plain text with .docx extension)
        let wordContent = """
        \(title)
        
        \(content)
        
        Generated by AIKO Document System
        Date: \(Date().formatted())
        """
        return Data(wordContent.utf8)
    }
    
    // MARK: - Document Selection
    
    private func toggleDocumentSelection(_ documentId: UUID) {
        if selectedDocuments.contains(documentId) {
            selectedDocuments.remove(documentId)
        } else {
            selectedDocuments.insert(documentId)
        }
    }
    
    private func toggleAllSelection() {
        if selectedDocuments.count == generatedDocuments.count {
            selectedDocuments.removeAll()
        } else {
            selectedDocuments = Set(generatedDocuments.map(\.id))
        }
    }
    
    // MARK: - Download Operations
    
    private func downloadSelected() {
        let documentsToDownload = generatedDocuments.filter { selectedDocuments.contains($0.id) }
        Task {
            await downloadDocuments(documentsToDownload)
        }
    }

    private func downloadAll() {
        Task {
            await downloadDocuments(generatedDocuments)
        }
    }

    private func downloadDocuments(_ documents: [GeneratedDocument]) async {
        guard !documents.isEmpty else { return }
        
        await MainActor.run {
            isDownloading = true
            downloadProgress = 0.0
            downloadError = nil
            downloadResults = []
        }
        
        do {
            guard let documentManager = documentManager else {
                throw DocumentManagerError.downloadFailed("Document manager not available")
            }
            
            let results = try await documentManager.downloadDocuments(documents) { progress in
                Task { @MainActor in
                    downloadProgress = progress
                }
            }
            
            await MainActor.run {
                downloadResults = results
                isDownloading = false
                
                // Show error if some downloads failed
                let failedDownloads = results.filter { !$0.success }
                if !failedDownloads.isEmpty {
                    downloadError = .downloadFailed("Failed to download \(failedDownloads.count) documents")
                }
            }
            
        } catch {
            await MainActor.run {
                isDownloading = false
                downloadError = error as? DocumentManagerError ?? .downloadFailed(error.localizedDescription)
            }
        }
    }
}

struct DocumentDownloadRow: View {
    let document: GeneratedDocument
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(isSelected ? .blue : .secondary)
                .onTapGesture {
                    onToggle()
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(document.title.isEmpty ? "Untitled Document" : document.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                HStack {
                    Text(document.fileType.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Show estimated file size based on content length
                    Text(formatFileSize(document.content.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
            
            // File type icon
            Image(systemName: getFileTypeIcon(for: document.fileType))
                .font(.title2)
                .foregroundColor(getFileTypeColor(for: document.fileType))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func getFileTypeIcon(for fileType: String) -> String {
        // Use generic document icon for all types
        return "doc.richtext"
    }
    
    private func getFileTypeColor(for fileType: String) -> Color {
        // Use hash-based color assignment for consistent colors
        let hash = abs(fileType.hashValue)
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .yellow, .cyan, .mint]
        return colors[hash % colors.count]
    }
}

struct DocumentsEmptyStateView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Documents Available")
                .font(.headline)
                .foregroundColor(.primary)

            Text("This acquisition doesn't have any generated documents yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.extraLarge)

            Spacer()
        }
    }
}

// MARK: - Document Selection Sheet

public struct DocumentSelectionSheet: View {
    let acquisitionId: UUID?
    let selectedDocuments: Set<UUID>
    let onToggleDocument: (UUID) -> Void
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var acquisition: Acquisition?
    @State private var generatedDocuments: [GeneratedDocument] = []
    @State private var isLoading = true

    public init(
        acquisitionId: UUID?,
        selectedDocuments: Set<UUID>,
        onToggleDocument: @escaping (UUID) -> Void,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.acquisitionId = acquisitionId
        self.selectedDocuments = selectedDocuments
        self.onToggleDocument = onToggleDocument
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    public var body: some View {
        SwiftUI.NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading documents...")
                        .frame(maxHeight: .infinity)
                } else if let acquisition {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        Text("Select Documents to Share")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top)

                        Text(acquisition.title.isEmpty ? "Untitled Acquisition" : acquisition.title)
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                            .padding(.bottom)

                        // Document list
                        if generatedDocuments.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("No documents available")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxHeight: .infinity)
                        } else {
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(generatedDocuments) { document in
                                        DocumentSelectionRow(
                                            document: document,
                                            isSelected: selectedDocuments.contains(document.id),
                                            onToggle: {
                                                onToggleDocument(document.id)
                                            }
                                        )
                                    }
                                }
                                .padding()
                            }
                        }

                        // Bottom actions
                        HStack(spacing: 16) {
                            Button("Cancel") {
                                onCancel()
                            }
                            .foregroundColor(.red)

                            Spacer()

                            Text("\(selectedDocuments.count) selected")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button("Share") {
                                onConfirm()
                            }
                            .fontWeight(.semibold)
                            .disabled(selectedDocuments.isEmpty)
                        }
                        .padding()
                        .background(Theme.Colors.aikoBackground)
                    }
                } else {
                    Text("Unable to load acquisition")
                        .frame(maxHeight: .infinity)
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .background(Color.black)
            .task {
                await loadAcquisition()
            }
        }
    }

    private func loadAcquisition() async {
        guard let acquisitionId = acquisitionId else {
            await MainActor.run {
                isLoading = false
            }
            return
        }

        // Create sample acquisition for demonstration
        // In real implementation, this would fetch from Core Data or API
        let sampleAcquisition = Acquisition(
            id: acquisitionId,
            title: "Sample Acquisition",
            requirements: "Sample acquisition for document selection",
            projectNumber: "SAMPLE-001",
            status: .inProgress
        )
        
        let sampleDocuments = generateSampleDocuments(for: sampleAcquisition)
        
        await MainActor.run {
            acquisition = sampleAcquisition
            generatedDocuments = sampleDocuments
            isLoading = false
        }
    }
    
    private func generateSampleDocuments(for acquisition: Acquisition) -> [GeneratedDocument] {
        var documents: [GeneratedDocument] = []
        
        documents.append(GeneratedDocument(
            title: "\(acquisition.title)_Contract.pdf",
            documentType: .contractScaffold,
            content: "Sample contract document"
        ))
        
        documents.append(GeneratedDocument(
            title: "\(acquisition.title)_SOW.docx",
            documentType: .sow,
            content: "Statement of Work document"
        ))
        
        return documents
    }
}

struct DocumentSelectionRow: View {
    let document: GeneratedDocument
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Theme.Colors.aikoPrimary : .gray)

                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title.isEmpty ? "Untitled Document" : document.title)
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack {
                        Text(document.fileType.uppercased())
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)
                        Text(document.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.Colors.aikoPrimary.opacity(0.2) : Theme.Colors.aikoSecondary)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
