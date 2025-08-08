# Product Requirements Document: Launch-Time Regulation Fetching

## Document Metadata
- Task: Implement Launch-Time Regulation Fetching
- Version: Enhanced v1.0
- Date: 2025-08-07
- Author: tdd-prd-architect
- Consensus Method: zen:consensus synthesis applied
- Models Consulted: Gemini 2.5 Pro, O3, O3-mini, GPT-4.1 (Confidence: 6/10-9/10)

## Consensus Enhancement Summary
Multi-model consensus identified critical performance and edge case improvements: adjusted memory targets (200MB → 300MB realistic), comprehensive error handling additions, enhanced security requirements, and detailed post-setup maintenance strategy. Server-side processing alternative documented as risk mitigation option.

## Executive Summary

The Launch-Time Regulation Fetching feature enables AIKO to automatically download, process, and populate the local ObjectBox vector database with official government regulations from the GSA acquisition.gov repository during the app's initial onboarding process. This ensures users have immediate access to comprehensive, semantically searchable regulatory content for intelligent form auto-population and compliance assistance, while maintaining the <400ms launch performance requirement through background processing.

**Enhanced through consensus**: Performance targets refined based on device capability analysis, comprehensive error handling strategy added, and alternative implementation approaches documented for risk mitigation.

## Background

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

**Enhanced through consensus**: Added recognition of aggressive performance targets and need for device-specific profiling across A12-A17 chip generations.

## User Stories

### Primary User Stories

**As an acquisition professional**, I want AIKO to have immediate access to current regulations so that I can receive accurate, compliant form auto-population suggestions without manual research.

**As a first-time user**, I want the app to quickly set up its regulation database during onboarding so that I can start using intelligent features immediately without lengthy setup delays.

**As a government contractor**, I want confidence that AIKO's suggestions are based on official, current regulations so that my compliance efforts are reliable and auditable.

**As a mobile user**, I want the regulation database setup to not interfere with app responsiveness so that I can continue using other features while the background setup completes.

### Edge Case User Stories

**Enhanced through consensus**: Expanded edge case coverage based on multi-model feedback.

**As a user with limited network connectivity**, I want the regulation fetch to gracefully handle interruptions and resume where it left off so that I don't lose progress from partial downloads.

**As a user on cellular data**, I want clear warnings about data usage and the option to defer regulation download until Wi-Fi is available so that I can control my data costs.

**As a user whose setup is interrupted (app termination, device restart)**, I want AIKO to resume the regulation setup process seamlessly when I restart the app so that I don't have to start over.

**As a user with limited device storage**, I want clear visibility into database size requirements and storage management options so that regulation data doesn't overwhelm my device.

**As a security-conscious user**, I want assurance that regulation data is verified for integrity and authenticity so that I'm confident in the reliability of compliance guidance.

**As a user returning after months**, I want AIKO to automatically detect and update outdated regulations so that my compliance guidance remains current without manual intervention.

## Functional Requirements

### Core Functionality

#### FR-001: GitHub Repository Integration
- **Requirement**: Integrate with GSA acquisition.gov GitHub repository API
- **Details**: 
  - Connect to official GSA-Acquisition-FAR repository
  - Fetch repository metadata and file listings
  - Download 1000+ HTML regulation files
  - Implement proper API rate limiting (60 req/hr unauthenticated)
  - **Enhanced**: Add GitHub API rate limiting detection and backoff strategy
- **Dependencies**: NetworkService, SecureNetworkService
- **Acceptance Criteria**: Successfully fetch complete file manifest within 30 seconds on standard WiFi

#### FR-002: Onboarding Flow Integration
- **Requirement**: Embed regulation fetch within app onboarding process
- **Details**:
  - Display "Setting up regulation database..." phase
  - Show detailed progress with file count and ETA
  - Allow user to skip and set up later (degraded mode)
  - **Enhanced**: Add cellular data warning and Wi-Fi requirement prompt
  - Provide background completion notification
  - **Enhanced**: Define clear messaging for partial/incomplete regulation coverage
- **Dependencies**: OnboardingView, OnboardingViewModel
- **Acceptance Criteria**: Onboarding flow completes setup initiation within 400ms launch constraint

#### FR-003: Background Processing Pipeline
- **Requirement**: Process regulations without blocking main thread
- **Details**:
  - Implement BackgroundTasks framework integration
  - Use Swift concurrency (async/await) for parallel processing
  - Process files in 100-file chunks to manage memory
  - **Enhanced**: Maintain <300MB memory usage during processing (revised from 200MB based on consensus)
  - **Enhanced**: Support resumable processing across app launches and device reboots
- **Dependencies**: RegulationProcessor, StructureAwareChunker
- **Acceptance Criteria**: Process 1000 files in <5 minutes on WiFi without UI blocking

