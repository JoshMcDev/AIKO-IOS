# Product Requirements Document: Build Regulation Processing Pipeline with Smart Chunking

## Document Metadata
- Task: Build Regulation Processing Pipeline with Smart Chunking
- Version: Draft v1.0
- Date: 2025-08-07
- Author: tdd-prd-architect
- Research Foundation: 4 comprehensive research documents analyzed
- Status: Draft for consensus review

## Executive Summary

The AIKO regulation processing pipeline is a critical component of the GraphRAG intelligence system that transforms raw HTML regulations into semantically meaningful chunks for vector database storage and AI-powered search. This system enables intelligent form auto-population, compliance checking, and regulatory guidance through advanced embedding technologies.

**Core Pipeline**: HTML → Text Extraction → Smart Chunking (512 tokens) → LFM2 Embeddings → ObjectBox Storage

**Key Innovation**: Research-validated approach combining AsyncChannel patterns, Core ML batch processing (2.6x performance gain), and semantic boundary preservation for optimal regulation comprehension.

## Background and Context

### Current State
- **Foundation Ready**: LFM2 Core ML model (149MB) operational and QA-validated
- **ObjectBox Vector Database**: Mock-first implementation with HNSW index configuration complete
- **Existing RegulationProcessor**: Basic HTML processing and chunking implemented
- **TypeScript Parser**: Production regulationParser.ts available for HTML processing patterns

### Business Problem
Government contractors need rapid access to relevant regulatory guidance during document creation. Manual regulation searching is time-consuming and error-prone, leading to compliance issues and delayed acquisitions. Current text-based search lacks semantic understanding of regulatory context and relationships.

### Opportunity
Create an intelligent pipeline that processes regulations once during onboarding, enabling instant semantic search and contextual recommendations during workflow execution. This transforms regulation compliance from reactive checking to proactive guidance.

## User Stories

### Primary Users: Government Contracting Professionals

**As a Contracting Officer**, I want the system to automatically process regulations during app setup so that I can search for relevant guidance using natural language queries without waiting for processing delays.

**As an Acquisition Specialist**, I want smart chunking to preserve regulatory hierarchy and context so that search results maintain legal accuracy and proper citation structure.

**As a Contract Specialist**, I want batch processing with progress tracking so that I can monitor regulation processing status and understand when the system is ready for use.

**As a Compliance Manager**, I want error handling and retry logic so that failed regulation processing doesn't block system functionality and problematic documents are identified for manual review.

**As a Project Manager**, I want processing to happen in background during onboarding so that users can continue other setup tasks while regulations are being processed.

### Secondary Users: System Administrators

**As a System Administrator**, I want memory-efficient processing so that the app doesn't consume excessive device resources during bulk regulation processing.

**As a Performance Monitor**, I want detailed processing metrics so that I can optimize pipeline performance and identify bottlenecks.

## Functional Requirements

### F1: Enhanced HTML Processing System
- **F1.1**: Integrate SwiftSoup for production-grade HTML parsing replacing basic regex patterns
- **F1.2**: Handle malformed HTML gracefully with error recovery mechanisms
- **F1.3**: Extract metadata (regulation number, section, title, last updated) from HTML structure
- **F1.4**: Preserve document hierarchy markers (sections, subsections, paragraphs)
- **F1.5**: Clean HTML entities and normalize whitespace while maintaining readability

### F2: Semantic Chunking Engine
- **F2.1**: Implement 512-token maximum chunks with semantic boundary preservation
- **F2.2**: Add 100-token overlap between chunks for context continuity
- **F2.3**: Detect and respect natural breakpoints (sentence endings, paragraph boundaries)
- **F2.4**: Preserve regulation structure markers within chunks
- **F2.5**: Use percentile-based similarity thresholds for optimal chunk boundaries

### F3: Batch Processing with Concurrency
- **F3.1**: Process exactly 10 chunks concurrently as specified in requirements
- **F3.2**: Implement TaskGroup for structured concurrency with error isolation
- **F3.3**: Use AsyncChannel for producer-consumer coordination between pipeline stages
- **F3.4**: Add Task.yield() every 100 operations for cooperative multitasking
- **F3.5**: Implement bounded memory buffers (512 chunks maximum) to prevent overflow

### F4: LFM2 Integration and Optimization
- **F4.1**: Leverage existing LFM2Service actor for embedding generation
- **F4.2**: Use Core ML batch prediction API for 2.6x performance improvement
- **F4.3**: Implement parallel Neural Engine instance utilization
- **F4.4**: Add embedding validation with dimension checks (768 dimensions)
- **F4.5**: Cache frequently accessed embeddings with LRU eviction

### F5: ObjectBox Vector Storage
- **F5.1**: Extend existing ObjectBox Semantic Index for regulation namespace
- **F5.2**: Configure HNSW index for efficient similarity search
- **F5.3**: Store rich metadata (source, category, confidence score, timestamp)
- **F5.4**: Implement batch insertion for optimal write performance
- **F5.5**: Add vector search with cosine similarity and metadata filtering

