# project.md - AIKO Project Configuration
> **Adaptive Intelligence for Kontract Optimization**
> **Project-Specific Claude Code Configuration**

---

## 🎯 Project Overview

**Project**: AIKO (Adaptive Intelligence for Kontract Optimization)  
**Version**: 5.0 (LLM-Powered iOS)  
**Type**: iOS Application  
**Domain**: Government Contracting  

### Project Vision
Build a focused iOS productivity tool that revolutionizes government contracting by leveraging user-chosen LLM providers for all intelligence features. No backend services, no cloud complexity - just powerful automation through a simple native interface.

**Core Philosophy**: Let LLMs handle intelligence. Let iOS handle the interface. Let users achieve more with less effort.

---

## 🏗️ Project Architecture

### Core Technologies
- **Frontend**: SwiftUI + The Composable Architecture (TCA) ✅
- **Storage**: Core Data (local only) + CfA audit trails
- **LLM Integration**: Universal multi-provider system with dynamic discovery ✅
- **Document Processing**: VisionKit Scanner + OCR + Smart Filing
- **Intelligence Layer**: All via user's LLM API keys
- **Security**: Keychain Services + LocalAuthentication (Face ID/Touch ID)
- **Integrations**: iOS Native (Mail, Calendar, Reminders) + Google Maps

### Simplified Architecture

```
AIKO iOS App (Simple Native UI)
├── UI Layer (SwiftUI) ✅
│   ├── Dashboard ✅
│   ├── Document Categories ✅
│   ├── Chat Interface ✅
│   ├── Scanner View (Phase 4)
│   ├── Intelligence Cards (Phase 6)
│   └── Provider Setup Wizard (Phase 5)
├── Services (Thin Client Layer)
│   ├── LLMService.swift ✅ (Enhanced)
│   ├── DocumentService.swift ✅
│   ├── ScannerService.swift (Phase 4)
│   ├── PromptOptimizationService.swift (Phase 5)
│   ├── GraphRAGService.swift (Phase 6)
│   ├── CaseForAnalysisService.swift (Phase 6)
│   └── ProviderDiscoveryService.swift (Phase 5)
└── LLM Intelligence (via User's API Keys)
    ├── Prompt Optimization Engine
    ├── GraphRAG Regulatory Knowledge
    ├── CASE FOR ANALYSIS Framework
    ├── Follow-On Action Generator
    └── Document Chain Orchestrator
```

---

## 📋 Project-Specific Tasks

### Current Sprint Focus
**Sprint**: Phase 4 - Document Scanner & Capture  
**Duration**: 2 weeks  
**Start Date**: January 17, 2025  

**Goals**:
1. Implement VisionKit scanner with edge detection
2. Build multi-page scanning workflow
3. Integrate OCR for text extraction
4. Create smart filing system

### Key Implementation Details

#### Phase 4: Document Scanner (In Progress)
**Status**: 🚧 Starting  
**Duration**: 2 weeks

**Implementation Plan**:
- **Week 1**: Core scanner implementation
  - VisionKit document scanner
  - Multi-page support
  - OCR integration
- **Week 2**: UI/UX and smart features
  - One-tap scanning
  - Auto-populate forms
  - Smart filing

**Performance Targets**:
- Scanner accuracy: > 95%
- OCR processing: < 2 seconds per page
- Auto-populate accuracy: > 90%
- User satisfaction: One-tap simplicity

---

## 🤖 LLM-Powered Intelligence Features

### 1. Prompt Optimization Engine (Phase 5)
**One-tap prompt enhancement with 15+ patterns**

```swift
struct PromptOptimizationEngine {
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
}
```

### 2. GraphRAG Regulatory Intelligence (Phase 6)
**Deep FAR/DFARS analysis with knowledge graphs**

- Relationship mapping between clauses
- Conflict detection and resolution
- Dependency tracking
- Confidence-scored citations
- Visual graph exploration

### 3. CASE FOR ANALYSIS Framework (Phase 6)
**Automatic justification for every AI decision**

```swift
struct CaseForAnalysis {
    let context: String      // Situation overview
    let authority: [String]  // FAR/DFARS citations
    let situation: String    // Specific analysis
    let evidence: [String]   // Supporting data
    let confidence: Double   // Decision confidence
    
    // Automatic generation with every recommendation
    // Collapsible UI cards for transparency
    // JSON export for audit trails
}
```

### 4. Universal Provider Support (Phase 5)
**Support any LLM with automatic discovery**

```swift
struct ProviderDiscoveryService {
    func discoverAPI(endpoint: URL, apiKey: String) async -> ProviderAdapter? {
        // Test connection
        // Analyze API structure
        // Generate dynamic adapter
        // Store configuration securely
    }
}
```

