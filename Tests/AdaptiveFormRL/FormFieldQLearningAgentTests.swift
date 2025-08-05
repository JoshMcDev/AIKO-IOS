@testable import AIKO
import CoreData
import XCTest

/// Comprehensive tests for FormFieldQLearningAgent
/// RED Phase: Tests written before implementation exists
/// Coverage: Q-learning algorithm convergence, catastrophic forgetting, epsilon-greedy exploration
final class FormFieldQLearningAgentTests: XCTestCase {
    // MARK: - Test Infrastructure

    var sut: FormFieldQLearningAgent?
    var mockCoreDataActor: MockCoreDataActor?
    var testScheduler: TestScheduler?

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test doubles
        mockCoreDataActor = MockCoreDataActor()
        testScheduler = TestScheduler()

        // Create system under test
        sut = FormFieldQLearningAgent(coreDataActor: mockCoreDataActor)

        // Wait for actor initialization
        _ = await sut.getQTableSize()
    }

    override func tearDown() async throws {
        sut = nil
        mockCoreDataActor = nil
        testScheduler = nil

        try await super.tearDown()
    }

    // MARK: - Q-Learning Algorithm Tests

    /// Test Q-value update using Bellman equation
    /// Target: Q(s,a) = Q(s,a) + α[r + γ max Q(s',a') - Q(s,a)]
    func testQLearningUpdateRule() async throws {
        guard let sut else {
            XCTFail("FormFieldQLearningAgent should be initialized")
            return
        }
        // Given: Initial state and action
        let initialState = createTestQLearningState(fieldType: .textField, context: .informationTechnology)
        let testAction = createTestQLearningAction(value: "NET-30", confidence: 0.8)
        let reward = 1.0 // User accepted suggestion

        // When: Update Q-value
        await sut.updateQValue(state: initialState, action: testAction, reward: reward)

        // Then: Q-value should be updated according to learning rule
        let qValue = await sut.getQValue(state: initialState, action: testAction)
        let expectedQValue = 0.0 + 0.1 * (reward - 0.0) // α=0.1, initial Q=0.0

        XCTAssertEqual(qValue, expectedQValue, accuracy: 0.001,
                       "Q-value should follow Bellman equation update rule")
    }

    /// Test learning rate (α=0.1) application correctness
    func testLearningRateApplication() async throws {
        guard let sut else {
            XCTFail("FormFieldQLearningAgent should be initialized")
            return
        }
        // Given: Known Q-value and reward
        let state = createTestQLearningState(fieldType: .dropdownField, context: .construction)
        let action = createTestQLearningAction(value: "Performance Bond Required", confidence: 0.9)

        // Seed initial Q-value
        await sut.updateQValue(state: state, action: action, reward: 0.5)
        let initialQ = await sut.getQValue(state: state, action: action)

        // When: Apply additional reward
        let newReward = 1.0
        await sut.updateQValue(state: state, action: action, reward: newReward)

        // Then: Learning rate should be correctly applied
        let finalQ = await sut.getQValue(state: state, action: action)
        let expectedDelta = 0.1 * (newReward - initialQ) // α * (reward - Q)
        let expectedFinalQ = initialQ + expectedDelta

        XCTAssertEqual(finalQ, expectedFinalQ, accuracy: 0.001,
                       "Learning rate α=0.1 should be correctly applied")
    }

    /// Test discount factor (γ=0.95) in multi-step scenarios
    func testDiscountFactorCalculation() async throws {
        guard let sut else {
            XCTFail("FormFieldQLearningAgent should be initialized")
            return
        }
        // Given: Multi-step scenario with future rewards
        let state1 = createTestQLearningState(fieldType: .textField, context: .informationTechnology)
        let action1 = createTestQLearningAction(value: "Software License", confidence: 0.7)

        let state2 = createTestQLearningState(fieldType: .textField, context: .informationTechnology)
        let action2 = createTestQLearningAction(value: "Annual Subscription", confidence: 0.8)

        // Seed future state with reward
        await sut.updateQValue(state: state2, action: action2, reward: 1.0)
        let futureQValue = await sut.getQValue(state: state2, action: action2)

        // When: Update current state considering future reward
        let immediateReward = 0.5
        await sut.updateQValueWithFutureState(
            currentState: state1,
            currentAction: action1,
            immediateReward: immediateReward,
            nextState: state2,
            discountFactor: 0.95
        )

        // Then: Discount factor should be applied to future rewards
        let currentQValue = await sut.getQValue(state: state1, action: action1)
        let expectedQValue = immediateReward + (0.95 * futureQValue)

        XCTAssertEqual(currentQValue, expectedQValue, accuracy: 0.001,
                       "Discount factor γ=0.95 should be applied to future rewards")
    }

    // MARK: - Catastrophic Forgetting Prevention Tests (CRITICAL PRIORITY)

    /// Test Q-network stability over 30-90 day simulation periods
    /// This is the highest priority test from consensus validation
    func testLongTermStabilityPrevention() async throws {
        guard let sut else {
            XCTFail("FormFieldQLearningAgent should be initialized")
            return
        }
        // Given: Initial learning for IT context
        let itStates = createITContextStates(count: 20)
        let itActions = createITContextActions(count: 10)

        // Train on IT context for simulated 30 days
        for day in 1 ... 30 {
            for state in itStates {
                for action in itActions {
                    let reward = Double.random(in: 0.7 ... 1.0) // Positive IT learning
                    await sut.updateQValue(state: state, action: action, reward: reward)
                }
            }
        }

        // Capture IT performance baseline
        let itBaselinePerformance = await calculateContextPerformance(states: itStates, actions: itActions)

        // When: Learn construction context for 30 days
        let constructionStates = createConstructionContextStates(count: 20)
        let constructionActions = createConstructionContextActions(count: 10)

        for day in 1 ... 30 {
            for state in constructionStates {
                for action in constructionActions {
                    let reward = Double.random(in: 0.6 ... 0.9) // Construction learning
                    await sut.updateQValue(state: state, action: action, reward: reward)
                }
            }
        }

        // Then: IT performance degradation should be < 5%
        let itFinalPerformance = await calculateContextPerformance(states: itStates, actions: itActions)
        let degradationPercent = ((itBaselinePerformance - itFinalPerformance) / itBaselinePerformance) * 100

        XCTAssertLessThan(degradationPercent, 5.0,
                          "Catastrophic forgetting: IT performance degradation should be <5%, got \(degradationPercent)%")
    }

    /// Test cross-context interference detection and mitigation
    func testCrossContextInterferencePrevention() async throws {
        guard let sut else {
            XCTFail("FormFieldQLearningAgent should be initialized")
            return
        }
        // Given: Distinct context patterns
        let itState = createTestQLearningState(fieldType: .textField, context: .informationTechnology)
        let constructionState = createTestQLearningState(fieldType: .textField, context: .construction)

        let itAction = createTestQLearningAction(value: "Cloud Services", confidence: 0.9)
        let constructionAction = createTestQLearningAction(value: "Performance Bond", confidence: 0.8)

        // Train IT context
        for _ in 1 ... 50 {
            await sut.updateQValue(state: itState, action: itAction, reward: 1.0)
        }

        let itQValueBeforeConstruction = await sut.getQValue(state: itState, action: itAction)

        // When: Train construction context with different patterns
        for _ in 1 ... 50 {
            await sut.updateQValue(state: constructionState, action: constructionAction, reward: 1.0)
        }

        // Then: IT Q-values should remain stable
        let itQValueAfterConstruction = await sut.getQValue(state: itState, action: itAction)
        let interferencePercent = abs((itQValueBeforeConstruction - itQValueAfterConstruction) / itQValueBeforeConstruction) * 100

        XCTAssertLessThan(interferencePercent, 2.0,
                          "Cross-context interference should be <2%, got \(interferencePercent)%")
    }

    /// Test continual learning performance with growing experience replay buffer
    func testContinualLearningWithGrowingBuffer() async throws {
        guard let sut else {
            XCTFail("FormFieldQLearningAgent should be initialized")
            return
        }
        // Given: Incrementally growing experience buffer
        var experiences: [QLearningExperience] = []
        let maxBufferSize = 10000

        // When: Continuously add experiences and measure learning efficiency
        for batchSize in stride(from: 100, through: maxBufferSize, by: 500) {
            // Add new experiences
            let newExperiences = createRandomExperiences(count: 500)
            experiences.append(contentsOf: newExperiences)

            // Keep buffer size manageable
            if experiences.count > maxBufferSize {
                experiences = Array(experiences.suffix(maxBufferSize))
            }

            // Measure learning performance
            let startTime = CFAbsoluteTimeGetCurrent()

            for experience in experiences.suffix(100) { // Process recent experiences
                await sut.updateQValue(
                    state: experience.state,
                    action: experience.action,
                    reward: experience.reward
                )
            }

            let learningTime = CFAbsoluteTimeGetCurrent() - startTime

            // Then: Learning time should not degrade significantly with buffer growth
            XCTAssertLessThan(learningTime, 1.0,
                              "Learning time should remain <1s with buffer size \(experiences.count)")
        }
    }

    // MARK: - Epsilon-Greedy Exploration Tests

    /// Test exploration vs exploitation balance (ε=0.1 initial)
    func testEpsilonGreedyBalance() async throws {
        guard let sut else {
            XCTFail("FormFieldQLearningAgent should be initialized")
            return
        }
        // Given: Known optimal action
        let state = createTestQLearningState(fieldType: .textField, context: .informationTechnology)
        let optimalAction = createTestQLearningAction(value: "Optimal Choice", confidence: 1.0)
        let suboptimalAction = createTestQLearningAction(value: "Poor Choice", confidence: 0.3)

        // Train optimal action
        for _ in 1 ... 100 {
            await sut.updateQValue(state: state, action: optimalAction, reward: 1.0)
            await sut.updateQValue(state: state, action: suboptimalAction, reward: -1.0)
        }

        // When: Make predictions with epsilon-greedy
        var explorationCount = 0
        var exploitationCount = 0
        let totalPredictions = 1000

        for _ in 1 ... totalPredictions {
            let prediction = await sut.predictFieldValue(state: state)

            if prediction.value == optimalAction.suggestedValue {
                exploitationCount += 1
            } else {
                explorationCount += 1
            }
        }

        // Then: Exploration rate should be approximately 10%
        let actualExplorationRate = Double(explorationCount) / Double(totalPredictions)

        XCTAssertEqual(actualExplorationRate, 0.1, accuracy: 0.02,
                       "Exploration rate should be ~10%, got \(actualExplorationRate * 100)%")
    }

    /// Test exploration decay mechanism (0.995 factor)
    func testExplorationDecayMechanism() async throws {
        guard let sut else {
            XCTFail("FormFieldQLearningAgent should be initialized")
            return
        }
        // Given: State with multiple visits
        let state = createTestQLearningState(fieldType: .dropdownField, context: .construction)
        let action = createTestQLearningAction(value: "Test Value", confidence: 0.7)

        // When: Visit state multiple times
        let initialExplorationRate = await sut.getCurrentExplorationRate(for: state)

        // Simulate 50 visits (should trigger decay after 10 visits)
        for _ in 1 ... 50 {
            await sut.updateQValue(state: state, action: action, reward: 0.5)
        }

        let finalExplorationRate = await sut.getCurrentExplorationRate(for: state)

        // Then: Exploration rate should decay
        XCTAssertLessThan(finalExplorationRate, initialExplorationRate,
                          "Exploration rate should decay with visits")

        // Should not go below minimum (0.01)
        XCTAssertGreaterThanOrEqual(finalExplorationRate, 0.01,
                                    "Exploration rate should not go below minimum 0.01")
    }

    /// Test state-specific exploration rate adaptation
    func testStateSpecificExplorationAdaptation() async throws {
        guard let sut else {
            XCTFail("FormFieldQLearningAgent should be initialized")
            return
        }
        // Given: Two different states
        let experiencedState = createTestQLearningState(fieldType: .textField, context: .informationTechnology)
        let newState = createTestQLearningState(fieldType: .textField, context: .construction)
        let action = createTestQLearningAction(value: "Test", confidence: 0.5)

        // Train one state extensively
        for _ in 1 ... 100 {
            await sut.updateQValue(state: experiencedState, action: action, reward: 0.8)
        }

        // When: Check exploration rates
        let experiencedExploration = await sut.getCurrentExplorationRate(for: experiencedState)
        let newStateExploration = await sut.getCurrentExplorationRate(for: newState)

        // Then: New state should have higher exploration rate
        XCTAssertGreaterThan(newStateExploration, experiencedExploration,
                             "New states should have higher exploration rates than experienced states")
    }

    // MARK: - State-Action Space Management Tests

    /// Test state hashing consistency for identical contexts
    func testStateHashingConsistency() async throws {
        // Given: Identical state parameters
        let state1 = createTestQLearningState(fieldType: .textField, context: .informationTechnology)
        let state2 = createTestQLearningState(fieldType: .textField, context: .informationTechnology)

        // When: Generate cache keys
        let hash1 = state1.cacheKey
        let hash2 = state2.cacheKey

        // Then: Hashes should be identical
        XCTAssertEqual(hash1, hash2, "Identical states should produce identical cache keys")
    }

    /// Test Q-table memory management and pruning
    func testQTableMemoryManagement() async throws {
        guard let sut else {
            XCTFail("FormFieldQLearningAgent should be initialized")
            return
        }
        // Given: Fill Q-table beyond capacity
        let maxCapacity = 10000

        // Create many state-action pairs
        for i in 1 ... (maxCapacity + 1000) {
            let state = createTestQLearningState(
                fieldType: .textField,
                context: .general,
                userSegment: .novice,
                temporalContext: TemporalContext(hourOfDay: i % 24, dayOfWeek: (i % 7) + 1, isWeekend: false)
            )
            let action = createTestQLearningAction(value: "Value \(i)", confidence: 0.5)

            await sut.updateQValue(state: state, action: action, reward: 0.5)
        }

        // When: Check Q-table size
        let qTableSize = await sut.getQTableSize()

        // Then: Size should be managed within reasonable bounds
        XCTAssertLessThanOrEqual(qTableSize, maxCapacity * 2,
                                 "Q-table size should be managed, got \(qTableSize)")
    }

    /// Test cache mechanisms (LRU, 1000 entry limit)
    func testLRUCacheMechanism() async throws {
        guard let sut else {
            XCTFail("FormFieldQLearningAgent should be initialized")
            return
        }
        // Given: Cache with known capacity
        let cacheCapacity = 1000

        // Fill cache beyond capacity
        for i in 1 ... (cacheCapacity + 100) {
            let state = createTestQLearningState(
                fieldType: .textField,
                context: .general,
                userSegment: .novice,
                temporalContext: TemporalContext(hourOfDay: i % 24, dayOfWeek: 1, isWeekend: false)
            )

            _ = await sut.predictFieldValue(state: state)
        }

        // When: Check cache size
        let cacheSize = await sut.getCacheSize()

        // Then: Cache should respect size limit
        XCTAssertLessThanOrEqual(cacheSize, cacheCapacity,
                                 "Cache should respect size limit of \(cacheCapacity), got \(cacheSize)")
    }

    // MARK: - Test Helper Methods

    private func createTestQLearningState(
        fieldType: FieldType,
        context: ContextCategory,
        userSegment: UserSegment = .intermediate,
        temporalContext: TemporalContext = TemporalContext(hourOfDay: 12, dayOfWeek: 3, isWeekend: false)
    ) -> QLearningState {
        QLearningState(
            fieldType: fieldType,
            contextCategory: context,
            userSegment: userSegment,
            temporalContext: temporalContext
        )
    }

    private func createTestQLearningAction(value: String, confidence: Double) -> QLearningAction {
        QLearningAction(
            suggestedValue: value,
            confidence: confidence
        )
    }

    private func createITContextStates(count: Int) -> [QLearningState] {
        (1 ... count).map { i in
            createTestQLearningState(
                fieldType: i % 2 == 0 ? .textField : .dropdownField,
                context: .informationTechnology,
                userSegment: UserSegment.allCases.randomElement() ?? .intermediate,
                temporalContext: TemporalContext(
                    hourOfDay: i % 24,
                    dayOfWeek: (i % 7) + 1,
                    isWeekend: i % 7 >= 5
                )
            )
        }
    }

    private func createITContextActions(count: Int) -> [QLearningAction] {
        let itValues = ["Cloud Services", "Software License", "IT Support", "Network Equipment", "Cybersecurity"]
        return (1 ... count).map { i in
            createTestQLearningAction(
                value: itValues[i % itValues.count],
                confidence: Double.random(in: 0.6 ... 1.0)
            )
        }
    }

    private func createConstructionContextStates(count: Int) -> [QLearningState] {
        (1 ... count).map { i in
            createTestQLearningState(
                fieldType: i % 2 == 0 ? .textField : .dropdownField,
                context: .construction,
                userSegment: UserSegment.allCases.randomElement() ?? .intermediate,
                temporalContext: TemporalContext(
                    hourOfDay: i % 24,
                    dayOfWeek: (i % 7) + 1,
                    isWeekend: i % 7 >= 5
                )
            )
        }
    }

    private func createConstructionContextActions(count: Int) -> [QLearningAction] {
        let constructionValues = ["Performance Bond", "Prevailing Wage", "Safety Requirements", "Building Materials", "Contractor Services"]
        return (1 ... count).map { i in
            createTestQLearningAction(
                value: constructionValues[i % constructionValues.count],
                confidence: Double.random(in: 0.6 ... 1.0)
            )
        }
    }

    private func createRandomExperiences(count: Int) -> [QLearningExperience] {
        (1 ... count).map { i in
            QLearningExperience(
                state: createTestQLearningState(
                    fieldType: FieldType.allCases.randomElement() ?? .textField,
                    context: ContextCategory.allCases.randomElement() ?? .general
                ),
                action: createTestQLearningAction(
                    value: "Random Value \(i)",
                    confidence: Double.random(in: 0.1 ... 1.0)
                ),
                reward: Double.random(in: -1.0 ... 1.0),
                nextState: createTestQLearningState(
                    fieldType: FieldType.allCases.randomElement() ?? .textField,
                    context: ContextCategory.allCases.randomElement() ?? .general
                )
            )
        }
    }

    private func calculateContextPerformance(states: [QLearningState], actions: [QLearningAction]) async -> Double {
        var totalQValue: Double = 0
        var count = 0

        for state in states {
            for action in actions {
                let qValue = await sut.getQValue(state: state, action: action)
                totalQValue += qValue
                count += 1
            }
        }

        return !isEmpty ? totalQValue / Double(count) : 0.0
    }
}

