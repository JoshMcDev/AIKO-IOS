# AIKO Architecture Guide

## System Architecture Overview

AIKO follows a modular, layered architecture built on SwiftUI and The Composable Architecture (TCA) pattern.

### Core Layers

1. **Presentation Layer**
   - SwiftUI Views
   - View Models (TCA Reducers)
   - UI Components

2. **Business Logic Layer**
   - Features (TCA Modules)
   - Services
   - Repositories

3. **Data Layer**
   - Core Data Models
   - Network Services
   - Local Storage

4. **Infrastructure Layer**
   - API Clients
   - Security Services
   - Utilities

## Key Architectural Patterns

### The Composable Architecture (TCA)
- State management through immutable state
- Actions define all possible state changes
- Reducers handle business logic
- Effects manage side effects

### Dependency Injection
```swift
struct MyFeature: Reducer {
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.documentService) var documentService
}
```

### Service Pattern
All external interactions go through service interfaces:
- `SAMGovService`
- `DocumentGenerationService`
- `RegulationRepository`
- `BiometricAuthenticationService`

## Module Structure

### Features
- `AppFeature` - Root application state
- `AcquisitionChatFeature` - Main chat interface
- `DocumentGenerationFeature` - Document creation
- `AuthenticationFeature` - User authentication

### Services
- `AdaptiveIntelligenceService` - AI processing
- `DocumentParser` - File parsing
- `RegulationService` - FAR/DFAR compliance
- `Context7Service` - External regulation API

### Models
- `DocumentType` - Document classifications
- `RegulationType` - Regulation categories
- `UserProfile` - User data model
- `Acquisition` - Core Data entity

## Data Flow

1. User Action → View → Reducer
2. Reducer → Effect → Service
3. Service → API/Database
4. Response → Reducer → State Update
5. State Update → View Refresh

## Security Architecture

### Authentication Flow
1. Biometric check on app launch
2. Keychain storage for sensitive data
3. Session management with timeout
4. Encrypted Core Data store

### Data Protection
- All API keys in Keychain
- Document encryption at rest
- TLS for all network calls
- No sensitive data in UserDefaults

## Performance Considerations

### Optimization Strategies
- Lazy loading for document lists
- Image caching for OCR processing
- Background processing for large files
- Efficient Core Data fetching

### Memory Management
- Proper cleanup in view disappear
- Weak references for delegates
- Autoreleasepool for batch operations

---

**Document Version**: 1.0  
**Last Updated**: 2025-07-11  
**Architecture Status**: Production