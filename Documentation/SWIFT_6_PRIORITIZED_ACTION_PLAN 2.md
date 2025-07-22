# AIKO Swift 6 Migration - Prioritized Action Plan

**Project**: AIKO Swift 6 Strict Concurrency Migration  
**Plan Date**: July 20, 2025  
**Target Completion**: August 5, 2025  
**Current Status**: Final Sprint Phase (80% Complete)  

---

## 🎯 Executive Summary

This action plan provides a prioritized, time-boxed approach to complete the AIKO Swift 6 migration. With 4/5 targets already Swift 6 compliant, the remaining work focuses on the main AIKO target using proven patterns and established methodologies.

**Key Principles**:
- ⚡ Address blocking issues first (compilation failures)
- 🏗️ Build on proven patterns from completed modules
- 🔄 Incremental progress with continuous validation
- 🛡️ Maintain code quality and safety throughout

---

## 🚨 HIGH PRIORITY: Blocking Issues (Week 1)

### Priority 1A: Critical Compilation Fixes

#### Task 1.1: Resolve Typealias Redeclaration Conflicts
**🔥 CRITICAL - BLOCKING COMPILATION**

**Description**: Fix invalid redeclaration of `CoreDataAcquisition` typealias causing build failures.

**Files Affected**:
- `Sources/Infrastructure/Repositories/AcquisitionRepository.swift`
- `Sources/Services/AcquisitionService.swift`
- `Sources/Services/DocumentChainManager.swift`

**Current Error**:
```swift
// Error: invalid redeclaration of 'CoreDataAcquisition'
typealias CoreDataAcquisition = Acquisition
```

**Solution Strategy**:
1. **Unique Naming Approach**: Use file-scoped typealiases
2. **Module Qualification**: Explicit `AIKO.Acquisition` vs `AppCore.Acquisition`
3. **Consistent Pattern**: Apply successful patterns from completed modules

**Implementation Steps**:
```swift
// File: AcquisitionRepository.swift
import CoreData
import AppCore

// Use file-specific typealias
private typealias LocalCoreDataAcquisition = AIKO.Acquisition

class AcquisitionRepository {
    func create(from model: AppCore.Acquisition) -> LocalCoreDataAcquisition {
        // Implementation using clear type distinction
    }
}
```

**Effort Estimate**: 6-8 hours  
**Owner**: Infrastructure Team  
**Target Completion**: July 22, 2025  
**Success Criteria**: Clean compilation of infrastructure layer  

---

#### Task 1.2: Core Sendable Conformance for Domain Aggregates
**🔥 CRITICAL - BLOCKING ASYNC OPERATIONS**

**Description**: Add Sendable conformance to domain aggregates preventing async repository operations.

**Files Affected**:
- `Sources/Domain/Models/AcquisitionAggregate.swift`
- `Sources/Domain/Events/EventSourcingAggregate.swift`
- Related domain model files

**Current Error**:
```swift
// Error: type 'AcquisitionAggregate' does not conform to the 'Sendable' protocol
public func findAll() async throws -> [AcquisitionAggregate] {
    return try await coreDataActor.performViewContextTask { context in
        // ...
    }
}
```

**Solution Strategy**:
1. **Sendable Conformance**: Add proper Sendable conformance to aggregates
2. **Thread Safety**: Ensure internal state is thread-safe
3. **Pattern Consistency**: Follow AppCore patterns for similar types

**Implementation Steps**:
```swift
// Make domain aggregates Sendable
public final class AcquisitionAggregate: Sendable {
    // Use immutable properties or proper synchronization
    private let _id: UUID
    private let _status: AcquisitionStatus
    
    // Thread-safe access patterns
    public var id: UUID { _id }
    public var status: AcquisitionStatus { _status }
}
```

**Effort Estimate**: 8-10 hours  
**Owner**: Domain Team  
**Target Completion**: July 23, 2025  
**Success Criteria**: Async repository operations compile without errors  

---

#### Task 1.3: Build Validation and Integration Testing
**⚠️ HIGH PRIORITY - VALIDATION**

**Description**: Comprehensive testing of fixes to ensure no regressions and successful integration.

**Activities**:
1. **Compilation Testing**: All targets build successfully
2. **Unit Test Validation**: Existing tests continue to pass
3. **Integration Testing**: Services layer functions correctly
4. **Performance Testing**: Build times remain optimized

**Implementation Steps**:
```bash
# Validation Script
#!/bin/bash
echo "🔨 Building all targets..."
swift build --target AikoCompat
swift build --target AppCore  
swift build --target AIKOiOS
swift build --target AIKOmacOS
swift build --target AIKO

echo "🧪 Running tests..."
swift test

echo "⏱️ Performance check..."
time swift build
```

