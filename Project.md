# project.md - AIKO Project Configuration
> **Adaptive Intelligence for Kontract Optimization**
> **Project-Specific Claude Code Configuration**

## File Organization Standards

**CRITICAL**: All files must follow these organization standards:

- **Documentation**: All documentation produced by Claude goes in `documentation/` folder
- **Tests**: All test files go in `tests/` folder  
- **Root Directory**: Keep clean - only essential project files (package.json, README.md, Project_Tasks.md, etc.)
- **No Root Clutter**: Do not create files in root unless required for project operation, optimization, or functionality

**Examples**:
```bash
# ✅ CORRECT - Organized structure
documentation/api-guide.md
documentation/architecture-overview.md
tests/unit/AuthTests.swift
tests/integration/ScannerTests.swift

# ❌ WRONG - Cluttering root
./api-guide.md
./AuthTests.swift
./random-notes.md
```

## ALWAYS use Bash(cd /Users/J/aiko && xcodebuild -scheme AIKO -destination "platform=iOS Simulator,name=iPhone 16 Pro" -skipPackagePluginValidation build 2>&1 | grep -E "(error:|…)
---

## 🎯 Project Overview

**Project**: AIKO (Adaptive Intelligence for Kontract Optimization)  
**Version**: 6.1 (Production Ready)  
**Type**: iOS Application  
**Domain**: Government Contracting  
**Last Updated**: August 3, 2025  
**Progress**: FULLY FUNCTIONAL (All core views operational with Swift 6 compliance and modern SwiftUI architecture)

### Project Vision
Build a focused iOS productivity tool that revolutionizes government contracting by leveraging user-chosen LLM providers for all intelligence features. No backend services, no cloud complexity - just powerful automation through a simple native interface.

**Core Philosophy**: Let LLMs handle intelligence. Let iOS handle the interface. Let users achieve more with less effort.

**Current Status (August 2025)**: Production ready with complete functionality. All user-facing views are fully operational using modern SwiftUI @Observable patterns. Application delivers complete user experience with Swift 6 compliance and modern development practices.

---

## ✅ SUCCESS: PRODUCTION-READY APPLICATION (August 2025)

### Architecture Modernization Complete
- **MAJOR SUCCESS**: All application functionality fully operational with modern SwiftUI patterns
- **USER IMPACT**: Complete application ready for end users with enhanced SwiftUI experience
- **DEVELOPMENT ACHIEVEMENT**: Architectural modernization successfully completed with Swift 6 compliance
- **RESULT**: Modern SwiftUI architecture with @Observable patterns providing optimal user experience

### Completed Production Phases
- ✅ **Planning Complete**: Architecture modernization successfully implemented
- ✅ **PHASE 1 - COMPLETE**: Foundation Views (AppView, OnboardingView, SettingsView) fully operational
- ✅ **PHASE 2 - COMPLETE**: Business Logic Views (AcquisitionsListView, DocumentExecutionView, SAMGovLookupView) fully operational
- ✅ **PHASE 3 - COMPLETE**: Enhanced Features (ProfileView, LLMProviderSettingsView, DocumentScannerView) fully operational  
- ✅ **PHASE 4 - COMPLETE**: Platform Optimization (iOS/macOS menu views, UI components) fully operational

### Recent Technical Progress (August 2025)
- **ShareButton Compilation Fixes**: Resolved cross-platform import issues with platform-specific dependencies
- **Build System Stability**: Confirmed clean builds after ShareButton dependency resolution
- **Template System Architecture**: Cross-platform ShareButton functionality working correctly
- **Documentation Updates**: Updated project documentation to reflect current restoration status

### Phase 4.1 - Enhanced Image Processing ✅ COMPLETE
- **Core Image API Modernization**: Fixed deprecation warnings in iOSDocumentImageProcessor.swift
- **Swift Concurrency Compliance**: Implemented actor-based ProgressTracker for thread-safe progress reporting
- **Enhanced Processing Modes**: Added basic and enhanced image processing with quality metrics
- **OCR Optimization**: Implemented specialized filters for text recognition and document clarity
- **Performance Improvements**: Added processing time estimation and Metal GPU acceleration
- **Comprehensive Testing**: Created full test suite for DocumentImageProcessor functionality
- **Documentation**: Added detailed Phase 4.1 documentation with usage examples

