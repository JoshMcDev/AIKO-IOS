# Phase 0: AI Core Engines & Quick Wins - PRD

**Date**: January 24, 2025  
**Project**: AIKO Unified Refactoring Initiative  
**Phase**: Week 1-4 Implementation  
**Status**: Initial PRD for VanillaIce Consensus  
**Priority**: High

## Executive Summary

Transform AIKO's fragmented AI service architecture into 5 unified Core Engines, reducing complexity from **90+ AI service files to 15-20 unified files** (75-80% reduction). This phase establishes the foundation for the complete 12-week unified refactoring initiative.

## Current State Analysis

### Codebase Assessment
- **Total Swift Files**: 492 in Sources directory
- **AI Service Files**: ~90 scattered files with overlapping responsibilities
- **Core Issues**: Fragmented architecture, mixed concurrency patterns, duplicate functionality
- **Existing Foundation**: 4 skeleton engines already exist (AIOrchestrator, DocumentEngine, PersonalizationEngine, ComplianceValidator)

### Current AI Service Categories
1. **LLM Providers** (5 files): ClaudeProvider, OpenAIProvider, GeminiProvider, AzureOpenAIProvider, LocalModelProvider
2. **Document Generators** (4 files): AIDocumentGenerator, ParallelDocumentGenerator, BatchDocumentGenerator, LLMDocumentGenerator
3. **User Pattern Learning** (3 files): UserPatternLearner, UserPatternLearningEngine, UserPatternTracker
4. **Prompt & Context** (4+ files): AdaptivePromptingEngine, DynamicQuestionGenerator, SmartDefaultsEngine, PromptRegistry
5. **Cache & Performance** (4+ files): DocumentGenerationCache, AdaptiveDocumentCache, EncryptedDocumentCache, PerformanceMonitor

## Target Architecture: 5 Core Engines

### 1. AIOrchestrator (MainActor)
**Purpose**: Central coordination hub for all AI operations
**Current State**: Skeleton exists
**Consolidates**: Request routing, provider management, workflow orchestration

```swift
@MainActor
final class AIOrchestrator: ObservableObject {
    private let documentEngine: DocumentEngine
    private let promptEngine: PromptEngine
    private let complianceValidator: ComplianceValidator
    private let personalizationEngine: PersonalizationEngine
    
    func routeRequest(_ request: AIRequest) async throws -> AIResponse
    func orchestrateWorkflow(_ workflow: AIWorkflow) async throws -> WorkflowResult
}
```

### 2. DocumentEngine (Actor)
**Purpose**: Unified document generation and management
**Current State**: Skeleton exists
**Consolidates**: All document generators, template management, parallel processing

```swift
actor DocumentEngine {
    func generateDocument(_ request: DocumentRequest) async throws -> GeneratedDocument
    func processDocumentChain(_ chain: DocumentChain) async throws -> [GeneratedDocument]
    func getTemplate(_ type: DocumentType) async throws -> DocumentTemplate
}
```

### 3. PromptEngine (Actor)
**Purpose**: Centralized prompt optimization and management
**Current State**: New engine (consolidating PromptRegistry + related services)
**Consolidates**: 15+ prompt patterns, optimization, context injection

```swift
actor PromptEngine {
    func optimizePrompt(_ prompt: String, for context: PromptContext) async throws -> OptimizedPrompt
    func applyPattern(_ pattern: PromptPattern, to prompt: String) async throws -> String
    func generateContextualPrompt(_ request: ContextRequest) async throws -> String
}
```

### 4. ComplianceValidator (Actor)
**Purpose**: Automated FAR/DFARS compliance checking
**Current State**: Skeleton exists
**Consolidates**: Regulatory compliance, validation, case-for-analysis generation

```swift
actor ComplianceValidator {
    func validateCompliance(_ document: Document) async throws -> ComplianceReport
    func generateCaseForAnalysis(_ decision: AIDecision) async throws -> CaseForAnalysis
    func checkRegulatory(_ content: String) async throws -> RegulatoryAnalysis
}
```

### 5. PersonalizationEngine (Actor)
**Purpose**: User behavior learning and preference management
**Current State**: Skeleton exists
**Consolidates**: Pattern learning, user preferences, smart defaults

