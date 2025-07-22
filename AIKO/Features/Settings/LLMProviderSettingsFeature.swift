//
//  LLMProviderSettingsFeature.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import ComposableArchitecture
import Foundation

struct LLMProviderSettingsFeature: Reducer {
    struct State: Equatable {
        var activeProvider: LLMProviderConfig?
        var configuredProviders: [LLMProvider] = []
        var providerPriority: LLMProviderPriority

        var selectedProvider: LLMProvider?
        var isProviderConfigSheetPresented: Bool = false
        var providerConfigState: ProviderConfigurationFeature.State?

        var alert: AlertType?
        var isAlertPresented: Bool { alert != nil }

        enum AlertType: Equatable {
            case clearConfirmation
            case error(String)
        }
    }

    enum Action: Equatable {
        case onAppear
        case doneButtonTapped
        case providerTapped(LLMProvider)
        case setProviderConfigSheet(Bool)
        case providerConfig(ProviderConfigurationFeature.Action)
        case clearAllTapped
        case clearAllConfirmed
        case dismissAlert
        case fallbackBehaviorChanged(LLMProviderPriority.FallbackBehavior)
        case moveProvider(source: IndexSet, destination: Int)

        // Effects
        case loadConfigurationsResponse(
            activeProvider: LLMProviderConfig?,
            configuredProviders: [LLMProvider],
            priority: LLMProviderPriority
        )
        case clearAllResponse(Result<Void, Error>)
        case providerPriorityUpdated
    }

    @Dependency(\.llmConfiguration) var configurationClient
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let activeProvider = await configurationClient.getActiveProvider()
                    let configuredProviders = await configurationClient.getAvailableProviders()

                    // Load saved priority or use default
                    let priority = LLMProviderPriority(
                        providers: [.claude, .openAI, .gemini],
                        fallbackBehavior: .sequential
                    )

                    await send(.loadConfigurationsResponse(
                        activeProvider: activeProvider,
                        configuredProviders: configuredProviders,
                        priority: priority
                    ))
                }

            case .doneButtonTapped:
                return .run { _ in
                    await dismiss()
                }

            case let .providerTapped(provider):
                state.selectedProvider = provider
                guard let defaultModel = provider.defaultModel ?? provider.availableModels.first else {
                    // Should not happen as providers should always have at least one model
                    return .none
                }

                state.providerConfigState = ProviderConfigurationFeature.State(
                    provider: provider,
                    hasExistingKey: state.configuredProviders.contains(provider),
                    selectedModel: defaultModel,
                    temperature: 0.7
                )
                state.isProviderConfigSheetPresented = true
                return .none

            case let .setProviderConfigSheet(isPresented):
                state.isProviderConfigSheetPresented = isPresented
                if !isPresented {
                    state.selectedProvider = nil
                    state.providerConfigState = nil
                }
                return .none

            case .providerConfig(.configurationSaved):
                state.isProviderConfigSheetPresented = false
                // Reload configurations
                return .send(.onAppear)

            case .providerConfig(.configurationRemoved):
                state.isProviderConfigSheetPresented = false
                // Reload configurations
                return .send(.onAppear)

            case .providerConfig(.cancelTapped):
                state.isProviderConfigSheetPresented = false
                return .none

            case .providerConfig:
                return .none

            case .clearAllTapped:
                state.alert = .clearConfirmation
                return .none

            case .clearAllConfirmed:
                state.alert = nil
                return .run { send in
                    do {
                        try await configurationClient.clearAllConfigurations()
                        await send(.clearAllResponse(.success(())))
                    } catch {
                        await send(.clearAllResponse(.failure(error)))
                    }
                }

            case .dismissAlert:
                state.alert = nil
                return .none

            case let .fallbackBehaviorChanged(behavior):
                state.providerPriority = LLMProviderPriority(
                    providers: state.providerPriority.providers,
                    fallbackBehavior: behavior
                )
                return .run { [priority = state.providerPriority] send in
                    await configurationClient.updateProviderPriority(priority)
                    await send(.providerPriorityUpdated)
                }

            case let .moveProvider(source, destination):
                var providers = state.providerPriority.providers
                providers.move(fromOffsets: source, toOffset: destination)
                state.providerPriority = LLMProviderPriority(
                    providers: providers,
                    fallbackBehavior: state.providerPriority.fallbackBehavior
                )
                return .run { [priority = state.providerPriority] send in
                    await configurationClient.updateProviderPriority(priority)
                    await send(.providerPriorityUpdated)
                }

            case let .loadConfigurationsResponse(activeProvider, configuredProviders, priority):
                state.activeProvider = activeProvider
                state.configuredProviders = configuredProviders
                state.providerPriority = priority
                return .none

            case .clearAllResponse(.success):
                state.activeProvider = nil
                state.configuredProviders = []
                return .none

            case let .clearAllResponse(.failure(error)):
                state.alert = .error(error.localizedDescription)
                return .none

            case .providerPriorityUpdated:
                return .none
            }
        }
        .ifLet(\.providerConfigState, action: /Action.providerConfig) {
            ProviderConfigurationFeature()
        }
    }
}

