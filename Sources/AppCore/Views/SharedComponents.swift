import SwiftUI

// MARK: - Navigation Bar Hidden Modifier

public struct NavigationBarHiddenModifier: ViewModifier {
    private let themeService: ThemeServiceProtocol?

    public init(themeService: ThemeServiceProtocol? = nil) {
        self.themeService = themeService
    }

    public func body(content: Content) -> some View {
        themeService?.applyNavigationBarHidden(to: AnyView(content)) ?? AnyView(content)
    }
}

// MARK: - AIKO Sheet Modifier

// Note: aikoSheet() is defined in the main module's Theme.swift

// MARK: - Document Types Section

public struct DocumentTypesSection: View {
    let documentTypes: [DocumentType]
    let selectedTypes: Set<DocumentType>
    let selectedDFTypes: Set<DFDocumentType>
    let documentStatus: [DocumentType: DocumentStatus]
    let hasAcquisition: Bool
    let loadedAcquisitionDisplayName: String?
    let onTypeToggled: (DocumentType) -> Void
    let onDFTypeToggled: (DFDocumentType) -> Void
    let onExecuteCategory: (DocumentCategory) -> Void

    @State private var expandedCategories: Set<DocumentCategory> = []

    public init(
        documentTypes: [DocumentType],
        selectedTypes: Set<DocumentType>,
        selectedDFTypes: Set<DFDocumentType>,
        documentStatus: [DocumentType: DocumentStatus],
        hasAcquisition: Bool,
        loadedAcquisitionDisplayName: String?,
        onTypeToggled: @escaping (DocumentType) -> Void,
        onDFTypeToggled: @escaping (DFDocumentType) -> Void,
        onExecuteCategory: @escaping (DocumentCategory) -> Void
    ) {
        self.documentTypes = documentTypes
        self.selectedTypes = selectedTypes
        self.selectedDFTypes = selectedDFTypes
        self.documentStatus = documentStatus
        self.hasAcquisition = hasAcquisition
        self.loadedAcquisitionDisplayName = loadedAcquisitionDisplayName
        self.onTypeToggled = onTypeToggled
        self.onDFTypeToggled = onDFTypeToggled
        self.onExecuteCategory = onExecuteCategory
    }

