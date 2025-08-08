# Product Requirements Document: Build Regulation Processing Pipeline with Smart Chunking

## Document Metadata
- Task: Build Regulation Processing Pipeline with Smart Chunking
- Version: Enhanced v1.0
- Date: 2025-08-07
- Author: tdd-prd-architect
- Consensus Method: zen:consensus synthesis applied
- Research Foundation: 4 comprehensive research documents analyzed
- Consensus Confidence: High (2 models consulted with detailed feedback)

## Consensus Enhancement Summary

Based on multi-model consensus analysis, this PRD has been significantly enhanced to address critical gaps identified by expert technical review:

**Major Improvements Applied:**
- **Replaced fixed 512-token chunking with structure-aware hierarchical chunking** to preserve regulatory context
- **Added comprehensive operational requirements** including regulation versioning and cleanup procedures
- **Enhanced security specifications** with key management and secure wipe policies
- **Expanded edge case coverage** for malformed HTML, power loss recovery, and regulatory amendments
- **Defined objective success metrics** with formal evaluation protocols and golden datasets
- **Clarified hardware requirements and memory optimization strategies**

## Executive Summary

The AIKO regulation processing pipeline transforms raw HTML regulations into semantically meaningful, hierarchy-preserving chunks for vector database storage and AI-powered search. This system enables intelligent form auto-population, compliance checking, and regulatory guidance through research-validated embedding technologies and architectural patterns.

**Enhanced Core Pipeline**: HTML → SwiftSoup Processing → Structure-Aware Chunking → LFM2 Batch Embeddings → ObjectBox HNSW Storage

**Key Innovation**: Multi-model consensus-validated approach combining AsyncChannel coordination, Core ML batch processing (2.6x performance gain), hierarchical boundary preservation, and robust operational procedures for production deployment.

## Background and Context

### Current State
- **Foundation Ready**: LFM2 Core ML model (149MB) operational and QA-validated
- **ObjectBox Vector Database**: Mock-first implementation with HNSW index configuration complete  
- **Existing RegulationProcessor**: Basic HTML processing and chunking implemented
- **TypeScript Parser**: Production regulationParser.ts available for HTML processing patterns

### Business Problem
Government contractors need rapid access to relevant regulatory guidance during document creation. Manual regulation searching is time-consuming and error-prone, leading to compliance issues and delayed acquisitions. Current text-based search lacks semantic understanding of regulatory context and hierarchical relationships critical for legal accuracy.

### Opportunity
Create an intelligent pipeline that processes regulations once during onboarding, enabling instant semantic search and contextual recommendations during workflow execution. This transforms regulation compliance from reactive checking to proactive guidance while maintaining legal accuracy through structure preservation.

## User Stories

### Primary Users: Government Contracting Professionals

**As a Contracting Officer**, I want the system to automatically process regulations during app setup so that I can search for relevant guidance using natural language queries without waiting for processing delays.

**As an Acquisition Specialist**, I want hierarchical structure preservation in chunks so that search results maintain regulatory context, proper citation structure, and legal accuracy with parent-child relationships intact.

**Enhanced through consensus**: *As an Acquisition Specialist*, I want incremental search availability during batch processing so that processed documents become searchable before the entire batch completes.

**As a Contract Specialist**, I want batch processing with detailed progress tracking including time estimates and pause/resume capability so that I can manage processing schedules and handle interruptions gracefully.

**As a Compliance Manager**, I want comprehensive error handling with partial retry and detailed logging so that failed regulation processing doesn't block system functionality and problematic documents are identified with actionable resolution steps.

**As a Project Manager**, I want memory-efficient background processing with automatic resource management so that the app remains responsive and doesn't impact other system operations.

### Enhanced through consensus: Secondary Users

**As a System Administrator**, I want regulation versioning and update detection so that I can manage regulatory amendments and ensure users access current information.

**As a Security Officer**, I want secure key management and cryptographic deletion so that sensitive regulation data is properly protected throughout its lifecycle.

**As a Performance Monitor**, I want comprehensive observability with logging and alerting so that I can proactively identify and resolve performance issues.

## Functional Requirements

