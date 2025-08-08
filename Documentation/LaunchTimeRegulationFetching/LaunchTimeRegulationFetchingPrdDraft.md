# Product Requirements Document: Launch-Time Regulation Fetching

## Document Metadata
- Task: Implement Launch-Time Regulation Fetching
- Version: Draft v1.0
- Date: 2025-08-07
- Author: tdd-prd-architect
- Status: Initial Draft (Pre-Consensus)

## Executive Summary

The Launch-Time Regulation Fetching feature enables AIKO to automatically download, process, and populate the local ObjectBox vector database with official government regulations from the GSA acquisition.gov repository during the app's initial onboarding process. This ensures users have immediate access to comprehensive, semantically searchable regulatory content for intelligent form auto-population and compliance assistance, while maintaining the <400ms launch performance requirement through background processing.

## Background and Context

AIKO currently operates without a comprehensive local regulation database, limiting its ability to provide intelligent, compliance-aware form auto-population and decision support. The proposed solution addresses this by:

1. **Establishing Regulatory Foundation**: Creating a complete local repository of GSA acquisition regulations
2. **Enabling Semantic Search**: Processing regulations through LFM2 Core ML for vector-based similarity search
3. **Maintaining Performance**: Ensuring app launch remains responsive while populating database in background
4. **Supporting Offline Operation**: Providing full regulatory access without network dependency after initial setup

### Current Architecture Context
- **Swift 6 strict concurrency compliance** across all components
- **ObjectBox Semantic Index** vector database foundation complete (Mock-first architecture)
- **LFM2-700M Core ML model** integrated (149MB, production-ready)
- **TCA → SwiftUI migration** completed with @Observable patterns
- **Zero SwiftLint violations** maintained across 587+ files

## User Stories

### Primary User Stories

**As an acquisition professional**, I want AIKO to have immediate access to current regulations so that I can receive accurate, compliant form auto-population suggestions without manual research.

**As a first-time user**, I want the app to quickly set up its regulation database during onboarding so that I can start using intelligent features immediately without lengthy setup delays.

**As a government contractor**, I want confidence that AIKO's suggestions are based on official, current regulations so that my compliance efforts are reliable and auditable.

**As a mobile user**, I want the regulation database setup to not interfere with app responsiveness so that I can continue using other features while the background setup completes.

### Edge Case User Stories

**As a user with limited network connectivity**, I want the regulation fetch to gracefully handle interruptions and resume where it left off so that I don't lose progress from partial downloads.

**As a user with limited device storage**, I want clear visibility into database size requirements and the ability to manage storage so that regulation data doesn't overwhelm my device.

**As a security-conscious user**, I want assurance that regulation data is verified for integrity so that I'm confident in the authenticity of compliance guidance.

**As a user returning after months**, I want AIKO to automatically update outdated regulations so that my compliance guidance remains current without manual intervention.

## Functional Requirements

### Core Functionality

#### FR-001: GitHub Repository Integration
- **Requirement**: Integrate with GSA acquisition.gov GitHub repository API
- **Details**: 
  - Connect to official GSA-Acquisition-FAR repository
  - Fetch repository metadata and file listings
  - Download 1000+ HTML regulation files
  - Implement proper API rate limiting and error handling
- **Dependencies**: NetworkService, SecureNetworkService
- **Acceptance Criteria**: Successfully fetch complete file manifest within 30 seconds on standard WiFi

#### FR-002: Onboarding Flow Integration
- **Requirement**: Embed regulation fetch within app onboarding process
- **Details**:
  - Display "Setting up regulation database..." phase
  - Show detailed progress with file count and ETA
  - Allow user to skip and set up later (degraded mode)
  - Provide background completion notification
- **Dependencies**: OnboardingView, OnboardingViewModel
- **Acceptance Criteria**: Onboarding flow completes setup initiation within 400ms launch constraint