    func filteredDocumentTypes(for category: DocumentCategory) -> [DocumentType] {
        category.documentTypes
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            // Acquisition name if loaded - centered
            if let acquisitionName = loadedAcquisitionDisplayName {
                HStack {
                    Spacer()
                    Text(acquisitionName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                }
            }

            // Header with search
            HStack(spacing: Theme.Spacing.small) {
                Label("Document Types", systemImage: "folder")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.aikoPrimary)

                // Status indicator - moved after Document Types
                Circle()
                    .fill(hasAcquisition ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }

            // Category folders
            VStack(spacing: Theme.Spacing.medium) {
                ForEach(DocumentCategory.allCases, id: \.self) { category in
                    DocumentCategoryFolder(
                        category: category,
                        isExpanded: expandedCategories.contains(category),
                        documentTypes: filteredDocumentTypes(for: category),
                        selectedTypes: selectedTypes,
                        selectedDFTypes: selectedDFTypes,
                        documentStatus: documentStatus,
                        hasAcquisition: hasAcquisition,
                        onToggleExpanded: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if expandedCategories.contains(category) {
                                    expandedCategories.remove(category)
                                } else {
                                    expandedCategories.insert(category)
                                }
                            }
                        },
                        onTypeToggled: onTypeToggled,
                        onDFTypeToggled: onDFTypeToggled,
                        onExecute: {
                            onExecuteCategory(category)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Document Category Folder

public struct DocumentCategoryFolder: View {
    let category: DocumentCategory
    let isExpanded: Bool
    let documentTypes: [DocumentType]
    let selectedTypes: Set<DocumentType>
    let selectedDFTypes: Set<DFDocumentType>
    let documentStatus: [DocumentType: DocumentStatus]
    let hasAcquisition: Bool
    let onToggleExpanded: () -> Void
    let onTypeToggled: (DocumentType) -> Void
    let onDFTypeToggled: (DFDocumentType) -> Void
    let onExecute: () -> Void

    var selectedCount: Int {
        if category == .determinationFindings {
            selectedDFTypes.count
        } else {
            documentTypes.count(where: { selectedTypes.contains($0) })
        }
    }

    var readyCount: Int {
        documentTypes.count(where: { documentStatus[$0] == .ready })
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Folder header
            Button(action: onToggleExpanded) {
                HStack(spacing: Theme.Spacing.large) {
                    // Category icon
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(Theme.Colors.aikoPrimary)
                        .frame(width: 32, height: 32)

                    // Category info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(category.rawValue)
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()

                            // Status badges
                            if selectedCount > 0 {
                                Text("\(selectedCount) selected")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Theme.Colors.aikoPrimary)
                                    .cornerRadius(8)
                            }

                            if readyCount > 0 {
                                Text("\(readyCount) ready")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }

                            // Execute button (only show if documents are selected)
                            if selectedCount > 0 {
                                Button(action: onExecute) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }

                            // Expand/collapse arrow
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        }

                        Text(category.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)

                        // Document count
                        if category == .determinationFindings {
                            Text("\(DFDocumentType.allCases.count) document types")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(documentTypes.count) document types")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(Theme.Spacing.large)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                        .fill(Theme.Colors.aikoSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                                .stroke(selectedCount > 0 ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                )
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                if category == .determinationFindings {
                    // Show D&F document type cards
                    VStack(spacing: Theme.Spacing.small) {
                        ForEach(DFDocumentType.allCases) { dfDocumentType in
                            DFDocumentTypeCard(
                                dfDocumentType: dfDocumentType,
                                isSelected: selectedDFTypes.contains(dfDocumentType),
                                hasAcquisition: hasAcquisition,
                                onToggle: {
                                    onDFTypeToggled(dfDocumentType)
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.top, Theme.Spacing.small)
                    .animation(.easeInOut(duration: 0.3), value: DFDocumentType.allCases)
                } else {
                    VStack(spacing: Theme.Spacing.small) {
                        ForEach(documentTypes) { documentType in
                            DocumentTypeCard(
                                documentType: documentType,
                                isSelected: selectedTypes.contains(documentType),
                                isAvailable: true, // All features unlocked
                                status: documentStatus[documentType] ?? .notReady,
                                onToggle: { onTypeToggled(documentType) }
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.top, Theme.Spacing.small)
                    .animation(.easeInOut(duration: 0.3), value: documentTypes)
                }
            }
        }
    }
}

// MARK: - Document Type Card

public struct DocumentTypeCard: View {
    let documentType: DocumentType
    let isSelected: Bool
    let isAvailable: Bool
    let status: DocumentStatus
    let onToggle: () -> Void

    var statusColor: Color {
        switch status {
        case .notReady: .red
        case .needsMoreInfo: .yellow
        case .ready: .green
        }
    }

    func statusText(for status: DocumentStatus) -> String {
        switch status {
        case .notReady: "Not Ready"
        case .needsMoreInfo: "Needs Info"
        case .ready: "Ready"
        }
    }

    public var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Theme.Spacing.medium) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                // Icon
                Image(systemName: documentType.icon)
                    .font(.body)
                    .foregroundColor(isAvailable ? .blue : .secondary)
                    .frame(width: 20, height: 20)

                // Document name only
                Text(documentType.shortName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                // FAR Reference
                Text(documentType.farReference)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .secondary)
                    .font(.body)
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.vertical, Theme.Spacing.small)
            .frame(maxWidth: .infinity)
            .frame(height: 44) // Fixed single-field height
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Theme.Colors.aikoSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    )
            )
            .opacity(isAvailable ? 1.0 : 0.6)
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DF Document Type Card

public struct DFDocumentTypeCard: View {
    let dfDocumentType: DFDocumentType
    let isSelected: Bool
    let hasAcquisition: Bool
    let onToggle: () -> Void

    public var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Theme.Spacing.medium) {
                // Status indicator - Red when no acquisition loaded
                Circle()
                    .fill(hasAcquisition ? Color.green : Color.red)
                    .frame(width: 8, height: 8)

                // Icon
                Image(systemName: dfDocumentType.icon)
                    .font(.body)
                    .foregroundColor(.blue)
                    .frame(width: 20, height: 20)

                // Document name only
                Text(dfDocumentType.shortName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                // FAR Reference
                Text(dfDocumentType.farReference)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .secondary)
                    .font(.body)
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.vertical, Theme.Spacing.small)
            .frame(maxWidth: .infinity)
            .frame(height: 44) // Fixed single-field height
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Theme.Colors.aikoSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    )
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