#### FR-004: LFM2 Core ML Processing
- **Requirement**: Generate embeddings for each regulation using LFM2 model
- **Details**:
  - Extract and clean HTML content from regulation files
  - Chunk content using structure-aware algorithms
  - Generate 768-dimensional embeddings via LFM2Service
  - Optimize for <2 seconds per 512-token chunk
  - **Enhanced**: Support batch processing (8-16 docs/batch) for efficiency
  - **Enhanced**: Implement model quantization option for older devices
- **Dependencies**: LFM2Service, StructureAwareChunker
- **Acceptance Criteria**: Process regulation content with >95% accuracy and <800MB peak memory

#### FR-005: ObjectBox Database Population
- **Requirement**: Store processed regulations in ObjectBox vector database
- **Details**:
  - Create RegulationEmbedding entities with metadata
  - Implement batch insert operations for efficiency
  - Configure HNSW vector indexing for similarity search
  - Support dual-namespace architecture (regulations/templates)
  - **Enhanced**: Include database corruption detection and repair mechanisms
- **Dependencies**: ObjectBoxSemanticIndex, GraphRAG module
- **Acceptance Criteria**: Store embeddings with sub-second similarity search performance

#### FR-006: Progress Tracking System
- **Requirement**: Provide detailed progress feedback to users
- **Details**:
  - Track download progress by file count and bytes
  - Show processing progress with ETA calculations
  - Display current phase (fetch, process, store, index)
  - **Enhanced**: Update progress UI every 500ms (adjusted from 100ms based on consensus)
  - Persist progress across app sessions
  - **Enhanced**: Define explicit progress API contract for telemetry
- **Dependencies**: ProgressTrackingEngine, ProgressBridge
- **Acceptance Criteria**: Update progress UI smoothly without blocking operations

### Error Handling and Recovery

**Enhanced through consensus**: Comprehensive error handling strategy added.

#### FR-007: Network Resilience
- **Requirement**: Handle network interruptions and failures gracefully
- **Details**:
  - Implement automatic retry with exponential backoff
  - Support resumable downloads from interruption point
  - Cache partial progress to persistent storage
  - Provide manual retry options for users
  - **Enhanced**: Handle GitHub repository changes and file deletions/renames
  - **Enhanced**: Detect and handle cellular vs Wi-Fi connectivity changes
- **Acceptance Criteria**: Successfully resume from 90% of network interruptions

#### FR-008: Storage and Memory Management
- **Requirement**: Prevent device storage and memory exhaustion
- **Details**:
  - Pre-check available device storage (require 2GB minimum)
  - Monitor memory usage and trigger garbage collection
  - Implement chunked processing to avoid memory spikes
  - **Enhanced**: Target <300MB peak memory usage (adjusted based on consensus)
  - Provide storage cleanup options for users
  - **Enhanced**: Handle low storage conditions gracefully during setup
- **Acceptance Criteria**: Never exceed 300MB RAM or cause storage-full conditions

#### FR-009: Corruption Detection and Recovery
- **Requirement**: Detect and recover from data corruption
- **Details**:
  - Implement SHA-256 hash verification for downloaded files
  - **Enhanced**: Add certificate pinning for GitHub API connections
  - **Enhanced**: Implement signature verification for regulation authenticity
  - Validate ObjectBox database integrity after population
  - Provide database rebuild option from cached source files
  - **Enhanced**: Create rollback/repair path for corrupted ObjectBox store
  - Alert users to corruption issues with recovery guidance
- **Acceptance Criteria**: Detect 100% of file corruption and provide recovery within 2 minutes

#### FR-010: Post-Setup Maintenance
- **Requirement**: Manage regulation updates and database maintenance
- **Details**:
  - **Enhanced**: Implement delta updates for changed regulations
  - **Enhanced**: Handle repository restructuring and schema migrations
  - **Enhanced**: Provide user-initiated wipe/rebuild functionality
  - **Enhanced**: Detect regulation updates and notify users
  - **Enhanced**: Support incremental sync for regulation changes
- **Dependencies**: Background task scheduling, GitHub API monitoring
- **Acceptance Criteria**: Successfully update regulations without full re-download

## Non-Functional Requirements

### Performance Requirements

#### NFR-001: Launch Performance
- **Requirement**: Maintain <400ms app launch time constraint
- **Clarification**: UI becomes interactive within 400ms, background regulation setup initialization may continue
- **Rationale**: Critical iOS performance standard for user experience
- **Implementation**: Background task initialization without blocking main thread
- **Measurement**: Time from app icon tap to first UI render
- **Target**: <400ms on iPhone 13 or equivalent hardware
- **Enhanced**: Must profile on iPhone 8/SE2 for older device compatibility

