# Todo Folder Organization

## File Naming Convention

### Priority Prefixes:
- **00_** - CURRENT_WORKING - The active file being worked on RIGHT NOW
- **01_** - IN_PROGRESS - Files with tasks partially completed
- **02_** - REVIEW - Files awaiting review or validation
- **03_** - COMPLETED - Files with all tasks finished
- **99_** - ARCHIVE - Historical completed files

### File Structure:
```
00_CURRENT_WORKING.md          <- Always the top priority file
01_IN_PROGRESS_Authentication.md
01_IN_PROGRESS_Testing.md
02_REVIEW_UIUpdates.md
03_COMPLETED_Cleanup.md
03_COMPLETED_Documentation.md
99_ARCHIVE_OldFeatures.md
```

### Workflow:
1. Current task always in `00_CURRENT_WORKING.md`
2. When switching tasks, rename current to appropriate status
3. Copy new task to `00_CURRENT_WORKING.md`
4. Completed files move to 03_ prefix
5. Old completed files can be archived with 99_ prefix

### Task Format:
```markdown
# [Feature/File Name]

## Status: [In Progress/Review/Complete]
## Priority: [High/Medium/Low]
## Started: [Date]
## Target Completion: [Date]

### Tasks:
- [x] Completed task
- [ ] Pending task
- [ ] Another task

### Blockers:
- Issue 1
- Issue 2

### Notes:
- Important information
- Dependencies
```