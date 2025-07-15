# Better-Auth Integration Architecture for AIKO

**Date**: July 15, 2025  
**Version**: 1.0  
**Status**: Planning Phase  

---

## Overview

This document outlines the technical architecture for integrating Better-Auth into the AIKO iOS/macOS government contracting application. The architecture prioritizes security, compliance, and offline capability while maintaining the performance-first approach established in the project.

---

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           AIKO iOS/macOS App                        │
├─────────────────────────────────────────────────────────────────────┤
│  SwiftUI Views          │  TCA Reducers        │  Services          │
│  ┌─────────────────┐   │  ┌────────────────┐  │  ┌──────────────┐ │
│  │  Login View     │   │  │ Auth Feature   │  │  │ Better-Auth  │ │
│  │  MFA View       │───┼─▶│ Reducer        │──┼─▶│ SDK Service  │ │
│  │  Profile View   │   │  │                │  │  │              │ │
│  └─────────────────┘   │  └────────────────┘  │  └──────┬───────┘ │
│                        │                       │         │         │
│  ┌─────────────────┐   │  ┌────────────────┐  │  ┌──────▼───────┐ │
│  │ Document Views  │   │  │ App Features   │  │  │  Keychain    │ │
│  │ Workflow Views  │───┼─▶│ Reducers       │──┼─▶│  Manager     │ │
│  │ Settings View   │   │  │                │  │  │              │ │
│  └─────────────────┘   │  └────────────────┘  │  └──────────────┘ │
└────────────────────────┴───────────────────────┴───────────────────┘
                                    │
                         Network Layer (Alamofire/URLSession)
                                    │
                    ┌───────────────┴────────────────┐
                    │                                │
            ┌───────▼────────┐            ┌─────────▼─────────┐
            │  Better-Auth   │            │   n8n Backend     │
            │  Auth Server   │            │   API Gateway     │
            │                │            │                   │
            │  - FISMA       │            │  - Document Gen   │
            │  - FedRAMP     │            │  - Workflows      │
            │  - MFA         │            │  - Data Process   │
            └────────────────┘            └───────────────────┘
```

---

## 2. Authentication Flow Architecture

### 2.1 Initial Authentication Flow

```swift
// TCA Authentication Feature
struct AuthenticationFeature: Reducer {
    struct State: Equatable {
        @PresentationState var loginState: LoginFeature.State?
        @PresentationState var mfaState: MFAFeature.State?
        
        var authStatus: AuthStatus = .unauthenticated
        var user: AuthenticatedUser?
        var biometricAvailable: Bool = false
        var offlineMode: Bool = false
    }
    
    enum Action: Equatable {
        case onAppear
        case checkAuthStatus
        case login(LoginFeature.Action)
        case mfa(MFAFeature.Action)
        case biometricAuth
        case logout
        case refreshToken
        case handleOfflineAuth
    }
    
    @Dependency(\.betterAuthService) var authService
    @Dependency(\.keychainManager) var keychain
    @Dependency(\.networkMonitor) var network
}
```

### 2.2 Token Management Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Access Token   │────▶│  Refresh Token   │────▶│  Offline Token  │
│  (15 minutes)   │     │  (8 hours)       │     │  (7 days)       │
└─────────────────┘     └──────────────────┘     └─────────────────┘
         │                       │                         │
         ▼                       ▼                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Keychain Storage                          │
│  - Encrypted with AES-256                                       │
│  - Protected by Biometric/Device Passcode                       │
│  - Automatic cleanup on logout                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Multi-Tenant Architecture

### 3.1 Tenant Isolation Model

```
Government Agency A          Government Agency B
        │                            │
        ▼                            ▼
┌───────────────┐           ┌───────────────┐
│  Tenant A     │           │  Tenant B     │
│  ┌─────────┐  │           │  ┌─────────┐  │
│  │ Users   │  │           │  │ Users   │  │
│  │ Roles   │  │           │  │ Roles   │  │
│  │ Data    │  │           │  │ Data    │  │
│  └─────────┘  │           │  └─────────┘  │
│               │           │               │
│  Encryption   │           │  Encryption   │
│  Key: A-256   │           │  Key: B-256   │
└───────────────┘           └───────────────┘
        │                            │
        └──────────┬─────────────────┘
                   ▼
           Better-Auth Platform
           (Tenant Management)
```

### 3.2 Tenant Switching Flow

```swift
struct TenantSwitchingFeature: Reducer {
    struct State: Equatable {
        var availableTenants: [Tenant] = []
        var currentTenant: Tenant?
        var isSwitching: Bool = false
    }
    
    enum Action: Equatable {
        case loadTenants
        case selectTenant(Tenant)
        case confirmSwitch
        case switchCompleted
    }
}
```

---

## 4. Offline Authentication Architecture

### 4.1 Offline Token Strategy

```
Online Mode                          Offline Mode
     │                                    │
     ▼                                    ▼
┌─────────────┐                    ┌──────────────┐
│ Validate    │                    │ Check Cached │
│ with Server │                    │ Credentials  │
└─────────────┘                    └──────────────┘
     │                                    │
     ▼                                    ▼
┌─────────────┐                    ┌──────────────┐
│ Get Fresh   │                    │ Use Offline  │
│ Tokens      │                    │ Token        │
└─────────────┘                    └──────────────┘
     │                                    │
     ▼                                    ▼
