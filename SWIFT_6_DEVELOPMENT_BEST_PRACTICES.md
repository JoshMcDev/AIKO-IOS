# Swift 6 Development Best Practices Guide

**Project**: AIKO Swift 6 Strict Concurrency Migration  
**Document Type**: Development Team Guidelines  
**Last Updated**: July 20, 2025  
**Applicable To**: All Development Teams  

---

## 🎯 Overview

This guide provides comprehensive best practices for maintaining Swift 6 strict concurrency compliance based on lessons learned during the AIKO migration. These practices ensure long-term code quality, safety, and maintainability.

---

## 🏗️ Architecture Patterns

### ✅ Proven Successful Patterns

#### 1. Module-by-Module Concurrency Adoption

**Pattern**: Enable strict concurrency one module at a time

```swift
// Package.swift - Incremental enablement
.target(
    name: "CoreModule",
    swiftSettings: [
        .unsafeFlags(["-strict-concurrency=complete"]) // ✅ Start here
    ]
),
.target(
    name: "FeatureModule", 
    dependencies: ["CoreModule"],
    swiftSettings: [
        .unsafeFlags(["-strict-concurrency=minimal"]) // 🔄 Enable next
    ]
)
```

**Benefits**:
- Isolated changes and testing
- Clear progress tracking
- Reduced risk and easier rollback
- Incremental learning and expertise building

**When to Use**: Always for new concurrency adoption projects

---

#### 2. Compatibility Layer for Third-Party Dependencies

**Pattern**: Wrap non-Sendable dependencies in Sendable actors

```swift
// ✅ CORRECT: Compatibility wrapper
actor ThirdPartyServiceWrapper {
    private let service: NonSendableThirdPartyService
    
    init(apiKey: String) {
        self.service = NonSendableThirdPartyService(apiKey: apiKey)
    }
    
    func performOperation(input: SendableInput) async throws -> SendableOutput {
        // Safe async wrapper around non-Sendable API
        let result = try await service.performOperation(input.toThirdPartyFormat())
        return SendableOutput(from: result)
    }
}

// ❌ AVOID: Direct usage of non-Sendable types
class UnsafeService {
    func operation() async {
        let service = NonSendableThirdPartyService() // Compiler error!
        await service.performOperation()
    }
}
```

**Benefits**:
- Maintains safety while using necessary dependencies
- Clear isolation boundary
- Easy to update when dependencies become Sendable
- Testable through protocol abstraction

**When to Use**: Any time you need non-Sendable third-party libraries

---

#### 3. Clear Type Qualification Strategy

**Pattern**: Use explicit module prefixes to resolve type conflicts

```swift
// ✅ CORRECT: Explicit type qualification
import AppCore
import CoreData

class AcquisitionService {
    func convert(_ coreDataEntity: AIKO.Acquisition) -> AppCore.Acquisition {
        // Clear distinction between types
        return AppCore.Acquisition(
            id: coreDataEntity.id,
            status: AppCore.AcquisitionStatus(from: coreDataEntity.status)
        )
    }
}

// ✅ ALTERNATIVE: File-scoped typealias
import AppCore
import CoreData

private typealias CoreDataAcquisition = AIKO.Acquisition
private typealias BusinessAcquisition = AppCore.Acquisition

class AcquisitionService {
    func convert(_ entity: CoreDataAcquisition) -> BusinessAcquisition {
        // Clear, readable code
    }
}

// ❌ AVOID: Ambiguous type references
import AppCore
import CoreData

class AcquisitionService {
    func convert(_ entity: Acquisition) -> Acquisition { // Which Acquisition?
        // Compiler confusion and developer confusion
    }
}
```

**Benefits**:
- Eliminates compilation ambiguity
- Self-documenting code
- Easier maintenance and refactoring
- Clear architectural boundaries

**When to Use**: Any time you have types with the same name in different modules

---

#### 4. Actor-Based Data Access

**Pattern**: Isolate data access behind dedicated actors

