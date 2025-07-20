import ComposableArchitecture
import Foundation
import SwiftUI

#if os(iOS)
    import AIKOiOS
#elseif os(macOS)
    import AIKOmacOS
#endif

/// Handles document sharing functionality
@Reducer
public struct ShareFeature: Sendable {
    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var mode: ShareMode = .none
        public var targetAcquisitionId: UUID?
        public var selectedDocumentIds: Set<UUID> = []
        @ObservationStateIgnored public var shareItems: [Any] = []
        public var isShowingShareSheet: Bool = false
        public var isPreparingShare: Bool = false
        public var shareError: String?

        // Derived state
        public var hasSelection: Bool {
            !selectedDocumentIds.isEmpty
        }

        public var selectionCount: Int {
            selectedDocumentIds.count
        }

        public init(mode: ShareMode = .none) {
            self.mode = mode
        }

        public static func == (lhs: State, rhs: State) -> Bool {
            lhs.mode == rhs.mode &&
                lhs.targetAcquisitionId == rhs.targetAcquisitionId &&
                lhs.selectedDocumentIds == rhs.selectedDocumentIds &&
                lhs.isShowingShareSheet == rhs.isShowingShareSheet &&
                lhs.isPreparingShare == rhs.isPreparingShare &&
                lhs.shareError == rhs.shareError
            // Note: shareItems is intentionally excluded from equality check
        }
    }

    // MARK: - Action

    public enum Action {
        // Share mode management
        case setShareMode(ShareMode)
        case cancelShare

        // Document selection
        case selectDocument(UUID)
        case deselectDocument(UUID)
        case selectAllDocuments([UUID])
        case clearSelection

        // Share actions
        case prepareShare
        case shareItemsPrepared([Any])
        case shareCompleted
        case shareFailed(String)

        // Share sheet
        case setShowingShareSheet(Bool)
    }

    // MARK: - Dependencies

    @Dependency(\.continuousClock) var clock

    // MARK: - Reducer

    private enum CancelID {
        case sharePreparation
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .setShareMode(mode):
                state.mode = mode
                state.selectedDocumentIds.removeAll()
                state.shareItems.removeAll()
                state.shareError = nil

                // Set target acquisition if applicable
                switch mode {
                case let .acquisition(id):
                    state.targetAcquisitionId = id
                case let .contractFile(id):
                    state.targetAcquisitionId = id
                default:
                    state.targetAcquisitionId = nil
                }

                return .none

            case .cancelShare:
                state.mode = .none
                state.targetAcquisitionId = nil
                state.selectedDocumentIds.removeAll()
                state.shareItems.removeAll()
                state.isShowingShareSheet = false
                state.isPreparingShare = false
                state.shareError = nil

                return .cancel(id: CancelID.sharePreparation)

            case let .selectDocument(id):
                state.selectedDocumentIds.insert(id)
                return .none

            case let .deselectDocument(id):
                state.selectedDocumentIds.remove(id)
                return .none

            case let .selectAllDocuments(ids):
                state.selectedDocumentIds = Set(ids)
                return .none

            case .clearSelection:
                state.selectedDocumentIds.removeAll()
                return .none

            case .prepareShare:
                guard !state.selectedDocumentIds.isEmpty else {
                    return .send(.shareFailed("No documents selected"))
                }

                state.isPreparingShare = true
                state.shareError = nil

                return .run { [selectedIds = state.selectedDocumentIds, mode = state.mode] send in
                    do {
                        // Simulate share preparation
                        try await clock.sleep(for: .milliseconds(500))

                        let shareItems = try await prepareShareItems(
                            documentIds: Array(selectedIds),
                            mode: mode
                        )

                        await send(.shareItemsPrepared(shareItems))
                    } catch {
                        await send(.shareFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.sharePreparation)

            case let .shareItemsPrepared(items):
                state.shareItems = items
                state.isPreparingShare = false
                state.isShowingShareSheet = true
                return .none

            case .shareCompleted:
                // Clean up after successful share
                state.isShowingShareSheet = false
                state.shareItems.removeAll()

                // Keep selection for potential re-share
                return .run { _ in
                    // Log share completion
                    print(" Share completed successfully")
                }

            case let .shareFailed(error):
                state.isPreparingShare = false
                state.shareError = error
                return .none

            case let .setShowingShareSheet(showing):
                state.isShowingShareSheet = showing
                if !showing {
                    state.shareItems.removeAll()
                }
                return .none
            }
        }
    }

    // MARK: - Helper Methods

    private func prepareShareItems(
        documentIds: [UUID],
        mode: ShareMode
    ) async throws -> [Any] {
        // This would integrate with actual document services
        // For now, return mock data

        switch mode {
        case .singleDocument:
            ["Document content for single share"]

        case .multipleDocuments:
            documentIds.map { "Document \($0.uuidString)" }

        case let .acquisition(id):
            ["Acquisition \(id.uuidString) with \(documentIds.count) documents"]

        case let .contractFile(id):
            ["Contract file for acquisition \(id.uuidString)"]

        case .none:
            []
        }
    }
}

// MARK: - Models

public enum ShareMode: Equatable, Sendable {
    case none
    case singleDocument
    case multipleDocuments
    case acquisition(UUID)
    case contractFile(UUID)

    public var title: String {
        switch self {
        case .none:
            "Share"
        case .singleDocument:
            "Share Document"
        case .multipleDocuments:
            "Share Documents"
        case .acquisition:
            "Share Acquisition Documents"
        case .contractFile:
            "Share Contract File"
        }
    }

    public var isActive: Bool {
        self != .none
    }
}

// MARK: - Extensions

public extension ShareFeature.State {
    /// Get a description of the current share operation
    var shareDescription: String {
        switch mode {
        case .none:
            "No active share"
        case .singleDocument:
            "Sharing 1 document"
        case .multipleDocuments:
            "Sharing \(selectionCount) documents"
        case .acquisition:
            "Sharing acquisition documents (\(selectionCount) selected)"
        case .contractFile:
            "Sharing contract file"
        }
    }

    /// Check if ready to share
    var canShare: Bool {
        hasSelection && !isPreparingShare
    }

    /// Reset to initial state
    mutating func reset() {
        self = ShareFeature.State()
    }
}

// MARK: - Share Sheet View Modifier

public struct ShareSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let items: [Any]
    let onCompletion: () -> Void
    @Dependency(\.shareService) var shareService

    public func body(content: Content) -> some View {
        content
            .task(id: isPresented) {
                if isPresented, !items.isEmpty {
                    // Use the share service instead of direct ShareSheet
                    _ = await shareService.share(items)
                    isPresented = false
                    onCompletion()
                }
            }
    }
}

// ShareSheet is already defined in ShareButton.swift