### F1: Enhanced HTML Processing System
- **F1.1**: Integrate SwiftSoup for production-grade HTML parsing replacing basic regex patterns
- **F1.2**: Handle malformed HTML, framesets, and embedded PDFs gracefully with error recovery mechanisms
- **F1.3**: Extract comprehensive metadata (regulation number, section, title, last updated, version) from HTML structure
- **F1.4**: Preserve document hierarchy markers (sections, subsections, paragraphs, lists) with parent-child relationships
- **F1.5**: Clean HTML entities and normalize whitespace while maintaining structural readability
- **Enhanced through consensus F1.6**: Implement HTML schema validation with automated fallback processing for parsing failures

### F2: Structure-Aware Hierarchical Chunking Engine (Enhanced through consensus)
- **F2.1**: Implement structure-aware chunking using HTML elements (h1, h2, h3, p, li) to preserve regulatory hierarchy
- **F2.2**: Maintain parent-child relationships with context preservation (95% of chunks must contain their immediate parent heading)
- **F2.3**: Apply semantic boundary detection within structural constraints for optimal chunk boundaries
- **F2.4**: Include hierarchical metadata in chunks (section path, depth level, parent context)
- **F2.5**: Handle edge cases including extremely long paragraphs (>4k tokens) with intelligent subdivision
- **Enhanced through consensus F2.6**: Implement deduplication strategy for duplicate regulation sections across documents

### F3: Advanced Batch Processing with Concurrency Management
- **F3.1**: Process exactly 10 chunks concurrently as specified with proper resource isolation
- **F3.2**: Implement TaskGroup for structured concurrency with individual error handling per chunk
- **F3.3**: Use AsyncChannel for producer-consumer coordination between pipeline stages
- **F3.4**: Add cooperative multitasking with Task.yield() every 100 operations
- **F3.5**: Implement bounded memory buffers with dynamic sizing based on available system memory
- **Enhanced through consensus F3.6**: Add fallback serial embedding path for GPU/Neural Engine contention scenarios

### F4: Optimized LFM2 Integration and Memory Management (Enhanced through consensus)
- **F4.1**: Leverage existing LFM2Service actor with validated performance benchmarking
- **F4.2**: Use Core ML batch prediction API with confirmed 2.6x performance improvement
- **F4.3**: Implement model quantization strategies to fit within 500MB memory constraints
- **F4.4**: Add embedding validation with dimension checks (768 dimensions) and quality metrics
- **F4.5**: Implement intelligent caching with LRU eviction and memory pressure monitoring
- **Enhanced through consensus F4.6**: Add model warm-up procedures and GPU/Neural Engine availability detection

### F5: ObjectBox Vector Storage with Operational Management
- **F5.1**: Extend existing ObjectBox Semantic Index for regulation namespace with version tracking
- **F5.2**: Configure HNSW index for efficient similarity search with performance tuning
- **F5.3**: Store comprehensive metadata (source, category, confidence score, timestamp, version, hierarchy path)
- **F5.4**: Implement batch insertion with transactional integrity and rollback capability
- **F5.5**: Add vector search with cosine similarity, metadata filtering, and incremental index updates
- **Enhanced through consensus F5.6**: Implement secure data deletion and cleanup procedures for replaced regulations

### F6: Comprehensive Progress Tracking and User Experience
- **F6.1**: Provide detailed progress updates with meaningful status messages ("Processing FAR 15.202... 847/1219")
- **F6.2**: Implement real-time progress callbacks with completion time estimates
- **F6.3**: Track comprehensive processing statistics (chunks/second, memory usage, error rates)
- **F6.4**: Add pause/resume functionality with checkpoint persistence
- **F6.5**: Generate processing summary reports with quality metrics and recommendations
- **Enhanced through consensus F6.6**: Implement incremental search availability with streaming index updates

### F7: Enhanced Error Handling and Recovery (Enhanced through consensus)
- **F7.1**: Implement categorized error types (network, parsing, embedding, storage) with specific recovery strategies
- **F7.2**: Add exponential backoff retry logic with partial batch recovery
- **F7.3**: Provide detailed error logging with actionable resolution guidance
- **F7.4**: Implement checkpoint-based recovery for power loss and interruption scenarios
- **F7.5**: Add comprehensive partial success reporting with per-document status tracking