```swift
// ✅ CORRECT: Actor-based Core Data access
actor CoreDataActor {
    private let container: NSPersistentContainer
    
    func performViewContextTask<T: Sendable>(
        _ operation: @Sendable @escaping (NSManagedObjectContext) throws -> T
    ) async rethrows -> T {
        return try await withCheckedThrowingContinuation { continuation in
            container.viewContext.perform {
                do {
                    let result = try operation(container.viewContext)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// ✅ USAGE: Safe repository pattern
actor AcquisitionRepository {
    private let coreDataActor: CoreDataActor
    
    func findAll() async throws -> [AppCore.Acquisition] {
        return try await coreDataActor.performViewContextTask { context in
            let request = NSFetchRequest<AIKO.Acquisition>(entityName: "Acquisition")
            let entities = try context.fetch(request)
            return entities.map { $0.toAppCoreModel() }
        }
    }
}

// ❌ AVOID: Direct Core Data access from multiple threads
class UnsafeRepository {
    private let context: NSManagedObjectContext
    
    func findAll() async throws -> [AppCore.Acquisition] {
        // Threading issues! NSManagedObjectContext is not Sendable
        let request = NSFetchRequest<AIKO.Acquisition>(entityName: "Acquisition")
        let entities = try context.fetch(request) // 💥 Crash risk
        return entities.map { $0.toAppCoreModel() }
    }
}
```

**Benefits**:
- Thread-safe data access
- Clear responsibility boundaries
- Excellent performance
- Easy to test and mock

**When to Use**: All Core Data access, database operations, shared resource access

---

## 🔒 Sendable Conformance Guidelines

### ✅ Safe Sendable Patterns

#### 1. Value Types with Sendable Properties

```swift
// ✅ CORRECT: Sendable struct with Sendable properties
public struct UserProfile: Sendable {
    public let id: UUID
    public let name: String
    public let email: String
    public let preferences: UserPreferences // Also Sendable
    public let createdAt: Date
}

// ✅ CORRECT: Sendable enum
public enum DocumentStatus: String, Sendable, CaseIterable {
    case draft = "draft"
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
}

// ❌ AVOID: Non-Sendable properties
public struct UnsafeProfile: Sendable {
    public let id: UUID
    public let name: String
    public var mutableData: NSMutableDictionary // Not Sendable!
}
```

#### 2. Reference Types with Immutable State

```swift
// ✅ CORRECT: Sendable class with immutable state
public final class ImmutableConfiguration: Sendable {
    public let apiEndpoint: URL
    public let timeout: TimeInterval
    public let headers: [String: String]
    
    public init(apiEndpoint: URL, timeout: TimeInterval, headers: [String: String]) {
        self.apiEndpoint = apiEndpoint
        self.timeout = timeout
        self.headers = headers
    }
}

// ✅ CORRECT: Sendable class with protected mutable state
public final class ThreadSafeCounter: Sendable {
    private let _value = OSAllocatedUnfairLock(initialState: 0)
    
    public var value: Int {
        _value.withLock { $0 }
    }
    
    public func increment() {
        _value.withLock { $0 += 1 }
    }
}

// ❌ AVOID: Mutable state without protection
public final class UnsafeCounter: Sendable {
    public var value: Int = 0 // Race condition risk!
    
    public func increment() {
        value += 1 // 💥 Data race
    }
}
```

#### 3. Actor-Based Reference Types

```swift
// ✅ CORRECT: Actor for mutable state
public actor UserSession {
    private var currentUser: User?
    private var authToken: String?
    private var lastActivity: Date = Date()
    
    public func login(user: User, token: String) {
        self.currentUser = user
        self.authToken = token
        self.lastActivity = Date()
    }
    
    public func getCurrentUser() -> User? {
        lastActivity = Date()
        return currentUser
    }
}

// ✅ USAGE: Safe from any context
func checkUserStatus() async {
    let session = UserSession()
    let user = await session.getCurrentUser()
    // Safe concurrent access
}
```

### ⚠️ Common Sendable Pitfalls

#### 1. Hidden Non-Sendable Properties

