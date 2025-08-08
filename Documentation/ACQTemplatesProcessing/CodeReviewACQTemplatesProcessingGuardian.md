# Code Review Status: ACQ Templates Processing - Guardian

## Metadata
- Task: ACQTemplatesProcessing
- Phase: guardian
- Timestamp: 2025-08-08T20:00:00Z
- Previous Phase File: none
- Research Documentation: researchPerplexity_ACQTemplatesProcessing.md (and others available)
- Agent: tdd-guardian

## Review Criteria

### Critical Patterns to Check
Based on requirements analysis, these patterns are critical:
- [ ] Memory constraint violations (50MB strict limit enforcement)
- [ ] Actor isolation violations in Swift 6 strict concurrency mode
- [ ] Force unwrapping in memory-critical paths and search operations
- [ ] Error handling for memory pressure and processing failures
- [ ] Security validation for government template data handling
- [ ] Performance degradation in search latency (<10ms P50 target)
- [ ] Memory permit system bypass or improper usage
- [ ] Cross-actor data race conditions
- [ ] Embedding dimension inconsistency (384 vs 768)
- [ ] Unsafe memory operations in SIMD optimization code

### Code Quality Standards
- [ ] Methods under 20 lines (critical for memory management functions)
- [ ] Cyclomatic complexity < 10 (essential for search performance paths)
- [ ] No hardcoded secrets or credentials (government data security)
- [ ] Proper error propagation with meaningful error types
- [ ] Comprehensive input validation for template metadata
- [ ] Memory cleanup and resource deallocation verification
- [ ] Thread-safe actor boundaries with proper isolation
- [ ] Consistent async/await usage throughout pipeline

### SOLID Principles Focus Areas
Based on memory-constrained design complexity:
- [ ] SRP: MemoryConstrainedTemplateProcessor should handle only processing, not storage
- [ ] SRP: HybridSearchService should handle search coordination, not embedding generation
- [ ] OCP: Search strategy extensible (lexical-only, hybrid, vector-only fallbacks)
- [ ] OCP: Template categorization patterns extensible for new document types
- [ ] LSP: All TemplateProcessor implementations must respect memory constraints
- [ ] LSP: All SearchService implementations must meet latency requirements
- [ ] ISP: MemoryPermitSystem interface segregated from processing logic
- [ ] ISP: Search result interfaces separate from internal ranking algorithms
- [ ] DIP: Depend on abstractions for LFM2Service, ObjectBox, and storage layers
- [ ] DIP: Template processing should not depend on concrete storage implementations

### Security Review Points
From government template processing requirements:
- [ ] Input validation for: template file formats (PDF, DOCX, MD), metadata extraction, file size limits
- [ ] Authentication checks at: template access points, search query endpoints, administrative functions
- [ ] Authorization validation for: user roles accessing different template categories, administrative operations
- [ ] Data encryption for: stored embeddings, cached template metadata, temporary processing files
- [ ] PII detection and redaction for: template content processing, metadata extraction, search indexing
- [ ] Secure memory handling for: embedding vectors, template content, user query data
- [ ] Access logging for: template access patterns, search queries, processing operations

### Performance Considerations
Based on strict performance requirements:
- [ ] Async operations for: template file I/O, embedding generation, database operations, search queries
- [ ] Caching opportunities: frequently accessed templates, category filters, embedding vectors
- [ ] Memory management for: large template processing (256MB), concurrent search operations, background processing
- [ ] Database query optimization: ObjectBox vector similarity search, category filtering, metadata queries
- [ ] SIMD optimization validation: cosine similarity calculations, vector operations on ARM64

### Platform-Specific Patterns (iOS/macOS)
- [ ] Main thread operations validation for UI updates and progress reporting
- [ ] Memory retention cycle prevention in actor references and closures
- [ ] SwiftUI state management patterns for search results and processing progress
- [ ] Combine publisher/subscriber patterns for real-time progress updates
- [ ] File system access patterns with proper sandboxing and security scopes
- [ ] Background processing coordination with iOS app lifecycle

### Memory-Specific Patterns (Critical for 50MB Constraint)
- [ ] Memory permit acquisition before any large allocations
- [ ] Proper permit release in all code paths (including error paths)
- [ ] Memory pressure response and graceful degradation
- [ ] Streaming processing without full document loading
- [ ] Memory-mapped file usage for large embedding storage
- [ ] Garbage collection coordination and memory cleanup
- [ ] Peak memory monitoring and alerting mechanisms

### Search Performance Patterns (Critical for <10ms Latency)
- [ ] BM25 prefilter implementation efficiency (<2ms target)
- [ ] Vector reranking optimization with SIMD (<8ms target)
- [ ] Cache warming strategies for frequently accessed categories
- [ ] Query preprocessing and optimization before search execution
- [ ] Result pagination and lazy loading for large result sets
- [ ] Search result caching and invalidation strategies