### Enhanced through consensus F8: Operational and Maintenance Requirements
- **F8.1**: Implement regulation version detection and automatic update processing
- **F8.2**: Add comprehensive logging and observability with configurable log levels
- **F8.3**: Create data export/import capabilities for backup and migration
- **F8.4**: Implement rollback procedures for failed updates or corrupted data
- **F8.5**: Add system health monitoring with automated alerting capabilities

## Non-Functional Requirements

### Performance (Enhanced through consensus)
- **P1**: Process 100+ documents per minute on specified hardware reference (iPhone 14 Pro, A16 Bionic)
- **P2**: Peak memory usage below 400MB with model quantization (reduced from 500MB based on consensus)
- **P3**: Embedding generation under 2 seconds per chunk with validated LFM2 benchmarking
- **P4**: ObjectBox batch insertions under 100ms with HNSW index optimization
- **P5**: End-to-end pipeline latency under 30 seconds for typical regulation with incremental availability
- **Enhanced through consensus P6**: Maintain processing throughput with 100-token overlap overhead included

### Security (Enhanced through consensus)
- **S1**: All processing occurs on-device with no external data transmission or cloud dependencies
- **S2**: Implement AES-256-GCM encryption for regulation embeddings with secure key management
- **S3**: Use iOS Keychain for cryptographic key storage with user authentication
- **S4**: Implement secure deletion with cryptographic erasure for temporary and failed processing files
- **S5**: Privacy-preserving analytics with no PII storage and user-controlled data retention
- **Enhanced through consensus S6**: Supply-chain validation for LFM2 model weights and third-party dependencies
- **Enhanced through consensus S7**: TEMPEST-aware design for classified information handling (when applicable)

### Usability (Enhanced through consensus)
- **U1**: Non-blocking UI during background processing with responsive user interaction
- **U2**: Clear progress indicators with meaningful status messages and time estimates
- **U3**: Error messages provide specific, actionable guidance with resolution steps
- **U4**: Processing can be paused, resumed, and cancelled with state preservation
- **U5**: WCAG 2.1 AA accessibility compliance with screen reader announcements
- **Enhanced through consensus U6**: Incremental feature availability with partial processing results

### Reliability (Enhanced through consensus)
- **R1**: 95% success rate for well-formed HTML documents with automated retry for transient failures
- **R2**: Graceful degradation with partial failures and continued operation
- **R3**: Automatic recovery from memory pressure with dynamic resource management
- **R4**: Data consistency maintained during interruptions with checkpoint-based recovery
- **R5**: Comprehensive audit logging for troubleshooting and compliance verification
- **Enhanced through consensus R6**: Automated health checks with self-healing capabilities where possible

### Scalability (Enhanced through consensus)
- **SC1**: Support for 1000+ regulation documents with linear performance scaling
- **SC2**: Memory usage independent of total document count through streaming processing
- **SC3**: Background processing without blocking other app functions
- **SC4**: Efficient incremental updates for changed regulations with version comparison
- **SC5**: Horizontal scaling preparation for future distributed processing requirements

## Acceptance Criteria

### Core Pipeline Functionality (Enhanced through consensus)
1. **HTML Processing**: Successfully extracts text from 95% of government HTML regulation files with graceful handling of malformed content
2. **Structure-Aware Chunking**: Creates semantically coherent chunks that preserve regulatory hierarchy with 95% parent-child relationship retention
3. **Embedding Generation**: Generates 768-dimension embeddings using validated LFM2 model with confirmed performance benchmarks
4. **Vector Storage**: Stores embeddings in ObjectBox with comprehensive searchable metadata and version tracking
5. **Batch Processing**: Processes 10 chunks concurrently with proper error isolation and fallback mechanisms

### Performance Standards (Enhanced through consensus)
1. **Throughput**: Processes minimum 100 documents per minute on iPhone 14 Pro hardware
2. **Memory Efficiency**: Peak memory usage stays below 400MB with model quantization
3. **Latency**: Individual chunk processing completes within 2 seconds with validated LFM2 performance
4. **Concurrency**: Maintains responsive UI during background processing with cooperative multitasking
5. **Resource Management**: Properly releases resources with automated cleanup and monitoring

