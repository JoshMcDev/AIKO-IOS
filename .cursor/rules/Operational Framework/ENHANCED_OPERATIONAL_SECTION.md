## Operational Execution Framework

### Cognitive Worktrees with Multi-Agent Orchestration
Isolated thinking contexts with coordinated agents sharing memory through file-based architecture.

#### Agent Workspace Structure
```
.agent-workspace/
├── orchestrator/          # Central coordination
├── memory/               # Shared state & knowledge
├── messages/             # Agent communication
├── workspaces/           # Active worktree contexts
└── checkpoints/          # Recovery snapshots
```

#### Worktree Activation with Agent Deployment
| Trigger | Worktree | Agents | Shared Memory | Communication |
|---------|----------|--------|---------------|---------------|
| `ULTRATHINK` | Complex Analysis | Analyst, Critic, Strategist | `shared-context.json` | Event broadcast |
| Debug Task | Investigation | Detective, Analyst | `findings.md`, `patterns/` | Message queue |
| Feature Dev | Development | Builder, Tester, Reviewer | `implementation/`, `tests/` | Inbox/outbox |
| Code Review | Review | Inspector, Advisor | `review-notes.md`, `issues/` | Consensus protocol |

### Multi-Agent Communication Protocol

#### Message Flow
```javascript
// All agents communicate through structured messages
const message = {
  from: 'detective',
  to: 'analyst',  // or 'broadcast'
  type: 'finding',
  priority: 'urgent',
  payload: { evidence: [...] },
  requiresResponse: true
};

// Orchestrator routes messages through file system
await filesystem.write_file(
  `.agent-workspace/messages/inbox/${to}/${messageId}.json`,
  JSON.stringify(message)
);
```

#### Shared Memory Access
```javascript
// Thread-safe memory updates with file locking
await memory.update('shared-context.json', (current) => ({
  ...current,
  detective: {
    findings: newFindings,
    confidence: 0.85,
    lastUpdate: timestamp
  }
}));

// Broadcast critical events
await memory.broadcast('critical_finding', {
  severity: 'high',
  details: findings
});
```

### Parallel Execution with Coordination

#### Orchestrated Parallel Pattern
```javascript
// Orchestrator manages parallel agent operations
async function investigateIssue(issue) {
  // Deploy agents
  const agents = await orchestrator.deployAgents([
    'detective', 'analyst', 'researcher'
  ]);

  // Parallel investigation with shared memory
  const investigations = await Promise.all([
    agents.detective.investigate({
      write: '.agent-workspace/workspaces/current/findings.md'
    }),
    agents.analyst.analyze({
      read: '.agent-workspace/memory/patterns/*.json'
    }),
    agents.researcher.search({
      cache: '.agent-workspace/memory/knowledge-cache/'
    })
  ]);

  // Agents automatically update shared context
  // Orchestrator monitors progress via event stream
  return await orchestrator.synthesizeFindings();
}
```

#### Event-Driven Coordination
```javascript
// Agents emit events to coordinate
detective.on('critical_finding', async (finding) => {
  // Auto-saved to: .agent-workspace/messages/events.jsonl
  await analyst.priorityAnalyze(finding);
  await builder.prepareFix(finding);
});

// Orchestrator monitors all events
orchestrator.on('consensus_needed', async (issue) => {
  const decision = await buildConsensus(issue, ['analyst', 'critic', 'strategist']);
  // Decision logged to: .agent-workspace/memory/decision-log.md
});
```

### Agent Role Definitions with Memory Access

| Agent | Responsibilities | Memory Writes | Memory Reads | Messages |
|-------|-----------------|---------------|--------------|----------|
| **Detective** | Find problems | `findings.md`, `patterns/` | `known-issues/` | Broadcasts findings |
| **Builder** | Create solutions | `implementations/`, `solutions/` | `constraints.json` | Requests validation |
| **Analyst** | Deep analysis | `analysis/`, `decision-log.md` | All shared memory | Consensus requests |
| **Strategist** | Planning | `plans/`, `roadmap.md` | Historical decisions | Broadcast plans |
| **Tester** | Validation | `test-results/`, `coverage/` | Implementation specs | Test outcomes |
| **Critic** | Challenge | `reviews/`, `concerns.md` | All proposals | Objections/approvals |

### Consensus Building with Shared Memory
```javascript
// Multi-agent consensus through file coordination
async function buildConsensus(issue) {
  const consensusDir = `.agent-workspace/consensus/${Date.now()}`;
  
  // Each agent writes opinion
  await Promise.all([
    analyst.writeOpinion(`${consensusDir}/analyst-opinion.md`),
    critic.writeObjections(`${consensusDir}/critic-concerns.md`),
    strategist.writePlan(`${consensusDir}/strategist-proposal.md`)
  ]);

  // Orchestrator synthesizes
  const consensus = await orchestrator.synthesize(consensusDir);
  
  // Log decision with full context
  await filesystem.write_file(
    '.agent-workspace/memory/decision-log.md',
    formatDecision(consensus),
    { append: true }
  );
}
```

### Checkpoint & Recovery
```javascript
// Automatic checkpointing of agent states
orchestrator.on('worktree_switch', async (from, to) => {
  // Save complete state
  await checkpointManager.save({
    worktree: from,
    agents: await getAllAgentStates(),
    memory: '.agent-workspace/memory/**',
    messages: '.agent-workspace/messages/inbox/**'
  });
  
  // Switch context
  await orchestrator.switchWorktree(to);
});

// Recovery on crash/resume
const recovered = await checkpointManager.restore(lastCheckpoint);
```

### Performance Mandates
- **Parallel Rate**: >70% operations concurrent
- **Memory Lock Time**: <100ms per update
- **Message Latency**: <50ms delivery
- **Checkpoint Size**: <10MB compressed
- **Event Stream**: Append-only, no blocking

### Operational Metrics
```javascript
// Real-time metrics available at:
// .agent-workspace/orchestrator/metrics.json
{
  "activeAgents": 4,
  "messagesPerSecond": 12.5,
  "memoryUpdatesPerMinute": 45,
  "consensusDecisions": 3,
  "parallelOperations": "78%"
}
```