## Operational Execution Framework

### Cognitive Worktrees
Isolated thinking contexts for focused problem-solving with parallel tool execution.

#### Worktree Activation Patterns
| Trigger | Worktree Type | Agents | Parallel Tools |
|---------|--------------|--------|----------------|
| `ULTRATHINK` | Complex Analysis | Analyst, Critic, Strategist | `zen.thinkdeep`, `TodoWrite`, `memory.search` |
| Debug Task | Investigation | Detective, Analyst | `zen.debug`, `ast-grep.find`, `git.diff` |
| Feature Dev | Development | Builder, Tester, Reviewer | `filesystem.*`, `git.*`, `TodoWrite` |
| Code Review | Review | Inspector, Advisor | `zen.codereview`, `github.*`, `precommit` |
| Planning | Strategic | Strategist, Validator | `zen.planner`, `TodoWrite`, `consensus` |

### Parallel Execution Rules

#### ALWAYS Parallelize:
```javascript
// Independent operations MUST run in parallel
await Promise.all([
  filesystem.read_multiple_files(files),
  git.status(),
  TodoWrite.getTasks(),
  memory.search("context"),
  brave-search.web_search(query)
]);
```

#### NEVER Parallelize:
- Sequential dependencies (create → update)
- Same file mutations
- Dependent task chains
- State modifications

### Multi-Agent Patterns

#### Investigation Pattern
```javascript
// Parallel evidence gathering
const evidence = await Promise.all([
  agent.detective.search(),    // Uses Task agent
  agent.analyst.examine(),      // Uses ast-grep
  agent.researcher.lookup()     // Uses web search
]);

// Sequential synthesis
const findings = await agent.synthesizer.combine(evidence);
```

#### Consensus Building
```javascript
// Critical decisions require multi-model validation
const decision = await zen.consensus({
  models: [
    {model: "anthropic/claude-opus-4", stance: "for"},
    {model: "openai/o3", stance: "against"},
    {model: "google/gemini-2.5-pro", stance: "neutral"}
  ],
  context: findings
});
```

### Operational Execution Flow

1. **Decompose** [ULTRATHINK]: Break into worktrees
2. **Parallelize**: Batch all independent operations  
3. **Orchestrate**: Deploy specialized agents
4. **Synthesize**: Combine findings via consensus
5. **Persist**: Save worktree state on switch

### Performance Mandates
- Parallel execution rate: >70%
- Batch size: 5-10 operations
- Context switch: <2 seconds
- Cache all read operations

### Worktree State Management
```javascript
// On context switch
const saveWorktree = async (current) => ({
  type: current.type,
  agents: current.agents.map(a => a.getState()),
  context: await memory.create_entities([{
    name: `worktree-${current.id}`,
    entityType: "WORKTREE_STATE",
    observations: [JSON.stringify(current)]
  }])
});
```