### Quality Assurance (Enhanced through consensus)
1. **Hierarchical Coherence**: 95% of chunks contain their immediate parent heading for legal context preservation
2. **Metadata Accuracy**: Extracted metadata matches source document structure with automated validation
3. **Error Handling**: Gracefully recovers from 95% of processing failures with actionable error reporting
4. **Data Integrity**: No data loss during processing interruptions with checkpoint-based recovery
5. **Search Quality**: Enables accurate semantic search with >90% relevance using gold-standard evaluation dataset

### Integration Requirements (Enhanced through consensus)
1. **LFM2 Service**: Seamlessly integrates with existing LFM2Service actor with performance validation
2. **ObjectBox Database**: Extends current ObjectBox Semantic Index with version management
3. **Progress Reporting**: Provides real-time status updates with pause/resume capability
4. **Error Reporting**: Integrates with app-wide error handling systems with detailed categorization
5. **Settings Integration**: Respects user preferences with granular control options

### Enhanced through consensus: Operational Acceptance Criteria
1. **Version Management**: Correctly identifies and processes regulation updates with change tracking
2. **Security Compliance**: Passes security audit with AES-256-GCM encryption and secure key management
3. **Observability**: Provides comprehensive logging and monitoring with configurable alert thresholds
4. **Recovery Procedures**: Successfully recovers from interruptions with <1% data loss
5. **Performance Consistency**: Maintains throughput within 10% variance across processing sessions

## Dependencies

### Internal Dependencies
- **LFM2Service**: Actor-based service for embedding generation (COMPLETED - QA Validated)
- **ObjectBoxSemanticIndex**: Vector database with HNSW configuration (COMPLETED - Mock Implementation)
- **RegulationProcessor**: Basic HTML processing foundation (EXISTS - Requires Enhancement)
- **GraphRAGTypes**: Core type definitions and models (COMPLETED)
- **AppCore Models**: Regulation data models and error types (EXISTS - Requires Extension)

### External Dependencies (Enhanced through consensus)
- **SwiftSoup**: HTML parsing library for production-grade text extraction (License: MIT)
- **Swift Async Algorithms**: AsyncChannel and async sequence processing (License: Apache 2.0)
- **Core ML**: Batch prediction API for LFM2 model execution (Apple Framework)
- **ObjectBox Swift**: Vector database with HNSW indexing support (Commercial License - Verification Required)
- **Foundation**: File system access and data processing utilities (Apple Framework)

### Hardware Dependencies (Enhanced through consensus)
- **Neural Engine**: Required for optimal LFM2 embedding performance (A14 Bionic or newer)
- **Storage**: Minimum 2GB available space for regulation database with expansion capability
- **Memory**: 8GB RAM recommended for optimal batch processing (6GB minimum)
- **CPU**: A14 Bionic or newer for acceptable performance (specified reference: iPhone 14 Pro)

### Enhanced through consensus: Licensing and Legal Dependencies
- **ObjectBox Commercial License**: Verification required for commercial deployment
- **HNSW Algorithm**: Patent landscape review required for vector search implementation
- **Third-party Library Maintenance**: Ongoing update and support verification for SwiftSoup and dependencies

## Constraints

### Technical Constraints (Enhanced through consensus)
- **Swift 6 Compliance**: All code must support strict concurrency checking with actor isolation
- **iOS 17.0+ Compatibility**: Required for async/await, actor features, and Core ML async APIs
- **On-Device Processing**: Absolute requirement - no cloud services or external API dependencies
- **Memory Limitations**: Must operate within iOS app memory constraints with automatic pressure handling
- **Battery Efficiency**: Processing should not significantly impact battery life with power management

### Business Constraints (Enhanced through consensus)
- **Regulation Format**: Limited to HTML format from government sources with fallback parsing
- **Processing Time**: Initial setup must complete within reasonable timeframe with user progress visibility
- **User Experience**: Cannot block critical app functionality during processing with incremental availability
- **Storage Efficiency**: Vector database size must remain manageable with compression and cleanup
- **Maintenance**: Solution must be maintainable by existing development team with comprehensive documentation

