# LLM Provider Migration Guide

**From**: Claude API Integration  
**To**: Multi-Provider LLM Architecture  
**Date**: July 15, 2025  
**Impact**: High - Core Architecture Change  

---

## Overview

This guide documents the migration from a Claude-specific implementation to a vendor-agnostic LLM architecture that supports multiple AI providers (Claude, OpenAI, Google Gemini, and future providers).

---

## Migration Rationale

### Government Requirements
1. **Vendor Independence**: Government contracts require vendor neutrality
2. **Procurement Flexibility**: Agencies need choice in AI providers
3. **Cost Management**: Different providers for different use cases
4. **Resilience**: Fallback options if primary provider fails

### Technical Benefits
1. **Future-Proof**: Easy addition of new providers
2. **Feature Optimization**: Use best provider for each task
3. **User Control**: Agencies manage their own API keys
4. **Security**: Provider-specific key isolation

---

## Breaking Changes

### 1. API Client Changes

#### Before (Claude-Specific)
```swift
class ClaudeAPIClient {
    func sendMessage(_ message: String) async throws -> String
}

let client = ClaudeAPIClient(apiKey: "sk-xxx")
let response = try await client.sendMessage(prompt)
```

#### After (Provider-Agnostic)
```swift
protocol LLMProviderProtocol {
    func sendRequest(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions
    ) async throws -> LLMResponse
}

let manager = LLMServiceManager.shared
let response = try await manager.sendRequest(
    prompt: prompt,
    options: .default
)
```

### 2. Configuration Changes

#### Before
```swift
// Single API key in UserDefaults
UserDefaults.standard.set(claudeAPIKey, forKey: "claude_api_key")
```

#### After
```swift
// Provider-specific keys in Keychain
try keychainManager.storeAPIKey(
    apiKey,
    for: .claude,
    withBiometric: true
)
```

### 3. Document Generation Changes

#### Before
```swift
let document = try await claudeClient.generateDocument(
    type: .letterOfJustification,
    context: contractContext
)
```

#### After
```swift
let document = try await documentService.generateDocument(
    type: .letterOfJustification,
    context: contractContext
)
// Provider selected automatically based on capabilities and availability
```

---

## Migration Steps

### Step 1: Update Dependencies
```bash
# Remove Claude-specific SDK
# pod 'ClaudeSDK'

# Add provider SDKs
pod 'OpenAI'
pod 'GoogleGenerativeAI'
# Claude API will use URLSession directly
```

### Step 2: Implement Core Protocols
1. Create `LLMProviderProtocol.swift`
2. Define `LLMResponse` and related types
3. Implement `LLMServiceManager`

### Step 3: Create Provider Adapters
1. `ClaudeAdapter.swift` - Migrate existing Claude code
2. `OpenAIAdapter.swift` - New implementation
3. `GeminiAdapter.swift` - New implementation

### Step 4: Update UI Components
1. Add provider selection in Settings
2. Update API key input screens
3. Add provider status indicators

### Step 5: Migrate Existing Data
```swift
// Run once on app launch after update
LLMMigrationService.migrateFromClaudeOnly()
```

---

## Feature Mapping

### Provider Capabilities Comparison

| Feature | Claude | OpenAI | Gemini |
|---------|--------|--------|--------|
| Max Context | 200K | 128K | 1M |
| Streaming | ✅ | ✅ | ✅ |
| Function Calling | ✅ | ✅ | ✅ |
| Vision | ✅ | ✅ | ✅ |
| Document Generation | ✅ | ✅ | ✅ |
| Cost/1K tokens | $0.03 | $0.06 | $0.02 |

### Provider Selection Logic
```swift
// Automatic provider selection based on task
func selectOptimalProvider(for task: TaskType) -> LLMProviderType {
    switch task {
    case .longDocument:
        // Gemini for 1M context
        return .gemini
    case .codeGeneration:
        // Claude for better code
        return .claude
    case .dataExtraction:
        // OpenAI for structured output
        return .openai
    default:
        // User preference or cheapest
        return userPreferredProvider ?? .gemini
    }
}
```

---

## Testing Strategy

### 1. Unit Tests
```swift
func testProviderAdapterConformance() {
    let providers: [LLMProviderProtocol] = [
        ClaudeAdapter(apiKey: "test"),
        OpenAIAdapter(apiKey: "test"),
        GeminiAdapter(apiKey: "test")
    ]
    
    for provider in providers {
        XCTAssertNotNil(provider.capabilities)
        XCTAssertTrue(provider.providerName.count > 0)
    }
}
```

### 2. Integration Tests
- Test each provider with real API calls
- Verify fallback mechanisms
- Test API key validation

### 3. UI Tests
- Provider selection flow
- API key configuration
- Error handling for each provider

---

## Rollback Plan

If issues arise, rollback strategy:

1. **Feature Flag**: Disable multi-provider UI
2. **Default to Claude**: Force Claude as only provider
3. **Restore Old Code**: Git revert to pre-migration

```swift
// Emergency rollback flag
if UserDefaults.standard.bool(forKey: "force_claude_only") {
    return ClaudeOnlyAdapter()
}
```

---

## Timeline

### Week 1-2: Core Architecture
- Protocol definitions
- Service manager
- Keychain integration

### Week 3-4: Provider Adapters
- Migrate Claude code
- Implement OpenAI
- Implement Gemini

### Week 5-6: UI Updates
- Settings screens
- Provider selection
- Migration tool

### Week 7-8: Testing & Release
- Comprehensive testing
- Beta testing with agencies
- Production release

---

## Government Compliance Notes

### Security Requirements
1. **API Key Storage**: FIPS 140-2 compliant encryption
2. **Audit Trail**: Log all provider changes
3. **Access Control**: Admin approval for provider changes
4. **Data Residency**: Verify each provider's compliance

### Procurement Compliance
1. **No Vendor Lock-in**: Document provider independence
2. **Cost Transparency**: Track usage per provider
3. **Open Standards**: Use standard protocols
4. **Export Capability**: Configuration portability

---

## Support Resources

### Documentation
- [LLM Provider Architecture](./LLM_Provider_Architecture.md)
- [API Key Security Guide](./API_Key_Security.md)
- [Provider Feature Comparison](./Provider_Comparison.md)

### Contact
- Architecture Team: For design questions
- Security Team: For compliance verification
- DevOps Team: For infrastructure setup

---

**Migration Status**: Planning Phase  
**Target Completion**: 8 weeks  
**Risk Level**: Medium (mitigated by phased approach)