### F6: Progress Tracking and Status Reporting
- **F6.1**: Provide detailed progress updates ("Processing FAR 15.202... 847/1219")
- **F6.2**: Implement real-time progress callbacks for UI integration
- **F6.3**: Track processing statistics (chunks/second, memory usage, errors)
- **F6.4**: Estimate completion time based on processing velocity
- **F6.5**: Generate processing summary reports with quality metrics

### F7: Error Handling and Recovery
- **F7.1**: Implement comprehensive error types for each pipeline stage
- **F7.2**: Add retry logic with exponential backoff for transient failures
- **F7.3**: Gracefully handle individual document failures without stopping pipeline
- **F7.4**: Log detailed error information for debugging and monitoring
- **F7.5**: Provide partial success reporting when some documents fail

## Non-Functional Requirements

### Performance
- **P1**: Process 100+ documents per minute on iPhone 14 Pro
- **P2**: Memory usage below 500MB peak during batch processing
- **P3**: Embedding generation under 2 seconds per 512-token chunk
- **P4**: ObjectBox insertions under 100ms per batch
- **P5**: End-to-end pipeline latency under 30 seconds for typical regulation

### Security
- **S1**: All processing occurs on-device with no external data transmission
- **S2**: Encrypted storage for processed regulation embeddings
- **S3**: Secure deletion of temporary processing files
- **S4**: Privacy-preserving analytics with no PII storage
- **S5**: Audit trail for regulation processing activities

### Usability
- **U1**: Non-blocking UI during background processing
- **U2**: Clear progress indicators with meaningful status messages
- **U3**: Error messages provide actionable guidance
- **U4**: Processing can be paused and resumed
- **U5**: Accessibility support for progress announcements

### Reliability
- **R1**: 95% success rate for well-formed HTML documents
- **R2**: Graceful degradation with partial failures
- **R3**: Automatic recovery from memory pressure
- **R4**: Data consistency maintained during interruptions
- **R5**: Comprehensive logging for troubleshooting

### Scalability
- **SC1**: Support for 1000+ regulation documents
- **SC2**: Linear performance scaling with document count
- **SC3**: Memory usage independent of total document count
- **SC4**: Background processing without blocking other app functions
- **SC5**: Efficient incremental updates for changed regulations

## Acceptance Criteria

### Core Pipeline Functionality
1. **HTML Processing**: Successfully extracts text from 95% of government HTML regulation files
2. **Smart Chunking**: Creates semantically coherent 512-token chunks with preserved boundaries
3. **Embedding Generation**: Generates 768-dimension embeddings using LFM2 model
4. **Vector Storage**: Stores embeddings in ObjectBox with searchable metadata
5. **Batch Processing**: Processes 10 chunks concurrently with proper error isolation

### Performance Standards
1. **Throughput**: Processes minimum 100 documents per minute
2. **Memory Efficiency**: Peak memory usage stays below 500MB
3. **Latency**: Individual chunk processing completes within 2 seconds
4. **Concurrency**: Maintains responsive UI during background processing
5. **Resource Management**: Properly releases resources after processing

### Quality Assurance
1. **Semantic Coherence**: 90% of chunks maintain semantic meaning when isolated
2. **Metadata Accuracy**: Extracted metadata matches source document structure
3. **Error Handling**: Gracefully recovers from 95% of processing failures
4. **Data Integrity**: No data loss during processing interruptions
5. **Search Quality**: Enables accurate semantic search with >90% relevance

### Integration Requirements
1. **LFM2 Service**: Seamlessly integrates with existing LFM2Service actor
2. **ObjectBox Database**: Extends current ObjectBox Semantic Index structure
3. **Progress Reporting**: Provides real-time status updates to UI layer
4. **Error Reporting**: Integrates with app-wide error handling systems
5. **Settings Integration**: Respects user preferences for background processing

## Dependencies

### Internal Dependencies
- **LFM2Service**: Actor-based service for embedding generation (COMPLETED)
- **ObjectBoxSemanticIndex**: Vector database with HNSW configuration (COMPLETED)
- **RegulationProcessor**: Basic HTML processing foundation (EXISTS)
- **GraphRAGTypes**: Core type definitions and models (COMPLETED)
- **AppCore Models**: Regulation data models and error types (EXISTS)

### External Dependencies
- **SwiftSoup**: HTML parsing library for production-grade text extraction
- **Swift Async Algorithms**: AsyncChannel and async sequence processing
- **Core ML**: Batch prediction API for LFM2 model execution
- **ObjectBox Swift**: Vector database with HNSW indexing support
- **Foundation**: File system access and data processing utilities

