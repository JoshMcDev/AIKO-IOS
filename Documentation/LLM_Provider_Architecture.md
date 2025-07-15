# LLM Provider Agnostic Architecture for AIKO

**Date**: July 15, 2025  
**Version**: 1.0  
**Status**: Design Phase  
**Priority**: CRITICAL - Vendor Independence for Government  

---

## Executive Summary

AIKO will implement a protocol-oriented, provider-agnostic architecture for LLM integration. This design allows government users to choose their preferred AI provider (Claude, OpenAI, Google Gemini, etc.) and use their own API keys, ensuring vendor independence and compliance with government procurement requirements.

---

## 1. Architecture Overview

### Core Design Pattern: Protocol-Oriented Architecture with Adapter Pattern

```swift
// MARK: - Core LLM Protocol
protocol LLMProviderProtocol {
    var providerName: String { get }
    var capabilities: LLMCapabilities { get }
    
    func sendRequest(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions
    ) async throws -> LLMResponse
    
    func streamRequest(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions
    ) -> AsyncThrowingStream<LLMStreamChunk, Error>
    
    func validateAPIKey(_ key: String) async throws -> Bool
    func getUsage() async throws -> LLMUsageMetrics
}

// MARK: - Provider Capabilities
struct LLMCapabilities {
    let maxTokens: Int
    let supportsStreaming: Bool
    let supportsFunctionCalling: Bool
    let supportsVision: Bool
    let supportsDocumentGeneration: Bool
    let costPerToken: Decimal?
    let specialFeatures: Set<String>
}

// MARK: - Unified Response Model
struct LLMResponse {
    let content: String
    let usage: TokenUsage
    let metadata: [String: Any]
    let providerSpecificData: Any?
}
```

---

## 2. Provider Implementation Architecture

### 2.1 Provider Adapters

```swift
// MARK: - Claude Adapter
final class ClaudeAdapter: LLMProviderProtocol {
    let providerName = "Claude (Anthropic)"
    let capabilities = LLMCapabilities(
        maxTokens: 200_000,
        supportsStreaming: true,
        supportsFunctionCalling: true,
        supportsVision: true,
        supportsDocumentGeneration: true,
        costPerToken: 0.00003,
        specialFeatures: ["constitutional-ai", "long-context"]
    )
    
    private let apiKey: String
    private let apiClient: ClaudeAPIClient
    
    init(apiKey: String) throws {
        self.apiKey = apiKey
        self.apiClient = ClaudeAPIClient(apiKey: apiKey)
    }
    
    func sendRequest(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions
    ) async throws -> LLMResponse {
        // Claude-specific implementation
    }
}

// MARK: - OpenAI Adapter
final class OpenAIAdapter: LLMProviderProtocol {
    let providerName = "OpenAI (GPT-4)"
    let capabilities = LLMCapabilities(
        maxTokens: 128_000,
        supportsStreaming: true,
        supportsFunctionCalling: true,
        supportsVision: true,
        supportsDocumentGeneration: true,
        costPerToken: 0.00006,
        specialFeatures: ["code-interpreter", "dalle-integration"]
    )
    
    // Implementation...
}

// MARK: - Gemini Adapter
final class GeminiAdapter: LLMProviderProtocol {
    let providerName = "Google Gemini"
    let capabilities = LLMCapabilities(
        maxTokens: 1_000_000,
        supportsStreaming: true,
        supportsFunctionCalling: true,
        supportsVision: true,
        supportsDocumentGeneration: true,
        costPerToken: 0.00002,
        specialFeatures: ["multimodal", "gemini-code"]
    )
    
    // Implementation...
}
```

### 2.2 LLM Service Manager (Facade Pattern)