## AST-Grep Pattern Configuration
Verify these patterns exist in .claude/review-patterns.yml:
- memory_constraint_violation (Critical) - Check for large allocations without permits
- force_unwrap (Critical) - Prevent crashes in production memory-critical code
- actor_isolation_violation (Critical) - Ensure Swift 6 concurrency compliance
- missing_error_handling (Critical) - Comprehensive error handling required
- hardcoded_secret (Critical) - Government data security requirement
- unsafe_memory_operation (Critical) - SIMD and memory-mapped operations
- unvalidated_input (Critical) - Template metadata and content validation
- long_method (Major) - Complexity management for performance-critical paths
- complex_conditional (Major) - Maintainability in search and processing logic
- memory_leak_potential (Major) - Actor references and closure capture patterns
- search_performance_violation (Major) - Latency requirement violations
- security_vulnerability (Major) - Government data handling compliance

## Metrics Baseline
- Target Method Length: < 20 lines (stricter for memory management)
- Target Complexity: < 10 (critical for performance paths)
- Target Test Coverage: > 90% (memory-critical), > 85% (overall)
- Memory Usage Target: < 50MB peak (strict enforcement)
- Search Latency Target: < 10ms P50, < 20ms P95
- Security Issues Tolerance: 0 (government data requirements)
- Force Unwrap Tolerance: 0 (production reliability)
- Critical Issue Tolerance: 0 (memory and performance constraints)

## Requirements-Specific Patterns
Based on ACQ Templates Processing analysis:

### Template Processing Patterns
- Memory-constrained processing with 2-4MB chunks
- Category detection accuracy >95% with pattern matching
- Streaming text extraction without full document loading
- Embedding dimension reduction (768→384) with semantic preservation
- Template metadata extraction and validation

### Hybrid Search Patterns
- BM25 lexical prefilter with 2ms latency target
- Exact cosine similarity reranking with SIMD optimization
- Sharded index management with LRU eviction
- Memory-mapped embedding storage and retrieval
- Cross-category search with relevance scoring

### Actor Concurrency Patterns
- MemoryConstrainedTemplateProcessor with strict isolation
- HybridSearchService @MainActor for UI coordination
- ShardedTemplateIndex with concurrent access safety
- MemoryPermitSystem with queue management and fairness
- Cross-actor data transfer with Sendable compliance

### Integration Patterns
- LFM2Service dimension reduction coordination
- ObjectBoxSemanticIndex namespace extension (templates + regulations)
- UnifiedSearchService cross-domain capabilities
- FormAutoPopulationService template-aware suggestions
- BackgroundRegulationProcessor coordination patterns

## Research-Based Quality Considerations
Based on `researchPerplexity_ACQTemplatesProcessing.md` and related research:

### Testing Strategy
- Memory profiling with Instruments for iOS-specific constraints
- Character-based text splitter validation for semantic boundaries
- Streaming architecture testing for large document processing
- Batch processing optimization for embedding generation efficiency
- Performance benchmarking with percentile analysis (P50, P95, P99)

### Quality Standards
- Swift-native patterns for performance and safety optimization
- Automated testing with XCTest for complex data processing workflows
- Memory and CPU efficiency for 256MB document processing
- Incremental processing techniques to avoid memory bloat
- Code review rigor for memory management and performance paths

### Security Focus
- Government template security handling with encryption-at-rest
- iOS file protection mechanisms for sensitive template data
- Secure document processing with PII detection and redaction
- Access control implementation for template retrieval operations
- Compliance audit trail generation for government data handling

### Performance Patterns
- Streaming directly to vector database avoiding intermediate files
- Efficient chunking strategies balancing size and semantic coherence
- Memory-mapped storage for large embedding datasets
- SIMD optimization for vector operations on Apple silicon
- Background processing coordination with iOS app lifecycle constraints

## Recommendations for Next Phase
Green Implementer should:
1. Focus on memory permit system implementation and validation first
2. Implement hybrid search with BM25 prefilter before vector reranking
3. Establish actor boundaries with proper Swift 6 isolation patterns
4. Create comprehensive mocking infrastructure for ObjectBox and LFM2Service
5. Implement streaming processing patterns before batch operations
6. Document memory usage patterns and permit acquisition strategies
7. Not fix performance issues during green phase - only document them
8. Create technical debt items for optimization opportunities
9. Reference this criteria file: codeReview_ACQTemplatesProcessing_guardian.md

## Handoff Checklist
- [x] Review criteria established based on memory-constrained architecture requirements
- [x] Pattern priorities set according to 50MB memory limit and 10ms search latency
- [x] Metrics baselines defined for strict performance and memory quality gates
- [x] Security focus areas identified for government template data protection
- [x] Performance considerations documented for hybrid search and processing
- [x] Platform-specific patterns included for iOS/macOS compatibility
- [x] Memory-specific patterns emphasized for constraint compliance
- [x] Research-based insights integrated from available documentation
- [x] Actor concurrency patterns specified for Swift 6 compliance
- [x] Integration patterns documented for GraphRAG infrastructure
- [x] Status file created and saved
- [x] Next phase agent: tdd-dev-executor (then tdd-green-implementer for review)