```swift
actor PersonalizationEngine {
    func learnFromInteraction(_ interaction: UserInteraction) async throws
    func generateSmartDefaults(for context: UserContext) async throws -> SmartDefaults
    func personalizeExperience(_ user: User) async throws -> PersonalizedSettings
}
```

## Supporting Unified Services (10-15 files)

### Core Infrastructure
- **UnifiedProviderAdapter**: Single interface for all LLM providers
- **UnifiedCacheService**: Consolidated caching with encryption
- **LLMProviderManager**: Provider discovery and management
- **CacheManager**: Cache lifecycle and optimization

### Supporting Services
- **ContextExtractionService**: Document and user context extraction
- **TemplateService**: Document template management
- **ValidationService**: Input/output validation
- **WorkflowService**: AI workflow orchestration support
- **MetricsService**: Performance monitoring and analytics

## Quick Wins (Week 1-2)

### File Cleanup
- Remove 10+ dead/obsolete AI service files
- Eliminate duplicate implementations
- Consolidate overlapping cache services
- Remove deprecated provider interfaces

### Infrastructure Improvements
- Implement feature flag system for gradual migration
- Add comprehensive logging for engine interactions
- Create unified error handling for all AI operations
- Establish performance monitoring baselines

## Implementation Strategy

### Week 1-2: Foundation & Quick Wins
1. **Day 1-3**: Clean up dead files, implement feature flags
2. **Day 4-7**: Enhance existing engine skeletons (RED → GREEN)
3. **Day 8-10**: Create PromptEngine from scattered prompt services
4. **Day 11-14**: Implement UnifiedProviderAdapter and basic caching

### Week 3-4: Engine Consolidation
1. **Day 15-21**: Migrate services into unified engines
2. **Day 22-28**: Integration testing, performance validation, Swift 6 compliance

## Success Criteria

### Quantitative Metrics
- **File Reduction**: 90 → 15-20 AI service files (75-80% reduction)
- **Build Performance**: Maintain <20s build time during transition
- **Test Coverage**: 90%+ coverage for all new unified engines
- **Swift 6 Compliance**: 100% strict concurrency compliance

### Qualitative Outcomes
- **Single Responsibility**: Each engine has clear, non-overlapping purpose
- **Actor Isolation**: All engines properly isolated for thread safety
- **Unified Interface**: Consistent API patterns across all engines
- **Performance**: No degradation in AI operation performance

## Risk Mitigation

### Technical Risks
- **Gradual Migration**: Feature flags enable incremental rollout
- **Comprehensive Testing**: TDD approach ensures reliability
- **Fallback Strategy**: Keep original files until migration complete
- **Performance Monitoring**: Real-time metrics during transition

### Integration Risks
- **Dependency Mapping**: Document all current dependencies before migration
- **Interface Compatibility**: Maintain existing APIs during transition
- **Data Migration**: Ensure seamless cache and preference migration

## Dependencies

### Internal
- TDD workflow completion (/tdd → /dev → /green → /refactor → /qa)
- Swift 6 concurrency compliance maintenance
- Existing Core Engine skeleton implementations

### External
- No external dependencies for this phase
- All work contained within existing AIKO architecture

## Expected Outcomes

### Architecture Simplification
- **75-80% reduction** in AI service complexity
- **Unified actor-based architecture** for thread safety
- **Clear separation of concerns** with single responsibility per engine
- **Centralized provider abstraction** reducing coupling

### Developer Experience
- **Simplified codebase navigation** with clear engine boundaries
- **Consistent API patterns** across all AI operations
- **Enhanced maintainability** through consolidated architecture
- **Improved testability** with clear engine isolation

### Performance Benefits
- **Reduced memory footprint** through consolidated caching
- **Improved build times** with fewer files to compile
- **Better resource utilization** through unified engine coordination
- **Enhanced error handling** with centralized management

## VanillaIce Consensus Questions

1. **Architecture Validation**: Do the 5 Core Engines properly address all current AI service responsibilities?
2. **Implementation Strategy**: Is the 4-week phased approach optimal for this complexity level?
3. **Risk Assessment**: Are the mitigation strategies sufficient for a 75-80% file reduction?
4. **Performance Impact**: Will the unified architecture maintain or improve current performance?
5. **Swift 6 Compliance**: Does the actor-based design properly handle concurrency requirements?

---

**Next Steps**: Submit to VanillaIce for consensus validation, then proceed with /design phase for detailed implementation planning.