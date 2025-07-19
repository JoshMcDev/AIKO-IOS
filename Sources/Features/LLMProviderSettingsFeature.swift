import ComposableArchitecture
import Foundation
import AppCore

// MARK: - LLM Provider Settings Feature

@Reducer
struct LLMProviderSettingsFeature {
    @ObservableState
    struct State: Equatable {
        var availableProviders: IdentifiedArrayOf<ProviderState> = []
        var activeProvider: (any LLMProviderProtocol)?
        var selectedProvider: (any LLMProviderProtocol)?
        @Presents var configurationSheet: LLMProviderConfigurationFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
        
        struct ProviderState: Equatable, Identifiable {
            let provider: any LLMProviderProtocol
            let isActive: Bool
            let isConfigured: Bool
            
            var id: String { provider.id }
            
            static func == (lhs: ProviderState, rhs: ProviderState) -> Bool {
                lhs.id == rhs.id && lhs.isActive == rhs.isActive && lhs.isConfigured == rhs.isConfigured
            }
        }
        
        static func == (lhs: State, rhs: State) -> Bool {
            lhs.availableProviders == rhs.availableProviders &&
            lhs.activeProvider?.id == rhs.activeProvider?.id &&
            lhs.selectedProvider?.id == rhs.selectedProvider?.id &&
            lhs.configurationSheet == rhs.configurationSheet &&
            lhs.alert == rhs.alert
        }
    }
    
    enum Action {
        case onAppear
        case loadProviders
        case providersLoaded([State.ProviderState], activeId: String?)
        case selectProvider(String)
        case configureProvider(any LLMProviderProtocol)
        case setActiveProvider(String)
        case removeProvider(String)
        case configurationSheet(PresentationAction<LLMProviderConfigurationFeature.Action>)
        case alert(PresentationAction<Alert>)
        
        enum Alert: Equatable {
            case confirmRemove(String)
            case confirmSetActive(String)
        }
    }
    
