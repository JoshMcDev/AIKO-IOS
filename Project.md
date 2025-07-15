# project.md - AIKO Project Configuration
> **Adaptive Intelligence for Kontract Optimization**
> **Project-Specific Claude Code Configuration**

---

## 🎯 Project Overview

**Project**: AIKO (Adaptive Intelligence for Kontract Optimization)  
**Version**: 2.0.0  
**Type**: iOS/macOS Application  
**Domain**: Government Contracting  

### Project Vision
Build an intelligent iOS/macOS application that revolutionizes government contracting by learning from user patterns, minimizing questions, and automating document processing through adaptive AI.

---

## 🏗️ Project Architecture

### Core Technologies
- **Frontend**: SwiftUI + The Composable Architecture (TCA)
- **Authentication**: Better-Auth (Government Compliance - FISMA, FedRAMP)
- **Persistence**: Core Data + CloudKit
- **AI Integration**: Multi-Provider LLM Support (Claude, OpenAI, Gemini) + Local Pattern Learning + Future Raindrop LNN
- **Document Processing**: Vision Framework + Custom OCR
- **Workflow Automation**: n8n (Performance-First Backend) + Native iOS (Thin Client)

### Architecture Decisions

#### Hybrid n8n + Native iOS Architecture (3 Async Workflows)

Based on /vanillaIce consensus analysis, the architecture has been optimized to:

1. **n8n Workflows** (Backend Processing):
   - Document Processing Pipeline
   - Compliance & Audit Pipeline  
   - Background Intelligence

2. **Native iOS Implementation** (Real-time Operations):
   - Cache/Sync via Swift actors + CloudKit
   - Real-time updates with WebSocket/SSE
   - Core Data with offline sync queue
   - Sub-100ms sync operations

**Critical Decision**: Cache/Sync operations moved from n8n to native iOS due to latency requirements identified by consensus analysis.

---

## 📋 Project-Specific Tasks

### Current Sprint Focus
**Sprint**: Adaptive Intelligence Foundation  
**Duration**: 2 weeks  
**Goals**:
1. Complete Task 2.3: User Pattern Learning Module
2. Complete Task 2.4: Smart Defaults System
3. Begin Task 2.5: Claude API Integration

### Key Implementation Details

#### Task 7.1: Hybrid Architecture Implementation
**Status**: 📅 Scheduled  
**Duration**: 6-7 weeks (reduced from 8-10 weeks)

**Implementation Timeline**:
- Weeks 1-3: n8n infrastructure + Document Pipeline
- Weeks 4-5: Compliance & Background Intelligence
- Week 6: Native iOS sync implementation
- Week 7: Integration testing + optimization

**Performance Targets**:
- Document processing: 90% faster than manual
- Autofill accuracy: 85%+ confidence threshold
- Sync latency: <100ms for critical operations
- User time saved: 15 minutes per acquisition

#### Task 12: n8n Performance Workflows
**Status**: 20% Complete

**Completed**:
- ✅ Real-time API Batching (40% fewer queries)
- ✅ Auto Cache Invalidation (5x faster reads)

**Pending Performance Optimizations**:
- Log Aggregation & Anomaly Detection (30% less downtime)
- Auto-scaling Triggers (instant scaling)
- DB Index Optimization (7x faster queries)
- Rate-limiting (99.9% uptime)
- Health Monitoring (80% faster recovery)
- Asset Preloading (60% faster loads)
- JWT Rotation (85ms auth time)
- Distributed Tracing (4x debug speed)

---

## 🚀 Project-Specific Workflows

### Document Generation System

#### Requirement Studio Central Workspace
- Document card system for visual workflow
- Letter of Justification prominent placement
- Quick-action buttons for document generation
- Real-time status indicators for all documents
- Intuitive navigation between requirements and documents

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
- `/Users/J/aiko/Documentation/01_Project_Overview.md`
- `/Users/J/aiko/Documentation/02_Architecture_Decisions.md`
- `/Users/J/aiko/Documentation/03_Implementation_Guide.md`
- `/Users/J/aiko/Documentation/04_Project_Tasks.md`

### n8n Workflow References
- **Documentation**: `/Users/J/.claude/n8n-workflow-reference.md`
- **Implementation Guide**: `/Users/J/.claude/n8n_workflows_implementation_guide.md`
- **Workflow Templates**: `/Users/J/.claude/n8n-workflows/`
- **Completed Workflows**: `/Users/J/Desktop/n8n aiko/`

---

## 🎯 Business Value Metrics

### Financial Impact (Validated by Consensus)
- **Annual Profit**: $40,000
- **Payback Period**: 9 months
- **5-Year NPV**: $127,000
- **ROI**: 317%

### Efficiency Gains
- **Time Saved**: 15 minutes per acquisition
- **Question Reduction**: 70% fewer manual inputs
- **Processing Speed**: 90% faster document generation
- **Error Reduction**: 45% fewer compliance issues

---

## 📊 Progress Tracking

### Completed Features
- ✅ Task 1: Foundation & Architecture
- ✅ Task 2.1: Conversational Flow Architecture
- ✅ Task 2.2: Context Extraction from Documents
- ✅ Task 2.4: Smart Defaults System

### In Progress
- 🚧 Task 2.3: User Pattern Learning Module
- 🚧 Task 12: n8n Performance Workflows (20%)

### Upcoming Priorities
1. Complete adaptive prompting engine
2. Implement n8n document processing pipeline
3. Build native iOS sync architecture
4. Create compliance automation workflows

---

## 🔄 Version History

- **v1.0** (2025-01-15) - Initial project configuration
  - Extracted from global CLAUDE.md v5.1
  - Added AIKO-specific architecture details
  - Included validated n8n consensus decisions
  - Documented performance targets and metrics

---

**Last Updated**: 2025-01-15  
**Project Lead**: Mr. Joshua  
**Configuration Type**: Project-Specific (AIKO)