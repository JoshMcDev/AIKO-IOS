import SwiftUI
import AppCore
import Foundation

/// SAMGovLookupView - PHASE 2 Business Logic View Restoration
/// Modern SwiftUI implementation with @Observable ViewModel pattern
/// Replaces TCA-based SAMGovLookupView with native SwiftUI architecture
/// Features: Batch lookup, three search types (CAGE, Company, UEI), report generation
public struct SAMGovLookupView: View {
    @Bindable var viewModel: SAMGovLookupViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: SAMGovLookupViewModel) {
        self.viewModel = viewModel
    }

    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #else
        return .automatic
        #endif
    }

    public var body: some View {
        NavigationView {
            ZStack {
                // Dark background to match app theme
                Color.black
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection

                        // Search Entries Section
                        searchEntriesSection

                        // Add More Button
                        addMoreButton

                        // Batch Search Button
                        batchSearchButton

                        // Results Section
                        if !viewModel.searchResults.isEmpty {
                            resultsSection
                        }

                        // Error Display
                        if let errorMessage = viewModel.errorMessage {
                            errorSection(errorMessage)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("SAM.gov Lookup")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: toolbarPlacement) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $viewModel.showingReportPreview) {
                SAMReportView(entity: viewModel.selectedEntityForReport)
            }
            .alert("API Key Required", isPresented: $viewModel.showingAPIKeyAlert) {
                Button("Go to Settings") {
                    // TODO: Navigate to settings
                    viewModel.navigateToSettings()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please configure your SAM.gov API key in Settings to use this feature.")
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            // SAM.gov Icon
            if let samIcon = loadSAMIcon() {
                samIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
            }

            // Title with patriotic gradient
            Text("Search SAM.gov")
                .font(.title2)
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
        }
        .padding(.top)
    }

    // MARK: - Search Entries Section

    @ViewBuilder
    private var searchEntriesSection: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.searchEntries.indices, id: \.self) { index in
                SearchEntryCard(
                    entry: $viewModel.searchEntries[index],
                    onSearch: {
                        Task {
                            await viewModel.performSearch(for: index)
                        }
                    },
                    onRemove: index > 0 ? {
                        viewModel.removeSearchEntry(at: index)
                    } : nil
                )
            }
        }
    }

    // MARK: - Add More Button

    @ViewBuilder
    private var addMoreButton: some View {
        Button(action: {
            viewModel.addSearchEntry()
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Add Another Search")
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))
            )
        }
    }

    // MARK: - Batch Search Button

    @ViewBuilder
    private var batchSearchButton: some View {
        Button(action: {
            Task {
                await viewModel.performAllSearches()
            }
        }) {
            HStack {
                if viewModel.isSearching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "magnifyingglass")
                }
                Text("Search All")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue)
            .cornerRadius(8)
        }
        .disabled(viewModel.shouldDisableBatchSearch)
    }

    // MARK: - Results Section

    @ViewBuilder
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .background(Color.gray.opacity(0.3))

            Text("Search Results")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(viewModel.searchResults, id: \.ueiSAM) { entity in
                EntityResultCard(
                    entity: entity,
                    onTap: {
                        viewModel.selectEntityForReport(entity)
                    }
                )
            }

            // Generate Report Button
            Button(action: {
                viewModel.generateBatchReport()
            }) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("Generate SAM.gov Report")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.green)
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Error Section

    @ViewBuilder
    private func errorSection(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .foregroundColor(.white)
                .font(.caption)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Helper Functions

    private func loadSAMIcon() -> Image? {
        #if os(iOS)
        if let image = UIImage(named: "SAMIcon", in: Bundle.main, compatibleWith: nil) {
            return Image(uiImage: image)
        }
        // Fallback to Resources directory
        if let data = try? Data(contentsOf: URL(fileURLWithPath: "/Users/J/aiko/Sources/Resources/SAMIcon.png")),
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let image = NSImage(named: "SAMIcon") {
            return Image(nsImage: image)
        }
        // Fallback to Resources directory
        if let data = try? Data(contentsOf: URL(fileURLWithPath: "/Users/J/aiko/Sources/Resources/SAMIcon.png")),
           let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        #endif
        return nil
    }
}

// MARK: - Search Entry Card Component

struct SearchEntryCard: View {
    @Binding var entry: SAMGovSearchEntry
    let onSearch: () -> Void
    let onRemove: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Search type filter buttons
            HStack {
                ForEach(SAMGovSearchType.allCases, id: \.self) { type in
                    Button(action: { entry.type = type }) {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.caption)
                            Text(type.rawValue)
                                .font(.caption)
                                .fontWeight(entry.type == type ? .semibold : .regular)
                        }
                        .foregroundColor(entry.type == type ? .white : .gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            entry.type == type ? .blue : Color.clear
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(entry.type == type ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(6)
                    }
                }

                Spacer()

                if let onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }

            // Search field
            HStack {
                TextField(entry.type.placeholder, text: $entry.text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    #if os(iOS)
                    .autocapitalization(entry.type == .cage || entry.type == .uei ? .allCharacters : .words)
                    #endif
                    .disableAutocorrection(true)
                    .onSubmit {
                        onSearch()
                    }

                if !entry.text.isEmpty {
                    Button(action: { entry.text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }

                // Search button
                Button(action: onSearch) {
                    if entry.isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                }
                .disabled(entry.text.isEmpty || entry.isSearching)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)

            // Result display
            if let result = entry.result {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Found: \(result.entityName)")
                            .font(.caption)
                            .foregroundColor(.green)
                            .lineLimit(1)
                    }
                    Text("UEI: \(result.ueiSAM)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Entity Result Card Component

struct EntityResultCard: View {
    let entity: EntityDetail
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Active Exclusions Warning
                if entity.hasActiveExclusions {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("ACTIVE EXCLUSIONS")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("This entity is excluded from federal contracts")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                    )
                }

                // Status Badge
                HStack {
                    Image(systemName: entity.registrationStatus == "Active" ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(entity.registrationStatus == "Active" ? .green : .orange)

                    Text(entity.registrationStatus)
                        .font(.headline)
                        .foregroundColor(entity.registrationStatus == "Active" ? .green : .orange)

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(entity.registrationStatus == "Active" ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                )

                // Basic Information
                VStack(alignment: .leading, spacing: 8) {
                    EntityInfoRow(label: "Legal Name", value: entity.legalBusinessName)
                    EntityInfoRow(label: "UEI", value: entity.ueiSAM)
                    if let cage = entity.cageCode {
                        EntityInfoRow(label: "CAGE Code", value: cage)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                // Business Types
                if !entity.businessTypes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Business Types")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.bottom, 4)

                        ForEach(entity.businessTypes, id: \.self) { type in
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(type)
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Entity Info Row Component

struct EntityInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.caption)
                .foregroundColor(.white)

            Spacer()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SAMGovLookupView_Previews: PreviewProvider {
    static var previews: some View {
        SAMGovLookupView(viewModel: SAMGovLookupViewModel(samGovService: PreviewMockSAMGovService()))
            .preferredColorScheme(.dark)
    }
}

struct PreviewMockSAMGovService: SAMGovServiceProtocol {
    func getEntityByCAGE(_ cage: String) async throws -> EntityDetail {
        return EntityDetail.mockCAGEEntity()
    }

    func getEntityByUEI(_ uei: String) async throws -> EntityDetail {
        return EntityDetail.mockUEIEntity()
    }

    func searchEntity(_ query: String) async throws -> EntitySearchResult {
        return EntitySearchResult.mockSearchResult()
    }
}
#endif
