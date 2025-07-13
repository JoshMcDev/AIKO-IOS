# Parallel Tasks

> Tasks ready for multi-agent parallel processing. Multiple agents can work on these simultaneously.
> When moved here from Working Tasks, subtasks can be distributed across agents.

## Parallel Execution Guidelines

1. **Task Distribution**:
   - Each subtask can be assigned to a different agent
   - Agents work independently on their assigned subtasks
   - Sync points occur at parent task completion

2. **Agent Coordination**:
   - Use Task Master AI to track which agent has which subtask
   - Regular sync meetings to ensure integration
   - Shared context through documentation updates

3. **Quality Gates**:
   - Each subtask must pass individual testing
   - Integration testing when all subtasks complete
   - Parent task moves to Completed only when all subtasks pass

## Active Parallel Tasks

<!-- Tasks will be moved here from 03_Working_Tasks.md when ready for parallel processing -->

### Example Format:
```
### Task X: Task Name
**Parallel Agents**: 3
**Distribution**:
- Agent A: Subtasks 1.1, 1.2
- Agent B: Subtasks 1.3, 1.4
- Agent C: Subtasks 1.5

#### Progress Tracking:
- [⏳] 1.1: Subtask name (Agent A)
- [⏳] 1.2: Subtask name (Agent A)
- [ ] 1.3: Subtask name (Agent B)
- [ ] 1.4: Subtask name (Agent B)
- [ ] 1.5: Subtask name (Agent C)

**Integration Points**:
- Daily sync at 10 AM
- Shared branch: feature/task-x
- Dependencies: 1.3 needs 1.1 output
```

---

## Parallel Processing Best Practices

1. **Clear Boundaries**:
   - Each subtask should have clear inputs/outputs
   - Minimize dependencies between parallel subtasks
   - Document interfaces between components

2. **Communication**:
   - Use Task Master AI comments for updates
   - Document decisions in shared files
   - Flag blockers immediately

3. **Integration**:
   - Continuous integration of subtask work
   - Regular testing of combined components
   - Early detection of integration issues

## Commands for Parallel Work

```bash
# Assign subtask to specific agent
/task-master-ai.update_task --projectRoot . --id 1.1 --prompt "Assigned to Agent A"

# Check parallel task status
/task-master-ai.get_task --projectRoot . --id 1 --withSubtasks

# Mark subtask complete
/task-master-ai.set_task_status --projectRoot . --id 1.1 --status completed
```

---

**Stage**: Parallel Processing  
**Next Stage**: Completed Tasks (when all subtasks done)  
**Last Updated**: January 2025