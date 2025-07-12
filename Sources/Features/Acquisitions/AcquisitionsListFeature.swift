import Foundation
import ComposableArchitecture

@Reducer
public struct AcquisitionsListFeature {
    @ObservableState
    public struct State: Equatable {
        public var acquisitions: [Acquisition] = []
        public var isLoading = false
        public var error: String?
        public var searchText = ""
        public var selectedStatus: Acquisition.Status?
        public var sortOrder: SortOrder = .dateDescending
        public var renamingAcquisitionId: UUID?
        public var newAcquisitionName = ""
        
        public var filteredAcquisitions: [Acquisition] {
            var filtered = acquisitions
            
            // Filter by search text
            if !searchText.isEmpty {
                filtered = filtered.filter { acquisition in
                    let searchLower = searchText.lowercased()
                    return (acquisition.title?.lowercased().contains(searchLower) ?? false) ||
                           (acquisition.projectNumber?.lowercased().contains(searchLower) ?? false) ||
                           (acquisition.requirements?.lowercased().contains(searchLower) ?? false)
                }
            }
            
            // Filter by status
            if let status = selectedStatus {
                filtered = filtered.filter { $0.statusEnum == status }
            }
            
            // Sort
            switch sortOrder {
            case .dateDescending:
                filtered.sort { ($0.createdDate ?? Date()) > ($1.createdDate ?? Date()) }
            case .dateAscending:
                filtered.sort { ($0.createdDate ?? Date()) < ($1.createdDate ?? Date()) }
            case .titleAscending:
                filtered.sort { ($0.title ?? "") < ($1.title ?? "") }
            case .titleDescending:
                filtered.sort { ($0.title ?? "") > ($1.title ?? "") }
            case .statusGrouped:
                filtered.sort { 
                    if $0.statusEnum == $1.statusEnum {
                        return ($0.createdDate ?? Date()) > ($1.createdDate ?? Date())
                    }
                    return $0.statusEnum.rawValue < $1.statusEnum.rawValue
                }
            }
            
            return filtered
        }
        
        public init() {}
    }
    
    public enum Action {
        case onAppear
        case loadAcquisitions
        case acquisitionsLoaded([Acquisition])
        case loadError(String)
        case searchTextChanged(String)
        case statusFilterChanged(Acquisition.Status?)
        case sortOrderChanged(SortOrder)
        case deleteAcquisition(UUID)
        case acquisitionDeleted(UUID)
        case openAcquisition(UUID)
        case shareDocument(UUID)
        case shareContractFile(UUID)
        case duplicateAcquisition(UUID)
        case acquisitionDuplicated(UUID)
        case clearError
        case renameAcquisition(UUID)
        case updateNewAcquisitionName(String)
        case confirmRename
        case cancelRename
        case acquisitionRenamed(UUID, String)
    }
    
    public enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case titleAscending = "Title A-Z"
        case titleDescending = "Title Z-A"
        case statusGrouped = "Status"
    }
    
    @Dependency(\.acquisitionService) var acquisitionService
    @Dependency(\.continuousClock) var clock
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadAcquisitions)
                
            case .loadAcquisitions:
                state.isLoading = true
                state.error = nil
                
                return .run { send in
                    do {
                        try await clock.sleep(for: .milliseconds(300)) // Prevent UI flicker
                        let acquisitions = try await acquisitionService.fetchAcquisitions()
                        await send(.acquisitionsLoaded(acquisitions))
                    } catch {
                        await send(.loadError(error.localizedDescription))
                    }
                }
                
            case let .acquisitionsLoaded(acquisitions):
                state.isLoading = false
                state.acquisitions = acquisitions
                return .none
                
            case let .loadError(error):
                state.isLoading = false
                state.error = error
                return .none
                
            case let .searchTextChanged(text):
                state.searchText = text
                return .none
                
            case let .statusFilterChanged(status):
                state.selectedStatus = status
                return .none
                
            case let .sortOrderChanged(order):
                state.sortOrder = order
                return .none
                
            case let .deleteAcquisition(id):
                return .run { send in
                    do {
                        try await acquisitionService.deleteAcquisition(id)
                        await send(.acquisitionDeleted(id))
                    } catch {
                        await send(.loadError(error.localizedDescription))
                    }
                }
                
            case let .acquisitionDeleted(id):
                state.acquisitions.removeAll { $0.id == id }
                return .none
                
            case .openAcquisition:
                // This will be handled by the parent feature to navigate to document generation
                return .none
                
            case .shareDocument:
                // Share functionality will be handled by parent feature
                // Parent will present share sheet with acquisition documents
                return .none
                
            case .shareContractFile:
                // Share functionality will be handled by parent feature
                // Parent will present share sheet with all contract files and summary
                return .none
                
            case let .duplicateAcquisition(id):
                // Duplicate the acquisition
                return .run { [acquisitionService] send in
                    do {
                        // Fetch the original acquisition
                        guard let original = try await acquisitionService.fetchAcquisition(id) else {
                            await send(.loadError("Acquisition not found"))
                            return
                        }
                        
                        // Create a duplicate with modified title
                        let newTitle = (original.title ?? "Untitled") + " (Copy)"
                        let newAcquisition = try await acquisitionService.createAcquisition(
                            newTitle,
                            original.requirements ?? "",
                            []
                        )
                        
                        await send(.acquisitionDuplicated(newAcquisition.id ?? UUID()))
                        await send(.loadAcquisitions)
                    } catch {
                        await send(.loadError("Failed to duplicate: \(error.localizedDescription)"))
                    }
                }
                
            case .acquisitionDuplicated:
                // Refresh is handled by loadAcquisitions
                return .none
                
            case .clearError:
                state.error = nil
                return .none
                
            case let .renameAcquisition(id):
                state.renamingAcquisitionId = id
                // Find the current name
                if let acquisition = state.acquisitions.first(where: { $0.id == id }) {
                    state.newAcquisitionName = acquisition.title ?? ""
                }
                return .none
                
            case let .updateNewAcquisitionName(name):
                state.newAcquisitionName = name
                return .none
                
            case .confirmRename:
                guard let id = state.renamingAcquisitionId,
                      !state.newAcquisitionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return .send(.cancelRename)
                }
                
                let newName = state.newAcquisitionName.trimmingCharacters(in: .whitespacesAndNewlines)
                
                return .run { send in
                    do {
                        try await acquisitionService.updateAcquisition(id) { acquisition in
                            acquisition.title = newName
                            acquisition.lastModifiedDate = Date()
                        }
                        await send(.acquisitionRenamed(id, newName))
                    } catch {
                        await send(.loadError(error.localizedDescription))
                    }
                }
                
            case .cancelRename:
                state.renamingAcquisitionId = nil
                state.newAcquisitionName = ""
                return .none
                
            case let .acquisitionRenamed(id, newName):
                // Update the local state
                if let index = state.acquisitions.firstIndex(where: { $0.id == id }) {
                    state.acquisitions[index].title = newName
                    state.acquisitions[index].lastModifiedDate = Date()
                }
                state.renamingAcquisitionId = nil
                state.newAcquisitionName = ""
                return .none
            }
        }
    }
}