### 5. Follow-On Actions & Document Chains (Phase 6)
**Intelligent workflow automation**

- LLM-suggested next steps
- Dependency management
- Parallel execution (up to 3 tasks)
- Review modes (iterative vs batch)
- Progress visualization

---

## 🚀 Project-Specific Workflows

### Document Scanner Workflow
1. **Capture**: VisionKit edge detection
2. **Process**: OCR text extraction
3. **Analyze**: Form field detection
4. **File**: Smart categorization
5. **Use**: Auto-populate forms

### LLM Intelligence Workflow
1. **Input**: User query or document
2. **Optimize**: Enhance prompt automatically
3. **Process**: Send to user's LLM provider
4. **Analyze**: Generate CfA justification
5. **Suggest**: Follow-on actions
6. **Execute**: With user approval

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

### Testing Requirements
- Unit test coverage: 80% minimum
- Integration tests for all workflows
- UI tests for critical user paths

### Performance Benchmarks
- App launch: <2 seconds
- Document processing: <5 seconds per page
- Autofill calculation: <100ms
- Network sync: <500ms

---

## 📚 Project Documentation

### Key Documentation Files
- `/Users/J/aiko/README.md` - Project overview and features
- `/Users/J/aiko/Documentation/Project_Tasks.md` - 7-phase implementation plan
- `/Users/J/aiko/Documentation/Phased_Deployment_Plan.md` - Deployment strategy
- `/Users/J/aiko/Stategy.md` - Simplification strategy

### Architecture References
- **LLM Integration**: Multi-provider system with dynamic discovery
- **Intelligence Features**: Prompt Optimization, GraphRAG, CfA, Follow-On Actions
- **iOS Native**: VisionKit, LocalAuthentication, EventKit, MFMailComposeViewController
- **Privacy First**: Direct API calls, no AIKO backend services

---

## 🎯 Business Value Metrics

### Development Efficiency (Simplified Approach)
- **Timeline**: 7.5 weeks vs 12+ months
- **Complexity**: 95% reduction
- **Maintenance**: 90% lower burden
- **App Size**: < 50MB target

### User Impact
- **Time Saved**: 15 minutes per acquisition
- **Prompt Enhancement**: < 3 seconds
- **Decision Transparency**: 100% with CfA
- **Provider Flexibility**: Any LLM works
- **Scanner Accuracy**: > 95%
- **Citation Accuracy**: > 95% with GraphRAG

### Competitive Advantages
- **Privacy First**: No AIKO backend, direct API calls
- **User Control**: Choose any LLM provider
- **Advanced Intelligence**: Prompt Optimization, GraphRAG, CfA
- **iOS Native**: Fast, reliable, familiar

---

## 📊 Progress Tracking

### Completed Phases (3/7 - 43%)
- ✅ Phase 1: Foundation & Architecture
- ✅ Phase 2: Resources & Templates (44 document templates)
- ✅ Phase 3: LLM Integration (Multi-provider system)

### Current Phase
- 🚧 Phase 4: Document Scanner & Capture (Starting Jan 17, 2025)

### Upcoming Phases
- 📅 Phase 5: Smart Integrations & Provider Flexibility (1.5 weeks)
- 📅 Phase 6: LLM Intelligence & Compliance Automation (2 weeks)
- 📅 Phase 7: Polish & App Store Release (2 weeks)

### Key Deliverables by Phase
1. **Phase 4**: Professional scanner with OCR
2. **Phase 5**: Prompt Optimization + Universal Provider Support
3. **Phase 6**: CfA + GraphRAG + Follow-On Actions
4. **Phase 7**: App Store release

---

## 🔄 Version History

- **v2.0** (2025-01-16) - Simplified LLM-Powered iOS Focus
  - Removed all backend services (n8n, Better-Auth, Raindrop)
  - Transformed from 16 phases to 7 phases
  - Added LLM-powered intelligence features:
    - Prompt Optimization Engine (15+ patterns)
    - GraphRAG for regulatory intelligence
    - CASE FOR ANALYSIS framework
    - Universal Provider Support
  - Updated terminology: "Cloud Intelligence" → "LLM Intelligence"
  - Aligned with 7.5-week timeline

- **v1.0** (2025-01-15) - Initial project configuration
  - Extracted from global CLAUDE.md v5.1
  - Added AIKO-specific architecture details
  - Included validated n8n consensus decisions
  - Documented performance targets and metrics

---

**Last Updated**: 2025-01-16  
**Project Lead**: Mr. Joshua  
**Configuration Type**: Project-Specific (AIKO)