```swift
// ❌ PROBLEM: Non-Sendable closure capture
public struct EventHandler: Sendable {
    public let onEvent: (Event) -> Void // Closure might capture non-Sendable!
}

// ✅ SOLUTION: Use Sendable closure
public struct EventHandler: Sendable {
    public let onEvent: @Sendable (Event) -> Void
}

// ✅ ALTERNATIVE: Actor-based event handling
public actor EventProcessor {
    public func handleEvent(_ event: Event) {
        // Process event safely
    }
}
```

#### 2. Collection Type Issues

```swift
// ❌ PROBLEM: Non-Sendable collection elements
public struct Configuration: Sendable {
    public let settings: [String: Any] // Any is not Sendable!
}

// ✅ SOLUTION: Use Sendable alternatives
public struct Configuration: Sendable {
    public let settings: [String: ConfigurationValue]
}

public enum ConfigurationValue: Sendable {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case array([ConfigurationValue])
}
```

---

## 🔍 Code Review Guidelines

### 🎯 Concurrency Review Checklist

#### Pre-Merge Requirements

**✅ Compilation Check**
- [ ] All targets build with strict concurrency enabled
- [ ] Zero concurrency-related warnings
- [ ] No new `@unchecked Sendable` annotations without justification

**✅ Sendable Conformance Review**
- [ ] All public types have appropriate Sendable conformance
- [ ] No hidden non-Sendable properties in Sendable types
- [ ] Closures are marked `@Sendable` where appropriate

**✅ Actor Usage Review**
- [ ] Actor boundaries are logical and well-defined
- [ ] No unnecessary actor boundary crossings
- [ ] Actor state is properly encapsulated

**✅ Pattern Compliance Review**
- [ ] Follows established architectural patterns
- [ ] Uses approved patterns for common scenarios
- [ ] No direct usage of non-Sendable third-party types

#### Review Comments Template

```swift
// ✅ GOOD REVIEW COMMENT
// Consider using actor-based pattern here for thread safety:
// actor SafeService {
//     private var state: ServiceState
//     func updateState() { ... }
// }

// ✅ GOOD REVIEW COMMENT  
// This type should conform to Sendable since it's passed between actors:
// public struct UserData: Sendable { ... }

// ✅ GOOD REVIEW COMMENT
// Wrap this third-party dependency in our compatibility layer:
// let service = await ThirdPartyWrapper.shared.performOperation()
```

### 🚨 Red Flags to Watch For

#### Immediate Rejection Criteria

```swift
// 🚨 RED FLAG: @unchecked Sendable without justification
extension ThirdPartyType: @unchecked Sendable {}
// REQUIRED: TODO comment with tracking ticket and justification

// 🚨 RED FLAG: Direct actor state access
actor UserService {
    var currentUser: User? // Should be private!
}

// 🚨 RED FLAG: Non-Sendable closure in Sendable context
public struct Handler: Sendable {
    let callback: () -> Void // Should be @Sendable
}

// 🚨 RED FLAG: Mutable shared state without protection
public class SharedCache: Sendable {
    public var items: [String: Any] = [:] // Race condition!
}
```

---

## 🧪 Testing Strategies

### ✅ Concurrency Testing Patterns

#### 1. Actor Isolation Testing

```swift
import XCTest

class ActorIsolationTests: XCTestCase {
    
    func testActorStateIsolation() async throws {
        let service = UserService()
        
        // Test concurrent access doesn't cause data races
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    await service.updateUser(User(id: i))
                }
            }
        }
        
        let finalState = await service.getAllUsers()
        XCTAssertEqual(finalState.count, 100)
    }
}
```

#### 2. Sendable Conformance Testing

```swift
func testSendableConformance() {
    // Compile-time test: This must compile without warnings
    let data = UserData(id: UUID(), name: "Test")
    
    Task {
        // If this compiles, UserData is properly Sendable
        await processUserData(data)
    }
}

func processUserData(_ data: UserData) async {
    // Function that requires Sendable parameter
}
```

#### 3. Performance Testing for Actor Boundaries