#### FR-003: Background Processing Pipeline
- **Requirement**: Process regulations without blocking main thread
- **Details**:
  - Implement BackgroundTasks framework integration
  - Use Swift concurrency (async/await) for parallel processing
  - Process files in 100-file chunks to manage memory
  - Maintain <200MB memory usage during processing
- **Dependencies**: RegulationProcessor, StructureAwareChunker
- **Acceptance Criteria**: Process 1000 files in <5 minutes on WiFi without UI blocking

#### FR-004: LFM2 Core ML Processing
- **Requirement**: Generate embeddings for each regulation using LFM2 model
- **Details**:
  - Extract and clean HTML content from regulation files
  - Chunk content using structure-aware algorithms
  - Generate 768-dimensional embeddings via LFM2Service
  - Optimize for <2 seconds per 512-token chunk
- **Dependencies**: LFM2Service, StructureAwareChunker
- **Acceptance Criteria**: Process regulation content with >95% accuracy and <800MB peak memory

#### FR-005: ObjectBox Database Population
- **Requirement**: Store processed regulations in ObjectBox vector database
- **Details**:
  - Create RegulationEmbedding entities with metadata
  - Implement batch insert operations for efficiency
  - Configure HNSW vector indexing for similarity search
  - Support dual-namespace architecture (regulations/templates)
- **Dependencies**: ObjectBoxSemanticIndex, GraphRAG module
- **Acceptance Criteria**: Store embeddings with sub-second similarity search performance

#### FR-006: Progress Tracking System
- **Requirement**: Provide detailed progress feedback to users
- **Details**:
  - Track download progress by file count and bytes
  - Show processing progress with ETA calculations
  - Display current phase (fetch, process, store, index)
  - Persist progress across app sessions
- **Dependencies**: ProgressTrackingEngine, ProgressBridge
- **Acceptance Criteria**: Update progress UI every 100ms without blocking operations

### Error Handling and Recovery

#### FR-007: Network Resilience
- **Requirement**: Handle network interruptions and failures gracefully
- **Details**:
  - Implement automatic retry with exponential backoff
  - Support resumable downloads from interruption point
  - Cache partial progress to persistent storage
  - Provide manual retry options for users
- **Acceptance Criteria**: Successfully resume from 90% of network interruptions

#### FR-008: Storage and Memory Management
- **Requirement**: Prevent device storage and memory exhaustion
- **Details**:
  - Pre-check available device storage (require 2GB minimum)
  - Monitor memory usage and trigger garbage collection
  - Implement chunked processing to avoid memory spikes
  - Provide storage cleanup options for users
- **Acceptance Criteria**: Never exceed 200MB RAM or cause storage-full conditions

#### FR-009: Corruption Detection and Recovery
- **Requirement**: Detect and recover from data corruption
- **Details**:
  - Implement SHA-256 hash verification for downloaded files
  - Validate ObjectBox database integrity after population
  - Provide database rebuild option from cached source files
  - Alert users to corruption issues with recovery guidance
- **Acceptance Criteria**: Detect 100% of file corruption and provide recovery within 2 minutes

## Non-Functional Requirements

### Performance Requirements

#### NFR-001: Launch Performance
- **Requirement**: Maintain <400ms app launch time constraint
- **Rationale**: Critical iOS performance standard for user experience
- **Implementation**: Background task initialization without blocking main thread
- **Measurement**: Time from app icon tap to first UI render
- **Target**: <400ms on iPhone 13 or equivalent hardware

#### NFR-002: Processing Performance
- **Requirement**: Complete full regulation database setup in <5 minutes
- **Rationale**: Reasonable onboarding time for comprehensive feature enablement
- **Implementation**: Parallel processing with optimized Core ML inference
- **Measurement**: End-to-end time from start to searchable database
- **Target**: <5 minutes on standard WiFi connection

#### NFR-003: Memory Efficiency
- **Requirement**: Peak memory usage <200MB during regulation processing
- **Rationale**: Maintain stability on memory-constrained devices
- **Implementation**: Chunked processing with autoreleasepool management
- **Measurement**: Instruments memory profiling during full processing
- **Target**: Never exceed 200MB resident memory