#### NFR-002: Processing Performance
- **Requirement**: Complete full regulation database setup in <5 minutes
- **Rationale**: Reasonable onboarding time for comprehensive feature enablement
- **Implementation**: Parallel processing with optimized Core ML inference
- **Enhanced**: Provide fallback to resume across launches for difficult cases
- **Measurement**: End-to-end time from start to searchable database
- **Target**: <5 minutes on standard WiFi connection

#### NFR-003: Memory Efficiency
- **Requirement**: Peak memory usage <300MB during regulation processing
- **Enhanced**: Adjusted from 200MB based on consensus analysis of Core ML tensor memory
- **Rationale**: Maintain stability on memory-constrained devices (2GB total)
- **Implementation**: Chunked processing with autoreleasepool management
- **Measurement**: Instruments memory profiling during full processing
- **Target**: Never exceed 300MB resident memory on low-end devices

### Security Requirements

#### NFR-004: Data Integrity and Authenticity
- **Requirement**: Verify authenticity and integrity of all downloaded regulation content
- **Implementation**: 
  - SHA-256 hash verification for file integrity
  - **Enhanced**: Certificate pinning for GitHub API connections
  - **Enhanced**: HTTPS enforcement with secure transport validation
  - **Enhanced**: Signature verification or GitHub release signing validation
- **Validation**: 100% verification of downloaded files against known checksums

#### NFR-005: Privacy Protection
- **Requirement**: No PII transmission or storage during regulation processing
- **Implementation**: All processing occurs locally with no external analytics
- **Enhanced**: GDPR/ITAR evaluation for regulation content containing personal data references
- **Validation**: Network monitoring confirms no PII in outbound requests

### Usability Requirements

#### NFR-006: User Control and Transparency
- **Requirement**: Clear progress indication and user control options
- **Implementation**: Detailed progress UI with pause/resume/cancel capabilities
- **Enhanced**: Explicit user messaging for onboarding interruptions and partial data scenarios
- **Enhanced**: Clear fallback behaviors when setup fails or is incomplete
- **Validation**: Users can understand and control the regulation setup process

#### NFR-007: Accessibility Compliance
- **Requirement**: Full VoiceOver support for regulation setup process
- **Implementation**: Accessible progress indicators and status announcements
- **Enhanced**: Support for broader accessibility needs beyond VoiceOver (cognitive impairments)
- **Enhanced**: Accessibility support during VoiceOver-active first run scenarios
- **Validation**: Complete navigation using VoiceOver without assistance

## Acceptance Criteria

### Primary Success Criteria

1. **Launch Performance**: App launches in <400ms with regulation fetch initialized in background
2. **Complete Processing**: All 1000+ GSA regulation files successfully downloaded, processed, and stored
3. **Search Functionality**: Semantic similarity search operational with <1 second response time
4. **Error Recovery**: System recovers from network interruptions and continues processing
5. **Progress Tracking**: Users receive clear, accurate progress updates throughout setup
6. **Memory Compliance**: Peak memory usage remains under 300MB during all operations
7. **Storage Efficiency**: Complete regulation database requires <500MB storage
8. **App Store Compliance**: Feature passes App Store review without rejection
9. **Offline Operation**: Full regulatory search available without network after setup
10. **Integration Testing**: Seamless integration with existing LLM and form auto-population features

### Enhanced Success Criteria

**Added through consensus validation**:

11. **Resume Capability**: Successfully resume processing after app termination in 95% of cases
12. **Cellular Data Protection**: Users receive clear warnings and can defer setup on cellular connections
13. **Authentication Verification**: 100% verification of regulation source authenticity
14. **Edge Case Handling**: Graceful handling of malformed HTML, API rate limits, and storage exhaustion
15. **Update Mechanism**: Delta updates complete in <2 minutes for typical regulation changes
16. **Security Compliance**: Certificate pinning and secure transport validated for all connections

### Quality Assurance Criteria

1. **Build Performance**: Maintains current 2.6s build time with new components
2. **SwiftLint Compliance**: Zero new SwiftLint violations introduced
3. **Swift 6 Compliance**: Full strict concurrency compliance maintained
4. **Test Coverage**: >90% test coverage for all new regulation processing components
5. **Documentation**: Complete API documentation for all public interfaces
6. **Cross-Device Testing**: Validation across A12-A17 device generations

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

### Enhanced Dependencies

**Added through consensus**:
- **Certificate Pinning**: GitHub API security validation
- **Background App Refresh**: Long-running background task support
- **Device Performance Profiling**: A12-A17 chip generation testing
- **SME Validation**: Subject matter expert review of regulation parsing accuracy

## Constraints

