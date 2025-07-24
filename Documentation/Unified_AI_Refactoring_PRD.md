# AIKO Unified AI Refactoring - Project Requirements Document

**Project Name:** Unified AI Service Consolidation  
**Version:** 1.0  
**Date:** 2025-01-24  
**Author:** Claude Code Analysis  
**Status:** Draft for Review  

## Executive Summary

The AIKO codebase currently contains **492 Swift files** with **~90 AI-related services** scattered across multiple directories, creating maintenance complexity and architectural debt. This PRD outlines a comprehensive refactoring initiative to consolidate these services into a **unified 5-engine system** comprising **15-20 total files**, achieving a **75-80% reduction** in AI service complexity while maintaining all existing functionality.

## Current State Analysis

### Codebase Overview
- **Total Swift Files:** 492
- **AI-Related Files:** ~90 (scattered across Services/, AppCore/, Features/)
- **Architecture:** Fragmented services with overlapping responsibilities
- **Concurrency:** Mixed patterns (some Swift 6 compliant, some legacy)

### Existing AI Services Inventory

#### LLM Providers (Services/LLM/Providers/)
- `ClaudeProvider.swift` - Anthropic Claude API implementation
- `OpenAIProvider.swift` - OpenAI GPT API implementation  
- `GeminiProvider.swift` - Google Gemini API implementation
- `AzureOpenAIProvider.swift` - Azure OpenAI implementation
- `LocalModelProvider.swift` - Local model support

#### Core Engines (AppCore/Services/Core/) - **ALREADY STARTED**
- `AIOrchestrator.swift` - Central coordination hub (MainActor, singleton)
- `DocumentEngine.swift` - Document generation core (Actor isolated)
- `PersonalizationEngine.swift` - User behavior and preferences (Actor isolated)
- `ComplianceValidator.swift` - Regulatory compliance validation (Actor isolated)
- `PromptRegistry.swift` - Basic prompt management

#### Document Generators (Services/)
- `AIDocumentGenerator.swift` - Primary document generation service
- `ParallelDocumentGenerator.swift` - Batch parallel processing
- `BatchDocumentGenerator.swift` - Batch operation handling
- `LLMDocumentGenerator.swift` - LLM-specific generation

#### User Pattern Learning
- `UserPatternLearner.swift` - Pattern recognition and learning
- `UserPatternLearningEngine.swift` - Learning algorithm engine
- `UserPatternTracker.swift` - Action tracking and analysis

#### Prompt & Context Management
- `AdaptivePromptingEngine.swift` - Dynamic prompt generation
- `DynamicQuestionGenerator.swift` - Interactive questioning
- `SmartDefaultsEngine.swift` - Intelligent defaults
- `GovernmentAcquisitionPrompts.swift` - Domain-specific prompts

#### Cache & Performance
- `DocumentGenerationCache.swift` - Document caching
- `AdaptiveDocumentCache.swift` - Adaptive caching strategies
- `EncryptedDocumentCache.swift` - Secure caching
- `DocumentGenerationPerformanceMonitor.swift` - Performance tracking

## Target Architecture: Unified 5-Engine System

### Core Engines (5 Files)

#### 1. AIOrchestrator.swift
**Status:** ✅ Skeleton exists  
**Role:** Central coordination hub and entry point for all AI operations  
**Consolidates:** Central routing and coordination  
**Pattern:** MainActor + ObservableObject for SwiftUI integration  

```swift
@MainActor
public final class AIOrchestrator: ObservableObject, Sendable {
    public static let shared = AIOrchestrator()
    // Coordinates all AI operations through unified API
}
```

#### 2. DocumentEngine.swift  
**Status:** ✅ Skeleton exists  
**Role:** Unified document generation pipeline  
**Consolidates:** AIDocumentGenerator, ParallelDocumentGenerator, BatchDocumentGenerator, LLMDocumentGenerator  
**Pattern:** Actor isolation for thread safety  

```swift
public actor DocumentEngine: Sendable {
    public static let shared = DocumentEngine()
    // Unified document generation with provider abstraction
}
```

