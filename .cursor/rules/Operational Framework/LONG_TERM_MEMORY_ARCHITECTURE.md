# Long-Term Memory Architecture for Multi-Agent System

## Memory Block Framework

### Base Memory Block Interface
```typescript
interface MemoryBlock {
  id: string;
  type: MemoryType;
  capacity: MemoryCapacity;
  
  // Core operations
  store(content: any, metadata?: Metadata): Promise<string>;
  retrieve(query: Query): Promise<MemoryResult[]>;
  update(id: string, content: any): Promise<void>;
  delete(id: string): Promise<void>;
  
  // Context operations
  getRelevantContext(currentState: any): Promise<Context>;
  summarize(): Promise<Summary>;
  
  // Maintenance
  compress(): Promise<void>;
  archive(olderThan: Date): Promise<void>;
  getMetrics(): Promise<MemoryMetrics>;
}

interface MemoryCapacity {
  maxItems?: number;
  maxSizeBytes?: number;
  ttl?: number; // Time to live in seconds
  compressionThreshold?: number;
}
```

## Memory Block Implementations

### 1. VectorMemoryBlock
Stores conversation chunks as embeddings for semantic retrieval.

```javascript
class VectorMemoryBlock extends BaseMemoryBlock {
  constructor(config) {
    super(config);
    this.vectorStore = new VectorStore({
      path: `.agent-workspace/memory/vectors/${this.id}/`,
      dimension: 1536, // OpenAI embedding dimension
      similarity: 'cosine'
    });
  }

  async store(messages, metadata) {
    // Generate embedding for message batch
    const embedding = await this.generateEmbedding(messages);
    
    // Store with metadata
    const entry = {
      id: crypto.randomUUID(),
      timestamp: Date.now(),
      messages,
      embedding,
      metadata: {
        ...metadata,
        tokenCount: this.countTokens(messages),
        participants: this.extractParticipants(messages),
        topics: await this.extractTopics(messages)
      }
    };

    // Save to vector store
    await this.vectorStore.insert(entry);
    
    // Update index
    await this.updateIndex(entry);
    
    return entry.id;
  }

  async retrieve(query) {
    // Generate query embedding
    const queryEmbedding = await this.generateEmbedding(query.text);
    
    // Semantic search
    const results = await this.vectorStore.search({
      vector: queryEmbedding,
      limit: query.limit || 10,
      threshold: query.threshold || 0.7
    });

    // Rerank by recency if needed
    if (query.preferRecent) {
      results.sort((a, b) => b.timestamp - a.timestamp);
    }

    return results.map(r => ({
      content: r.messages,
      relevance: r.similarity,
      metadata: r.metadata
    }));
  }

  async getRelevantContext(currentState) {
    // Smart context selection based on current conversation
    const recentTopics = await this.extractTopics(currentState.recentMessages);
    
    // Multi-query retrieval
    const contexts = await Promise.all([
      this.retrieve({ text: recentTopics.join(' '), limit: 5 }),
      this.retrieve({ text: currentState.currentIntent, limit: 3 }),
      this.retrieveSimilarConversations(currentState.pattern)
    ]);

    // Merge and deduplicate
    return this.mergeContexts(contexts);
  }
}
```

### 2. FactExtractionMemoryBlock
Extracts and stores facts from conversations.

```javascript
class FactExtractionMemoryBlock extends BaseMemoryBlock {
  constructor(config) {
    super(config);
    this.factsPath = `.agent-workspace/memory/facts/${this.id}/`;
    this.factGraph = new FactGraph(this.factsPath);
  }

  async store(messages, metadata) {
    // Extract facts using LLM
    const facts = await this.extractFacts(messages);
    
    // Deduplicate against existing facts
    const newFacts = await this.deduplicateFacts(facts);
    
    // Store facts with relationships
    for (const fact of newFacts) {
      const factEntry = {
        id: crypto.randomUUID(),
        fact: fact.statement,
        confidence: fact.confidence,
        source: {
          messageIds: messages.map(m => m.id),
          timestamp: Date.now(),
          extractor: 'fact-extraction-v2'
        },
        entities: fact.entities,
        relations: fact.relations,
        category: fact.category
      };

      // Store in fact graph
      await this.factGraph.addFact(factEntry);
      
      // Update entity index
      await this.updateEntityIndex(factEntry);
    }

    // Update fact summary
    await this.updateFactSummary();
    
    return newFacts;
  }

  async retrieve(query) {
    // Multi-strategy retrieval
    const strategies = [
      this.retrieveByEntity(query.entities),
      this.retrieveByPattern(query.pattern),
      this.retrieveByTimeRange(query.timeRange),
      this.retrieveByConfidence(query.minConfidence)
    ];

    const results = await Promise.all(strategies);
    
    // Merge and rank
    return this.rankFacts(this.mergeFacts(results), query);
  }

  async extractFacts(messages) {
    const prompt = `Extract factual statements from this conversation.
