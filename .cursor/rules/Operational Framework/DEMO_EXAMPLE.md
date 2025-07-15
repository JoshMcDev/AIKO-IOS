# Operational Framework Demo

## Scenario: "Debug why the API is returning 500 errors"

### WITHOUT Operational Framework:
```
1. Check logs (wait)
2. Search for error patterns (wait)
3. Look at recent changes (wait)
4. Analyze code (wait)
5. Consult AI model (wait)
Total time: ~5 minutes sequential
```

### WITH Operational Framework:

```javascript
// [WORKTREE: Investigation-API-500]
// Agents: Detective, Analyst, Researcher

// Phase 1: Parallel Evidence Gathering (10 seconds)
const [logs, patterns, changes, traces] = await Promise.all([
  // Detective agent
  Task("search logs for 500 errors with stack traces"),
  
  // Analyst agent  
  ast-grep.find_code({
    pattern: "throw new Error($$$)",
    project_folder: "/api"
  }),
  
  // Researcher agent
  git.diff({ target: "main", context_lines: 10 }),
  
  // Memory agent
  memory.search("recent API changes decisions")
]);

// Phase 2: Multi-Model Analysis (15 seconds)
const analyses = await Promise.all([
  zen.debug({
    step: "Analyzing error patterns",
    findings: logs.stackTraces,
    model: "anthropic/claude-opus-4"
  }),
  
  zen.analyze({
    step: "Code flow analysis", 
    relevant_files: patterns.matches,
    model: "openai/o3"
  }),
  
  zen.thinkdeep({
    step: "Root cause hypothesis",
    evidence: {...logs, ...changes},
    model: "google/gemini-2.5-pro"
  })
]);

// Phase 3: Consensus Building (5 seconds)
const rootCause = await zen.consensus({
  models: analyses.map(a => ({ model: a.model, findings: a.findings })),
  decision_type: "root_cause_analysis"
});

// Total time: ~30 seconds (vs 5 minutes)
// Quality: 3 expert opinions vs 1
// Coverage: Comprehensive vs sequential
```

### Results Comparison:

| Metric | Traditional | Operational Framework |
|--------|-------------|--------------------|
| Time | 5 minutes | 30 seconds |
| Coverage | Sequential discovery | Parallel comprehensive |
| Validation | Single perspective | Multi-model consensus |
| Context | Might lose details | Worktree preserves all |
| Resumability | Start over | Can switch and resume |

### Worktree State After:
```json
{
  "id": "investigation-api-500",
  "findings": {
    "root_cause": "Database connection pool exhausted",
    "evidence": ["connection timeout logs", "pool size config"],
    "fix": "Increase pool size and add circuit breaker"
  },
  "agents": {
    "detective": { "searches_completed": 4 },
    "analyst": { "patterns_found": 2 },
    "researcher": { "models_consulted": 3 }
  },
  "next_action": "Switch to Development worktree for fix"
}
```