### Security Requirements

#### NFR-004: Data Integrity
- **Requirement**: Verify authenticity of all downloaded regulation content
- **Implementation**: SHA-256 hash verification and HTTPS certificate pinning
- **Validation**: 100% verification of downloaded files against known checksums

#### NFR-005: Privacy Protection
- **Requirement**: No PII transmission or storage during regulation processing
- **Implementation**: All processing occurs locally with no external analytics
- **Validation**: Network monitoring confirms no PII in outbound requests

### Usability Requirements

#### NFR-006: User Control and Transparency
- **Requirement**: Clear progress indication and user control options
- **Implementation**: Detailed progress UI with pause/resume/cancel capabilities
- **Validation**: Users can understand and control the regulation setup process

#### NFR-007: Accessibility Compliance
- **Requirement**: Full VoiceOver support for regulation setup process
- **Implementation**: Accessible progress indicators and status announcements
- **Validation**: Complete navigation using VoiceOver without assistance

## Acceptance Criteria

### Primary Success Criteria

1. **Launch Performance**: App launches in <400ms with regulation fetch initialized in background
2. **Complete Processing**: All 1000+ GSA regulation files successfully downloaded, processed, and stored
3. **Search Functionality**: Semantic similarity search operational with <1 second response time
4. **Error Recovery**: System recovers from network interruptions and continues processing
5. **Progress Tracking**: Users receive clear, accurate progress updates throughout setup
6. **Memory Compliance**: Peak memory usage remains under 200MB during all operations
7. **Storage Efficiency**: Complete regulation database requires <500MB storage
8. **App Store Compliance**: Feature passes App Store review without rejection
9. **Offline Operation**: Full regulatory search available without network after setup
10. **Integration Testing**: Seamless integration with existing LLM and form auto-population features

### Quality Assurance Criteria

1. **Build Performance**: Maintains current 2.6s build time with new components
2. **SwiftLint Compliance**: Zero new SwiftLint violations introduced
3. **Swift 6 Compliance**: Full strict concurrency compliance maintained
4. **Test Coverage**: >90% test coverage for all new regulation processing components
5. **Documentation**: Complete API documentation for all public interfaces

## Dependencies

### Internal Dependencies
- **ObjectBox Semantic Index**: Vector database foundation (COMPLETED)
- **LFM2 Core ML Service**: Embedding generation (COMPLETED)
- **RegulationProcessor**: Structure-aware content processing (COMPLETED)
- **ProgressTrackingEngine**: User progress feedback system
- **OnboardingView/ViewModel**: Integration point for user experience

### External Dependencies
- **GSA GitHub Repository**: Source of regulation content (github.com/GSA/GSA-Acquisition-FAR)
- **Network Connectivity**: Required for initial download (WiFi recommended)
- **Device Storage**: Minimum 2GB available space required
- **iOS BackgroundTasks**: Background processing capability

### Technical Dependencies
- **Swift 6.0**: Strict concurrency compliance maintained
- **iOS 17.0+**: BackgroundTasks and modern networking APIs
- **ObjectBox Swift**: Vector database functionality
- **Core ML**: LFM2 model inference
- **SwiftUI**: Observable pattern for progress UI

## Constraints

### Technical Constraints
1. **iOS App Store Guidelines**: No blocking of app launch beyond 400ms limit
2. **Memory Limitations**: iOS memory pressure management required
3. **Background Processing Limits**: iOS background task time limitations
4. **Core ML Model Size**: 149MB LFM2 model must be efficiently managed
5. **Swift 6 Compliance**: All new code must satisfy strict concurrency checking

### Business Constraints
1. **Regulatory Currency**: Must use official GSA sources only
2. **Offline Operation**: No cloud dependencies after initial setup
3. **User Experience**: Cannot negatively impact existing app responsiveness
4. **Maintenance Overhead**: Automated updates without manual intervention required