### Regulatory Constraints (Enhanced through consensus)
- **Government Data**: Must handle CUI (Controlled Unclassified Information) with appropriate security measures
- **Privacy Requirements**: All data must remain on user's device with cryptographic protection
- **Compliance Standards**: Processing must maintain regulatory accuracy with audit trail capability
- **Security Protocols**: Implementation must follow government security guidelines with validation
- **Data Retention**: Support user-controlled data deletion with cryptographic erasure

## Risk Assessment (Enhanced through consensus)

### High Risk Items
1. **Memory-Performance Conflict**: 400MB memory constraint vs. 400-600MB typical embedding model requirements
   - *Enhanced Mitigation*: Implement model quantization, streaming embedding, and memory pressure monitoring
2. **Hierarchical Chunking Complexity**: Structure-aware chunking may introduce parsing complexity and edge cases
   - *Enhanced Mitigation*: Comprehensive testing with real regulation documents and fallback mechanisms
3. **LFM2 Performance Validation**: Unverified 2.6x performance claims critical to meeting throughput targets
   - *Enhanced Mitigation*: Immediate benchmarking on target hardware with performance validation protocol

### Medium Risk Items
1. **ObjectBox Commercial Licensing**: Potential licensing costs or restrictions for commercial deployment
   - *Enhanced Mitigation*: Legal review and alternative vector database evaluation (backup options identified)
2. **Neural Engine Contention**: GPU/Neural Engine resource conflicts with 10-way concurrency
   - *Enhanced Mitigation*: Fallback serial processing path and dynamic resource allocation
3. **Regulation Format Changes**: Government HTML structure modifications could break parsing
   - *Enhanced Mitigation*: Robust schema validation, automated testing, and graceful degradation

### Low Risk Items
1. **SwiftSoup Integration**: Well-established library with stable API and active maintenance
2. **Swift Async Algorithms**: Apple-supported library with comprehensive documentation
3. **Core ML Batch Processing**: Apple-provided API with documented behavior and performance characteristics

### Enhanced through consensus: Additional Risk Considerations
1. **Security Audit Compliance**: Meeting government security requirements for CUI handling
2. **Performance Consistency**: Maintaining throughput across different hardware configurations
3. **Data Migration**: Handling regulation database updates and version migrations

## Success Metrics (Enhanced through consensus)

### Primary Metrics
1. **Processing Throughput**: >100 documents/minute sustained performance on iPhone 14 Pro hardware
2. **Hierarchical Search Quality**: >90% semantic relevance with preserved regulatory context using ROUGE-L evaluation
3. **System Reliability**: <5% failure rate for regulation processing with automated recovery
4. **Memory Efficiency**: Peak usage <400MB with model quantization during bulk processing
5. **User Satisfaction**: Positive feedback on regulation search experience with legal accuracy validation

### Secondary Metrics
1. **Processing Speed**: <30 seconds end-to-end for typical regulation with incremental availability
2. **Error Recovery**: >95% success rate for retry operations with partial batch recovery
3. **Storage Efficiency**: <50MB average per 1000 regulation chunks with compression optimization
4. **Battery Impact**: <5% additional drain during background processing with power management
5. **Performance Consistency**: <10% variation in processing times across different regulation types

### Enhanced through consensus: Quality Metrics with Formal Evaluation
1. **Hierarchical Coherence**: 95% of chunks contain immediate parent heading using objective measurement protocol
2. **Metadata Accuracy**: 95% correct extraction of regulation identifiers with automated validation
3. **Search Precision**: 85% relevant results in top 10 search results using golden dataset evaluation
4. **Processing Completeness**: 98% of regulation content successfully processed with quality assurance
5. **Error Transparency**: 100% of errors provide actionable user guidance with resolution success tracking

### Enhanced through consensus: Operational Metrics
1. **System Availability**: 99.5% uptime during processing operations with automated health monitoring
2. **Version Update Success**: 95% successful regulation updates with rollback capability
3. **Security Compliance**: 100% encryption coverage with regular security audit validation
4. **Recovery Time**: <2 minutes average recovery from interruptions using checkpoint systems
5. **Documentation Coverage**: 100% API and operational procedure documentation with maintenance protocols

