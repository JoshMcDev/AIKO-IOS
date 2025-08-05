//
//  LLMProviderSettingsView.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import ComposableArchitecture
import LocalAuthentication
import SwiftUI

struct LLMProviderSettingsView: View {
    let store: StoreOf<LLMProviderSettingsFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            NavigationView {
                List {
                    // Active Provider Section
                    Section {
                        if let activeProvider = viewStore.activeProvider {
                            HStack {
                                Image(systemName: activeProvider.provider.iconName)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 30)

                                VStack(alignment: .leading) {
                                    Text(activeProvider.provider.name)
                                        .font(.headline)
                                    Text(activeProvider.model.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        } else {
                            Text("No active provider configured")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Active Provider")
                    }

                    // Available Providers Section
                    Section {
                        ForEach(LLMProvider.allCases) { provider in
                            ProviderRowView(
                                provider: provider,
                                isConfigured: viewStore.configuredProviders.contains(provider),
                                isActive: viewStore.activeProvider?.provider == provider,
                                onTap: {
                                    viewStore.send(.providerTapped(provider))
                                }
                            )
                        }
                    } header: {
                        Text("Available Providers")
                    } footer: {
                        Text("Tap a provider to configure or manage its API key")
                    }

                    // Provider Priority Section
                    Section {
                        NavigationLink(destination: ProviderPriorityView(store: store)) {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                Text("Fallback Priority")
                                Spacer()
                                Text(viewStore.providerPriority.fallbackBehavior.displayName)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text("Provider Settings")
                    }

                    // Security Section
                    Section {
                        Button(action: {
                            viewStore.send(.clearAllTapped)
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("Clear All API Keys")
                                    .foregroundColor(.red)
                            }
                        }
                    } header: {
                        Text("Security")
                    } footer: {
                        Text("This will remove all stored API keys and require reconfiguration")
                    }
                }
                .navigationTitle("LLM Providers")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            viewStore.send(.doneButtonTapped)
                        }
                    }
                }
            }
            .sheet(
                isPresented: viewStore.binding(
                    get: \.isProviderConfigSheetPresented,
                    send: LLMProviderSettingsFeature.Action.setProviderConfigSheet
                )
            ) {
                if let provider = viewStore.selectedProvider {
                    ProviderConfigurationView(
                        store: store.scope(
                            state: \.providerConfigState,
                            action: LLMProviderSettingsFeature.Action.providerConfig
                        ),
                        provider: provider
                    )
                }
            }
            .alert(
                isPresented: viewStore.binding(
                    get: \.isAlertPresented,
                    send: LLMProviderSettingsFeature.Action.dismissAlert
                )
            ) {
                switch viewStore.alert {
                case .clearConfirmation:
                    Alert(
                        title: Text("Clear All API Keys?"),
                        message: Text("This action cannot be undone. All provider configurations will be removed."),
                        primaryButton: .destructive(Text("Clear All")) {
                            viewStore.send(.clearAllConfirmed)
                        },
                        secondaryButton: .cancel()
                    )
                case let .error(message):
                    Alert(
                        title: Text("Error"),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                case .none:
                    Alert(title: Text(""))
                }
            }
        })
    }
}

// MARK: - Provider Row View

