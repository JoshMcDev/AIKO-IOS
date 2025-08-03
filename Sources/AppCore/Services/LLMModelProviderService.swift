import Foundation

/// Centralized service for managing LLM model definitions
/// Eliminates code duplication between ViewModel and Service layers
/// Follows Single Responsibility Principle
public struct LLMModelProviderService: Sendable {
    // MARK: - Singleton Access

    public static let shared = LLMModelProviderService()

    private init() {}

    // MARK: - Model Provider Methods

    /// Get available models for a provider
    /// Centralized definition eliminates duplication across codebase
    /// - Parameter provider: Provider to get models for
    /// - Returns: Array of available models
    public func getModelsForProvider(_ provider: LLMProvider) -> [LLMModel] {
        switch provider {
        case .claude:
            [
                LLMModel(id: "claude-3-opus-20240229", name: "Claude 3 Opus", description: "Most capable Claude model", contextLength: 200_000),
                LLMModel(id: "claude-3-sonnet-20240229", name: "Claude 3 Sonnet", description: "Balanced Claude model", contextLength: 200_000),
                LLMModel(id: "claude-3-haiku-20240307", name: "Claude 3 Haiku", description: "Fastest Claude model", contextLength: 200_000),
            ]
        case .openAI, .chatGPT:
            [
                LLMModel(id: "gpt-4-turbo-preview", name: "GPT-4 Turbo", description: "Latest GPT-4 model", contextLength: 128_000),
                LLMModel(id: "gpt-4", name: "GPT-4", description: "Standard GPT-4 model", contextLength: 8192),
                LLMModel(id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", description: "Fast and efficient", contextLength: 16385),
            ]
        case .gemini:
            [
                LLMModel(id: "gemini-pro", name: "Gemini Pro", description: "Google's advanced model", contextLength: 32768),
                LLMModel(id: "gemini-pro-vision", name: "Gemini Pro Vision", description: "Gemini with vision capabilities", contextLength: 32768),
            ]
        case .azureOpenAI:
            [
                LLMModel(id: "gpt-35-turbo", name: "GPT-3.5 Turbo (Azure)", description: "Azure OpenAI GPT-3.5", contextLength: 16385),
                LLMModel(id: "gpt-4", name: "GPT-4 (Azure)", description: "Azure OpenAI GPT-4", contextLength: 8192),
            ]
        case .local:
            [
                LLMModel(id: "local-llama", name: "Local Llama", description: "Local Llama model", contextLength: 4096),
            ]
        case .custom:
            [] // User-defined models
        }
    }

    /// Get default model for a provider
    /// - Parameter provider: Provider to get default model for
    /// - Returns: Default model or nil if no models available
    public func getDefaultModel(for provider: LLMProvider) -> LLMModel? {
        getModelsForProvider(provider).first
    }

    /// Check if provider supports the specified model
    /// - Parameters:
    ///   - provider: Provider to check
    ///   - modelId: Model ID to validate
    /// - Returns: True if model is supported
    public func isModelSupported(by provider: LLMProvider, modelId: String) -> Bool {
        getModelsForProvider(provider).contains { $0.id == modelId }
    }
}
