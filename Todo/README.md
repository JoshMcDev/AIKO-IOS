# Todo Folder Structure & Usage Guide

This folder contains persistent memory systems for maintaining context and tracking progress across Claude Code sessions.

## 📁 Folder Structure

```
Todo/
├── README.md                             # This file (CAPITALS first)
├── ChatHistory_20250711.md               # Current daily conversation log
├── Todo_00_CurrentWorking_TodoList.md    # Active task list with Task Master integration
├── Todo_01_InProgress_FARPart53Implementation.json  # In-progress task tracking
├── Todo_03_Completed_ProjectCleanup.md   # Completed task archive
└── ChatHistory/                          # Archived chat history files
    └── [Older chat history files]
```

**Note**: File system display may show folders first, but our logical organization lists files before subfolders, with CAPITAL files at the top.

##  File Naming Convention

All files follow a consistent naming pattern:
- **Category prefix** followed by underscore (e.g., Todo_, ChatHistory_)
- **Number** (if applicable) followed by underscore separator (e.g., Todo_00_, Todo_01_)
- **Status** followed by underscore and description (e.g., CurrentWorking_TodoList)
- **Pattern**: `Category_##_Status_Description`
- **Number meanings**:
  - `00` = Current/Active working files
  - `01` = In Progress tasks
  - `02` = Under Review
  - `03` = Completed tasks
  - `99` = Archived files

**Special formats**:
- ChatHistory files: `ChatHistory_YYYYMMDD.md` (e.g., ChatHistory_20250711.md)
- Standard files: README.md and CLAUDE.md maintain conventional naming

##  How It Works

### 1. Todo List Management (`Todo_00_CurrentWorking_TodoList.md`)
- **Purpose**: Maintains current task state across sessions
- **Format**: Task Master AI integrated with checkboxes
- **Updates**: Mark ☒ for completed, ☐ for pending
- **Integration**: Synced with `.taskmaster/tasks/tasks.json`
- **Usage**: 
  - Updated in real-time as tasks complete
  - Referenced on session start for context
  - Shows all main tasks and subtasks with dependencies

### 2. Chat History (`ChatHistory_YYYYMMDD.md`)
- **Purpose**: Preserves conversation context
- **Format**: Verbatim conversation log with timestamps
- **Location**: Current day's file stays in Todo folder for quick reference
- **Archival**: Previous days' files move to ChatHistory/ subfolder
- **Naming**: Files named with ChatHistory_ prefix and date (e.g., `ChatHistory_20250711.md`)
- **Updates**: 
  - Every 30 minutes automatically
  - On any memory save event
  - When tasks are completed
- **Special Protocol**: 
  - "Goodnight" command adds daily summary at file top
  - Summary includes work completed and next steps

### 3. Recovery Protocol

When starting a new session or after context reset:
```bash
1. Check ./Todo/Todo_00_CurrentWorking_TodoList.md
2. Load ./Todo/ChatHistory_YYYYMMDD.md (today's date)
3. Review any "Goodnight" summaries
4. Continue from last completed subtask
```

##  Benefits

1. **Context Persistence**: Never lose progress between sessions
2. **Task Continuity**: Always know what's next
3. **History Tracking**: Complete audit trail of conversations
4. **Recovery**: Quick restoration after crashes or resets
5. **Collaboration**: Clear handoff points for team work

##  Best Practices

1. **Update Regularly**: Don't wait for memory events
2. **Use Checkboxes**: Visual progress tracking
3. **Write Summaries**: Use "Goodnight" for clean handoffs
4. **Review on Start**: Always check these files when beginning work
5. **Keep Current**: Archive old completed tasks to maintain clarity

##  Integration Points

- **Task Master AI**: Tasks synced with `.taskmaster/tasks/tasks.json`
- **Global CLAUDE.md**: System configuration at `/Users/J/.claude/CLAUDE.md`
- **Project CLAUDE.md**: Project-specific settings at `/Users/J/aiko/CLAUDE.md`
- **Memory Graph**: Persistent_Memory_System entity tracks state

##  Todo File Template Structure

When creating new Todo files, use this structure:

```markdown
# Current Working Tasks

## Active File: [File Name]
**Status**: In Progress
**Started**: [Date]

### Tasks:
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

### Notes:
- [Add relevant notes here]
```

---

**Project Owner**: Mr. Joshua  
**Last Updated**: 2025-07-11  
**System Version**: v3.1