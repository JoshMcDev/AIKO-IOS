import Foundation

/// Enhanced API Configuration with improved security
public enum EnhancedAPIConfiguration {
    
    /// Get Anthropic API key with enhanced security
    public static func getAnthropicKey() async throws -> String {
        return try await EnhancedAPIKeyManager.shared.getAPIKey(for: .anthropic)
    }
    
    /// Get OpenAI API key with enhanced security
    public static func getOpenAIKey() async throws -> String {
        return try await EnhancedAPIKeyManager.shared.getAPIKey(for: .openai)
    }
    
    /// Get SAM.gov API key with enhanced security
    public static func getSAMKey() async throws -> String {
        return try await EnhancedAPIKeyManager.shared.getAPIKey(for: .sam)
    }
    
    /// Store an API key securely
    public static func storeAPIKey(_ key: String, for service: APIService) async throws {
        try await EnhancedAPIKeyManager.shared.storeAPIKey(key, for: service)
    }
    
    /// Rotate API keys
    public static func rotateAllKeys() async throws {
        for service in APIService.allCases {
            _ = try? await EnhancedAPIKeyManager.shared.rotateKey(for: service)
        }
    }
    
    /// Get base URL for a service
    public static func baseURL(for service: APIService) -> String {
        switch service {
        case .anthropic:
            return ProcessInfo.processInfo.environment["ANTHROPIC_BASE_URL"] ?? "https://api.anthropic.com"
        case .openai:
            return ProcessInfo.processInfo.environment["OPENAI_BASE_URL"] ?? "https://api.openai.com"
        case .sam:
            return ProcessInfo.processInfo.environment["SAM_BASE_URL"] ?? "https://api.sam.gov"
        }
    }
    
    /// Check if running in production
    public static var isProduction: Bool {
        return ProcessInfo.processInfo.environment["ENVIRONMENT"] == "production"
    }
    
    /// Get API headers with authentication
    public static func headers(for service: APIService) async throws -> [String: String] {
        let apiKey = try await getAPIKey(for: service)
        
        var headers = [String: String]()
        
        switch service {
        case .anthropic:
            headers["x-api-key"] = apiKey
            headers["anthropic-version"] = "2024-10-22"
            headers["Content-Type"] = "application/json"
        case .openai:
            headers["Authorization"] = "Bearer \(apiKey)"
            headers["Content-Type"] = "application/json"
        case .sam:
            headers["X-API-Key"] = apiKey
            headers["Accept"] = "application/json"
        }
        
        // Add security headers
        headers["X-Request-ID"] = UUID().uuidString
        headers["X-Client-Version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        return headers
    }
    
    /// Get API key for a service
    private static func getAPIKey(for service: APIService) async throws -> String {
        switch service {
        case .anthropic:
            return try await getAnthropicKey()
        case .openai:
            return try await getOpenAIKey()
        case .sam:
            return try await getSAMKey()
        }
    }
}

// MARK: - Migration Helper

extension APIConfiguration {
    /// Migrate from old API configuration to enhanced version
    public static func migrateToEnhanced() async throws {
        // Get existing key from old configuration
        let oldKey = getAnthropicKey()
        
        // Skip if it's the default placeholder
        guard oldKey != "YOUR_API_KEY_HERE" else { return }
        
        // Store in enhanced manager
        try await EnhancedAPIConfiguration.storeAPIKey(oldKey, for: .anthropic)
        
        // Clear old keychain entry
        _ = KeychainManager.shared.deleteAnthropicKey()
    }
}