**Effort Estimate**: 6 hours  
**Owner**: QA Team  
**Target Completion**: July 24, 2025  
**Success Criteria**: All targets build, tests pass, performance maintained  

---

## ⚠️ MEDIUM PRIORITY: Sendable Conformance (Week 2)

### Priority 2A: Complete Data Type Sendable Coverage

#### Task 2.1: Service Layer DTOs and Models
**📊 MEDIUM - ENABLES STRICT CONCURRENCY**

**Description**: Add Sendable conformance to remaining data types in services layer.

**Target Types**:
- `FormRecommendation`
- `FormGuidance`
- Service request/response DTOs
- Configuration models

**Files Affected**:
- `Sources/Services/` - Various service implementation files
- `Sources/Models/` - Data transfer objects
- `Sources/Infrastructure/` - Configuration models

**Solution Strategy**:
1. **Systematic Review**: Audit all public types in services layer
2. **Sendable Analysis**: Determine which types can be made Sendable
3. **Safe Implementation**: Add conformance without breaking existing code

**Implementation Example**:
```swift
// Before
public struct FormRecommendation {
    public let content: String
    public let confidence: Double
    public let metadata: [String: Any] // Problem: Any is not Sendable
}

// After
public struct FormRecommendation: Sendable {
    public let content: String
    public let confidence: Double
    public let metadata: [String: String] // Sendable alternative
}
```

**Effort Estimate**: 10-12 hours  
**Owner**: Services Team  
**Target Completion**: July 30, 2025  
**Success Criteria**: 90%+ of service layer types are Sendable  

---

#### Task 2.2: UI Layer Model Updates
**🎨 MEDIUM - UI LAYER COMPLIANCE**

**Description**: Ensure UI layer models and view state types have proper Sendable conformance.

**Target Areas**:
- View models and state objects
- UI configuration types
- Feature-specific models

**Files Affected**:
- `Sources/Views/` - View implementation files
- `Sources/Features/` - Feature-specific models
- `Sources/UI/` - UI utility types

**Solution Strategy**:
1. **View Model Analysis**: Review TCA state and action types
2. **Configuration Safety**: Ensure UI configuration types are Sendable
3. **Feature Isolation**: Maintain feature boundaries while adding compliance

**Implementation Pattern**:
```swift
// TCA State with Sendable conformance
public struct AcquisitionsListState: Sendable {
    public var acquisitions: IdentifiedArrayOf<AppCore.Acquisition> = []
    public var isLoading: Bool = false
    public var selectedAcquisition: AppCore.Acquisition?
}

// TCA Action with Sendable conformance
public enum AcquisitionsListAction: Sendable {
    case loadAcquisitions
    case acquisitionSelected(AppCore.Acquisition)
    case acquisitionUpdated(AppCore.Acquisition)
}
```

**Effort Estimate**: 8-10 hours  
**Owner**: UI Team  
**Target Completion**: July 31, 2025  
**Success Criteria**: UI layer builds with strict concurrency enabled  

---

### Priority 2B: Actor Boundary Optimization

#### Task 2.3: Service Layer Actor Boundaries
**🏗️ MEDIUM - ARCHITECTURE OPTIMIZATION**

**Description**: Define and implement clear actor boundaries for service layer operations.

**Target Services**:
- `AcquisitionService`
- `DocumentChainManager`
- `GovernmentFormService`
- Background processing services

**Solution Strategy**:
1. **Boundary Analysis**: Identify natural actor boundaries
2. **Pattern Application**: Use successful patterns from AppCore
3. **Performance Optimization**: Ensure minimal actor boundary crossings

**Implementation Pattern**:
```swift
// Service with clear actor boundary
actor AcquisitionService {
    private let repository: AcquisitionRepository
    private let coreDataActor: CoreDataActor
    
    public func createAcquisition(
        from request: AppCore.Acquisition
    ) async throws -> AppCore.Acquisition {
        // All service operations isolated within actor
        return try await repository.create(from: request)
    }
}
```

**Effort Estimate**: 12-15 hours  
**Owner**: Architecture Team  
**Target Completion**: August 1, 2025  
**Success Criteria**: Clear actor boundaries, optimized performance  

---

## 🔧 LOW PRIORITY: Cleanup & Optimization (Week 3)

### Priority 3A: Code Cleanup and Maintenance

#### Task 3.1: Remove Deprecated CoreDataActor Methods
**🧹 LOW - CODE MAINTENANCE**

**Description**: Clean up deprecated methods in CoreDataActor that are no longer needed.

**Files Affected**:
- `Sources/Infrastructure/CoreDataActor.swift`
- Related test files