    @Dependency(\.llmManager) var llmManager
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadProviders)
                
            case .loadProviders:
                return .run { send in
                    // Get all providers and their configuration status
                    let allProviders = await llmManager.getAllProviders()
                    let activeProviderId = await llmManager.activeProvider?.id
                    
                    let providerStates = await allProviders.asyncMap { provider in
                        let isConfigured = await provider.isConfigured
                        return State.ProviderState(
                            provider: provider,
                            isActive: provider.id == activeProviderId,
                            isConfigured: isConfigured
                        )
                    }
                    
                    await send(.providersLoaded(providerStates, activeId: activeProviderId))
                }
                
            case let .providersLoaded(providers, activeId):
                state.availableProviders = IdentifiedArray(uniqueElements: providers)
                if let activeId = activeId,
                   let activeProvider = providers.first(where: { $0.id == activeId })?.provider {
                    state.activeProvider = activeProvider
                }
                return .none
                
            case let .selectProvider(providerId):
                guard let providerState = state.availableProviders[id: providerId] else {
                    return .none
                }
                
                state.selectedProvider = providerState.provider
                
                if providerState.isConfigured {
                    if !providerState.isActive {
                        state.alert = AlertState {
                            TextState("Set Active Provider")
                        } actions: {
                            ButtonState(role: .cancel) {
                                TextState("Cancel")
                            }
                            ButtonState(action: .confirmSetActive(providerId)) {
                                TextState("Set Active")
                            }
                        } message: {
                            TextState("Set \(providerState.provider.name) as the active LLM provider?")
                        }
                    }
                } else {
                    return .send(.configureProvider(providerState.provider))
                }
                
                return .none
                
            case let .configureProvider(provider):
                state.configurationSheet = LLMProviderConfigurationFeature.State(
                    provider: provider
                )
                return .none
                
            case let .setActiveProvider(providerId):
                return .run { send in
                    do {
                        try await llmManager.setActiveProvider(providerId)
                        await send(.loadProviders)
                    } catch {
                        // Handle error
                        print("Failed to set active provider: \(error)")
                    }
                }
                
            case let .removeProvider(providerId):
                state.alert = AlertState {
                    TextState("Remove Provider")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmRemove(providerId)) {
                        TextState("Remove")
                    }
                    ButtonState(role: .cancel) {
                        TextState("Cancel")
                    }
                } message: {
                    TextState("Remove the API key and configuration for this provider?")
                }
                return .none
                
            case .configurationSheet(.presented(.saved)):
                state.configurationSheet = nil
                return .send(.loadProviders)
                
            case .configurationSheet(.dismiss):
                state.configurationSheet = nil
                return .none
                
            case .alert(.presented(.confirmSetActive(let providerId))):
                state.alert = nil
                return .send(.setActiveProvider(providerId))
                
            case .alert(.presented(.confirmRemove(let providerId))):
                state.alert = nil
                return .run { send in
                    do {
                        try await llmManager.removeProviderConfiguration(providerId)
                        await send(.loadProviders)
                    } catch {
                        print("Failed to remove provider: \(error)")
                    }
                }
                
            case .alert(.dismiss):
                state.alert = nil
                return .none
                
            case .configurationSheet:
                return .none
            }
        }
        .ifLet(\.$configurationSheet, action: \.configurationSheet) {
            LLMProviderConfigurationFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Provider Configuration Feature

@Reducer
struct LLMProviderConfigurationFeature {
    @ObservableState
    struct State: Equatable {
        let provider: any LLMProviderProtocol
        var apiKey: String = ""
        var organizationId: String = ""
        var customEndpoint: String = ""
        var deploymentName: String = ""
        var isValidating: Bool = false
        
        var canSave: Bool {
            if provider.id == "local" {
                return !customEndpoint.isEmpty
            } else if provider.id == "azure-openai" {
                return !apiKey.isEmpty && !customEndpoint.isEmpty && !deploymentName.isEmpty
            } else {
                return !apiKey.isEmpty
            }
        }
        
        static func == (lhs: State, rhs: State) -> Bool {
            lhs.provider.id == rhs.provider.id &&
            lhs.apiKey == rhs.apiKey &&
            lhs.organizationId == rhs.organizationId &&
            lhs.customEndpoint == rhs.customEndpoint &&
            lhs.deploymentName == rhs.deploymentName &&
            lhs.isValidating == rhs.isValidating
        }
    }
    
    enum Action {
        case updateAPIKey(String)
        case updateOrganizationId(String)
        case updateCustomEndpoint(String)
        case updateDeploymentName(String)
        case saveTapped
        case cancelTapped
        case validationStarted
        case validationCompleted(Result<Bool, Error>)
        case saved
    }
    
    @Dependency(\.llmManager) var llmManager
    @Dependency(\.dismiss) var dismiss
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .updateAPIKey(key):
                state.apiKey = key
                return .none
                
            case let .updateOrganizationId(id):
                state.organizationId = id
                return .none
                
            case let .updateCustomEndpoint(endpoint):
                state.customEndpoint = endpoint
                return .none
                
            case let .updateDeploymentName(name):
                state.deploymentName = name
                return .none
                
            case .saveTapped:
                state.isValidating = true
                return .run { [state] send in
                    await send(.validationStarted)
                    
                    // Build configuration
                    var additionalSettings: [String: String] = [:]
                    if state.provider.id == "azure-openai" {
                        additionalSettings["deploymentName"] = state.deploymentName
                    }
                    
                    let config = LLMProviderConfig(
                        provider: state.provider.id,
                        providerId: state.provider.id,
                        model: state.provider.capabilities.supportedModels.first?.id ?? "",
                        apiKey: state.apiKey,
                        organizationId: state.organizationId.isEmpty ? nil : state.organizationId,
                        customEndpoint: state.customEndpoint.isEmpty ? nil : state.customEndpoint,
                        customHeaders: additionalSettings.isEmpty ? nil : additionalSettings,
                        temperature: 0.7
                    )
                    
                    do {
                        try await llmManager.configureProvider(config)
                        await send(.validationCompleted(.success(true)))
                    } catch {
                        await send(.validationCompleted(.failure(error)))
                    }
                }
                
            case .cancelTapped:
                return .run { _ in
                    await dismiss()
                }
                
            case .validationStarted:
                return .none
                
            case let .validationCompleted(result):
                state.isValidating = false
                
                switch result {
                case .success:
                    return .send(.saved)
                    
                case .failure(let error):
                    // Show error alert
                    print("Validation failed: \(error)")
                    return .none
                }
                
            case .saved:
                return .run { _ in
                    await dismiss()
                }
            }
        }
    }
}

// MARK: - Async Extensions

extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()
        
        for element in self {
            try await values.append(transform(element))
        }
        
        return values
    }
}