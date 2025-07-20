import ComposableArchitecture
import Dependencies
import SwiftUI

// MARK: - Download Options Sheet

public struct DownloadOptionsSheet: View {
    let acquisition: Acquisition
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedDocuments: Set<UUID> = []
    @State private var isDownloading = false
    @State private var downloadError: String?

    // TODO: GeneratedFile is a Core Data model in the main module
    // This needs to be refactored to use a protocol or DTO
    var generatedFiles: [Any] {
        [] // Placeholder - needs Core Data models
    }

    public init(acquisition: Acquisition, onDismiss: @escaping () -> Void) {
        self.acquisition = acquisition
        self.onDismiss = onDismiss
    }

    @ViewBuilder
    private var documentList: some View {
        SwiftUI.List {
            Section {
                // TODO: Restore when GeneratedFile is available
                EmptyView()
            } header: {
                HStack {
                    Text("Available Documents")
                    Spacer()
                    Button("Select All") {
                        // TODO: Implement selection logic
                    }
                    .font(.caption)
                }
            }
        }
    }

    public var body: some View {
        SwiftUI.NavigationView {
            VStack(spacing: 0) {
                if generatedFiles.isEmpty {
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
                        VStack(spacing: Theme.Spacing.md) {
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
                                    .cornerRadius(Theme.CornerRadius.md)
                                }
                            }

                            Button(action: downloadAll) {
                                Label("Download All Documents", systemImage: "arrow.down.doc.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.Colors.aikoAccent)
                                    .foregroundColor(.white)
                                    .cornerRadius(Theme.CornerRadius.md)
                            }
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
                            dismiss()
                        }
                    }
                }
                .alert("Download Error", isPresented: .init(
                    get: { downloadError != nil },
                    set: { _ in downloadError = nil }
                )) {
                    Button("OK") {}
                } message: {
                    if let error = downloadError {
                        Text(error)
                    }
                }
                .overlay {
                    if isDownloading {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .overlay {
                                ProgressView("Downloading...")
                                    .padding()
                                    .background(Color.black)
                                    .cornerRadius(Theme.CornerRadius.md)
                            }
                    }
                }
        }
    }

    private func downloadSelected() {
        // TODO: Implement when GeneratedFile is available
        // let filesToDownload = generatedFiles.filter { file in
        //     selectedDocuments.contains(file.id!)
        // }
        // downloadDocuments(filesToDownload)
        downloadDocuments([])
    }

    private func downloadAll() {
        downloadDocuments(generatedFiles)
    }

    private func downloadDocuments(_: [Any]) {
        isDownloading = true

        #if os(iOS)
            // iOS implementation - handled by platform-specific code
            downloadError = "Download functionality should be implemented in platform-specific code"
            isDownloading = false
        #else
            // macOS implementation - handled by platform-specific code
            downloadError = "Download functionality should be implemented in platform-specific code"
            isDownloading = false
        #endif
    }
}

struct DocumentDownloadRow: View {
    let file: Any // TODO: Should be GeneratedFile from Core Data
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
                Text("Untitled Document") // TODO: Use file.fileName
                    .font(.subheadline)
                    .foregroundColor(.primary)

                HStack {
                    Text("Unknown Type") // TODO: Use file.fileType
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // TODO: Use file.content?.count
                    // if let size = file.content?.count {
                    //     Text(formatFileSize(size))
                    //         .font(.caption)
                    //         .foregroundColor(.secondary)
                    // }
                }
            }

            Spacer()
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
}

struct DocumentsEmptyStateView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
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
                .padding(.horizontal, Theme.Spacing.xl)

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

    // TODO: acquisitionService needs to be injected from the main module
    // @Dependency(\.acquisitionService) var acquisitionService
    @State private var acquisition: Acquisition?
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
                        if true { // TODO: Check acquisition.documentsArray.isEmpty
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
                                    // TODO: Restore when AcquisitionDocument is available
                                    // ForEach(acquisition.documentsArray, id: \.id) { document in
                                    //     DocumentSelectionRow(
                                    //         document: document,
                                    //         isSelected: selectedDocuments.contains(document.id ?? UUID()),
                                    //         onToggle: {
                                    //             if let docId = document.id {
                                    //                 onToggleDocument(docId)
                                    //             }
                                    //         }
                                    //     )
                                    // }
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
        guard acquisitionId != nil else {
            isLoading = false
            return
        }

        // TODO: Implement when acquisitionService is available
        // do {
        //     acquisition = try await acquisitionService.fetchAcquisition(acquisitionId)
        //     isLoading = false
        // } catch {
        //     print("Failed to load acquisition: \(error)")
        //     isLoading = false
        // }
        isLoading = false
    }
}

struct DocumentSelectionRow: View {
    let document: Any // TODO: Should be AcquisitionDocument from Core Data
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Theme.Colors.aikoPrimary : .gray)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Untitled Document") // TODO: Use document.documentType
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack {
                        Text("Unknown Type") // TODO: Use document.documentType
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // TODO: Use document.createdDate
                        // if let date = document.createdDate {
                        //     Text("•")
                        //         .foregroundColor(.secondary)
                        //     Text(date, style: .date)
                        //         .font(.caption)
                        //         .foregroundColor(.secondary)
                        // }
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