### Hardware Dependencies
- **Neural Engine**: Required for optimal LFM2 embedding performance
- **Storage**: Minimum 2GB available space for regulation database
- **Memory**: 8GB RAM recommended for optimal batch processing
- **CPU**: A14 Bionic or newer for acceptable performance

## Constraints

### Technical Constraints
- **Swift 6 Compliance**: All code must support strict concurrency checking
- **iOS 17.0+ Compatibility**: Required for async/await and actor features
- **On-Device Processing**: No cloud services or external API dependencies
- **Memory Limitations**: Must operate within iOS app memory constraints
- **Battery Efficiency**: Processing should not significantly impact battery life

### Business Constraints
- **Regulation Format**: Limited to HTML format from government sources
- **Processing Time**: Initial setup must complete within reasonable timeframe
- **User Experience**: Cannot block critical app functionality during processing
- **Storage Efficiency**: Vector database size must remain manageable
- **Maintenance**: Solution must be maintainable by existing development team

### Regulatory Constraints
- **Government Data**: Must handle CUI (Controlled Unclassified Information) appropriately
- **Privacy Requirements**: All data must remain on user's device
- **Compliance Standards**: Processing must maintain regulatory accuracy
- **Security Protocols**: Implementation must follow government security guidelines
- **Data Retention**: Support user-controlled data deletion

## Risk Assessment

### High Risk Items
1. **Memory Exhaustion**: Large document batches could exceed device memory limits
   - *Mitigation*: Implement bounded buffers and streaming processing
2. **Embedding Quality**: Poor chunking could degrade search accuracy
   - *Mitigation*: Extensive testing with real regulation documents
3. **Performance Degradation**: Batch processing might impact app responsiveness
   - *Mitigation*: Use cooperative multitasking with Task.yield()

### Medium Risk Items
1. **HTML Parsing Failures**: Malformed government HTML could break processing
   - *Mitigation*: Robust error handling and fallback processing
2. **ObjectBox Integration**: Vector operations might have unexpected performance characteristics
   - *Mitigation*: Performance testing and optimization tuning
3. **Concurrency Bugs**: Actor coordination might introduce race conditions
   - *Mitigation*: Comprehensive testing and actor isolation validation

### Low Risk Items
1. **SwiftSoup Integration**: Well-established library with stable API
2. **LFM2 Model**: Already validated and production-ready
3. **Core ML Batch Processing**: Apple-provided API with documented behavior

## Success Metrics

### Primary Metrics
1. **Processing Throughput**: >100 documents/minute sustained performance
2. **Search Quality**: >90% semantic relevance for regulation queries
3. **System Reliability**: <5% failure rate for regulation processing
4. **User Satisfaction**: Positive feedback on regulation search experience
5. **Memory Efficiency**: Peak usage <500MB during bulk processing

### Secondary Metrics
1. **Processing Speed**: <30 seconds end-to-end for typical regulation
2. **Error Recovery**: >95% success rate for retry operations
3. **Storage Efficiency**: <50MB average per 1000 regulation chunks
4. **Battery Impact**: <5% additional drain during background processing
5. **Performance Consistency**: <10% variation in processing times

### Quality Metrics
1. **Chunk Coherence**: 90% of chunks semantically complete when isolated
2. **Metadata Accuracy**: 95% correct extraction of regulation identifiers
3. **Search Precision**: 85% relevant results in top 10 search results
4. **Processing Completeness**: 98% of regulation content successfully processed
5. **Error Transparency**: 100% of errors provide actionable user guidance

## Implementation Phases

### Phase 1: Foundation Enhancement (Week 1)
1. Integrate SwiftSoup for robust HTML processing
2. Implement semantic chunking with boundary detection
3. Create AsyncChannel-based pipeline coordination
4. Add comprehensive error handling and logging
5. Implement basic progress tracking

### Phase 2: Performance Optimization (Week 2)
1. Add batch processing with TaskGroup concurrency
2. Implement Core ML async prediction API
3. Add memory management with bounded buffers
4. Integrate ObjectBox batch insertion
5. Optimize embedding generation pipeline

### Phase 3: Production Hardening (Week 3)
1. Add comprehensive test coverage
2. Implement monitoring and metrics collection
3. Add cancellation and pause/resume functionality
4. Performance tuning and optimization
5. Documentation and integration testing

## Technical Architecture Notes

### AsyncChannel Pattern
Based on Swift Async Algorithms research, the pipeline uses AsyncChannel for producer-consumer coordination between HTML processing, chunking, embedding generation, and storage stages.

### Batch Processing Strategy  
Core ML research validates 2.6x performance improvement with batch processing. Implementation uses TaskGroup with exactly 10 concurrent chunks as specified.

### Memory Management
Implements bounded buffer pattern with 512-chunk maximum to prevent memory exhaustion during large document processing.

### Error Propagation
Uses AsyncThrowingSequence pattern for transparent error handling across pipeline stages with retry logic for transient failures.