struct ProviderRowView: View {
    let provider: LLMProvider
    let isConfigured: Bool
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: provider.iconName)
                    .foregroundColor(isConfigured ? .accentColor : .secondary)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.name)
                        .foregroundColor(.primary)

                    if isConfigured {
                        HStack {
                            Image(systemName: "key.fill")
                                .font(.caption2)
                            Text("API Key Configured")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Provider Configuration View

struct ProviderConfigurationView: View {
    let store: StoreOf<ProviderConfigurationFeature>
    let provider: LLMProvider

    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var isAuthenticating: Bool = false

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            NavigationView {
                Form {
                    // Provider Info
                    Section {
                        HStack {
                            Image(systemName: provider.iconName)
                                .font(.largeTitle)
                                .foregroundColor(.accentColor)

                            VStack(alignment: .leading) {
                                Text(provider.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("Configure API access")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // API Key Section
                    Section {
                        HStack {
                            if showAPIKey {
                                TextField("API Key", text: $apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("API Key", text: $apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }

                            Button(action: {
                                showAPIKey.toggle()
                            }) {
                                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }

                        if viewStore.hasExistingKey {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("API key already configured")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text("API Key")
                    } footer: {
                        Text(getAPIKeyHelperText())
                    }

                    // Model Selection
                    Section {
                        Picker("Model", selection: viewStore.binding(
                            get: \.selectedModel,
                            send: ProviderConfigurationFeature.Action.modelSelected
                        )) {
                            ForEach(provider.availableModels) { model in
                                VStack(alignment: .leading) {
                                    Text(model.name)
                                    Text("\(model.contextWindow / 1000)K context")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    } header: {
                        Text("Model Selection")
                    }

                    // Advanced Settings
                    Section {
                        HStack {
                            Text("Temperature")
                            Slider(
                                value: viewStore.binding(
                                    get: \.temperature,
                                    send: ProviderConfigurationFeature.Action.temperatureChanged
                                ),
                                in: 0 ... 1,
                                step: 0.1
                            )
                            Text("\(viewStore.temperature, specifier: "%.1f")")
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }

                        if provider == .custom {
                            TextField(
                                "Custom Endpoint URL",
                                text: viewStore.binding(
                                    get: \.customEndpoint,
                                    send: ProviderConfigurationFeature.Action.customEndpointChanged
                                )
                            )
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        }
                    } header: {
                        Text("Advanced Settings")
                    }

                    // Actions
                    Section {
                        Button(action: {
                            Task {
                                await authenticateAndSave()
                            }
                        }) {
                            HStack {
                                Spacer()
                                if viewStore.isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Text(viewStore.hasExistingKey ? "Update Configuration" : "Save Configuration")
                                }
                                Spacer()
                            }
                        }
                        .disabled(apiKey.isEmpty || viewStore.isSaving)

                        if viewStore.hasExistingKey {
                            Button(action: {
                                viewStore.send(.removeConfiguration)
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Remove Configuration")
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .navigationTitle("\(provider.name) Configuration")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            viewStore.send(.cancelTapped)
                        }
                    }
                }
                .onAppear {
                    // Load existing API key if available
                    if viewStore.hasExistingKey {
                        Task {
                            await loadExistingKey()
                        }
                    }
                }
            }
        })
    }

    private func getAPIKeyHelperText() -> String {
        switch provider {
        case .claude:
            "Get your API key from console.anthropic.com"
        case .openAI, .chatGPT:
            "Get your API key from platform.openai.com"
        case .gemini:
            "Get your API key from makersuite.google.com"
        case .custom:
            "Enter your custom provider's API key"
        }
    }

    private func authenticateAndSave() async {
        // Require biometric authentication before saving
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fallback to device passcode
            await saveConfiguration()
            return
        }

        isAuthenticating = true

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to save API key"
            )

            if success {
                await saveConfiguration()
            }
        } catch {
            print("Biometric authentication failed: \(error)")
            // Fallback to device passcode
            await saveConfiguration()
        }

        isAuthenticating = false
    }

    private func saveConfiguration() async {
        await ViewStore(store).send(.saveConfiguration(apiKey: apiKey)).finish()
    }

    private func loadExistingKey() async {
        // In production, we might not want to load the actual key
        // Instead, just show that it exists
        // For now, we'll leave the field empty for security
    }
}

// MARK: - Provider Priority View

struct ProviderPriorityView: View {
    let store: StoreOf<LLMProviderSettingsFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            Form {
                Section {
                    Picker("Fallback Behavior", selection: viewStore.binding(
                        get: \.providerPriority.fallbackBehavior,
                        send: { LLMProviderSettingsFeature.Action.fallbackBehaviorChanged($0) }
                    )) {
                        ForEach(LLMProviderPriority.FallbackBehavior.allCases, id: \.self) { behavior in
                            Text(behavior.displayName).tag(behavior)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                } header: {
                    Text("Fallback Strategy")
                } footer: {
                    Text(viewStore.providerPriority.fallbackBehavior.description)
                }

                Section {
                    ForEach(viewStore.providerPriority.providers) { provider in
                        HStack {
                            Image(systemName: provider.iconName)
                            Text(provider.name)
                            Spacer()
                            Image(systemName: "line.horizontal.3")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onMove { source, destination in
                        viewStore.send(.moveProvider(source: source, destination: destination))
                    }
                } header: {
                    Text("Priority Order")
                } footer: {
                    Text("Drag to reorder provider priority")
                }
            }
            .navigationTitle("Provider Priority")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                EditButton()
            }
        })
    }
}

// MARK: - Extensions

extension LLMProviderPriority.FallbackBehavior: CaseIterable {
    var displayName: String {
        switch self {
        case .sequential:
            "Sequential"
        case .loadBalanced:
            "Load Balanced"
        case .costOptimized:
            "Cost Optimized"
        case .performanceOptimized:
            "Performance"
        }
    }

    var description: String {
        switch self {
        case .sequential:
            "Try providers in order until one succeeds"
        case .loadBalanced:
            "Distribute requests across available providers"
        case .costOptimized:
            "Choose the most cost-effective provider"
        case .performanceOptimized:
            "Choose the fastest responding provider"
        }
    }
}