```swift
func testActorPerformance() async throws {
    let service = DataService()
    
    let startTime = CFAbsoluteTimeGetCurrent()
    
    // Test multiple actor boundary crossings
    for _ in 0..<1000 {
        _ = await service.quickOperation()
    }
    
    let endTime = CFAbsoluteTimeGetCurrent()
    let duration = endTime - startTime
    
    // Assert reasonable performance
    XCTAssertLessThan(duration, 1.0, "Actor boundary crossings should be fast")
}
```

#### 4. Integration Testing for Concurrency

```swift
func testConcurrentServiceIntegration() async throws {
    let acquisitionService = AcquisitionService()
    let documentService = DocumentService()
    
    // Test services working together concurrently
    async let acquisitions = acquisitionService.fetchAll()
    async let documents = documentService.fetchAll()
    
    let (acqs, docs) = await (acquisitions, documents)
    
    // Verify no data corruption from concurrent access
    XCTAssertFalse(acqs.isEmpty)
    XCTAssertFalse(docs.isEmpty)
}
```

### 📊 Testing Metrics

#### Required Coverage
- **Actor Methods**: 100% coverage for all public actor methods
- **Sendable Types**: Compile-time verification for all Sendable conformance
- **Concurrent Operations**: Integration tests for all concurrent workflows
- **Performance**: Benchmarks for actor boundary crossing performance

#### Automated Testing
```bash
#!/bin/bash
# Automated concurrency testing script

echo "🔨 Building with strict concurrency..."
swift build -Xswiftc -strict-concurrency=complete

echo "🧪 Running concurrency tests..."
swift test --filter ConcurrencyTests

echo "⚡ Performance testing..."
swift test --filter PerformanceTests

echo "🔍 Static analysis..."
# Run static analysis tools for concurrency issues

echo "✅ All concurrency tests passed!"
```

---

## 🛡️ Preventive Measures

### 🔧 Development Environment Setup

#### 1. Compiler Flags Configuration

```swift
// Package.swift - Recommended settings
.target(
    name: "YourTarget",
    swiftSettings: [
        // Enable strict concurrency for new code
        .unsafeFlags(["-strict-concurrency=complete"]),
        
        // Additional helpful flags
        .unsafeFlags(["-warn-concurrency"]),
        .unsafeFlags(["-enable-actor-data-race-checks"])
    ]
)
```

#### 2. IDE Configuration

**Xcode Settings**:
- Enable "Swift Concurrency" warnings
- Set "Treat Warnings as Errors" for concurrency issues
- Configure code completion to suggest Sendable conformance

**VS Code Settings**:
```json
{
    "swift.diagnostics": {
        "concurrency": "error",
        "sendable": "error"
    }
}
```

#### 3. Pre-Commit Hooks

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "🔍 Checking Swift concurrency compliance..."

# Check for @unchecked Sendable without justification
if grep -r "@unchecked Sendable" Sources/ | grep -v "TODO\|FIXME"; then
    echo "❌ Found @unchecked Sendable without justification!"
    echo "Please add TODO comment with tracking ticket."
    exit 1
fi

# Verify strict concurrency builds
if ! swift build -Xswiftc -strict-concurrency=complete; then
    echo "❌ Failed to build with strict concurrency!"
    exit 1
fi

echo "✅ Concurrency checks passed!"
```

### 📚 Team Education & Training

#### 1. Onboarding Checklist

**New Team Member Concurrency Training**:
- [ ] Complete Swift Concurrency fundamentals course
- [ ] Review AIKO concurrency patterns documentation
- [ ] Pair program on actor-based service implementation
- [ ] Complete concurrency code review training
- [ ] Demonstrate understanding with small practice PR

#### 2. Regular Training Activities

**Monthly Concurrency Reviews**:
- Review recent concurrency-related bugs and solutions
- Share new patterns and best practices
- Discuss upcoming Swift concurrency features
- Practice code review scenarios

**Quarterly Deep Dives**:
- Performance optimization for actor-based designs
- Advanced Sendable conformance patterns
- Integration testing strategies for concurrent code

#### 3. Documentation Maintenance

**Living Documentation**:
- Keep this best practices guide updated with new learnings
- Document new patterns as they emerge
- Share lessons learned from production issues
- Maintain decision log for architectural choices

---

## 📈 Monitoring & Maintenance

### 🔍 Ongoing Monitoring

#### 1. Build Metrics

**Automated Tracking**:
```bash
#!/bin/bash
# Monitor build health for concurrency