**Activities**:
1. **Method Review**: Identify all deprecated methods
2. **Usage Audit**: Ensure no remaining references
3. **Safe Removal**: Remove deprecated code safely

**Effort Estimate**: 3-4 hours  
**Owner**: Infrastructure Team  
**Target Completion**: August 5, 2025  
**Success Criteria**: Cleaner CoreDataActor interface  

---

#### Task 3.2: Eliminate @unchecked Sendable Annotations
**🛡️ LOW - SAFETY IMPROVEMENT**

**Description**: Replace all `@unchecked Sendable` annotations with proper Sendable conformance.

**Approach**:
1. **Audit Phase**: Find all @unchecked usages
2. **Analysis Phase**: Determine proper Sendable implementation for each
3. **Replacement Phase**: Implement proper conformance

**Search Strategy**:
```bash
# Find all @unchecked Sendable usages
grep -r "@unchecked Sendable" Sources/
```

**Implementation Strategy**:
```swift
// Before: Unsafe annotation
extension ThirdPartyType: @unchecked Sendable {}

// After: Proper wrapper
actor ThirdPartyWrapper: Sendable {
    private let wrapped: ThirdPartyType
    
    func safeMethod() async -> SendableResult {
        // Safe wrapper implementation
    }
}
```

**Effort Estimate**: 6-8 hours  
**Owner**: All Teams (distributed)  
**Target Completion**: August 6, 2025  
**Success Criteria**: Zero @unchecked Sendable annotations remain  

---

### Priority 3B: Final Validation and Documentation

#### Task 3.3: Enable Strict Concurrency for AIKO Target
**🎯 TARGET - FINAL ENABLEMENT**

**Description**: Change main AIKO target from minimal to complete strict concurrency.

**File**: `Package.swift`

**Change**:
```swift
// Current
.target(
    name: "AIKO",
    // ...
    swiftSettings: [
        .unsafeFlags(["-strict-concurrency=minimal"]),
    ]
)

// Target
.target(
    name: "AIKO", 
    // ...
    swiftSettings: [
        .unsafeFlags(["-strict-concurrency=complete"]),
    ]
)
```

**Validation Steps**:
1. **Compilation Test**: Ensure clean build
2. **Warning Analysis**: Address any new warnings
3. **Performance Test**: Verify build performance
4. **Integration Test**: Full application testing

**Effort Estimate**: 4-6 hours  
**Owner**: Build Team  
**Target Completion**: August 7, 2025  
**Success Criteria**: AIKO target builds with strict concurrency complete  

---

#### Task 3.4: Comprehensive Testing and Validation
**🧪 VALIDATION - QUALITY ASSURANCE**

**Description**: Final comprehensive testing to ensure migration success and quality.

**Testing Categories**:

1. **Compilation Testing**
   - All 5 targets build successfully
   - Build times remain optimized (< 5 seconds each)
   - No warnings with strict concurrency enabled

2. **Functional Testing**
   - All existing features work correctly
   - No regressions in functionality
   - Async operations perform correctly

3. **Performance Testing**
   - App launch time maintained
   - UI responsiveness preserved
   - Memory usage optimized

4. **Concurrency Safety Testing**
   - No data races in concurrent operations
   - Proper actor isolation maintained
   - Thread safety verified

**Test Script**:
```bash
#!/bin/bash
echo "🏗️ Full Build Test"
swift build --target AIKO

echo "🧪 Unit Test Suite"
swift test

echo "⚡ Performance Test"
time swift build

echo "🔍 Static Analysis"
# Run any static analysis tools

echo "✅ Migration Complete!"
```

**Effort Estimate**: 16-20 hours  
**Owner**: QA Team + All Teams  
**Target Completion**: August 8, 2025  
**Success Criteria**: All tests pass, performance maintained, zero concurrency issues  

---

## 📊 Resource Allocation & Timeline

### Team Assignments

| Team | Primary Responsibility | Time Allocation | Key Tasks |
|------|----------------------|-----------------|-----------|
| **Infrastructure** | Core compilation fixes | 40% | Typealias fixes, CoreDataActor cleanup |
| **Domain** | Sendable conformance | 30% | Domain aggregates, event sourcing |
| **Services** | Service layer compliance | 35% | DTOs, actor boundaries |
| **UI** | View layer updates | 25% | UI models, TCA state |
| **Architecture** | Pattern definition | 30% | Actor boundaries, optimization |
| **QA** | Testing & validation | 50% | Comprehensive testing |

### Weekly Schedule

#### Week 1: Critical Fixes (July 22-26, 2025)
- **Monday-Tuesday**: Typealias conflict resolution
- **Tuesday-Wednesday**: Core Sendable conformance
- **Thursday-Friday**: Build validation and testing