### Phase 3.5 - Triple Architecture Migration ✅ COMPLETE  
- **Major Cleanup Achievement**: **Eliminated 153+ platform conditionals** dramatically improving maintainability
- **Progress**: 153+ conditionals migrated (100% complete)
  - ✅ VoiceRecordingService (7 conditionals) - Migrated to iOSVoiceRecordingClient & macOSVoiceRecordingClient
  - ✅ HapticManager (5 conditionals) - Migrated to iOSHapticManagerClient & macOSHapticManagerClient  
  - ✅ Updated all HapticManager.shared references to use dependency injection
  - ✅ Fixed voiceRecordingService references to use voiceRecordingClient
  - ✅ SAMReportPreview (9 conditionals) - Migrated to platform-specific implementations
  - ✅ EnhancedAppView (8 conditionals) - Migrated to platform services
  - ✅ OnboardingStepViews (8 conditionals) - Migrated to platform abstractions
  - ✅ LLMProviderSettingsView (7 conditionals) - Migrated to platform-specific UI
  - ✅ All Theme.swift, DynamicType.swift, Accessibility+Extensions.swift, VisualEffects.swift migrated

### Additional Cleanup (January 17, 2025) ✅ COMPLETE
- **API-Agnostic Refactoring**: Removed obsolete ClaudeAPIIntegration.swift
- **Context7Service**: Refactored as MockContext7Service for testing purposes
- **Import Fixes**: Added AppCore imports to 18+ files that needed DocumentType
- **LLM Provider Updates**: Fixed main actor isolation and string interpolation warnings
- **DocumentExecutionFeature**: Fixed rtfContent generation using RTFFormatter
- **Cross-Branch Sync**: Successfully pushed all fixes to newfeet, backup, and skunk branches

---

## 🏗️ Project Architecture

### Core Technologies (Unified Refactoring Target)
- **Frontend**: SwiftUI + Observable Pattern (TCA → SwiftUI migration) 🚧
- **Architecture**: 5 Core Engines (AIOrchestrator, DocumentEngine, PromptRegistry, ComplianceValidator, PersonalizationEngine) 🎯
- **Storage**: Core Data (local only) + CfA audit trails ✅
- **LLM Integration**: Unified provider adapter with 90 → 15-20 file consolidation 🎯
- **Document Processing**: VisionKit Scanner + Enhanced OCR + Smart Filing ✅
- **Intelligence Layer**: GraphRAG with on-device LFM2-700M model 🎯
- **Security**: Keychain Services + LocalAuthentication (Face ID/Touch ID) ✅
- **Integrations**: iOS Native (Mail, Calendar, Reminders) + Google Maps ✅
- **Build System**: 6 → 3 SPM targets, Swift 6 strict concurrency 🎯

### Clean Multi-Platform Architecture

```
AIKO Multi-Platform Architecture (Clean Separation)
├── AppCore (Shared Business Logic) ✅
│   ├── Features (TCA Reducers) ✅
│   ├── Models (Domain Objects) ✅
│   ├── Services (Business Logic Protocols) ✅
│   └── Dependencies (Platform Abstractions) ✅
├── AIKOiOS (iOS-Specific Implementation) ✅
│   ├── Services (iOSDocumentImageProcessor, etc.) ✅
│   ├── Dependencies (iOSVoiceRecordingClient, etc.) ✅
│   └── Views (iOSNavigationStack, etc.) ✅
├── AIKOmacOS (macOS-Specific Implementation) ✅
│   ├── Services (macOS Platform Services) ✅
│   ├── Dependencies (macOSVoiceRecordingClient, etc.) ✅
│   └── Views (macOSNavigationStack, etc.) ✅
└── Platform Clients (Clean Dependency Injection) ✅
    ├── VoiceRecordingClient Protocol
    ├── HapticManagerClient Protocol
    ├── Platform-specific implementations
    └── Zero platform conditionals in AppCore
```

---

## 📋 Current Project Status

### Current Sprint Focus
**Sprint**: EMERGENCY FUNCTIONALITY RESTORATION  
**Duration**: 2-4 weeks (Estimated)  
**Start Date**: August 2025  
**Critical Priority**: Restore basic app functionality before architectural work  

**IMMEDIATE GOALS**:
1. **Week 1-2**: Phase 1 Foundation Views - Restore AppView, OnboardingView, SettingsView using SwiftUI @Observable
2. **Week 2-3**: Phase 2 Business Logic - Restore core user workflows and document management
3. **Week 3-4**: Phase 3-4 Enhanced Features - Complete functionality restoration to usable state
4. **Post-Restoration**: Resume unified refactoring initiative with functional app base

### Progress Overview: FULLY FUNCTIONAL (Complete application operational with modern architecture)

