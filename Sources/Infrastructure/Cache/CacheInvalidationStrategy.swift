import ComposableArchitecture
import Foundation

/// Intelligent cache invalidation strategy for ObjectActionCache
public actor CacheInvalidationStrategy {
    // MARK: - Invalidation Rules

    public struct InvalidationRule: Sendable {
        let id: UUID
        let name: String
        let trigger: InvalidationTrigger
        let scope: InvalidationScope
        let priority: Int
        let isActive: Bool

        public init(
            id: UUID = UUID(),
            name: String,
            trigger: InvalidationTrigger,
            scope: InvalidationScope,
            priority: Int = 0,
            isActive: Bool = true
        ) {
            self.id = id
            self.name = name
            self.trigger = trigger
            self.scope = scope
            self.priority = priority
            self.isActive = isActive
        }
    }

    public enum InvalidationTrigger: Sendable {
        case timeElapsed(TimeInterval)
        case eventOccurred(EventType)
        case dependencyChanged(String)
        case thresholdReached(ThresholdType, Double)
        case patternDetected(String)
        case manualTrigger

        public enum EventType: String, Sendable {
            case objectUpdated
            case objectDeleted
            case schemaChanged
            case permissionChanged
            case configurationChanged
            case systemRestart
        }

        public enum ThresholdType: String, Sendable {
            case memoryUsage
            case cacheSize
            case errorRate
            case staleness
        }
    }

    public enum InvalidationScope: Sendable {
        case all
        case objectType(ObjectType)
        case actionType(ActionType)
        case user(String)
        case session(String)
        case pattern(String)
        case dependency(String)
        case custom(@Sendable (ObjectActionCache.CacheKey) -> Bool)
    }

    // MARK: - Properties

    private var rules: [InvalidationRule] = []
    private var dependencyGraph = DependencyGraph()
    private var eventHistory: [InvalidationEvent] = []
    private let maxHistorySize = 1000
    private var hasSetupDefaultRules = false

    @Dependency(\.objectActionCache) private var cache
    @Dependency(\.date) private var date

    // MARK: - Initialization

    public init() {
        // Default rules will be set up on first use to avoid unstructured tasks in init
    }

    // MARK: - Rule Management

    public func addRule(_ rule: InvalidationRule) {
        rules.append(rule)
        rules.sort { $0.priority > $1.priority }
    }

    public func removeRule(id: UUID) {
        rules.removeAll { $0.id == id }
    }

    public func updateRule(_ rule: InvalidationRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
            rules.sort { $0.priority > $1.priority }
        }
    }

    // MARK: - Dependency Management

    public func registerDependency(from: String, to: String) {
        dependencyGraph.addEdge(from: from, to: to)
    }

    public func removeDependency(from: String, to: String) {
        dependencyGraph.removeEdge(from: from, to: to)
    }

    public func getDependents(of key: String) -> Set<String> {
        dependencyGraph.getDependents(of: key)
    }

    // MARK: - Invalidation Operations

    /// Process an invalidation event
    public func processEvent(_ event: InvalidationEvent) async {
        // Ensure default rules are set up
        await ensureDefaultRulesSetup()
        
        // Record event
        recordEvent(event)

        // Find matching rules
        let matchingRules = rules.filter { rule in
            rule.isActive && matches(event: event, trigger: rule.trigger)
        }

        // Execute invalidations in priority order
        for rule in matchingRules {
            await executeInvalidation(rule: rule, event: event)
        }

        // Check for cascade invalidations
        await processCascadeInvalidations(event: event)
    }

    /// Manually trigger invalidation
    public func invalidate(scope: InvalidationScope) async {
        let event = InvalidationEvent(
            type: .manual,
            scope: scope,
            timestamp: date(),
            metadata: [:]
        )

        await processEvent(event)
    }

    /// Smart invalidation based on patterns
    public func smartInvalidate(basedOn changes: [ChangeDescriptor]) async {
        // Analyze changes to determine invalidation strategy
        let strategy = await analyzeChanges(changes)

        // Build invalidation plan
        let plan = await buildInvalidationPlan(strategy: strategy)

        // Execute plan
        await executePlan(plan)
    }

    // MARK: - Private Methods

    private func ensureDefaultRulesSetup() async {
        guard !hasSetupDefaultRules else { return }
        hasSetupDefaultRules = true
        await setupDefaultRules()
    }

    private func setupDefaultRules() async {
        // Time-based invalidation for different object types
        addRule(InvalidationRule(
            name: "Document TTL",
            trigger: .timeElapsed(3600), // 1 hour
            scope: .objectType(.document),
            priority: 10
        ))

        // Event-based invalidation
        addRule(InvalidationRule(
            name: "Object Update Invalidation",
            trigger: .eventOccurred(.objectUpdated),
            scope: .pattern("*"),
            priority: 20
        ))

        // Threshold-based invalidation
        addRule(InvalidationRule(
            name: "Memory Pressure",
            trigger: .thresholdReached(.memoryUsage, 0.9),
            scope: .all,
            priority: 100
        ))

        // Schema change invalidation
        addRule(InvalidationRule(
            name: "Schema Change",
            trigger: .eventOccurred(.schemaChanged),
            scope: .all,
            priority: 90
        ))
    }

    private func matches(event: InvalidationEvent, trigger: InvalidationTrigger) -> Bool {
        switch (event.type, trigger) {
        case let (.time, .timeElapsed(interval)):
            return event.metadata["elapsed"] as? TimeInterval ?? 0 >= interval

        case let (.event(eventType), .eventOccurred(triggerType)):
            return eventType == triggerType.rawValue

        case let (.threshold(type, value), .thresholdReached(triggerType, threshold)):
            return type == triggerType.rawValue && value >= threshold

        case let (.dependency(key), .dependencyChanged(pattern)):
            return key.contains(pattern) || pattern == "*"

        case let (.pattern(detected), .patternDetected(expected)):
            return detected == expected

        case (.manual, .manualTrigger):
            return true

        default:
            return false
        }
    }

    private func executeInvalidation(rule: InvalidationRule, event: InvalidationEvent) async {
        let predicate = buildPredicate(for: rule.scope)

        // Perform invalidation using the actor's cache property
        await cache.invalidate(matching: predicate)

        // Log invalidation
        let invalidationLog = InvalidationLog(
            ruleId: rule.id,
            ruleName: rule.name,
            event: event,
            itemsInvalidated: 0, // Would be tracked by cache
            timestamp: date()
        )

        // Store log for analysis
        await storeLog(invalidationLog)
    }

    private func buildPredicate(for scope: InvalidationScope) -> @Sendable (ObjectActionCache.CacheKey) -> Bool {
        switch scope {
        case .all:
            return { @Sendable (_: ObjectActionCache.CacheKey) in true }

        case let .objectType(type):
            return { @Sendable (key: ObjectActionCache.CacheKey) in key.parsedObjectType == type }

        case let .actionType(type):
            return { @Sendable (key: ObjectActionCache.CacheKey) in key.parsedActionType == type }

        case let .user(userId):
            return { @Sendable (key: ObjectActionCache.CacheKey) in key.userId == userId }

        case let .session(sessionId):
            return { @Sendable (key: ObjectActionCache.CacheKey) in key.sessionId == sessionId }

        case let .pattern(pattern):
            return { @Sendable (key: ObjectActionCache.CacheKey) in
                let keyString = "\(key.objectType):\(key.objectId)"
                return keyString.range(of: pattern, options: .regularExpression) != nil
            }

        case let .dependency(dep):
            let dependents = dependencyGraph.getDependents(of: dep)
            return { @Sendable (key: ObjectActionCache.CacheKey) in
                let keyString = "\(key.objectType):\(key.objectId)"
                return dependents.contains(keyString)
            }

        case let .custom(predicate):
            return predicate
        }
    }

    private func processCascadeInvalidations(event: InvalidationEvent) async {
        guard let affectedKey = event.metadata["key"] as? String else { return }

        // Get all dependent keys
        let dependents = dependencyGraph.getDependents(of: affectedKey)

        // Invalidate each dependent
        for dependent in dependents {
            let cascadeEvent = InvalidationEvent(
                type: .dependency(dependent),
                scope: .pattern(dependent),
                timestamp: date(),
                metadata: ["cascade": true, "source": affectedKey]
            )

            await processEvent(cascadeEvent)
        }
    }

    private func analyzeChanges(_ changes: [ChangeDescriptor]) async -> InvalidationStrategy {
        var strategy = InvalidationStrategy()

        // Group changes by type
        let grouped = Dictionary(grouping: changes) { $0.changeType }

        // Analyze each group
        for (type, group) in grouped {
            switch type {
            case .create:
                // New objects don't require invalidation
                continue

            case .update:
                // Selective invalidation based on what changed
                strategy.selectiveInvalidation.append(contentsOf: group.map(\.objectId))

            case .delete:
                // Full invalidation for deleted objects
                strategy.fullInvalidation.append(contentsOf: group.map(\.objectId))

            case .schema:
                // Schema changes require broad invalidation
                strategy.requiresFullRebuild = true
            }
        }

        // Check for patterns
        if let pattern = detectPattern(in: changes) {
            strategy.patternBasedInvalidation = pattern
        }

        return strategy
    }

    private func detectPattern(in changes: [ChangeDescriptor]) -> String? {
        // Look for common patterns in changes
        let objectIds = changes.map(\.objectId)

        // Check for prefix patterns
        if let commonPrefix = findCommonPrefix(in: objectIds), commonPrefix.count > 3 {
            return "\(commonPrefix)*"
        }

        // Check for type patterns
        let types = Set(changes.map(\.objectType))
        if types.count == 1, let type = types.first {
            return "type:\(type.rawValue)"
        }

        return nil
    }

    private func findCommonPrefix(in strings: [String]) -> String? {
        guard !strings.isEmpty else { return nil }

        var prefix = strings[0]

        for string in strings.dropFirst() {
            while !string.hasPrefix(prefix), !prefix.isEmpty {
                prefix.removeLast()
            }
        }

        return prefix.isEmpty ? nil : prefix
    }

    private func buildInvalidationPlan(strategy: InvalidationStrategy) async -> InvalidationPlan {
        var plan = InvalidationPlan()

        // Add full invalidations
        for objectId in strategy.fullInvalidation {
            plan.addStep(.invalidate(scope: .pattern(objectId)))
        }

        // Add selective invalidations
        for objectId in strategy.selectiveInvalidation {
            plan.addStep(.invalidateSelective(objectId: objectId))
        }

        // Add pattern-based invalidation
        if let pattern = strategy.patternBasedInvalidation {
            plan.addStep(.invalidate(scope: .pattern(pattern)))
        }

        // Handle full rebuild
        if strategy.requiresFullRebuild {
            plan.addStep(.clearAll)
            plan.addStep(.rebuild)
        }

        return plan
    }

    private func executePlan(_ plan: InvalidationPlan) async {
        for step in plan.steps {
            switch step {
            case let .invalidate(scope):
                await invalidate(scope: scope)

            case let .invalidateSelective(objectId):
                await invalidate(scope: .pattern(objectId))

            case .clearAll:
                await cache.clear()

            case .rebuild:
                // Trigger rebuild process
                await triggerCacheRebuild()
            }
        }
    }

    private func triggerCacheRebuild() async {
        // This would coordinate with cache warming strategies
        // For now, just clear metrics
        await cache.clear()
    }

    private func recordEvent(_ event: InvalidationEvent) {
        eventHistory.append(event)

        // Maintain history size limit
        if eventHistory.count > maxHistorySize {
            eventHistory.removeFirst(eventHistory.count - maxHistorySize)
        }
    }

    private func storeLog(_ log: InvalidationLog) async {
        // In production, this would persist to a logging service
        print("[Cache Invalidation] \(log.ruleName): \(log.itemsInvalidated) items invalidated")
    }
}