```swift
// MARK: - LLM Service Manager
final class LLMServiceManager: ObservableObject {
    @Published var currentProvider: LLMProviderProtocol?
    @Published var availableProviders: [LLMProviderType] = []
    @Published var providerStatus: [LLMProviderType: ProviderStatus] = [:]
    
    private let keychainManager: KeychainManager
    private let fallbackManager: FallbackManager
    private var providers: [LLMProviderType: LLMProviderProtocol] = [:]
    
    init(keychainManager: KeychainManager) {
        self.keychainManager = keychainManager
        self.fallbackManager = FallbackManager()
        loadConfiguredProviders()
    }
    
    // MARK: - Provider Management
    func configureProvider(
        type: LLMProviderType,
        apiKey: String
    ) async throws {
        // Validate API key
        let provider = try createProvider(type: type, apiKey: apiKey)
        let isValid = try await provider.validateAPIKey(apiKey)
        
        guard isValid else {
            throw LLMError.invalidAPIKey
        }
        
        // Store in Keychain
        try keychainManager.storeAPIKey(
            apiKey,
            for: type,
            withBiometric: true
        )
        
        providers[type] = provider
        
        if currentProvider == nil {
            currentProvider = provider
        }
    }
    
    // MARK: - Request Handling with Fallback
    func sendRequest(
        prompt: String,
        context: ConversationContext? = nil,
        options: LLMRequestOptions = .default
    ) async throws -> LLMResponse {
        guard let provider = currentProvider else {
            throw LLMError.noProviderConfigured
        }
        
        do {
            return try await provider.sendRequest(
                prompt: prompt,
                context: context,
                options: options
            )
        } catch {
            // Attempt fallback
            if let fallbackProvider = try await fallbackManager.getNextProvider(
                after: provider,
                from: Array(providers.values)
            ) {
                currentProvider = fallbackProvider
                return try await sendRequest(
                    prompt: prompt,
                    context: context,
                    options: options
                )
            }
            throw error
        }
    }
}
```

---

## 3. Secure API Key Management

### 3.1 Keychain Integration

```swift
// MARK: - Keychain Manager for API Keys
final class LLMKeychainManager {
    private let service = "com.aiko.llm.apikeys"
    private let accessGroup = "com.aiko.shared"
    
    enum KeychainError: Error {
        case storeFailed
        case retrieveFailed
        case deleteFailed
        case biometricFailed
    }
    
    // MARK: - Store API Key with Biometric Protection
    func storeAPIKey(
        _ key: String,
        for provider: LLMProviderType,
        withBiometric: Bool = true
    ) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
            kSecValueData as String: key.data(using: .utf8)!,
            kSecAttrAccessGroup as String: accessGroup
        ]
        
        if withBiometric {
            let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                nil
            )!
            
            query[kSecAttrAccessControl as String] = access
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw KeychainError.storeFailed
        }
    }
    
    // MARK: - Retrieve API Key
    func retrieveAPIKey(
        for provider: LLMProviderType
    ) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: accessGroup
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &dataTypeRef
        )
        
        if status == errSecSuccess {
            if let data = dataTypeRef as? Data,
               let key = String(data: data, encoding: .utf8) {
                return key
            }
        }
        
        throw KeychainError.retrieveFailed
    }
}
```

### 3.2 Government Security Compliance

```swift
// MARK: - Security Audit Trail
struct APIKeyAuditEvent {
    let timestamp: Date
    let provider: LLMProviderType
    let action: APIKeyAction
    let userId: String
    let deviceId: String
    let success: Bool
    
    enum APIKeyAction: String {
        case stored
        case retrieved
        case updated
        case deleted
        case validated
    }
}

// MARK: - FIPS 140-2 Compliant Encryption
extension LLMKeychainManager {
    func encryptAPIKey(_ key: String) throws -> Data {
        // Use CommonCrypto with FIPS-approved algorithms
        // AES-256-GCM encryption
    }
}
```

---

## 4. Provider-Specific Feature Handling

### 4.1 Feature Flags and Capabilities