For each fact, provide:
- statement: The fact in clear, concise form
- confidence: 0-1 score
- entities: Named entities involved
- relations: Relationships between entities
- category: Type of fact (personal, technical, temporal, etc)

Conversation:
${JSON.stringify(messages)}`;

    const extraction = await this.llm.extract(prompt);
    return extraction.facts;
  }

  async getRelevantContext(currentState) {
    // Get facts relevant to current discussion
    const relevantFacts = await this.retrieve({
      entities: currentState.activeEntities,
      timeRange: 'recent',
      minConfidence: 0.7
    });

    // Format as context
    return {
      facts: relevantFacts,
      summary: await this.generateFactSummary(relevantFacts),
      confidence: this.calculateAggregateConfidence(relevantFacts)
    };
  }
}
```

### 3. StaticMemoryBlock
Stores persistent, unchanging information.

```javascript
class StaticMemoryBlock extends BaseMemoryBlock {
  constructor(config) {
    super(config);
    this.staticPath = `.agent-workspace/memory/static/${this.id}/`;
    this.cache = new Map();
  }

  async store(content, metadata) {
    const entry = {
      id: metadata.key || crypto.randomUUID(),
      content,
      metadata: {
        ...metadata,
        immutable: true,
        created: Date.now(),
        version: 1
      }
    };

    // Write to file
    await filesystem.write_file(
      `${this.staticPath}/${entry.id}.json`,
      JSON.stringify(entry, null, 2)
    );

    // Update cache
    this.cache.set(entry.id, entry);

    // Index for search
    await this.updateSearchIndex(entry);

    return entry.id;
  }

  async retrieve(query) {
    if (query.id) {
      // Direct retrieval
      return [await this.getById(query.id)];
    }

    // Search-based retrieval
    const results = await this.searchIndex(query);
    
    return results.map(r => ({
      content: r.content,
      metadata: r.metadata,
      relevance: r.score
    }));
  }

  async getRelevantContext(currentState) {
    // Get all relevant static info
    const relevant = await this.retrieve({
      tags: currentState.requiredInfo,
      categories: currentState.contextCategories
    });

    return {
      staticInfo: relevant,
      formatted: this.formatForContext(relevant)
    };
  }
}
```

### 4. ConversationGraphMemoryBlock
Stores conversation flow as a graph structure.

```javascript
class ConversationGraphMemoryBlock extends BaseMemoryBlock {
  constructor(config) {
    super(config);
    this.graphPath = `.agent-workspace/memory/graphs/${this.id}/`;
    this.graph = new ConversationGraph(this.graphPath);
  }

  async store(messages, metadata) {
    // Create conversation nodes
    const nodes = messages.map(msg => ({
      id: msg.id,
      type: 'message',
      content: msg.content,
      speaker: msg.speaker,
      timestamp: msg.timestamp,
      intent: msg.intent,
      sentiment: msg.sentiment
    }));

    // Create edges (conversation flow)
    const edges = [];
    for (let i = 0; i < nodes.length - 1; i++) {
      edges.push({
        from: nodes[i].id,
        to: nodes[i + 1].id,
        type: 'follows',
        weight: 1
      });
    }

    // Add topic edges
    const topics = await this.extractTopics(messages);
    for (const topic of topics) {
      edges.push({
        from: 'topic:' + topic,
        to: nodes[0].id,
        type: 'discusses',
        weight: topic.relevance
      });
    }

    // Store in graph
    await this.graph.addNodes(nodes);
    await this.graph.addEdges(edges);

    // Update patterns
    await this.updateConversationPatterns();

    return nodes.map(n => n.id);
  }

  async retrieve(query) {
    if (query.pattern) {
      // Find similar conversation patterns
      return await this.graph.findPatterns(query.pattern);
    }

    if (query.path) {
      // Get conversation paths
      return await this.graph.getConversationPaths(query.path);
    }

    // General graph search
    return await this.graph.search(query);
  }

  async getRelevantContext(currentState) {
    // Find similar conversation flows
    const similarFlows = await this.graph.findSimilarFlows(
      currentState.conversationPath
    );

    // Get successful outcomes from similar flows
    const outcomes = await this.graph.getOutcomes(similarFlows);

    return {
      similarConversations: similarFlows,
      successfulPatterns: outcomes.filter(o => o.success),
      suggestedNextSteps: this.predictNextSteps(currentState, similarFlows)
    };
  }
}
```