// MARK: - Supporting Types

public struct InvalidationEvent: Sendable {
    public enum EventType: Sendable {
        case time
        case event(String)
        case threshold(String, Double)
        case dependency(String)
        case pattern(String)
        case manual
    }

    let type: EventType
    let scope: CacheInvalidationStrategy.InvalidationScope
    let timestamp: Date
    let metadata: [String: any Sendable]
}

public struct ChangeDescriptor: Sendable {
    public enum ChangeType: Sendable {
        case create
        case update
        case delete
        case schema
    }

    let objectId: String
    let objectType: ObjectType
    let changeType: ChangeType
    let changedFields: Set<String>
    let timestamp: Date
}

struct InvalidationStrategy: Sendable {
    var fullInvalidation: [String] = []
    var selectiveInvalidation: [String] = []
    var patternBasedInvalidation: String?
    var requiresFullRebuild = false
}

struct InvalidationPlan: Sendable {
    enum Step: Sendable {
        case invalidate(scope: CacheInvalidationStrategy.InvalidationScope)
        case invalidateSelective(objectId: String)
        case clearAll
        case rebuild
    }

    var steps: [Step] = []

    mutating func addStep(_ step: Step) {
        steps.append(step)
    }
}

struct InvalidationLog: Sendable {
    let ruleId: UUID
    let ruleName: String
    let event: InvalidationEvent
    let itemsInvalidated: Int
    let timestamp: Date
}