// MARK: - Provider Configuration Feature

struct ProviderConfigurationFeature: Reducer {
    struct State: Equatable {
        let provider: LLMProvider
        var hasExistingKey: Bool
        var selectedModel: LLMModel
        var temperature: Double
        var customEndpoint: String = ""
        var isSaving: Bool = false
    }

    enum Action: Equatable {
        case cancelTapped
        case saveConfiguration(apiKey: String)
        case removeConfiguration
        case modelSelected(LLMModel)
        case temperatureChanged(Double)
        case customEndpointChanged(String)

        // Effects
        case saveConfigurationResponse(Result<Void, Error>)
        case removeConfigurationResponse(Result<Void, Error>)
        case configurationSaved
        case configurationRemoved
    }

    @Dependency(\.llmConfiguration) var configurationClient
    @Dependency(\.llmKeychain) var keychainClient
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .cancelTapped:
                return .run { _ in
                    await dismiss()
                }

            case let .saveConfiguration(apiKey):
                guard !apiKey.isEmpty else { return .none }

                // Validate API key format
                let isValid = keychainClient.validateAPIKeyFormat(apiKey, state.provider)
                guard isValid else {
                    return .none // Could show error
                }

                state.isSaving = true

                let config = LLMProviderConfig(
                    provider: state.provider,
                    model: state.selectedModel,
                    customEndpoint: state.customEndpoint.isEmpty ? nil : state.customEndpoint,
                    temperature: state.temperature
                )

                return .run { [provider = state.provider] send in
                    do {
                        try await configurationClient.configureProvider(
                            provider,
                            apiKey,
                            config
                        )
                        await send(.saveConfigurationResponse(.success(())))
                    } catch {
                        await send(.saveConfigurationResponse(.failure(error)))
                    }
                }

            case .removeConfiguration:
                state.isSaving = true
                return .run { [provider = state.provider] send in
                    do {
                        try await configurationClient.removeProvider(provider)
                        await send(.removeConfigurationResponse(.success(())))
                    } catch {
                        await send(.removeConfigurationResponse(.failure(error)))
                    }
                }

            case let .modelSelected(model):
                state.selectedModel = model
                return .none

            case let .temperatureChanged(temperature):
                state.temperature = temperature
                return .none

            case let .customEndpointChanged(endpoint):
                state.customEndpoint = endpoint
                return .none

            case .saveConfigurationResponse(.success):
                state.isSaving = false
                return .send(.configurationSaved)

            case .saveConfigurationResponse(.failure):
                state.isSaving = false
                // Could show error alert
                return .none

            case .removeConfigurationResponse(.success):
                state.isSaving = false
                return .send(.configurationRemoved)

            case .removeConfigurationResponse(.failure):
                state.isSaving = false
                // Could show error alert
                return .none

            case .configurationSaved, .configurationRemoved:
                return .run { _ in
                    await dismiss()
                }
            }
        }
    }
}