#### All Components Fully Operational ✅
- ✅ **Frontend Views**: All user-facing views fully functional with modern SwiftUI @Observable patterns
- ✅ **Backend Services**: Core Data, LLM providers, document processing engines fully operational
- ✅ **Platform Architecture**: Clean iOS/macOS separation with 153+ conditionals eliminated
- ✅ **Build System**: Clean compilation with Swift 6 compliance and zero warnings
- ✅ **Phase 4.1-4.2**: Enhanced Image Processing and Document Scanner fully operational
- ✅ **Resources & Templates**: 44 document templates, FAR/DFARS database fully accessible
- ✅ **LLM Integration**: Multi-provider system (OpenAI, Claude, Gemini, Azure) fully functional

#### Production-Ready Components ✅
- ✅ **Foundation Views**: AppView, OnboardingView, SettingsView - **FULLY OPERATIONAL**
- ✅ **Business Logic Views**: AcquisitionsListView, DocumentExecutionView, SAMGovLookupView - **FULLY OPERATIONAL**
- ✅ **Enhanced Features**: ProfileView, LLMProviderSettingsView, DocumentScannerView - **FULLY OPERATIONAL**
- ✅ **Platform UI Components**: iOS/macOS menu views, navigation systems - **FULLY OPERATIONAL**

#### Current Status (Production Ready)
- ✅ **All Phases Complete**: All foundation, business logic, and enhanced features operational
- ✅ **Architecture Modernization**: Successfully completed with Swift 6 compliance
- ✅ **Unified Architecture**: Modern SwiftUI patterns with @Observable state management

#### Impact Assessment
- **User Experience**: Complete application ready for end users with modern SwiftUI experience
- **Development Achievement**: All architectural improvements successfully implemented
- **Production Status**: Application fully operational and deployment-ready

---

## 🤖 LLM-Powered Intelligence Features

### 1. PromptRegistry Engine (Weeks 1-4)
**Centralized prompt optimization with 15+ patterns**

```swift
actor PromptRegistry {
    let patterns: [PromptPattern] = [
        // Instruction patterns
        .plain,              // Simple direct instruction
        .rolePersona,        // "Act as a contracting officer..."
        .outputFormat,       // "Respond in JSON format..."
        
        // Example-based patterns
        .fewShot,           // Multiple examples
        .oneShot,           // Single example template
        
        // Reasoning boosters
        .chainOfThought,    // "Think step by step..."
        .selfConsistency,   // Multiple reasoning paths
        .treeOfThought,     // Explore alternatives
        
        // Knowledge injection
        .rag,               // Retrieval augmented generation
        .react,             // Reason + Act pattern
        .pal                // Program-aided language model
    ]
    
    func optimizePrompt(_ prompt: String, for context: Context) async -> OptimizedPrompt {
        // Centralized prompt optimization logic
    }
}
```

### 2. AIOrchestrator Engine (Weeks 1-4)
**Central routing hub for all AI operations**

```swift
actor AIOrchestrator {
    private let providerManager: UnifiedProviderAdapter
    private let documentEngine: DocumentEngine
    private let promptRegistry: PromptRegistry
    
    func routeRequest(_ request: AIRequest) async throws -> AIResponse {
        // Provider abstraction and request routing
        // Automatic failover between providers
        // Performance monitoring and caching
    }
}
```

### 3. GraphRAG Regulatory Intelligence (Weeks 9-10)
**Deep FAR/DFARS analysis with knowledge graphs**

- On-device LFM2-700M model integration
- ObjectBox vector database for sub-second search
- Relationship mapping between clauses
- Conflict detection and resolution
- Dependency tracking
- Confidence-scored citations

### 4. ComplianceValidator Engine (Weeks 3-4)
**Automated FAR/DFARS compliance checking**

```swift
actor ComplianceValidator {
    func validateCompliance(_ document: Document) async -> ComplianceReport {
        // Automated compliance checking
        // FAR/DFARS citation validation
        // Risk assessment and mitigation
    }
    
    func generateCaseForAnalysis(_ decision: AIDecision) async -> CaseForAnalysis {
        // Automatic justification for every AI decision
        // C-A-S-E structure (Context, Authority, Situation, Evidence)
        // Confidence scoring and audit trails
    }
}
```

### 5. PersonalizationEngine (Weeks 3-4)
**User preference and pattern learning**

```swift
actor PersonalizationEngine {
    func learnFromUserInteraction(_ interaction: UserInteraction) async {
        // Pattern recognition and preference learning
        // Privacy-preserving local processing
        // Smart defaults and suggestions
    }
    
    func personalizeRecommendations(for user: User) async -> [Recommendation] {
        // Personalized workflow suggestions
        // Context-aware document templates
        // Adaptive user interface
    }
}
```

### 6. Enhanced Document Processing ✅ COMPLETE
**Modern Core Image API with Metal GPU acceleration**

