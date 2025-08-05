import AppCore
import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct OriginalSAMGovInterface: View {
    @Bindable var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchResults: [EntityDetail] = []
    @State private var errorMessage: String?
    @State private var showingAPIKeyAlert = false
    @State private var showingReportPreview = false

    // Multiple search entries - the original batched search functionality
    @State private var searchEntries: [SearchEntry] = [
        SearchEntry(),
        SearchEntry(),
        SearchEntry(),
    ]

    struct SearchEntry: Identifiable {
        let id = UUID()
        var text: String = ""
        var type: SearchType = .cage
        var isSearching: Bool = false
        var result: EntityDetail?
    }

    enum SearchType: String, CaseIterable {
        case cage = "CAGE Code"
        case companyName = "Company Name"
        case uei = "UEI"

        var placeholder: String {
            switch self {
            case .companyName: "Enter company name..."
            case .uei: "Enter UEI (12 characters)..."
            case .cage: "Enter CAGE code..."
            }
        }

        var icon: String {
            switch self {
            case .companyName: "building.2"
            case .uei: "number"
            case .cage: "barcode"
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with SAM icon
                    VStack(spacing: 12) {
                        if let samIcon = loadSAMIcon() {
                            samIcon
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                        }

                        Text("Search SAM.gov")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.698, green: 0.132, blue: 0.203),
                                        Color.white,
                                        Color(red: 0.0, green: 0.125, blue: 0.698),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(.top)

                    // Search Section
                    ScrollView {
                        VStack(spacing: 20) {
                            // Search entries with filter buttons - the original design
                            ForEach(searchEntries.indices, id: \.self) { index in
                                SearchEntryView(
                                    entry: $searchEntries[index],
                                    onSearch: { performSearch(for: index) },
                                    onRemove: index > 0 ? { // Show X on all cards except the first one
                                        searchEntries.remove(at: index)
                                    } : nil
                                )
                            }

                            // Add more button - the original batched search feature
                            Button(action: {
                                searchEntries.append(SearchEntry())
                            }, label: {
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
                            })
                            .padding(.horizontal)

                            // Search all button
                            Button(action: performAllSearches) {
                                HStack {
                                    if searchEntries.contains(where: \.isSearching) {
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
                            .disabled(searchEntries.allSatisfy(\.text.isEmpty) || searchEntries.contains(where: \.isSearching))
                            .padding(.horizontal)
                        }
                        .padding(.vertical)

                        if !searchResults.isEmpty {
                            Divider()
                                .background(Color.gray.opacity(0.3))

                            Text("Search Results")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .padding(.top)

                            ForEach(searchResults, id: \.entityName) { result in
                                EntityDetailView(entity: result)
                                    .padding()
                            }

                            // Generate Report Button
                            Button(action: {
                                showingReportPreview = true
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
                            .padding(.horizontal)
                            .padding(.bottom)

                        } else if let error = errorMessage {
                            SAMGovErrorView(message: error)
                                .padding()
                        }
                    }
                }
            }
            .navigationTitle("SAM.gov Research")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                #endif
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingReportPreview) {
            OriginalSAMReportPreview(entities: searchResults)
        }
        .alert("API Key Required", isPresented: $showingAPIKeyAlert) {
            Button("Go to Settings") {
                // Navigate to settings
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please configure your SAM.gov API key in Settings to use this feature.")
        }
    }

    private func loadSAMIcon() -> Image? {
        #if os(iOS)
        if let image = UIImage(named: "SAMIcon", in: Bundle.main, compatibleWith: nil) {
            return Image(uiImage: image)
        }
        // Fallback to direct file loading
        if let data = try? Data(contentsOf: URL(fileURLWithPath: "/Users/J/aiko/Sources/Resources/SAMIcon.png")),
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let image = NSImage(named: "SAMIcon") {
            return Image(nsImage: image)
        }
        // Fallback to direct file loading
        if let data = try? Data(contentsOf: URL(fileURLWithPath: "/Users/J/aiko/Sources/Resources/SAMIcon.png")),
           let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        #endif
        return nil
    }

    private func performSearch(for index: Int) {
        guard index < searchEntries.count else { return }
        let entry = searchEntries[index]

        guard !entry.text.isEmpty else { return }

        searchEntries[index].isSearching = true
        searchEntries[index].result = nil

        Task {
            do {
                let result: EntityDetail?
                let repository = SAMGovRepository()
                let service = await repository.createService()

                switch entry.type {
                case .companyName:
                    let searchResults = try await service.searchEntity(entry.text)
                    guard let firstEntity = searchResults.entities.first else {
                        throw SAMGovError.entityNotFound
                    }
                    result = try await service.getEntityByUEI(firstEntity.ueiSAM)
                case .uei:
                    result = try await service.getEntityByUEI(entry.text)
                case .cage:
                    result = try await service.getEntityByCAGE(entry.text)
                }

                await MainActor.run {
                    searchEntries[index].isSearching = false
                    searchEntries[index].result = result
                    if let result {
                        if !searchResults.contains(where: { $0.entityName == result.entityName }) {
                            searchResults.append(result)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    searchEntries[index].isSearching = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func performAllSearches() {
        for index in searchEntries.indices {
            if !searchEntries[index].text.isEmpty, !searchEntries[index].isSearching {
                performSearch(for: index)
            }
        }
    }
}

// MARK: - Search Entry View with Filter Buttons

struct SearchEntryView: View {
    @Binding var entry: OriginalSAMGovInterface.SearchEntry
    let onSearch: () -> Void
    let onRemove: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Search type filter buttons - THE ORIGINAL DESIGN
            HStack {
                ForEach(OriginalSAMGovInterface.SearchType.allCases, id: \.self) { type in
                    Button(action: { entry.type = type }, label: {
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
                    })
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
                    Button(action: { entry.text = "" }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    })
                }

                // Search button with magnifying glass
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
        .padding(.horizontal)
    }
}

// MARK: - Entity Detail View

struct EntityDetailView: View {
    let entity: EntityDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Active Exclusions Warning (if applicable)
            if entity.hasActiveExclusions {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("ACTIVE EXCLUSIONS")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("This entity is excluded from receiving federal contracts, grants, and benefits")
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
                InfoRow(label: "Legal Name", value: entity.legalBusinessName)
                InfoRow(label: "UEI", value: entity.ueiSAM)
                if let cage = entity.cageCode {
                    InfoRow(label: "CAGE Code", value: cage)
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
}

// MARK: - Info Row Helper

struct InfoRow: View {
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

// MARK: - Error View

struct SAMGovErrorView: View {
    let message: String

    var body: some View {
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
}
