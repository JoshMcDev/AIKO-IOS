import AppCore
import SwiftUI
#if os(macOS)
import AppKit
#endif

/// AcquisitionsListView - Federal Acquisition Management Interface
/// PHASE 2: Business Logic View with comprehensive filtering, sorting, and search
/// Displays federal acquisitions with status tracking and workflow management
public struct AcquisitionsListView: View {
    @State private var viewModel = AcquisitionsListViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchSection

                // Filters Section
                if viewModel.hasFiltersApplied {
                    filtersSection
                }

                // Content
                contentView
            }
            .navigationTitle("Federal Acquisitions")
            .toolbar {
                ToolbarItem(placement: toolbarPlacement) {
                    toolbarContent
                }
            }
            .task {
                await viewModel.loadAcquisitions()
            }
            .sheet(isPresented: $viewModel.showingAcquisitionDetails) {
                if let acquisition = viewModel.selectedAcquisition {
                    AcquisitionDetailView(acquisition: acquisition)
                }
            }
            .sheet(isPresented: $viewModel.showingCreateAcquisition) {
                CreateAcquisitionView()
            }
        }
    }

    // MARK: - View Components

    private var searchSection: some View {
        VStack(spacing: 12) {
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search acquisitions...", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.searchText) { _, newValue in
                        viewModel.updateSearchText(newValue)
                    }

                if !viewModel.searchText.isEmpty {
                    Button("Clear") {
                        viewModel.updateSearchText("")
                    }
                    .foregroundColor(.blue)
                }
            }

            // Filter and Sort Controls
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Status Filters
                    ForEach(AcquisitionStatus.allCases, id: \.self) { status in
                        filterChip(for: status)
                    }

                    Divider()
                        .frame(height: 20)

                    // Phase Filters
                    ForEach(AcquisitionStatus.Phase.allCases, id: \.self) { phase in
                        phaseChip(for: phase)
                    }

                    Divider()
                        .frame(height: 20)

                    // Sort Options
                    sortMenu
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(PlatformColors.searchSectionBackground)
    }

    private var filtersSection: some View {
        HStack {
            Text("Filters Applied")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("Clear All") {
                viewModel.clearAllFilters()
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(PlatformColors.filtersSectionBackground)
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            ProgressView("Loading acquisitions...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)

                Text("Error Loading Acquisitions")
                    .font(.headline)

                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button("Retry") {
                    Task {
                        await viewModel.loadAcquisitions()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.filteredAcquisitions.isEmpty {
            emptyStateView
        } else {
            acquisitionsListView
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Acquisitions Found")
                .font(.headline)

            if viewModel.hasFiltersApplied {
                Text("Try adjusting your search or filters")
                    .font(.body)
                    .foregroundColor(.secondary)

                Button("Clear Filters") {
                    viewModel.clearAllFilters()
                }
                .buttonStyle(.bordered)
            } else {
                Text("Create your first acquisition to get started")
                    .font(.body)
                    .foregroundColor(.secondary)

                Button("Create Acquisition") {
                    viewModel.createNewAcquisition()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var acquisitionsListView: some View {
        List(viewModel.filteredAcquisitions) { acquisition in
            AcquisitionRowView(acquisition: acquisition) {
                viewModel.selectAcquisition(acquisition)
            }
        }
        .listStyle(.plain)
    }

    private var toolbarContent: some View {
        HStack {
            // Active count badge
            if viewModel.activeAcquisitionsCount > 0 {
                Text("\(viewModel.activeAcquisitionsCount) Active")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }

            Button("New", systemImage: "plus") {
                viewModel.createNewAcquisition()
            }
        }
    }

    // MARK: - Filter Components

    private func filterChip(for status: AcquisitionStatus) -> some View {
        let isSelected = viewModel.selectedFilters.statuses.contains(status)

        return Button {
            viewModel.toggleStatusFilter(status)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: status.icon)
                    .font(.caption)
                Text(status.displayName)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : PlatformColors.filterChipBackground)
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }

    private func phaseChip(for phase: AcquisitionStatus.Phase) -> some View {
        let isSelected = viewModel.selectedFilters.phase == phase

        return Button {
            viewModel.filterByPhase(phase)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: phase.icon)
                    .font(.caption)
                Text(phase.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.green : PlatformColors.filterChipBackground)
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(Array(AcquisitionSort.Field.allCases), id: \.self) { field in
                Button {
                    let newAscending = viewModel.currentSort.field == field ? !viewModel.currentSort.ascending : false
                    viewModel.sortBy(field, ascending: newAscending)
                } label: {
                    HStack {
                        Text(field.rawValue)
                        if viewModel.currentSort.field == field {
                            Image(systemName: viewModel.currentSort.ascending ? "arrow.up" : "arrow.down")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption)
                Text("Sort")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(PlatformColors.sortMenuBackground)
            .foregroundColor(.primary)
            .clipShape(Capsule())
        }
    }

    // MARK: - Platform-Specific Colors

    private enum PlatformColors {
        static var sortMenuBackground: Color {
            #if os(iOS)
            Color(.systemGray5)
            #else
            Color(NSColor.controlBackgroundColor)
            #endif
        }

        static var searchSectionBackground: Color {
            #if os(iOS)
            Color(.systemGroupedBackground)
            #else
            Color(NSColor.controlBackgroundColor)
            #endif
        }

        static var filtersSectionBackground: Color {
            #if os(iOS)
            Color(.systemGray6)
            #else
            Color(NSColor.separatorColor)
            #endif
        }

        static var filterChipBackground: Color {
            #if os(iOS)
            Color(.systemGray5)
            #else
            Color(NSColor.controlColor)
            #endif
        }
    }

    // MARK: - Platform-Specific Toolbar Placement

    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #else
        return .automatic
        #endif
    }
}

// MARK: - Supporting Views

/// Individual acquisition row in the list
private struct AcquisitionRowView: View {
    let acquisition: AppCore.Acquisition
    let onTap: () -> Void

    private var rowBackgroundColor: Color {
        #if os(iOS)
        return Color(.systemBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Header Row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(acquisition.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        if let projectNumber = acquisition.projectNumber {
                            Text(projectNumber)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Status Badge
                    HStack(spacing: 4) {
                        Image(systemName: acquisition.status.icon)
                            .font(.caption)
                        Text(acquisition.status.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(acquisition.status.color))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }

                // Requirements Preview
                Text(acquisition.requirements)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // Footer Row
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("Created \(acquisition.createdDate, style: .date)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    Spacer()

                    if !acquisition.uploadedFiles.isEmpty || !acquisition.generatedFiles.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "paperclip")
                                .font(.caption)
                            Text("\(acquisition.uploadedFiles.count + acquisition.generatedFiles.count) files")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(rowBackgroundColor)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder Views

private struct AcquisitionDetailView: View {
    let acquisition: AppCore.Acquisition

    var body: some View {
        NavigationStack {
            VStack {
                Text("Acquisition Details")
                    .font(.title)
                Text(acquisition.title)
                    .font(.headline)
                Text("This view will be implemented in a future phase")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

private struct CreateAcquisitionView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Create New Acquisition")
                    .font(.title)
                Text("This view will be implemented in a future phase")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("New Acquisition")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}