### Operational Constraints
1. **Zero Downtime**: Feature must not interrupt existing app functionality
2. **Storage Management**: Must coexist with existing app data without conflicts
3. **Cross-Platform**: Implementation must support iOS and macOS targets
4. **Version Compatibility**: Must work across iOS 17.0+ version range

## Risk Assessment

### High-Risk Areas

#### Technical Risks
1. **Memory Pressure**: Large-scale Core ML processing may trigger iOS memory warnings
   - **Mitigation**: Chunked processing with aggressive memory management
   - **Contingency**: Reduce chunk size and implement more frequent garbage collection

2. **App Store Rejection**: Background processing might violate performance guidelines
   - **Mitigation**: Ensure <400ms launch and proper background task registration
   - **Contingency**: Implement user-initiated setup as alternative flow

3. **ObjectBox Integration**: Vector database performance under large dataset load
   - **Mitigation**: Leverage existing mock-first architecture and production testing
   - **Contingency**: Implement progressive loading and database partitioning

#### Operational Risks
1. **GSA Repository Changes**: Source repository structure modifications could break integration
   - **Mitigation**: Implement flexible parsing with schema validation
   - **Contingency**: Cache repository metadata and implement change detection

2. **Device Storage Exhaustion**: Large regulation database may cause storage issues
   - **Mitigation**: Pre-flight storage checks and user storage management options
   - **Contingency**: Implement selective regulation download by user priorities

### Medium-Risk Areas
1. **Network Reliability**: Variable connectivity may cause incomplete downloads
2. **Battery Impact**: Extended processing may drain device battery significantly
3. **LFM2 Model Performance**: Core ML inference speed may vary across device generations

### Risk Mitigation Strategy
- **Comprehensive Testing**: Full device testing across iPhone models and iOS versions
- **Progressive Rollout**: Feature flag implementation for gradual user base activation
- **Monitoring Integration**: Performance metrics collection for post-deployment optimization
- **Fallback Mechanisms**: Graceful degradation when regulation data unavailable

## Success Metrics

### Primary Metrics
1. **Setup Completion Rate**: >95% of users successfully complete regulation database setup
2. **User Satisfaction**: >4.5/5 rating for regulation-enhanced form auto-population
3. **Performance Compliance**: 100% of launches remain under 400ms performance target
4. **Search Usage**: >70% of users actively utilize regulation search within 30 days
5. **Error Rate**: <2% of regulation processing operations encounter unrecoverable errors

### Secondary Metrics
1. **Time to Value**: Users access regulation-enhanced features within 10 minutes of setup
2. **Memory Efficiency**: Average memory usage <150MB during regulation processing
3. **Storage Optimization**: Regulation database size <400MB for 90% of regulation sets
4. **Background Success**: >98% of background processing tasks complete successfully
5. **Cross-Platform Parity**: Feature performance consistent across iOS and macOS

### Technical Performance Metrics
1. **Build Performance**: Maintain <3 second build time with regulation components
2. **Test Coverage**: Achieve >95% test coverage for all regulation processing code
3. **Code Quality**: Zero new SwiftLint violations or Swift 6 compliance issues
4. **Documentation Coverage**: 100% API documentation for all public regulation interfaces

## Implementation Phases

### Phase 1: Foundation (Week 1)
- GitHub API integration and basic file fetching
- Onboarding flow integration with progress UI
- Background task framework setup
- Basic error handling and retry logic

### Phase 2: Processing Pipeline (Week 2)
- LFM2 Core ML integration for regulation embedding
- StructureAware content chunking and cleanup
- ObjectBox database population and indexing
- Memory management and performance optimization

### Phase 3: Production Readiness (Week 3)
- Comprehensive error handling and recovery
- Advanced progress tracking and user controls
- Cross-platform testing and optimization
- App Store compliance validation

### Phase 4: Enhancement (Week 4)
- Background update scheduling
- Delta synchronization capabilities
- Analytics and performance monitoring
- User feedback integration and refinement