// MARK: - Test Support Classes

/// Mock Core Data actor for testing
final class MockCoreDataActor: CoreDataActorProtocol {
    private var storage: [String: Any] = [:]

    func save(_ key: String, value: Any) async {
        storage[key] = value
    }

    func load(_ key: String) async -> Any? {
        storage[key]
    }

    func delete(_ key: String) async {
        storage.removeValue(forKey: key)
    }

    func clear() async {
        storage.removeAll()
    }
}

/// Test scheduler for controlled timing
final class TestScheduler {
    private var scheduledTasks: [(Date, () async -> Void)] = []

    func schedule(after delay: TimeInterval, task: @escaping () async -> Void) {
        let executeTime = Date().addingTimeInterval(delay)
        scheduledTasks.append((executeTime, task))
    }

    func runScheduledTasks() async {
        let now = Date()
        let tasksToRun = scheduledTasks.filter { $0.0 <= now }
        scheduledTasks.removeAll { $0.0 <= now }

        for (_, task) in tasksToRun {
            await task()
        }
    }
}

/// Q-Learning experience for replay buffer testing
struct QLearningExperience {
    let state: QLearningState
    let action: QLearningAction
    let reward: Double
    let nextState: QLearningState
}

// MARK: - Extensions for Testing

extension FieldType: CaseIterable {
    public static let allCases: [FieldType] = [.textField, .dropdownField, .numberField, .dateField]
}

extension ContextCategory: CaseIterable {
    public static let allCases: [ContextCategory] = [.informationTechnology, .construction, .professionalServices, .general]
}

extension UserSegment: CaseIterable {
    public static let allCases: [UserSegment] = [.novice, .intermediate, .expert]
}