#### Week 2: Complete Implementation (July 29 - August 2, 2025)
- **Monday-Tuesday**: Service layer Sendable coverage
- **Wednesday**: UI layer model updates
- **Thursday-Friday**: Actor boundary optimization

#### Week 3: Final Validation (August 5-8, 2025)
- **Monday**: Code cleanup and deprecated removal
- **Tuesday-Wednesday**: @unchecked Sendable elimination
- **Thursday**: Enable strict concurrency for AIKO target
- **Friday**: Comprehensive testing and validation

### Effort Summary

| Priority Level | Total Effort | Timeline | Success Rate |
|----------------|--------------|----------|--------------|
| **High Priority** | 20-24 hours | Week 1 | **Critical** |
| **Medium Priority** | 30-37 hours | Week 2 | **Important** |
| **Low Priority** | 29-38 hours | Week 3 | **Quality** |
| **Total Effort** | **79-99 hours** | **3 weeks** | **High Confidence** |

---

## ⚠️ Risk Management

### Risk Mitigation Strategies

#### High-Impact Risks

1. **Typealias Conflicts Complexity**
   - **Risk**: More complex resolution needed than anticipated
   - **Mitigation**: Use proven patterns from type conflict resolution work
   - **Fallback**: Explicit module qualification throughout

2. **Sendable Conformance Dependencies**
   - **Risk**: Cascade of required changes for complex types
   - **Mitigation**: Incremental approach, wrapper patterns for complex cases
   - **Fallback**: Strategic @unchecked usage with TODO comments

3. **Performance Regression**
   - **Risk**: Actor boundaries impact performance
   - **Mitigation**: Performance testing at each stage, optimization focus
   - **Fallback**: Adjust actor boundaries based on profiling

#### Medium-Impact Risks

4. **Timeline Pressure**
   - **Risk**: Tasks take longer than estimated
   - **Mitigation**: Focus on high priority items first, incremental progress
   - **Fallback**: Extend timeline while maintaining quality

5. **Integration Issues**
   - **Risk**: Changes break existing functionality
   - **Mitigation**: Comprehensive testing, incremental changes
   - **Fallback**: Rollback capability, feature flags

### Monitoring and Reporting

#### Daily Standup Focus
- **Blockers**: Any compilation or integration issues
- **Progress**: Percentage complete for current sprint tasks
- **Quality**: Test results and performance metrics

#### Weekly Reviews
- **Progress Assessment**: Completed vs planned work
- **Quality Metrics**: Build times, test coverage, performance
- **Risk Review**: New risks identified, mitigation effectiveness

---

## 🎯 Success Criteria & Acceptance

### Technical Success Criteria

#### Build Requirements ✅
- [ ] All 5 targets build with `-strict-concurrency=complete`
- [ ] Build times remain under 5 seconds per target
- [ ] Zero compilation warnings related to concurrency

#### Code Quality Requirements ✅
- [ ] No `@unchecked Sendable` annotations remain
- [ ] Clear actor boundaries documented and implemented
- [ ] All public types have appropriate Sendable conformance

#### Functional Requirements ✅
- [ ] All existing features continue to work
- [ ] No performance regressions
- [ ] Async operations perform correctly

### Business Success Criteria

#### Future-Proofing ✅
- [ ] Codebase ready for Swift 6 and beyond
- [ ] Modern concurrency patterns established
- [ ] Technical debt significantly reduced

#### Developer Experience ✅
- [ ] Clean, maintainable code structure
- [ ] Clear patterns for future development
- [ ] Excellent build performance maintained

### Documentation Requirements ✅
- [ ] Migration patterns documented
- [ ] Best practices guide created
- [ ] Code review guidelines updated

---

## 🚀 Next Actions

### Immediate Actions (Next 24 Hours)
1. **Team Kickoff**: Review action plan with all teams
2. **Environment Setup**: Ensure development environments ready
3. **Begin Task 1.1**: Start typealias conflict resolution

### Week 1 Deliverables
- ✅ All compilation errors resolved
- ✅ Core domain types have Sendable conformance
- ✅ Infrastructure layer builds cleanly

### Final Milestone
- ✅ **Target Date**: August 8, 2025
- ✅ **Deliverable**: 100% Swift 6 compliant AIKO project
- ✅ **Quality**: Zero warnings, comprehensive test coverage
- ✅ **Performance**: Optimized build times and runtime performance

---

**Action Plan Prepared By**: Swift Migration Team  
**Approved By**: Technical Leadership  
**Review Schedule**: Daily standups + Weekly progress reviews  
**Escalation Path**: Technical Lead → Engineering Manager → CTO