#### 3. PersonalizationEngine.swift
**Status:** ✅ Skeleton exists  
**Role:** User behavior analysis and personalization  
**Consolidates:** UserPatternLearner, UserPatternLearningEngine, UserPatternTracker, SmartDefaultsProvider  
**Pattern:** Actor isolation with GraphRAG integration  

```swift
public actor PersonalizationEngine: Sendable {
    public static let shared = PersonalizationEngine()
    // Unified personalization with behavior analysis
}
```

#### 4. ComplianceValidator.swift
**Status:** ✅ Skeleton exists  
**Role:** Regulatory and security compliance validation  
**Consolidates:** FARCompliance, FARComplianceManager, CMMCComplianceTracker, SecurityValidator  
**Pattern:** Actor isolation for validation processing  

```swift
public actor ComplianceValidator: Sendable {
    public static let shared = ComplianceValidator()
    // Multi-threaded compliance validation
}
```

#### 5. PromptEngine.swift
**Status:** 🆕 New engine (extends existing PromptRegistry)  
**Role:** Unified prompt management and optimization  
**Consolidates:** PromptRegistry, AdaptivePromptingEngine, DynamicQuestionGenerator, SmartDefaultsEngine, GovernmentAcquisitionPrompts  
**Pattern:** Actor isolation for prompt optimization  

```swift
public actor PromptEngine: Sendable {
    public static let shared = PromptEngine()
    // Unified prompt management with adaptive optimization
}
```

### Provider Layer (3 Files)

#### 6. UnifiedProviderAdapter.swift
**Role:** Provider abstraction and routing  
**Consolidates:** Provider coordination logic  

#### 7. LLMProviderManager.swift  
**Role:** LLM provider lifecycle management  
**Consolidates:** LLMManager, LLMConfigurationManager  

#### 8. AIProviderFactory.swift
**Role:** Provider instantiation and configuration  
**Consolidates:** Provider factory patterns  

### Cache Layer (2 Files)

#### 9. UnifiedCacheService.swift
**Role:** Centralized caching with multiple storage backends  
**Consolidates:** DocumentGenerationCache, AdaptiveDocumentCache, EncryptedDocumentCache  

#### 10. CacheManager.swift
**Role:** Cache coordination, policies, and invalidation  
**Consolidates:** Cache management logic  

### Supporting Services (5-10 Files)

#### 11. AIContextExtractor.swift
**Consolidates:** DocumentContextExtractor, UnifiedDocumentContextExtractor, AdaptiveDataExtractor  

#### 12. AITemplateService.swift
**Consolidates:** StandardTemplateService, UnifiedTemplateService, DFTemplateService  

#### 13. AIValidationService.swift
**Consolidates:** DocumentParserValidator, FieldValidator, SpellCheckService  

#### 14. AIWorkflowCoordinator.swift
**Consolidates:** WorkflowEngine, OneTapWorkflowEngine, SessionEngine  

#### 15. AIMetricsCollector.swift
**Consolidates:** MetricsService, DocumentGenerationPerformanceMonitor  

#### Optional Extensions (16-20)
- `AISecurityService.swift` - Security-specific operations
- `AIOptimizationService.swift` - Performance optimization
- `AIIntegrationBridge.swift` - Legacy system integration  
- `AIConfigurationManager.swift` - Centralized configuration
- `AIErrorHandler.swift` - Unified error handling

## Technical Implementation Strategy

### Concurrency Architecture

```swift
// Central coordination through MainActor
@MainActor AIOrchestrator 
    ↓ coordinates
[Actor] DocumentEngine ←→ [Actor] PersonalizationEngine
    ↓                           ↓
[Actor] ComplianceValidator ←→ [Actor] PromptEngine
    ↓
UnifiedProviderAdapter → LLM Providers
```

### Key Architectural Patterns

1. **Actor Isolation:** All core engines use actors for thread safety
2. **Singleton Pattern:** Global access through shared instances  
3. **Task Deduplication:** Prevent duplicate operations across engines
4. **Provider Abstraction:** Unified interface for multiple LLM providers
5. **Centralized Caching:** Unified cache layer with intelligent invalidation
6. **Sendable Compliance:** Full Swift 6 concurrency compliance