echo "📊 Concurrency Build Metrics Report"
echo "=================================="

# Track build times with strict concurrency
echo "Build times:"
time swift build -Xswiftc -strict-concurrency=complete

# Count @unchecked Sendable usage
echo "@unchecked Sendable count:"
grep -r "@unchecked Sendable" Sources/ | wc -l

# Check for concurrency warnings
echo "Concurrency warnings:"
swift build -Xswiftc -strict-concurrency=complete 2>&1 | grep -i concurrency | wc -l
```

#### 2. Code Quality Metrics

**Weekly Reports**:
- Number of `@unchecked Sendable` annotations (target: decreasing)
- Percentage of types with Sendable conformance (target: increasing)
- Actor boundary crossing count (target: optimized)
- Concurrency-related bug count (target: zero)

#### 3. Performance Monitoring

**Runtime Metrics**:
- Actor contention monitoring
- Task creation/completion rates
- Memory usage patterns for actor-based code
- App responsiveness with concurrent operations

### 🔄 Continuous Improvement

#### 1. Pattern Evolution

**Regular Pattern Review**:
- Evaluate effectiveness of current patterns
- Identify opportunities for improvement
- Retire obsolete patterns
- Document new patterns as they emerge

#### 2. Tool Integration

**Development Tools**:
- Integrate concurrency linting into CI/CD
- Add performance regression detection
- Automate actor boundary analysis
- Create custom diagnostics for team-specific patterns

#### 3. Community Engagement

**External Learning**:
- Follow Swift Evolution proposals for concurrency
- Participate in Swift forums and communities
- Share learnings with broader Swift community
- Contribute to open source concurrency tools

---

## 🎯 Success Metrics

### 📊 Key Performance Indicators

#### Code Quality Metrics
- **Sendable Compliance**: 95%+ of public types
- **@unchecked Usage**: <5 instances with justification
- **Build Performance**: <5 seconds per target
- **Warning Count**: Zero concurrency warnings

#### Development Velocity Metrics
- **Review Time**: <2 hours for concurrency-related PRs
- **Bug Rate**: Zero concurrency-related production bugs
- **Onboarding Time**: <1 week for new developers to be productive

#### Business Impact Metrics
- **App Performance**: No regressions in user-facing performance
- **Reliability**: 99.9%+ uptime with concurrent operations
- **Future-Proofing**: Ready for Swift 6+ adoption

### 🏆 Long-Term Goals

#### 6-Month Targets
- [ ] Zero `@unchecked Sendable` annotations
- [ ] Complete actor-based architecture for all data access
- [ ] Comprehensive concurrency test coverage
- [ ] Developer expertise in advanced concurrency patterns

#### 12-Month Targets
- [ ] Contribution to Swift concurrency best practices community
- [ ] Custom tooling for concurrency analysis
- [ ] Mentorship program for other teams adopting Swift 6
- [ ] Performance optimization beyond baseline requirements

---

## 📚 Additional Resources

### 📖 Essential Reading
- [Swift Concurrency Manifesto](https://gist.github.com/lattner/31ed37682ef1576b16bca1432ea9f782)
- [WWDC 2024: Migrate your app to Swift 6](https://developer.apple.com/videos/play/wwdc2024/10169/)
- [Swift Evolution: Concurrency Proposals](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)

### 🛠️ Tools & Utilities
- [Swift Concurrency Checker](https://github.com/apple/swift-syntax)
- [Actor Performance Profiler](https://developer.apple.com/instruments/)
- [Sendable Conformance Analyzer](https://github.com/realm/SwiftLint)

### 🎯 Templates & Examples
- Actor-based service template
- Sendable data model template
- Concurrency test template
- Code review checklist template

---

**Best Practices Guide Maintained By**: Swift Concurrency Team  
**Review Frequency**: Monthly updates, quarterly major revisions  
**Feedback**: Submit issues to team repository  
**Version**: 1.0 (based on AIKO migration experience)