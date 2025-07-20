# AikoCompat Module

This module provides an API-agnostic interface for AI providers and Sendable-safe wrappers around non-Sendable dependencies.

## Purpose

1. **API Agnosticism**: Provides a vendor-neutral interface for AI completions, allowing the application to switch between providers (Anthropic, OpenAI, etc.) without code changes
2. **Concurrency Safety**: As part of our Swift 6 concurrency migration, this module isolates non-Sendable dependencies behind actor boundaries

## Components

### AIProvider Protocol

The core abstraction for AI providers:

```swift
// API-agnostic interface
let provider = await AIProviderFactory.defaultProvider()
let request = AICompletionRequest.simple(prompt: "Hello, world!")
let response = try await provider.complete(request)
print(response.content)
```

### AnthropicProvider

Concrete implementation for Claude/Anthropic:

```swift
// Register Anthropic as the default provider
await AIProviderFactory.registerAnthropic(apiKey: "your-key")

// Or create directly
let config = AIProviderConfig(apiKey: "your-key")
let provider = AnthropicProvider(config: config)
```

## Migration Strategy

1. Replace direct SwiftAnthropic imports with AikoCompat
2. Use AIProvider protocol instead of concrete Anthropic types
3. Leverage migration helpers for minimal code changes
4. This module has strict concurrency enabled to ensure all wrappers are properly Sendable

## Migration Helpers

For existing code using SwiftAnthropic:

```swift
// Old code:
import SwiftAnthropic
let service = AnthropicServiceFactory.service(apiKey: key)

// New code:
import AikoCompat
let provider = AnthropicServiceFactory.service(apiKey: key) // Returns AIProvider
```

## Adding New Providers

To add support for a new AI provider:

1. Create an actor implementing the AIProvider protocol
2. Map the provider's API to our generic types (AICompletionRequest/Response)
3. Register the provider with AIProviderFactory
4. Document any provider-specific features or limitations

## Future Plans

- Add support for OpenAI, Gemini, and other providers
- Implement proper streaming support
- Add function calling / tool use abstractions
- Support for embeddings and other AI capabilities