## Implementation Phases (Enhanced through consensus)

### Phase 1: Enhanced Foundation (Week 1-2)
1. Integrate SwiftSoup for robust HTML processing with error handling
2. Implement structure-aware chunking with hierarchical boundary detection
3. Create AsyncChannel-based pipeline coordination with error isolation
4. Add comprehensive logging and monitoring infrastructure
5. Implement LFM2 performance validation and benchmarking protocols

### Phase 2: Performance and Security Optimization (Week 2-3)
1. Add batch processing with TaskGroup concurrency and resource management
2. Implement Core ML async prediction with model quantization strategies
3. Add memory management with bounded buffers and pressure monitoring
4. Integrate ObjectBox batch insertion with transactional integrity
5. Implement security measures including key management and encryption

### Phase 3: Operational Capabilities (Week 3-4)
1. Add version management and regulation update detection
2. Implement pause/resume functionality with checkpoint persistence
3. Create comprehensive error handling with partial recovery mechanisms
4. Add incremental search availability with streaming index updates
5. Implement data export/import and backup capabilities

### Phase 4: Production Hardening and Validation (Week 4-5)
1. Add comprehensive test coverage with golden dataset evaluation
2. Implement monitoring and metrics collection with alerting
3. Performance tuning and optimization with hardware-specific adjustments
4. Security audit and compliance validation
5. Documentation completion and deployment preparation

## Technical Architecture Notes (Enhanced through consensus)

### Structure-Aware Chunking Strategy
Based on consensus feedback, the pipeline uses HTML structure elements (h1, h2, h3, p, li) to create chunks that preserve regulatory hierarchy. This ensures legal accuracy by maintaining parent-child relationships and regulatory context.

### AsyncChannel Coordination Pattern
Swift Async Algorithms research validates AsyncChannel for producer-consumer coordination between HTML processing, structure-aware chunking, embedding generation, and storage stages with proper error isolation.

### Memory-Optimized Batch Processing
Consensus analysis identified memory constraints requiring model quantization and streaming strategies. Implementation uses dynamic resource allocation with fallback mechanisms for GPU/Neural Engine contention.

### Comprehensive Error Handling
Enhanced error categorization (network, parsing, embedding, storage) with specific recovery strategies, checkpoint-based resumption, and partial batch processing capability.

### Security and Compliance Framework
Multi-layered security approach with AES-256-GCM encryption, iOS Keychain integration, secure deletion protocols, and comprehensive audit logging for government compliance requirements.

## Appendix: Consensus Synthesis

### Summary of Multi-Model Consensus Feedback

**Model 1 (Gemini-2.5-Pro, Stance: For, Confidence: 7/10)**
- Identified critical misalignment between user needs and proposed fixed-size chunking
- Highlighted unverified LFM2 performance claims as major dependency risk
- Recommended structure-aware chunking and immediate performance validation

**Model 2 (O3, Stance: Against, Confidence: 8/10)**
- Provided comprehensive technical analysis identifying memory constraint conflicts
- Highlighted missing operational requirements and security specifications
- Emphasized need for formal evaluation metrics and edge case coverage

**Convergent Findings:**
- Both models agreed on feasibility but emphasized aggressive performance targets
- Unanimous recommendation for immediate LFM2 benchmarking and validation
- Consensus on need for objective success metrics and formal evaluation protocols
- Agreement on importance of comprehensive error handling and recovery mechanisms

**Key Decisions Based on Consensus:**
1. **Chunking Strategy**: Replaced fixed-size with structure-aware hierarchical chunking
2. **Memory Management**: Reduced target from 500MB to 400MB with quantization requirements
3. **Success Metrics**: Added formal evaluation protocols and golden dataset requirements
4. **Operational Requirements**: Added version management, observability, and security enhancements
5. **Risk Mitigation**: Enhanced with specific technical solutions and fallback mechanisms

This enhanced PRD incorporates all critical feedback from the consensus process to ensure technical feasibility, user value alignment, and production readiness.