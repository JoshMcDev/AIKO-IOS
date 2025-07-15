# AIKO Task Management Protocol

> Simplified guide for managing tasks with TodoWrite and 9-stage quality pipeline
> Version 2.0 - Post Task System Migration (July 14, 2025)

## Critical Update: TodoWrite-Only System

**As of July 14, 2025: TodoWrite is the EXCLUSIVE task management system**
- ✅ TodoWrite - ACTIVE (single source of truth)

## Overview

The AIKO project follows a streamlined task management protocol using Claude Code's internal TodoWrite tool, ensuring zero synchronization issues while maintaining our 9-stage quality pipeline for production readiness.

## Current Architecture

### Task Management
- **TodoWrite**: Internal Claude Code tool
- **Features**: Tasks, subtasks, priorities, status tracking
- **Storage**: Session-persistent, no external files

### Codebase Structure
```
Sources/
├── Core/               # Core infrastructure
├── CoreData/          # Data persistence layer
├── Domain/            # Business logic
├── Features/          # Feature modules
│   ├── AcquisitionChatFeatureEnhanced.swift
│   └── Document processing features
├── Infrastructure/    # Supporting systems
├── Models/            # Data models
├── Services/          # Service layer
│   ├── ConversationalFlowArchitecture.swift
│   ├── AdaptiveConversationOrchestrator.swift
│   └── Integration services
├── UI/                # User interface components
└── Views/             # SwiftUI views
```

### Integration Stack
- **Better_Auth**: Authentication system (planned)
- **n8n Workflows**: 10 performance-optimized workflows (designed)
- **Raindrop (liquid.ai)**: Serverless infrastructure (planned)

## Task Structure in TodoWrite

### Active Tasks (Current Status)
- **Task 1**: Document parser ✅ COMPLETED
- **Task 2**: Adaptive prompting engine 🔄 IN PROGRESS
  - 2.1: Conversational flow architecture ✅ COMPLETED
  - 2.2: Context extraction from documents ⏳ PENDING
  - 2.3: User pattern learning module ⏳ PENDING
  - 2.4: Smart defaults system ⏳ PENDING
  - 2.5: Claude API integration ⏳ PENDING

### Phase Organization
- Phase 1: Foundation & Core Document Processing (Active)
- Phase 2: Intelligent Form Generation & FAR Integration
- Phase 3: Advanced Search & Integration Services
- Phase 4: Intelligence & Learning Systems
- Phase 5: Analytics & Advanced Features
- Phase 6: Polish & Production Readiness

### Integration Tasks (Parallel Track)
- Tasks 44-50: Better_Auth + n8n + Raindrop Integration

## Task Progression Protocol

### 1. Task Initiation
```javascript
// Using TodoWrite tool
TodoWrite.addTask("Implement feature X", {
  priority: "high",
  status: "pending"
});
```

### 2. Subtask Breakdown
- Create subtasks directly in TodoWrite
- Each subtask should be completable in 1-2 hours
- Link subtasks to parent task

### 3. Task Updates
```javascript
// Update task status
TodoWrite.updateStatus("task-id", "in_progress");

// Mark completion
TodoWrite.updateStatus("task-id", "completed");
```

### 4. Quality Gates
Each task must pass through ALL stages:

| Stage | File | Criteria | Command |
|-------|------|----------|---------|
| Phased Plan | 00_Phased_Deployment_Plan.md | Strategy defined | Define phases |
| Current Phase | 01_Current_Phase_Reference.md | Phase selected | Track progress |
| Working | 02_Working_Tasks.md | Planning complete | Start development |
| SubTasks | 03_Working_SubTasks.md | Detailed breakdown | Define sub-subtasks |
| Parallel | 04_Parallel_Tasks.md | Active development | Multi-agent work |
| Completed | 05_Completed_Tasks.md | Code complete | Move when done |
| Tested | 06_Tested_Tasks.md | 0 errors, 0 warnings | Run test suite |
| Verified | 07_Verified_Tasks.md | Score ≥ 95/100, simulation ready | Quality check |
| Certified | 08_Certified_Tasks.md | Passed simulation, production ready | Final review |
| Deployed | 09_Deployed_Tasks.md | Beta version released | Track version |

### 5. Task Management Best Practices

#### TodoWrite Usage
- Update status immediately when starting/completing tasks
- Use clear, descriptive task names
- Set appropriate priorities (high, medium, low)
- Group related tasks with consistent naming

#### Quality Pipeline Integration
- Track task progress through conceptual stages
- Document stage completion in task descriptions
- Maintain quality standards at each gate

## Phase 1 Focus (Current)

### Core Tasks
1. **Task 1**: Document parser (PDF/Word/Image)
   - 5 subtasks with sub-subtasks
   - Critical for all document processing
   
2. **Task 32**: Resources & Tools category  
   - 6 subtasks in Task Master (Task #14)
   - UI/UX integration required

3. **Task 38**: Form caching
   - 4 subtasks in Task Master (Task #15)
   - Enables offline functionality

### Supporting Tasks (Partial)
- Task 77: UI/UX Design System (Week 1-2 deliverables)
- Task 78: Backend Architecture (Week 1-2 deliverables)
- Task 80: Test Framework Setup (Week 1-2 deliverables)

## Daily Workflow

### Morning
1. Review TodoWrite task list
2. Identify priorities for the day
3. Update any overnight status changes

### During Development
1. Mark tasks as 'in_progress' when starting
2. Update subtask completion in real-time
3. Document blockers in task descriptions
4. Complete tasks immediately when done

### End of Day
1. Ensure all task statuses are current
2. Add new tasks discovered during work
3. Set priorities for next day
4. Review overall progress

## Technology Integration Status

### Better_Auth Integration
- **Status**: Planning Phase
- **Goal**: Minimal overhead authentication
- **Timeline**: Weeks 3-4 of implementation

### n8n Workflow Implementation
- **Status**: 10 workflows designed ✅
- **Workflows**: API batching, cache invalidation, monitoring, etc.
- **Impact**: 4.2x performance improvement projected

### Raindrop (liquid.ai) Infrastructure
- **Status**: Architecture analysis phase
- **Goal**: Serverless, event-driven architecture
- **Benefits**: 77% cost reduction, instant scaling

## Success Metrics

### Phase 1 Targets
- [ ] Document parsing accuracy > 95%
- [ ] Page load time < 2 seconds
- [ ] Offline functionality working
- [ ] Core UI responsive
- [ ] Test framework operational

### Quality Standards
- Every feature must achieve 95% quality score
- Zero technical debt policy
- Complete test coverage
- Full documentation

## Current Implementation Focus

### Adaptive Prompting Engine (Task 2)
- **Completed**: Conversational flow architecture
- **Active**: Context extraction implementation
- **Benefits**: 70% reduction in user prompts
- **Architecture**: 
  - ConversationalFlowArchitecture.swift
  - AdaptiveConversationOrchestrator.swift
  - AcquisitionChatFeatureEnhanced.swift

### Performance Targets
- Document parsing accuracy > 95%
- Response time < 180ms (P95)
- Support 750 concurrent users
- 99.99% uptime

---

**Last Updated**: July 14, 2025  
**Version**: 2.0  
**Status**: Active Protocol
