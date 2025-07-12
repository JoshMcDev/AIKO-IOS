# AIKO API Reference

## External APIs

### Claude API Integration
```swift
// Configuration
let apiKey = "YOUR_CLAUDE_API_KEY"
let model = "claude-3-opus-20240229"
```

**Endpoints Used**:
- `/v1/messages` - Main conversation endpoint
- Rate Limit: 1000 requests/minute
- Context Window: 200K tokens

### SAM.gov API
```swift
// Base URL
let baseURL = "https://api.sam.gov/entity-information/v3/entities"
```

**Key Endpoints**:
- `/entities` - Entity search and verification
- `/exclusions` - Check exclusion status
- Authentication: API key required

### Perplexity API (via Task Master)
```swift
// Configuration in .taskmaster/config.json
"apiKeys": {
    "perplexity": "pplx-[KEY]"
}
```

## Internal Service APIs

### Document Generation Service
```swift
public protocol DocumentGenerationService {
    func generateDocument(type: DocumentType, requirements: String) async throws -> GeneratedDocument
    func batchGenerate(types: [DocumentType], requirements: String) async throws -> [GeneratedDocument]
}
```

### Regulation Repository
```swift
public protocol RegulationRepository {
    func getRegulationsForAgency(agency: String) async throws -> RegulationSet
    func checkForUpdates() async throws -> [RegulationUpdate]
    func searchRegulations(query: String) async throws -> [RegulationSearchResult]
}
```

### Adaptive Intelligence Service
```swift
public protocol AdaptiveIntelligenceService {
    func analyzeRequirements(text: String) async throws -> RequirementAnalysis
    func getCompletenessScore(analysis: RequirementAnalysis) -> Double
    func suggestNextSteps(analysis: RequirementAnalysis) -> [String]
}
```

## Authentication APIs

### Biometric Authentication
```swift
public protocol BiometricAuthenticationService {
    func authenticate() async throws -> Bool
    func isAvailable() -> Bool
    func getBiometricType() -> BiometricType
}
```

## Document Processing APIs

### Document Parser
```swift
public protocol DocumentParser {
    func parsePDF(data: Data) async throws -> String
    func parseWord(data: Data) async throws -> String
    func parseImage(image: UIImage) async throws -> String
}
```

---

**Document Version**: 1.0  
**Last Updated**: 2025-07-11  
**API Stability**: Production