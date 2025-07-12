# FAP - Follow-on Action Prompting

> Claude's Follow-on Action Prompting: Demonstrating integration effects & logical follow-on recommendations

## Command: /fap

### Purpose
Analyzes the previous user input/action to:
1. Show integration effects across the system
2. Identify logical next steps
3. Recommend follow-on actions
4. Highlight potential improvements or risks

### Usage
```
/fap
```

### Output Format
```markdown
## 🔄 Follow-on Action Analysis

### Previous Action Summary:
[Brief description of what was just completed]

### Integration Effects:
- **Task Master AI**: [How it affects task tracking]
- **File Structure**: [Changes to documentation/files]
- **Pipeline Flow**: [Impact on task progression]
- **Multi-Agent**: [Effects on parallel processing]

### Recommended Follow-on Actions:

#### Immediate (Do Now):
1. [Action 1 with specific command]
2. [Action 2 with file to update]

#### Short-term (Next Session):
1. [Planning recommendation]
2. [Testing/validation step]

#### Long-term (This Phase):
1. [Strategic consideration]
2. [Architecture decision]

### Potential Risks:
- ⚠️ [Risk 1 and mitigation]
- ⚠️ [Risk 2 and mitigation]

### Commands to Execute:
```bash
# Command 1
/task-master-ai.command --projectRoot /Users/J/aiko

# Command 2
/tool.command
```
```

### Example Response

After reordering task files:

```markdown
## 🔄 Follow-on Action Analysis

### Previous Action Summary:
Reordered Todo files from 00-08 to 00-10, adding deployment tracking

### Integration Effects:
- **Task Master AI**: No changes needed, references remain valid
- **File Structure**: New 10_Deployed_Tasks.md adds beta tracking
- **Pipeline Flow**: Extended pipeline now includes deployment stage
- **Multi-Agent**: Clearer progression from subtasks → parallel work

### Recommended Follow-on Actions:

#### Immediate (Do Now):
1. Update Task Master phase tasks to reference new file numbers
   ```bash
   /task-master-ai.update_task --projectRoot /Users/J/aiko --id 8 --prompt "Update references to use new file numbering 00-10"
   ```

2. Create beta deployment checklist in 10_Deployed_Tasks.md

#### Short-term (Next Session):
1. Start Phase 1 Task 1 (Document Parser) - move to 02_Working_Tasks
2. Assign subtasks to agents in 04_Parallel_Tasks

#### Long-term (This Phase):
1. Plan v1.0.0-beta deployment criteria
2. Set up automated deployment pipeline

### Potential Risks:
- ⚠️ File references in code may break - search and update all references
- ⚠️ Team confusion with new numbering - update team documentation

### Commands to Execute:
```bash
# Verify all files are accessible
ls -la /Users/J/aiko/Todo/*.md

# Check Task Master sync
/task-master-ai.get_tasks --projectRoot /Users/J/aiko --withSubtasks
```
```

### Implementation Logic

When /fap is called, analyze:
1. Last user message/command
2. Recent file changes
3. Task Master updates
4. Current phase status
5. Pipeline state

Then recommend based on:
- Logical progression
- Integration dependencies  
- Best practices
- Risk mitigation
- Efficiency optimization