```swift
// MARK: - Dynamic Feature Management
struct LLMFeatureManager {
    func isFeatureAvailable(
        _ feature: LLMFeature,
        for provider: LLMProviderProtocol
    ) -> Bool {
        switch feature {
        case .functionCalling:
            return provider.capabilities.supportsFunctionCalling
        case .vision:
            return provider.capabilities.supportsVision
        case .documentGeneration:
            return provider.capabilities.supportsDocumentGeneration
        case .streaming:
            return provider.capabilities.supportsStreaming
        case .specialFeature(let name):
            return provider.capabilities.specialFeatures.contains(name)
        }
    }
    
    func adaptRequestForProvider(
        _ request: UniversalLLMRequest,
        provider: LLMProviderProtocol
    ) -> LLMRequestOptions {
        var options = LLMRequestOptions.default
        
        // Adapt based on provider capabilities
        if !provider.capabilities.supportsStreaming {
            options.streaming = false
        }
        
        if provider.capabilities.maxTokens < request.desiredTokens {
            options.maxTokens = provider.capabilities.maxTokens
        }
        
        return options
    }
}
```

### 4.2 Provider-Specific UI Configuration

```swift
// MARK: - Provider Settings View
struct LLMProviderSettingsView: View {
    @StateObject private var manager = LLMServiceManager.shared
    @State private var selectedProvider: LLMProviderType = .claude
    @State private var apiKey: String = ""
    @State private var showingAPIKeyInput = false
    
    var body: some View {
        Form {
            Section("Active Provider") {
                Picker("LLM Provider", selection: $selectedProvider) {
                    ForEach(LLMProviderType.allCases) { provider in
                        HStack {
                            Image(provider.iconName)
                            Text(provider.displayName)
                            if manager.providerStatus[provider] == .active {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .tag(provider)
                    }
                }
                
                if let currentProvider = manager.currentProvider {
                    ProviderCapabilitiesView(provider: currentProvider)
                }
            }
            
            Section("API Key Management") {
                SecureField("API Key", text: $apiKey)
                
                Button("Configure Provider") {
                    Task {
                        try await manager.configureProvider(
                            type: selectedProvider,
                            apiKey: apiKey
                        )
                        apiKey = ""
                    }
                }
                .disabled(apiKey.isEmpty)
            }
            
            Section("Fallback Order") {
                FallbackOrderConfigurationView()
            }
        }
    }
}
```

---

## 5. Graceful Fallback System

### 5.1 Fallback Manager

```swift
// MARK: - Fallback Manager
final class FallbackManager {
    struct FallbackConfiguration {
        var priorityOrder: [LLMProviderType]
        var healthCheckInterval: TimeInterval = 300 // 5 minutes
        var maxRetries: Int = 3
        var retryDelay: TimeInterval = 1.0
    }
    
    private var configuration: FallbackConfiguration
    private var providerHealth: [LLMProviderType: HealthStatus] = [:]
    
    func getNextProvider(
        after failedProvider: LLMProviderProtocol,
        from availableProviders: [LLMProviderProtocol]
    ) async throws -> LLMProviderProtocol? {
        let failedType = LLMProviderType(from: failedProvider.providerName)
        
        // Update health status
        providerHealth[failedType] = .unhealthy(since: Date())
        
        // Find next healthy provider in priority order
        for providerType in configuration.priorityOrder {
            if providerType == failedType { continue }
            
            if let provider = availableProviders.first(where: {
                LLMProviderType(from: $0.providerName) == providerType
            }) {
                // Perform health check
                if await isProviderHealthy(provider) {
                    return provider
                }
            }
        }
        
        return nil
    }
    
    private func isProviderHealthy(_ provider: LLMProviderProtocol) async -> Bool {
        do {
            // Simple health check - validate API key still works
            _ = try await provider.validateAPIKey("")
            return true
        } catch {
            return false
        }
    }
}
```

---

## 6. Integration with AIKO Features

### 6.1 Document Generation Integration

