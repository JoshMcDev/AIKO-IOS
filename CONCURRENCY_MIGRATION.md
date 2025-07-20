# AIKO Concurrency Migration Plan

## Current Status (2025-01-20)

We have temporarily disabled strict concurrency checking in Package.swift to stop the unproductive "whack-a-mole" pattern of fixing individual Sendable conformance errors. This decision was made after a comprehensive multi-model AI consensus analysis that concluded:

1. **Option A (Fix one-by-one)**: Unsustainable, inefficient, and demoralizing
2. **Option B (Full refactor)**: Ideal end-state but too disruptive for immediate implementation
3. **Option C (Liberal suppression)**: Dangerous - hides real concurrency issues
4. **Option D (Temporary disable)**: Most pragmatic approach when followed by strategic planning

## Migration Strategy

### Phase 1: Immediate Actions (COMPLETED)
- ✅ Disabled strict concurrency with `-strict-concurrency=minimal` flag
- ✅ Documented the decision and migration plan
- ✅ Stopped the unproductive whack-a-mole fixing pattern

### Phase 2: Short-term Plan (1-2 weeks)
- [ ] Create `AikoCompat` module for non-Sendable dependencies
  - Wrap SwiftAnthropic in a Sendable-compliant actor
  - Isolate other third-party dependencies
- [ ] Identify and prioritize high-risk modules
  - Core Data layer (NSManagedObjectContext issues)
  - Services layer (non-Sendable closures)
  - Repositories (mixed actor isolation)
- [ ] Document current concurrency patterns and their issues
- [ ] Create detailed migration roadmap with priorities

### Phase 3: Medium-term Execution (1-3 months)
- [ ] Refactor Core Data access behind dedicated actor
  - Use background contexts for actor-based operations
  - Pass NSManagedObjectIDs (Sendable) between actors
- [ ] Convert Services to actors with clear boundaries
  - Define actor boundaries based on data flow
  - Eliminate non-Sendable closures
- [ ] Enable strict concurrency module-by-module
  - Start with new features in isolated modules
  - Gradually migrate existing modules
- [ ] Track @unchecked Sendable usage
  - Add TODO comments with migration tickets
  - Monitor count in CI

### Phase 4: Long-term Goals
- [ ] Re-enable strict concurrency globally
- [ ] Remove all @unchecked Sendable annotations
- [ ] Achieve full Swift 6 concurrency compliance

## Key Patterns to Implement

### 1. Core Data Actor Pattern
```swift
actor DataStore {
    private let container: NSPersistentContainer
    
    func fetch<T>(...) async throws -> [T] {
        let context = container.newBackgroundContext()
        // Perform fetch and return Sendable types
    }
}
```

### 2. Service Actor Pattern
```swift
actor NetworkService {
    func request<T: Sendable>(...) async throws -> T {
        // All networking isolated to this actor
    }
}
```

### 3. Compatibility Wrapper Pattern
```swift
actor AnthropicWrapper {
    private let client: SwiftAnthropic // Non-Sendable
    
    func createMessage(...) async throws -> MessageResponse {
        // Safe async wrapper around non-Sendable API
    }
}
```

## Tracking Progress

- All `@unchecked Sendable` annotations must include: `// TODO(CONC-####): reason, date, owner`
- CI script will monitor count of unsafe annotations
- Module-by-module migration status tracked in this document

## Success Criteria

1. Zero compiler warnings/errors with strict concurrency enabled
2. No @unchecked Sendable annotations
3. Clear actor boundaries throughout the codebase
4. All third-party dependencies properly wrapped
5. Comprehensive test coverage for concurrent operations

## References

- [Swift 6 Migration Guide](https://www.swift.org/migration/documentation/migrationguide/)
- [WWDC 2024: Migrate your app to Swift 6](https://developer.apple.com/videos/play/wwdc2024/10169/)
- VanillaIce Consensus Analysis: `~/ai-stack/aiko-concurrency-refactor-analysis.md`