### Technical Constraints
1. **iOS App Store Guidelines**: No blocking of app launch beyond 400ms limit
2. **Memory Limitations**: iOS memory pressure management required (300MB target)
3. **Background Processing Limits**: iOS background task time limitations
4. **Core ML Model Size**: 149MB LFM2 model must be efficiently managed
5. **Swift 6 Compliance**: All new code must satisfy strict concurrency checking
6. **GitHub API Limits**: 60 requests/hour for unauthenticated access

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
1. **Memory Pressure on Older Devices**: A12 chip generation may struggle with 300MB memory target
   - **Mitigation**: Device-specific memory budgets and model quantization
   - **Contingency**: Staged processing and progressive download options

2. **GitHub API Rate Limiting**: Unauthenticated 60 req/hr limit may cause delays
   - **Mitigation**: Exponential backoff and request batching optimization
   - **Contingency**: Pre-computed regulation bundles as fallback

3. **App Store Performance Rejection**: Background processing might violate guidelines
   - **Mitigation**: Ensure <400ms launch and proper background task registration
   - **Contingency**: User-initiated setup as alternative flow

#### Operational Risks
1. **GSA Repository Changes**: Source repository structure modifications could break integration
   - **Mitigation**: Flexible parsing with schema validation and change detection
   - **Contingency**: Cache repository metadata and implement graceful degradation

2. **Device Storage Exhaustion**: Large regulation database may cause storage issues
   - **Mitigation**: Pre-flight storage checks and user storage management options
   - **Contingency**: Selective regulation download by user priorities

### Medium-Risk Areas
1. **Network Reliability**: Variable connectivity may cause incomplete downloads
2. **Battery Impact**: Extended processing may drain device battery significantly
3. **LFM2 Model Performance**: Core ML inference speed may vary across device generations

### Enhanced Risk Mitigation Strategy

**Based on consensus recommendations**:
- **Alternative Implementation**: Server-side pre-processing option documented as risk mitigation
- **Progressive Rollout**: Feature flag implementation for gradual user base activation
- **Comprehensive Testing**: Full device testing across iPhone models and iOS versions
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
2. **Memory Efficiency**: Average memory usage <250MB during regulation processing
3. **Storage Optimization**: Regulation database size <400MB for 90% of regulation sets
4. **Background Success**: >98% of background processing tasks complete successfully
5. **Cross-Platform Parity**: Feature performance consistent across iOS and macOS

### Technical Performance Metrics
1. **Build Performance**: Maintain <3 second build time with regulation components
2. **Test Coverage**: Achieve >95% test coverage for all regulation processing code
3. **Code Quality**: Zero new SwiftLint violations or Swift 6 compliance issues
4. **Documentation Coverage**: 100% API documentation for all public regulation interfaces

## Appendix: Consensus Synthesis

### Multi-Model Analysis Summary

**Models Consulted**: Gemini 2.5 Pro, O3, O3-mini, GPT-4.1
**Consensus Confidence**: High (4/5 models provided detailed feedback)
**Average Confidence**: 7.5/10

### Key Consensus Improvements Applied

1. **Memory Budget Adjustment**: 200MB → 300MB realistic target based on Core ML tensor analysis
2. **Progress Update Frequency**: 100ms → 500ms to reduce overhead
3. **Comprehensive Error Handling**: Added edge cases for interruptions, storage, and network failures
4. **Security Enhancement**: Certificate pinning and authenticity verification beyond SHA-256
5. **Post-Setup Maintenance**: Delta updates, corruption recovery, and schema migration support

### Alternative Implementation Consideration

**Server-Side Processing Option**: Consensus identified server-side pre-processing as significant risk mitigation strategy. This approach would:
- Reduce on-device processing time from minutes to seconds
- Minimize battery impact and memory pressure
- Improve reliability across device generations
- Require backend infrastructure but eliminate mobile constraints

**Decision**: Proceed with on-device processing for privacy-first architecture, with server-side option documented as future enhancement and risk mitigation strategy.

### Implementation Phases

### Phase 1: Foundation (Week 1)
- GitHub API integration with rate limiting and error handling
- Onboarding flow integration with cellular data warnings
- Background task framework setup with resume capability
- Basic error handling and retry logic with persistence

### Phase 2: Processing Pipeline (Week 2)
- LFM2 Core ML integration with batch processing optimization
- Structure-aware content chunking and cleanup
- ObjectBox database population with corruption detection
- Memory management and performance optimization (300MB target)

### Phase 3: Production Readiness (Week 3)
- Comprehensive error handling and recovery mechanisms
- Advanced progress tracking with 500ms update frequency
- Certificate pinning and security enhancement implementation
- Cross-platform testing and optimization across A12-A17 devices

### Phase 4: Enhancement (Week 4)
- Delta update scheduling and background maintenance
- Post-setup corruption detection and repair mechanisms
- Analytics and performance monitoring integration
- User feedback integration and comprehensive QA validation