```swift
// MARK: - Document Generation with Provider Flexibility
struct DocumentGenerationService {
    let llmManager: LLMServiceManager
    
    func generateDocument(
        type: DocumentType,
        context: ContractContext
    ) async throws -> GeneratedDocument {
        // Check if current provider supports document generation
        guard let provider = llmManager.currentProvider,
              provider.capabilities.supportsDocumentGeneration else {
            throw DocumentError.providerDoesNotSupportDocumentGeneration
        }
        
        let prompt = DocumentPromptBuilder.build(
            for: type,
            with: context,
            optimizedFor: provider.providerName
        )
        
        let response = try await llmManager.sendRequest(
            prompt: prompt,
            context: context.conversationContext,
            options: .documentGeneration
        )
        
        return GeneratedDocument(
            content: response.content,
            metadata: response.metadata,
            provider: provider.providerName
        )
    }
}
```

### 6.2 User Pattern Learning Integration

```swift
// MARK: - Pattern Learning with Multi-Provider Support
extension UserPatternLearningEngine {
    func recordProviderPreference(
        provider: LLMProviderType,
        for taskType: TaskType,
        satisfaction: Double
    ) {
        // Track which providers work best for which tasks
        providerPreferences[taskType, default: [:]][provider] = satisfaction
    }
    
    func recommendProvider(for taskType: TaskType) -> LLMProviderType? {
        guard let preferences = providerPreferences[taskType] else {
            return nil
        }
        
        return preferences.max(by: { $0.value < $1.value })?.key
    }
}
```

---

## 7. Implementation Timeline

### Phase 1: Core Architecture (Week 1-2)
- [ ] Define LLMProviderProtocol and core types
- [ ] Implement Keychain manager for secure storage
- [ ] Create base adapter architecture
- [ ] Design fallback system

### Phase 2: Provider Adapters (Week 3-4)
- [ ] Implement Claude adapter
- [ ] Implement OpenAI adapter
- [ ] Implement Google Gemini adapter
- [ ] Add validation and health checks

### Phase 3: Integration (Week 5-6)
- [ ] Integrate with document generation
- [ ] Update UI for provider selection
- [ ] Implement fallback testing
- [ ] Security audit

### Phase 4: Testing & Polish (Week 7-8)
- [ ] Comprehensive testing across providers
- [ ] Performance optimization
- [ ] Government compliance verification
- [ ] Documentation completion

---

## 8. Migration Strategy

### From Claude-Only to Multi-Provider

```swift
// MARK: - Migration Helper
struct LLMMigrationService {
    static func migrateFromClaudeOnly() async throws {
        // 1. Check for existing Claude API key
        if let existingKey = try? KeychainHelper.retrieve("claude_api_key") {
            // 2. Migrate to new structure
            let manager = LLMServiceManager.shared
            try await manager.configureProvider(
                type: .claude,
                apiKey: existingKey
            )
            
            // 3. Set Claude as default
            UserDefaults.standard.set(
                LLMProviderType.claude.rawValue,
                forKey: "default_llm_provider"
            )
            
            // 4. Clean up old storage
            try? KeychainHelper.delete("claude_api_key")
        }
    }
}
```

---

## 9. Cost Management

### 9.1 Usage Tracking

```swift
struct LLMUsageTracker {
    func trackUsage(
        provider: LLMProviderType,
        tokens: TokenUsage,
        cost: Decimal?
    ) {
        // Track usage for government billing/reporting
        let usage = ProviderUsage(
            provider: provider,
            date: Date(),
            promptTokens: tokens.prompt,
            completionTokens: tokens.completion,
            estimatedCost: cost
        )
        
        // Store in Core Data for reporting
        CoreDataManager.shared.save(usage)
    }
}
```

---

## 10. Government Compliance Considerations

### Security Requirements
1. **FIPS 140-2**: All API keys encrypted with approved algorithms
2. **Audit Trail**: Complete logging of provider changes and API usage
3. **Data Residency**: Ensure providers comply with data location requirements
4. **Access Control**: Role-based access to provider configuration

### Procurement Compliance
1. **Vendor Neutrality**: No hardcoded preference for any provider
2. **Cost Transparency**: Clear usage and cost reporting
3. **Open Competition**: Easy addition of new providers
4. **Configuration Export**: Ability to export/import provider configs

---

**Document Version**: 1.0  
**Last Updated**: July 15, 2025  
**Next Review**: After Phase 1 Implementation