## Memory Composition System

### MemoryOrchestrator
Combines multiple memory blocks for comprehensive context.

```javascript
class MemoryOrchestrator {
  constructor() {
    this.memoryBlocks = new Map();
    this.config = this.loadConfig();
  }

  registerMemoryBlock(block) {
    this.memoryBlocks.set(block.id, block);
    
    // Set up inter-block communication
    block.on('fact_extracted', fact => 
      this.propagateFact(fact, block.id)
    );
  }

  async storeMemory(content, options = {}) {
    const tasks = [];

    // Store in vector memory for semantic search
    if (options.vector !== false) {
      tasks.push(
        this.memoryBlocks.get('vector').store(content)
      );
    }

    // Extract facts if knowledge extraction enabled
    if (options.extractFacts) {
      tasks.push(
        this.memoryBlocks.get('facts').store(content)
      );
    }

    // Update conversation graph
    if (options.updateGraph) {
      tasks.push(
        this.memoryBlocks.get('graph').store(content)
      );
    }

    await Promise.all(tasks);
  }

  async getContext(currentState, requirements) {
    // Parallel retrieval from all memory blocks
    const contexts = await Promise.all([
      this.getVectorContext(currentState, requirements.vector),
      this.getFactContext(currentState, requirements.facts),
      this.getStaticContext(currentState, requirements.static),
      this.getGraphContext(currentState, requirements.graph)
    ]);

    // Merge contexts with priority
    return this.mergeContexts(contexts, requirements.priority);
  }

  async mergeContexts(contexts, priority) {
    const merged = {
      messages: [],
      facts: [],
      static: [],
      patterns: [],
      metadata: {}
    };

    // Apply priority weights
    const weighted = contexts.map((ctx, idx) => ({
      ...ctx,
      weight: priority[idx] || 1
    }));

    // Smart merging with deduplication
    for (const ctx of weighted) {
      if (ctx.messages) {
        merged.messages.push(...this.weightedSelect(
          ctx.messages, 
          ctx.weight
        ));
      }
      // ... merge other types
    }

    // Compress if needed
    if (this.exceedsLimit(merged)) {
      return this.compressContext(merged);
    }

    return merged;
  }
}
```

## Usage Example

```javascript
// Initialize memory system
const memory = new MemoryOrchestrator();

// Register memory blocks
memory.registerMemoryBlock(new VectorMemoryBlock({
  id: 'conversation-vectors',
  capacity: { maxItems: 10000 }
}));

memory.registerMemoryBlock(new FactExtractionMemoryBlock({
  id: 'extracted-facts',
  llm: factExtractionModel
}));

memory.registerMemoryBlock(new StaticMemoryBlock({
  id: 'user-preferences'
}));

memory.registerMemoryBlock(new ConversationGraphMemoryBlock({
  id: 'conversation-flow'
}));

// During conversation
async function processMessage(message, conversationState) {
  // Store in appropriate memory blocks
  await memory.storeMemory([message], {
    vector: true,
    extractFacts: true,
    updateGraph: true
  });

  // Get relevant context for response
  const context = await memory.getContext(conversationState, {
    vector: { limit: 5, threshold: 0.7 },
    facts: { confidence: 0.8, recency: 'week' },
    static: { categories: ['preferences', 'rules'] },
    graph: { pattern: 'similar_intent' },
    priority: [0.3, 0.3, 0.2, 0.2] // Weights
  });

  // Use context in response generation
  return generateResponse(message, context);
}
```

## Memory Block Configuration

```yaml
# .agent-workspace/memory/config.yaml
memory_blocks:
  vector:
    type: VectorMemoryBlock
    config:
      embedding_model: "text-embedding-ada-002"
      chunk_size: 512
      overlap: 50
      retention: "90d"
      
  facts:
    type: FactExtractionMemoryBlock
    config:
      extraction_model: "gpt-4"
      confidence_threshold: 0.7
      deduplication: true
      categories:
        - personal
        - technical
        - preferences
        - temporal
        
  static:
    type: StaticMemoryBlock
    config:
      indexes:
        - key
        - category
        - tags
      searchable: true
      
  graph:
    type: ConversationGraphMemoryBlock
    config:
      max_depth: 10
      pattern_detection: true
      outcome_tracking: true

orchestrator:
  default_priority: [0.4, 0.3, 0.1, 0.2]
  context_limit: 4000  # tokens
  compression: "smart"  # or "aggressive"
```

This architecture provides flexible, extensible long-term memory that agents can use in any combination to maintain context across conversations.