┌─────────────┐                    ┌──────────────┐
│ Full Access │                    │ Limited      │
│             │                    │ Access       │
└─────────────┘                    └──────────────┘
```

### 4.2 Sync Queue Architecture

```swift
struct OfflineSyncQueue {
    struct QueuedAction: Codable {
        let id: UUID
        let action: ActionType
        let timestamp: Date
        let payload: Data
        let retryCount: Int
    }
    
    enum ActionType: String, Codable {
        case createDocument
        case updateContract
        case submitForm
        case uploadAttachment
    }
}
```

---

## 5. Security Layer Architecture

### 5.1 Defense in Depth

```
Layer 1: Network Security
├── TLS 1.3 with Certificate Pinning
├── Better-Auth SDK Encryption
└── VPN Support for Government Networks

Layer 2: Application Security
├── OAuth 2.0 + PKCE
├── JWT with Short Expiry
└── Session Management

Layer 3: Device Security
├── Biometric Authentication
├── Secure Enclave Integration
├── Keychain Access Control
└── Jailbreak Detection

Layer 4: Data Security
├── AES-256 Encryption at Rest
├── Field-Level Encryption
├── Secure Key Derivation
└── Crypto-Shredding on Logout
```

### 5.2 Audit Trail Architecture

```swift
struct AuditEvent: Codable {
    let id: UUID
    let timestamp: Date
    let userId: String
    let tenantId: String
    let eventType: EventType
    let ipAddress: String
    let deviceInfo: DeviceInfo
    let result: EventResult
    let metadata: [String: String]
}

enum EventType: String, Codable {
    case login
    case logout
    case mfaChallenge
    case passwordChange
    case permissionChange
    case dataAccess
    case documentGeneration
}
```

---

## 6. Integration Points

### 6.1 AIKO App Integration

```swift
// AppReducer.swift
struct AppReducer: Reducer {
    struct State: Equatable {
        var auth = AuthenticationFeature.State()
        var userPattern = UserPatternLearningFeature.State()
        var documentGen = DocumentGenerationFeature.State()
        var n8nWorkflow = N8NWorkflowFeature.State()
    }
    
    enum Action: Equatable {
        case auth(AuthenticationFeature.Action)
        case userPattern(UserPatternLearningFeature.Action)
        case documentGen(DocumentGenerationFeature.Action)
        case n8nWorkflow(N8NWorkflowFeature.Action)
        case requiresAuthentication
    }
}
```

### 6.2 n8n Backend Integration

```
AIKO App                    Better-Auth               n8n Backend
    │                           │                          │
    ├──Authenticate────────────▶│                          │
    │                           ├──Return Token───────────▶│
    │◀──────Token──────────────┤                          │
    │                           │                          │
    ├──API Request with Token──┼─────────────────────────▶│
    │                           │                          ├──Validate Token
    │                           │◀─────────────────────────┤
    │                           ├──Token Valid────────────▶│
    │                           │                          │
    │◀──────Response────────────┼──────────────────────────┤
```

---

## 7. Performance Considerations

### 7.1 Authentication Performance Targets

| Operation | Target | Max Acceptable |
|-----------|--------|----------------|
| Initial Login | < 1s | 2s |
| Biometric Auth | < 200ms | 500ms |
| Token Refresh | < 300ms | 1s |
| MFA Verification | < 2s | 5s |
| Offline Auth | < 100ms | 200ms |

### 7.2 Optimization Strategies

1. **Token Caching**
   - Pre-emptive token refresh
   - Background refresh when app is active
   - Intelligent retry with exponential backoff

2. **Connection Pooling**
   - Maintain persistent HTTPS connections
   - Connection multiplexing
   - Smart retry mechanisms

3. **Offline Optimization**
   - Minimal offline token validation
   - Efficient local storage queries
   - Background sync when online

---

## 8. Migration Strategy

### 8.1 From Current JWT to Better-Auth

```
Phase 1: Parallel Authentication (Week 3-4)
├── Keep existing JWT system active
├── Implement Better-Auth alongside
└── A/B test with small user group

Phase 2: Gradual Migration (Week 5-6)
├── Migrate users in batches
├── Maintain backward compatibility
└── Monitor for issues

Phase 3: Complete Cutover (Week 7-8)
├── Disable old JWT system
├── Full Better-Auth activation
└── Remove legacy code
```

---

## 9. Monitoring & Observability

### 9.1 Key Metrics

```swift
struct AuthMetrics {
    static let loginSuccessRate = "auth.login.success_rate"
    static let loginLatency = "auth.login.latency"
    static let tokenRefreshRate = "auth.token.refresh_rate"
    static let mfaAdoptionRate = "auth.mfa.adoption_rate"
    static let offlineAuthUsage = "auth.offline.usage"
    static let securityEventCount = "auth.security.event_count"
}
```

### 9.2 Alerting Thresholds

- Login success rate < 95%
- Authentication latency > 2s
- Failed login attempts > 5 per minute
- Token refresh failures > 1%
- Security events detected

---

## 10. Disaster Recovery

### 10.1 Failover Strategy

```
Primary: Better-Auth Cloud (US-East)
     │
     ├── Health Check Failure
     ▼
Secondary: Better-Auth Cloud (US-West)
     │
     ├── Complete Outage
     ▼
Fallback: Offline Mode (7 days)
```

### 10.2 Data Recovery

- Hourly credential backups
- Point-in-time recovery capability
- Automated failover testing
- Recovery time objective (RTO): 15 minutes
- Recovery point objective (RPO): 1 hour

---

**Document Version**: 1.0  
**Last Updated**: July 15, 2025  
**Next Review**: After Week 2 Assessment Completion