### Migration Strategy

#### Phase 1: Foundation (Week 1-2)
- ✅ Enhance existing skeleton engines (RED → GREEN)
- ✅ Implement PromptEngine as 5th core engine
- ✅ Create provider abstraction layer
- ✅ Implement unified cache service

#### Phase 2: Consolidation (Week 3-4) 
- Consolidate document generators into DocumentEngine
- Consolidate user pattern services into PersonalizationEngine  
- Consolidate compliance services into ComplianceValidator
- Consolidate prompt services into PromptEngine

#### Phase 3: Integration Testing (Week 5)
- End-to-end testing of unified engines
- Performance benchmarking  
- Backward compatibility validation
- Load testing for concurrent operations

#### Phase 4: Migration & Cleanup (Week 6)
- Migrate all consumers to unified engines
- Remove legacy services
- Update dependency injection
- Documentation updates

## Integration Challenges & Mitigation

### Challenge 1: Actor Coordination Complexity
**Risk:** Deadlocks or performance bottlenecks from actor communication  
**Mitigation:** 
- Careful dependency design to avoid circular references
- Task-based communication patterns
- Performance monitoring and optimization

### Challenge 2: Caching Consistency  
**Risk:** Cache invalidation conflicts across engines  
**Mitigation:**
- Centralized cache manager with coordination protocols
- Event-driven cache invalidation
- Cache versioning and conflict resolution

### Challenge 3: Provider Abstraction Complexity
**Risk:** Different LLM provider capabilities and limitations  
**Mitigation:**
- Capability-based provider selection
- Graceful fallback mechanisms  
- Provider-specific optimization strategies

### Challenge 4: Migration Risk
**Risk:** Breaking existing functionality during consolidation  
**Mitigation:**
- Phased migration with feature flags
- Comprehensive test coverage
- Backward compatibility layer during transition

## Success Metrics

### Quantitative Goals
- **File Reduction:** 90 → 15-20 files (75-80% reduction)
- **Code Duplication:** <5% across AI services  
- **Performance:** Maintain or improve current response times
- **Memory Usage:** Reduce by 15-20% through unified caching
- **Test Coverage:** Maintain >90% coverage for all unified engines

### Qualitative Goals  
- **Maintainability:** Single responsibility per engine
- **Extensibility:** Easy to add new LLM providers  
- **Reliability:** Improved error handling and recovery
- **Developer Experience:** Simplified API surface

## Risk Assessment

### High Risk 📊
- **Complex Migration:** Large scope refactoring with breaking change potential
- **Performance Impact:** Centralization might create bottlenecks

### Medium Risk ⚠️  
- **Actor Coordination:** Complex inter-actor communication patterns
- **Cache Consistency:** Multi-engine cache synchronization

### Low Risk ✅
- **Provider Abstraction:** Well-defined interface contracts
- **Testing Strategy:** Existing test patterns can be extended

## Dependencies & Prerequisites

### Internal Dependencies
- Existing core engine skeletons (AIOrchestrator, DocumentEngine, PersonalizationEngine, ComplianceValidator)
- TCA dependency injection system
- Swift 6 concurrency compliance
- Existing LLM provider implementations

### External Dependencies  
- LLM provider APIs (Claude, OpenAI, Gemini)
- SwiftUI integration requirements
- Performance monitoring infrastructure

## Timeline & Milestones

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| **Phase 1** | Week 1-2 | Enhanced core engines (RED → GREEN) |
| **Phase 2** | Week 3-4 | Service consolidation complete |
| **Phase 3** | Week 5 | Integration testing & validation |
| **Phase 4** | Week 6 | Migration complete & cleanup |

**Total Duration:** 6 weeks  
**Key Milestone:** End of Phase 2 - All 90 services consolidated into 15-20 files

## Conclusion

The unified AI refactoring initiative represents a significant architectural improvement for AIKO, reducing complexity by 75-80% while maintaining all existing functionality. The existing core engine foundations provide a solid starting point, and the phased migration approach minimizes risk while ensuring system stability.

**Recommendation:** ✅ Proceed with unified refactoring using the proposed 5-engine architecture and phased migration strategy.