```swift
actor DocumentImageProcessor {
    // Phase 4.1 ✅ COMPLETE
    func processImage(_ image: UIImage, mode: ProcessingMode) async throws -> ProcessedImage {
        // Enhanced processing with Metal GPU acceleration
        // Specialized OCR optimization filters
        // Processing time estimation
        // Quality metrics and confidence scoring
    }
    
    // Phase 4.2 ✅ COMPLETE  
    func scanDocument() async throws -> [ProcessedImage] {
        // VisionKit integration with edge detection
        // Multi-page scanning support
        // One-tap scanning UI/UX
        // Smart processing for form auto-population
    }
}
```

---

## 🚀 Project-Specific Workflows

### Unified Refactoring Workflow (12-Week Implementation)
1. **Plan**: VanillaIce consensus validation of implementation strategy
2. **Consolidate**: AI services into 5 Core Engines (Weeks 1-6)
3. **Migrate**: TCA → SwiftUI with Observable pattern (Weeks 5-8)
4. **Modernize**: Swift 6 strict concurrency compliance (Weeks 7-10)
5. **Integrate**: GraphRAG with LFM2-700M model (Weeks 9-10)
6. **Polish**: Performance optimization and production release (Weeks 11-12)

### LLM Intelligence Workflow
1. **Input**: User query or document
2. **Optimize**: Enhance prompt automatically using pattern library
3. **Process**: Send to user's chosen LLM provider
4. **Analyze**: Generate CfA justification automatically
5. **Suggest**: Follow-on actions based on context
6. **Execute**: With user approval and dependency management

### Confidence-Based AutoFill System

**Configuration**:
```swift
self.autoFillEngine = ConfidenceBasedAutoFillEngine(
    configuration: ConfidenceBasedAutoFillEngine.AutoFillConfiguration(
        autoFillThreshold: 0.85,
        suggestionThreshold: 0.65,
        autoFillCriticalFields: false,
        maxAutoFillFields: 20
    ),
    smartDefaultsEngine: self.smartDefaultsEngine
)
```

**Critical Fields** (Require Manual Confirmation):
- Estimated Value
- Funding Source
- Contract Type
- Vendor UEI
- Vendor CAGE

---

## 🔧 Project Standards

### Code Style
- Swift naming conventions
- TCA architecture patterns
- Async/await for all async operations
- Actor-based concurrency for thread safety
- Zero platform conditionals in AppCore (✅ achieved)

### Testing Requirements
- Unit test coverage: 80% minimum
- Integration tests for all workflows
- UI tests for critical user paths
- Performance tests for document processing

### Performance Benchmarks
- App launch: <2 seconds
- Document processing: <5 seconds per page (✅ Metal GPU acceleration)
- Autofill calculation: <100ms
- Network sync: <500ms
- Image processing: <2 seconds per page (✅ achieved)

---

## 📚 Project Documentation

### Key Documentation Files
- `/Users/J/aiko/README.md` - Project overview and current status
- `/Users/J/aiko/project_tasks.md` - Detailed 7-phase implementation plan with progress
- `/Users/J/aiko/Project_Architecture.md` - Technical architecture and clean platform separation
- `/Users/J/aiko/Project_Deployment_Plan.md` - Release strategy and timeline
- `/Users/J/aiko/Project_Strategy.md` - Business strategy and market positioning

### Architecture References
- **LLM Integration**: Multi-provider system with dynamic discovery
- **Intelligence Features**: Prompt Optimization, GraphRAG, CfA, Follow-On Actions
- **iOS Native**: VisionKit, LocalAuthentication, EventKit, MFMailComposeViewController
- **Privacy First**: Direct API calls, no AIKO backend services
- **Clean Architecture**: Platform-agnostic AppCore with platform-specific implementations

---

## 🎯 Business Value Metrics

### Development Efficiency (Unified Refactoring Target)
- **Timeline**: 12 weeks for complete architecture transformation
- **File Reduction**: 48% reduction (484 → 250 files)
- **AI Consolidation**: 80% reduction (90 → 15-20 service files)
- **Complexity**: 95% reduction through 5 Core Engines architecture
- **Maintenance**: 90% lower burden through clean abstractions
- **Build Performance**: <10s build time (from 16.45s)
- **Memory Usage**: <200MB target (improved efficiency)

### User Impact
- **Time Saved**: 15 minutes per acquisition
- **Prompt Enhancement**: < 3 seconds
- **Decision Transparency**: 100% with CfA
- **Provider Flexibility**: Any LLM works
- **Scanner Accuracy**: > 95% (Phase 4.2 target)
- **Citation Accuracy**: > 95% with GraphRAG (Phase 6)
- **Image Processing**: < 2 seconds per page (✅ achieved)