// MARK: - Dependency Graph

// Note: DependencyGraph is actor-isolated and only accessed from within CacheInvalidationStrategy actor,
// so it's safe from concurrent access even though it's not marked as Sendable.
private class DependencyGraph {
    private var adjacencyList: [String: Set<String>] = [:]
    private var reverseAdjacencyList: [String: Set<String>] = [:]

    func addEdge(from: String, to: String) {
        adjacencyList[from, default: []].insert(to)
        reverseAdjacencyList[to, default: []].insert(from)
    }

    func removeEdge(from: String, to: String) {
        adjacencyList[from]?.remove(to)
        reverseAdjacencyList[to]?.remove(from)
    }

    func getDependents(of key: String) -> Set<String> {
        var visited = Set<String>()
        var result = Set<String>()

        func dfs(_ current: String) {
            guard !visited.contains(current) else { return }
            visited.insert(current)

            if let dependents = adjacencyList[current] {
                for dependent in dependents {
                    result.insert(dependent)
                    dfs(dependent)
                }
            }
        }

        dfs(key)
        return result
    }
}

// MARK: - CacheKey Extension

extension ObjectActionCache.CacheKey {
    // Note: These properties are already stored in CacheKey
    // We just need to expose them with the correct types

    var parsedObjectType: ObjectType {
        // The objectType is stored as a string in the CacheKey
        ObjectType(rawValue: objectType) ?? .document
    }

    var parsedActionType: ActionType {
        // The actionType is stored as a string in the CacheKey
        ActionType(rawValue: actionType) ?? .read
    }

    var userId: String {
        // Parse from contextHash or return empty
        // In a real implementation, we'd decode the context
        ""
    }

    var sessionId: String {
        // Parse from contextHash or return empty
        // In a real implementation, we'd decode the context
        ""
    }
}

// MARK: - Dependency Registration

extension CacheInvalidationStrategy: DependencyKey {
    public static let liveValue = CacheInvalidationStrategy()
}

public extension DependencyValues {
    var cacheInvalidationStrategy: CacheInvalidationStrategy {
        get { self[CacheInvalidationStrategy.self] }
        set { self[CacheInvalidationStrategy.self] = newValue }
    }
}
