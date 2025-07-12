# AIKO Task Management Protocol

> Comprehensive guide for managing tasks through the 7-stage pipeline with multi-agent support

## Overview

The AIKO project follows a structured task management protocol that ensures quality delivery through systematic progression of tasks from planning to production. This protocol integrates with Task Master AI for tracking and utilizes a 7-stage pipeline for quality assurance.

## File Structure

```
Todo/
├── 00_Phased_Deployment_Plan.md     # 6-phase deployment strategy
├── 01_Current_Phase_Reference.md    # Current phase status and quick commands
├── 02_Working_Tasks.md              # Current phase tasks in planning/development
├── 03_Working_SubTasks.md           # Detailed subtask breakdown
├── 04_Parallel_Tasks.md             # Tasks distributed for multi-agent processing
├── 05_Completed_Tasks.md            # Code-complete tasks
├── 06_Tested_Tasks.md               # Tasks passing all tests
├── 07_Verified_Tasks.md             # Tasks scoring ≥95/100
├── 08_Certified_Tasks.md            # Production-ready tasks
├── 09_Production_Tasks.md           # Live operational tasks
├── 10_Deployed_Tasks.md             # Beta deployments with version tracking
└── README.md                        # Pipeline overview
```

## Task Master AI Integration

All tasks are tracked in Task Master AI with the following structure:

### Phase Tasks (Master Level)
- Phase 1: Task #8 - Foundation & Core Document Processing
- Phase 2: Task #9 - Intelligent Form Generation & FAR Integration  
- Phase 3: Task #10 - Advanced Search & Integration Services
- Phase 4: Task #11 - Intelligence & Learning Systems
- Phase 5: Task #12 - Analytics & Advanced Features
- Phase 6: Task #13 - Polish & Production Readiness

### Implementation Tasks
- Tasks #1-7: Core MVP features
- Task #8: Offline caching system (with 4 subtasks)
- Task #14: Resources & Tools category (with 6 subtasks)
- Task #15: Form caching for offline use (with 4 subtasks)

## Task Progression Protocol

### 1. Task Initiation
```bash
# Start a task
/task-master-ai.set_task_status --projectRoot /Users/J/aiko --id [task-id] --status in-progress

# Move task to Working Tasks file
# Add task details to 02_Working_Tasks.md
```

### 2. Subtask Breakdown
- For complex tasks, create subtasks in Task Master AI
- Document sub-subtasks in `02_5_Working_SubTasks.md`
- Each subtask should be completable in 1-2 hours

### 3. Multi-Agent Distribution
When ready for parallel processing:
1. Move task to `03_Parallel_Tasks.md`
2. Assign subtasks to different agents
3. Track progress in Task Master AI
4. Coordinate through daily syncs

### 4. Quality Gates
Each task must pass through ALL stages:

| Stage | File | Criteria | Command |
|-------|------|----------|---------|
| Working | 02_Working_Tasks.md | Planning complete | Start development |
| SubTasks | 03_Working_SubTasks.md | Detailed breakdown | Define sub-subtasks |
| Parallel | 04_Parallel_Tasks.md | Active development | Multi-agent work |
| Completed | 05_Completed_Tasks.md | Code complete | Move when done |
| Tested | 06_Tested_Tasks.md | 0 errors, 0 warnings | Run test suite |
| Verified | 07_Verified_Tasks.md | Score ≥ 95/100 | Quality check |
| Certified | 08_Certified_Tasks.md | Production ready | Final review |
| Production | 09_Production_Tasks.md | Live & operational | Deploy to prod |
| Deployed | 10_Deployed_Tasks.md | Beta version released | Track version |

### 5. Task Movement Commands
```bash
# Check task status
/task-master-ai.get_task --projectRoot /Users/J/aiko --id [task-id] --withSubtasks

# Update task status
/task-master-ai.set_task_status --projectRoot /Users/J/aiko --id [task-id] --status completed

# Move files between stages
# Manual file movement required - update the appropriate .md files
```

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
1. Check phase progress:
   ```bash
   /task-master-ai.get_task --projectRoot /Users/J/aiko --id 8 --withSubtasks
   ```

2. Review working tasks in `02_Working_Tasks.md`

3. Identify tasks ready for parallel processing

### During Development
1. Update Task Master AI status as work progresses
2. Move completed subtasks through pipeline stages
3. Document blockers and issues
4. Coordinate with other agents on parallel tasks

### End of Day
1. Update all task statuses
2. Move completed items to next stage
3. Update documentation
4. Plan next day priorities

## Multi-Agent Coordination

### Task Distribution
- Each agent claims subtasks in `03_Parallel_Tasks.md`
- Update Task Master AI with agent assignment
- Use comments for inter-agent communication

### Sync Points
- Daily sync at defined time
- Integration testing when all subtasks complete
- Merge conflicts resolved by lead agent

### Best Practices
1. Clear subtask boundaries
2. Minimal inter-dependencies
3. Regular integration commits
4. Comprehensive documentation

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

## Troubleshooting

### Common Issues
1. **Task stuck in stage**: Check quality gates
2. **Parallel conflicts**: Review sync points
3. **Task Master sync**: Verify project root path
4. **File organization**: Follow numbering convention

### Emergency Procedures
1. Context overflow: Save state immediately
2. Pipeline blockage: Escalate to team lead
3. Integration failure: Rollback and debug
4. Quality gate failure: Document and fix

---

**Last Updated**: January 2025  
**Version**: 1.0  
**Status**: Active Protocol