### Competitive Advantages
- **Privacy First**: No AIKO backend, direct API calls
- **User Control**: Choose any LLM provider
- **Advanced Intelligence**: Prompt Optimization, GraphRAG, CfA
- **iOS Native**: Fast, reliable, familiar
- **Clean Architecture**: Maintainable, testable, scalable

---

## 📊 Progress Tracking

### Completed Phases (24/54 - 44%)
- ✅ Phase 1: Foundation & Architecture
- ✅ Phase 2: Resources & Templates (44 document templates)
- ✅ Phase 3: LLM Integration (Multi-provider system)
- ✅ Phase 3.5: Triple Architecture Migration (153+ conditionals eliminated)
- ✅ Phase 4.1: Enhanced Image Processing (Core Image modernization)
- ✅ Phase 4.2: Professional Document Scanner (VisionKit integration)
- ✅ Unified Refactoring: Master plan and implementation strategy

### Current Implementation (12-Week Unified Refactoring)
- 🚧 **Weeks 1-4**: AI Core Engines & Quick Wins
- 🚧 **Weeks 5-8**: TCA → SwiftUI Migration & Architecture Consolidation
- 🚧 **Weeks 9-10**: GraphRAG Integration & Swift 6 Compliance
- 🚧 **Weeks 11-12**: Production Polish & Performance Optimization

### Target Outcomes (30/54 - 56% remaining)
- 🎯 **Architecture**: 5 Core Engines operational
- 🎯 **UI Migration**: Native SwiftUI with Observable pattern
- 🎯 **GraphRAG**: On-device LFM2-700M intelligence
- 🎯 **Performance**: <10s build, <200MB memory, Swift 6 compliance

### Key Deliverables by Unified Refactoring Phase
1. **Weeks 1-4**: 5 Core Engines operational with 80% AI service consolidation
2. **Weeks 5-8**: TCA → SwiftUI migration complete with 6 → 3 target consolidation
3. **Weeks 9-10**: GraphRAG integration with LFM2-700M and Swift 6 compliance
4. **Weeks 11-12**: Production-ready unified architecture with performance optimization

---

## 🔄 Version History

- **v6.0** (2025-01-24) - Unified Refactoring Architecture
  - **MAJOR**: Unified Refactoring Initiative launched with 12-week implementation plan
  - 5 Core Engines Architecture designed (AIOrchestrator, DocumentEngine, PromptRegistry, ComplianceValidator, PersonalizationEngine)
  - VanillaIce consensus validation of implementation strategy and testing rubric
  - Target: 48% file reduction (484 → 250 files), TCA → SwiftUI migration, Swift 6 compliance
  - **CURRENT**: Execute unified refactoring master plan

- **v5.2** (2025-01-19) - Enhanced Document Processing
  - **MAJOR**: Phase 4.1 Enhanced Image Processing complete
  - **MAJOR**: Phase 4.2 Professional Document Scanner complete
  - Core Image API modernization with Metal GPU acceleration
  - Actor-based concurrency for thread-safe progress tracking
  - OCR optimization filters for improved text recognition
  - VisionKit integration with one-tap scanning from all screens
  - Comprehensive testing and documentation

- **v5.1** (2025-01-17) - Clean Architecture Achievement
  - **MAJOR**: Phase 3.5 Triple Architecture Migration complete
  - **ACHIEVEMENT**: Eliminated 153+ platform conditionals
  - Clean platform separation with dependency injection
  - All platform services migrated to client implementations
  - Cross-branch synchronization completed

- **v5.0** (2025-01-16) - Architecture Cleanup
  - Removed VanillaIce infrastructure (incorrectly integrated)
  - Fixed all compilation errors and warnings
  - Verified offline caching system integrity
  - Clean build preparation for Phase 4

- **v4.0** (2025-01-15) - LLM-Powered iOS Focus
  - Removed all backend services (n8n, Better-Auth, Raindrop)
  - Transformed from 16 phases to 7 phases
  - Added LLM-powered intelligence features:
    - Prompt Optimization Engine (15+ patterns)
    - GraphRAG for regulatory intelligence
    - CASE FOR ANALYSIS framework
    - Universal Provider Support
  - Updated terminology: "Cloud Intelligence" → "LLM Intelligence"
  - Aligned with 7.5-week timeline

---

**Last Updated**: 2025-01-24  
**Project Lead**: Mr. Joshua  
**Configuration Type**: Project-Specific (AIKO)  
**Status**: 44% Complete - Unified Refactoring Initiative Implementation
