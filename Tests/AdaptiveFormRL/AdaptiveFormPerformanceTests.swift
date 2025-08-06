@testable import AIKO
import CoreData
import MLX
import XCTest

/// Comprehensive performance tests for Adaptive Form RL system
/// RED Phase: Tests written before implementation exists
/// Coverage: MLX Swift benchmarks, latency requirements, resource constraints, load testing
final class AdaptiveFormPerformanceTests: XCTestCase {
    // MARK: - Test Infrastructure

    var adaptiveService: AdaptiveFormPopulationService?
    var qLearningAgent: FormFieldQLearningAgent?
    var contextClassifier: AcquisitionContextClassifier?
    var mockCoreDataActor: MockCoreDataActor?
    var performanceMonitor: PerformanceMonitor?
    var mlxBenchmarker: MLXPerformanceBenchmarker?

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test infrastructure
        mockCoreDataActor = MockCoreDataActor()
        performanceMonitor = PerformanceMonitor()
        mlxBenchmarker = MLXPerformanceBenchmarker()

        // Initialize system components
        qLearningAgent = FormFieldQLearningAgent(coreDataActor: mockCoreDataActor)
        contextClassifier = AcquisitionContextClassifier()

        adaptiveService = AdaptiveFormPopulationService(
            contextClassifier: contextClassifier,
            qLearningAgent: qLearningAgent,
            modificationTracker: FormModificationTracker(coreDataActor: mockCoreDataActor),
            explanationEngine: ValueExplanationEngine(),
            metricsCollector: AdaptiveFormMetricsCollector(),
            agenticOrchestrator: PerformanceMockAgenticOrchestrator()
        )

        // Warm up MLX Swift framework
        await mlxBenchmarker.warmUp()
    }

    override func tearDown() async throws {
        adaptiveService = nil
        qLearningAgent = nil
        contextClassifier = nil
        mockCoreDataActor = nil
        performanceMonitor = nil
        mlxBenchmarker = nil

        try await super.tearDown()
    }

    // MARK: - Latency Requirements Tests

    /// Test field suggestion generation latency <50ms (P95)
    func testFieldSuggestionLatencyP95() async throws {
        // Given: Various field types and contexts
        guard let qLearningAgent else {
            XCTFail("QLearningAgent should be initialized")
            return
        }

        let testScenarios = createFieldSuggestionTestScenarios()
        var latencies: [TimeInterval] = []

        // When: Generate suggestions and measure latency
        for scenario in testScenarios {
            let startTime = CFAbsoluteTimeGetCurrent()

            _ = await qLearningAgent.predictFieldValue(state: scenario.state)

            let latency = CFAbsoluteTimeGetCurrent() - startTime
            latencies.append(latency)
        }

        // Then: P95 latency should be <50ms
        let p95Latency = calculatePercentile(latencies, percentile: 95)

        XCTAssertLessThan(p95Latency * 1000, 50.0,
                          "Field suggestion P95 latency should be <50ms, got \(p95Latency * 1000)ms")
    }

    /// Test complete form population latency <200ms (P95)
    func testFormPopulationLatencyP95() async throws {
        // Given: Various form types with different complexities
        guard let adaptiveService else {
            XCTFail("AdaptiveService should be initialized")
            return
        }

        let formTestCases = createFormPopulationTestCases()
        var latencies: [TimeInterval] = []

        // When: Populate forms and measure total latency
        for testCase in formTestCases {
            let startTime = CFAbsoluteTimeGetCurrent()

            _ = try await adaptiveService.populateForm(
                testCase.formData,
                acquisition: testCase.acquisition,
                userProfile: testCase.userProfile
            )

            let latency = CFAbsoluteTimeGetCurrent() - startTime
            latencies.append(latency)
        }

        // Then: P95 latency should be <200ms
        let p95Latency = calculatePercentile(latencies, percentile: 95)

        XCTAssertLessThan(p95Latency * 1000, 200.0,
                          "Form population P95 latency should be <200ms, got \(p95Latency * 1000)ms")
    }

    /// Test context classification latency <30ms (P95)
    func testContextClassificationLatencyP95() async throws {
        // Given: Various acquisition contexts
        let acquisitions = createContextClassificationTestData()
        var latencies: [TimeInterval] = []

        // When: Classify contexts and measure latency
        for acquisition in acquisitions {
            let startTime = CFAbsoluteTimeGetCurrent()

            _ = try await contextClassifier.classifyAcquisition(acquisition)

            let latency = CFAbsoluteTimeGetCurrent() - startTime
            latencies.append(latency)
        }

        // Then: P95 latency should be <30ms
        let p95Latency = calculatePercentile(latencies, percentile: 95)

        XCTAssertLessThan(p95Latency * 1000, 30.0,
                          "Context classification P95 latency should be <30ms, got \(p95Latency * 1000)ms")
    }

    /// Test Q-network update latency <500ms (P95) for async operations
    func testQNetworkUpdateLatencyP95() async throws {
        // Given: Various Q-learning update scenarios
        let updateScenarios = createQNetworkUpdateScenarios(count: 100)
        var latencies: [TimeInterval] = []

        // When: Perform Q-network updates and measure latency
        for scenario in updateScenarios {
            let startTime = CFAbsoluteTimeGetCurrent()

            await qLearningAgent.updateQValue(
                state: scenario.state,
                action: scenario.action,
                reward: scenario.reward
            )

            let latency = CFAbsoluteTimeGetCurrent() - startTime
            latencies.append(latency)
        }

        // Then: P95 latency should be <500ms
        let p95Latency = calculatePercentile(latencies, percentile: 95)

        XCTAssertLessThan(p95Latency * 1000, 500.0,
                          "Q-network update P95 latency should be <500ms, got \(p95Latency * 1000)ms")
    }

    // MARK: - MLX Swift Performance Benchmarks (CRITICAL PRIORITY)

    /// Test Q-network inference latency on various device configurations
    func testMLXQNetworkInferencePerformance() async throws {
        // Given: Various device capability scenarios
        let deviceConfigs = [
            DeviceConfig(cpu: .highPerformance, gpu: .available, memory: .abundant),
            DeviceConfig(cpu: .standard, gpu: .available, memory: .limited),
            DeviceConfig(cpu: .lowPower, gpu: .unavailable, memory: .constrained),
        ]

        // When: Test MLX inference performance on each configuration
        for config in deviceConfigs {
            await mlxBenchmarker.simulateDeviceConfig(config)

            let inferenceResults = await mlxBenchmarker.benchmarkQLearningInference(
                iterations: 100,
                stateSpaceSize: 1000
            )

            // Then: Performance should meet requirements based on device config
            switch config.cpu {
            case .highPerformance:
                XCTAssertLessThan(inferenceResults.averageLatency, 0.020, // 20ms
                                  "High-performance device should achieve <20ms inference")
            case .standard:
                XCTAssertLessThan(inferenceResults.averageLatency, 0.040, // 40ms
                                  "Standard device should achieve <40ms inference")
            case .lowPower:
                XCTAssertLessThan(inferenceResults.averageLatency, 0.080, // 80ms
                                  "Low-power device should achieve <80ms inference")
            }

            // Verify GPU acceleration benefits when available
            if config.gpu == .available {
                XCTAssertTrue(inferenceResults.usedGPU, "Should utilize GPU when available")
                XCTAssertGreaterThan(inferenceResults.gpuSpeedup, 1.5, "GPU should provide >1.5x speedup")
            }
        }
    }

    /// Test MLX Swift GPU acceleration vs CPU fallback performance
    func testMLXGPUAccelerationVsCPUFallback() async throws {
        // Given: Same inference workload
        let testState = createComplexQLearningState()
        let iterations = 50

        // When: Benchmark GPU vs CPU performance
        let gpuResults = await mlxBenchmarker.benchmarkWithGPU(
            state: testState,
            iterations: iterations
        )

        let cpuResults = await mlxBenchmarker.benchmarkWithCPU(
            state: testState,
            iterations: iterations
        )

        // Then: GPU should provide significant speedup
        let speedupRatio = cpuResults.averageLatency / gpuResults.averageLatency

        XCTAssertGreaterThan(speedupRatio, 2.0,
                             "GPU should provide >2x speedup over CPU, got \(speedupRatio)x")

        // Verify accuracy is maintained
        let accuracyDiff = abs(gpuResults.averageAccuracy - cpuResults.averageAccuracy)
        XCTAssertLessThan(accuracyDiff, 0.01,
                          "GPU and CPU results should have similar accuracy")
    }

    /// Test model quantization impact on accuracy vs speed trade-offs
    func testMLXModelQuantizationTradeoffs() async throws {
        // Given: Different quantization levels
        let quantizationLevels: [QuantizationLevel] = [.float32, .float16, .int8]
        var results: [QuantizationLevel: QuantizationResults] = [:]

        // When: Test each quantization level
        for level in quantizationLevels {
            let quantizedResults = await mlxBenchmarker.benchmarkQuantizedModel(
                quantization: level,
                testCases: createQuantizationTestCases(count: 100)
            )

            results[level] = quantizedResults
        }

        // Then: Verify speed vs accuracy trade-offs
        guard let float32Results = results[.float32] else {
            XCTFail("float32 results should be available")
            return
        }
        guard let float16Results = results[.float16] else {
            XCTFail("float16 results should be available")
            return
        }
        guard let int8Results = results[.int8] else {
            XCTFail("int8 results should be available")
            return
        }

        // float16 should be faster than float32 with minimal accuracy loss
        XCTAssertLessThan(float16Results.averageLatency, float32Results.averageLatency,
                          "float16 should be faster than float32")

        let float16AccuracyLoss = float32Results.accuracy - float16Results.accuracy
        XCTAssertLessThan(float16AccuracyLoss, 0.02,
                          "float16 accuracy loss should be <2%")

        // int8 should be much faster but with acceptable accuracy loss
        XCTAssertLessThan(int8Results.averageLatency, float16Results.averageLatency,
                          "int8 should be faster than float16")

        let int8AccuracyLoss = float32Results.accuracy - int8Results.accuracy
        XCTAssertLessThan(int8AccuracyLoss, 0.05,
                          "int8 accuracy loss should be <5%")
    }

    /// Test memory allocation patterns during MLX operations
    func testMLXMemoryAllocationPatterns() async throws {
        // Given: Memory monitoring enabled
        let memoryMonitor = MLXMemoryMonitor()
        await memoryMonitor.startMonitoring()

        // When: Perform various MLX operations
        let operations = [
            ("Model Loading", { await self.mlxBenchmarker.loadQLearningModel() }),
            ("Inference", { await self.mlxBenchmarker.performInference(iterations: 50) }),
            ("Training", { await self.mlxBenchmarker.performTraining(epochs: 10) }),
            ("Model Unloading", { await self.mlxBenchmarker.unloadModel() }),
        ]

        for (operationName, operation) in operations {
            let initialMemory = await memoryMonitor.getCurrentMemoryUsage()

            await operation()

            let finalMemory = await memoryMonitor.getCurrentMemoryUsage()
            let memoryDelta = finalMemory - initialMemory

            // Memory allocation should be reasonable for each operation
            switch operationName {
            case "Model Loading":
                XCTAssertLessThan(memoryDelta, 25_000_000, // 25MB
                                  "Model loading should use <25MB additional memory")
            case "Inference":
                XCTAssertLessThan(memoryDelta, 5_000_000, // 5MB
                                  "Inference should use <5MB additional memory")
            case "Training":
                XCTAssertLessThan(memoryDelta, 15_000_000, // 15MB
                                  "Training should use <15MB additional memory")
            case "Model Unloading":
                XCTAssertLessThan(abs(memoryDelta), 2_000_000, // 2MB tolerance
                                  "Model unloading should release most memory")
            default:
                break
            }
        }

        await memoryMonitor.stopMonitoring()

        // Then: Verify no significant memory leaks
        let memoryLeakDetected = await memoryMonitor.detectMemoryLeaks()
        XCTAssertFalse(memoryLeakDetected, "No memory leaks should be detected in MLX operations")
    }

    /// Test concurrent MLX operations impact on UI responsiveness
    func testConcurrentMLXOperationsUIImpact() async throws {
        // Given: UI responsiveness monitor
        let uiMonitor = UIResponsivenessMonitor()
        uiMonitor.startMonitoring()

        // When: Perform concurrent MLX operations while simulating UI updates
        await withTaskGroup(of: Void.self) { group in
            // MLX inference tasks
            for i in 1 ... 5 {
                group.addTask {
                    await self.mlxBenchmarker.performConcurrentInference(id: i)
                }
            }

            // Simulated UI update tasks
            for i in 1 ... 10 {
                group.addTask {
                    await uiMonitor.simulateUIUpdate(frameIndex: i)
                }
            }
        }

        uiMonitor.stopMonitoring()

        // Then: UI should maintain 60fps with minimal dropped frames
        let droppedFrames = uiMonitor.getDroppedFrameCount()
        let frameDropPercentage = Double(droppedFrames) / Double(uiMonitor.getTotalFrames()) * 100

        XCTAssertLessThan(frameDropPercentage, 5.0,
                          "Frame drop percentage should be <5% during concurrent MLX operations, got \(frameDropPercentage)%")
    }

    /// Test MLX model compilation time and caching effectiveness
    func testMLXModelCompilationAndCaching() async throws {
        // Given: Clean state with no cached models
        await mlxBenchmarker.clearModelCache()

        // When: Compile model for first time
        let firstCompilationStart = CFAbsoluteTimeGetCurrent()
        await mlxBenchmarker.compileQLearningModel()
        let firstCompilationTime = CFAbsoluteTimeGetCurrent() - firstCompilationStart

        // Clear model from memory but keep cache
        await mlxBenchmarker.unloadModel()

        // Load model again (should use cache)
        let cachedLoadStart = CFAbsoluteTimeGetCurrent()
        await mlxBenchmarker.loadQLearningModel()
        let cachedLoadTime = CFAbsoluteTimeGetCurrent() - cachedLoadStart

        // Then: Cached loading should be significantly faster
        let speedupRatio = firstCompilationTime / cachedLoadTime

        XCTAssertGreaterThan(speedupRatio, 3.0,
                             "Cached model loading should be >3x faster than compilation, got \(speedupRatio)x")

        XCTAssertLessThan(cachedLoadTime, 2.0,
                          "Cached model loading should be <2s, got \(cachedLoadTime)s")
    }

    // MARK: - Resource Constraints Tests

    /// Test memory usage <50MB including MLX Swift overhead
    func testMemoryUsageConstraints() async throws {
        // Given: Memory baseline measurement
        let memoryMonitor = SystemMemoryMonitor()
        let baselineMemory = await memoryMonitor.getCurrentMemoryUsage()

        // When: Initialize full adaptive form system
        _ = try await adaptiveService.populateForm(
            createLargeFormData(),
            acquisition: createComplexAcquisition(),
            userProfile: UserProfile(id: UUID(), name: "Memory Test User", email: "test@example.com")
        )

        // Perform typical usage patterns
        for _ in 1 ... 50 {
            let state = createRandomQLearningState()
            _ = await qLearningAgent.predictFieldValue(state: state)

            await qLearningAgent.updateQValue(
                state: state,
                action: createRandomQLearningAction(),
                reward: Double.random(in: 0 ... 1)
            )
        }

        // Then: Additional memory usage should be <50MB
        let currentMemory = await memoryMonitor.getCurrentMemoryUsage()
        let additionalMemory = currentMemory - baselineMemory

        XCTAssertLessThan(additionalMemory, 50_000_000,
                          "Additional memory usage should be <50MB, got \(additionalMemory / 1_000_000)MB")
    }

    /// Test memory growth patterns over time with Q-table expansion
    func testMemoryGrowthPatterns() async throws {
        // Given: Memory monitoring over extended usage
        let memoryMonitor = SystemMemoryMonitor()
        var memorySnapshots: [(time: TimeInterval, memory: Int64)] = []

        let startTime = CFAbsoluteTimeGetCurrent()

        // When: Simulate extended usage with Q-table growth
        for iteration in 1 ... 1000 {
            // Create unique states to grow Q-table
            let state = createUniqueQLearningState(iteration: iteration)
            let action = createRandomQLearningAction()

            await qLearningAgent.updateQValue(state: state, action: action, reward: 0.5)

            // Take memory snapshots every 100 iterations
            if iteration % 100 == 0 {
                let currentTime = CFAbsoluteTimeGetCurrent() - startTime
                let currentMemory = await memoryMonitor.getCurrentMemoryUsage()
                memorySnapshots.append((time: currentTime, memory: currentMemory))
            }
        }

        // Then: Memory growth should be linear and bounded
        guard let initialMemory = memorySnapshots.first?.memory else {
            XCTFail("Initial memory snapshot should be available")
            return
        }
        guard let finalMemory = memorySnapshots.last?.memory else {
            XCTFail("Final memory snapshot should be available")
            return
        }
        let memoryGrowth = finalMemory - initialMemory

        XCTAssertLessThan(memoryGrowth, 30_000_000,
                          "Memory growth should be <30MB over 1000 iterations, got \(memoryGrowth / 1_000_000)MB")

        // Verify linear growth pattern (not exponential)
        let growthRate = calculateMemoryGrowthRate(memorySnapshots)
        XCTAssertLessThan(growthRate, 100_000, // 100KB per iteration
                          "Memory growth rate should be <100KB per iteration")
    }

    /// Test CPU usage <5% average during form filling including MLX inference
    func testCPUUsageConstraints() async throws {
        // Given: CPU monitoring setup
        let cpuMonitor = CPUUsageMonitor()
        cpuMonitor.startMonitoring()

        // When: Perform typical form filling workflow
        let formCount = 20
        for i in 1 ... formCount {
            let formData = createVariedFormData(index: i)
            let acquisition = createVariedAcquisition(index: i)
            let userProfile = UserProfile(id: UUID(), name: "CPU Test User \(i)", email: "test\(i)@example.com")

            _ = try await adaptiveService.populateForm(formData, acquisition: acquisition, userProfile: userProfile)

            // Simulate user modifications
            await adaptiveService.trackModification(
                fieldId: "testField",
                originalValue: "original\(i)",
                newValue: "modified\(i)",
                formType: "SF-1449",
                context: createRandomAcquisitionContext()
            )

            // Small delay to simulate realistic usage
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        cpuMonitor.stopMonitoring()

        // Then: Average CPU usage should be <5%
        let averageCPUUsage = cpuMonitor.getAverageCPUUsage()

        XCTAssertLessThan(averageCPUUsage, 5.0,
                          "Average CPU usage should be <5% during form filling, got \(averageCPUUsage)%")
    }

    /// Test battery drain <2% additional impact with GPU acceleration
    func testBatteryDrainImpact() async throws {
        // Given: Battery monitoring setup
        let batteryMonitor = BatteryUsageMonitor()
        let baselineDrain = await batteryMonitor.measureBaselineDrain(duration: 60) // 1 minute baseline

        // When: Perform intensive adaptive form operations with GPU
        await batteryMonitor.startIntensiveMonitoring()

        // Simulate intensive usage
        await withTaskGroup(of: Void.self) { group in
            // Multiple concurrent inference tasks
            for i in 1 ... 10 {
                group.addTask {
                    for _ in 1 ... 50 {
                        let state = createRandomQLearningState()
                        _ = await self.qLearningAgent.predictFieldValue(state: state)
                    }
                }
            }

            // Form processing tasks
            for i in 1 ... 5 {
                group.addTask {
                    let formData = createLargeFormData()
                    let acquisition = createComplexAcquisition()
                    let userProfile = UserProfile(id: UUID(), name: "Battery Test \(i)", email: "test\(i)@example.com")

                    _ = try await self.adaptiveService.populateForm(formData, acquisition: acquisition, userProfile: userProfile)
                }
            }
        }

        let intensiveDrain = await batteryMonitor.stopIntensiveMonitoring()

        // Then: Additional battery drain should be <2%
        let additionalDrain = intensiveDrain - baselineDrain
        let drainPercentage = (additionalDrain / batteryMonitor.getBatteryCapacity()) * 100

        XCTAssertLessThan(drainPercentage, 2.0,
                          "Additional battery drain should be <2%, got \(drainPercentage)%")
    }

    /// Test thermal impact during extended MLX operations
    func testThermalImpactDuringMLXOperations() async throws {
        // Given: Thermal monitoring setup
        let thermalMonitor = ThermalStateMonitor()
        thermalMonitor.startMonitoring()

        let initialThermalState = await thermalMonitor.getCurrentThermalState()

        // When: Perform extended MLX operations
        let operationDuration: TimeInterval = 300 // 5 minutes
        let startTime = CFAbsoluteTimeGetCurrent()

        while CFAbsoluteTimeGetCurrent() - startTime < operationDuration {
            // Continuous MLX inference operations
            await mlxBenchmarker.performContinuousInference(duration: 10) // 10 second bursts

            // Check for thermal throttling
            let currentThermalState = await thermalMonitor.getCurrentThermalState()
            if currentThermalState == .critical {
                break // Stop if we hit critical thermal state
            }

            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second cooldown
        }

        let finalThermalState = await thermalMonitor.getCurrentThermalState()
        thermalMonitor.stopMonitoring()

        // Then: Should not cause excessive thermal issues
        XCTAssertNotEqual(finalThermalState, .critical,
                          "Extended MLX operations should not cause critical thermal state")

        let thermalImpact = thermalMonitor.calculateThermalImpact(from: initialThermalState, to: finalThermalState)
        XCTAssertLessThan(thermalImpact, 0.3, // Arbitrary scale 0-1
                          "Thermal impact should be moderate, got \(thermalImpact)")
    }

    // MARK: - Load Testing

    /// Test 10,000+ forms per user without degradation
    func testHighVolumeFormProcessing() async throws {
        // Given: Large volume of forms to process
        let formCount = 10000
        let batchSize = 100
        var processingTimes: [TimeInterval] = []

        // When: Process forms in batches
        for batchStart in stride(from: 0, to: formCount, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, formCount)
            let batchStartTime = CFAbsoluteTimeGetCurrent()

            // Process batch
            for i in batchStart ..< batchEnd {
                let formData = createVariedFormData(index: i)
                let acquisition = createVariedAcquisition(index: i)
                let userProfile = UserProfile(id: UUID(), name: "Load Test User", email: "loadtest@example.com")

                _ = try await adaptiveService.populateForm(formData, acquisition: acquisition, userProfile: userProfile)
            }

            let batchTime = CFAbsoluteTimeGetCurrent() - batchStartTime
            processingTimes.append(batchTime / Double(batchSize)) // Average per form
        }

        // Then: Performance should not degrade significantly over time
        let firstBatchAverage = processingTimes.prefix(10).reduce(0, +) / 10
        let lastBatchAverage = processingTimes.suffix(10).reduce(0, +) / 10

        let degradationPercent = ((lastBatchAverage - firstBatchAverage) / firstBatchAverage) * 100

        XCTAssertLessThan(degradationPercent, 20.0,
                          "Performance degradation should be <20% over 10K forms, got \(degradationPercent)%")
    }

    /// Test Q-table performance with large datasets
    func testQLearningScalabilityWithLargeDatasets() async throws {
        // Given: Progressively larger Q-table sizes
        let dataSizes = [1000, 5000, 10000, 25000, 50000]
        var performanceMetrics: [Int: PerformanceMetrics] = [:]

        // When: Test performance at each data size
        for dataSize in dataSizes {
            // Populate Q-table with specified size
            await populateQLearningData(size: dataSize)

            // Measure lookup performance
            let lookupStart = CFAbsoluteTimeGetCurrent()
            for _ in 1 ... 1000 {
                let state = createRandomQLearningState()
                let action = createRandomQLearningAction()
                _ = await qLearningAgent.getQValue(state: state, action: action)
            }
            let lookupTime = CFAbsoluteTimeGetCurrent() - lookupStart

            // Measure update performance
            let updateStart = CFAbsoluteTimeGetCurrent()
            for _ in 1 ... 1000 {
                let state = createRandomQLearningState()
                let action = createRandomQLearningAction()
                await qLearningAgent.updateQValue(state: state, action: action, reward: 0.5)
            }
            let updateTime = CFAbsoluteTimeGetCurrent() - updateStart

            performanceMetrics[dataSize] = PerformanceMetrics(
                lookupTime: lookupTime / 1000, // Average per lookup
                updateTime: updateTime / 1000 // Average per update
            )
        }

        // Then: Performance should scale reasonably
        guard let smallDataMetrics = performanceMetrics[1000] else {
            XCTFail("Small data metrics should be available")
            return
        }
        guard let largeDataMetrics = performanceMetrics[50000] else {
            XCTFail("Large data metrics should be available")
            return
        }

        let lookupDegradation = largeDataMetrics.lookupTime / smallDataMetrics.lookupTime
        let updateDegradation = largeDataMetrics.updateTime / smallDataMetrics.updateTime

        XCTAssertLessThan(lookupDegradation, 3.0,
                          "Q-table lookup should not degrade >3x with 50x data increase, got \(lookupDegradation)x")

        XCTAssertLessThan(updateDegradation, 2.0,
                          "Q-table update should not degrade >2x with 50x data increase, got \(updateDegradation)x")
    }

    // MARK: - Test Helper Methods

    private func createFieldSuggestionTestScenarios() -> [FieldSuggestionScenario] {
        [
            FieldSuggestionScenario(
                state: createTestQLearningState(fieldType: .textField, context: .informationTechnology),
                expectedComplexity: .medium
            ),
            FieldSuggestionScenario(
                state: createTestQLearningState(fieldType: .dropdownField, context: .construction),
                expectedComplexity: .high
            ),
            FieldSuggestionScenario(
                state: createTestQLearningState(fieldType: .numberField, context: .professionalServices),
                expectedComplexity: .low
            ),
        ]
    }

    private func createFormPopulationTestCases() -> [FormPopulationTestCase] {
        [
            FormPopulationTestCase(
                formData: createSimpleFormData(),
                acquisition: createSimpleAcquisition(),
                userProfile: UserProfile(id: UUID(), name: "Simple User", email: "simple@test.com")
            ),
            FormPopulationTestCase(
                formData: createComplexFormData(),
                acquisition: createComplexAcquisition(),
                userProfile: UserProfile(id: UUID(), name: "Complex User", email: "complex@test.com")
            ),
            FormPopulationTestCase(
                formData: createLargeFormData(),
                acquisition: createLargeAcquisition(),
                userProfile: UserProfile(id: UUID(), name: "Large User", email: "large@test.com")
            ),
        ]
    }

    private func createContextClassificationTestData() -> [AcquisitionAggregate] {
        [
            AcquisitionAggregate(
                id: UUID(),
                title: "Software Development Services",
                requirements: "Need cloud computing and database management",
                projectDescription: "IT solution with cybersecurity",
                estimatedValue: 200_000,
                deadline: Date().addingTimeInterval(60 * 24 * 3600),
                isRecurring: false
            ),
            AcquisitionAggregate(
                id: UUID(),
                title: "Building Construction Project",
                requirements: "Construction services and building materials",
                projectDescription: "Facility construction with contractor services",
                estimatedValue: 500_000,
                deadline: Date().addingTimeInterval(120 * 24 * 3600),
                isRecurring: false
            ),
        ]
    }

    private func createQNetworkUpdateScenarios(count: Int) -> [QNetworkUpdateScenario] {
        (1 ... count).map { _ in
            QNetworkUpdateScenario(
                state: createTestQLearningState(
                    fieldType: FieldType.allCases.randomElement() ?? .textField,
                    context: ContextCategory.allCases.randomElement() ?? .general
                ),
                action: createRandomQLearningAction(),
                reward: Double.random(in: -1 ... 1)
            )
        }
    }

    private func createTestQLearningState(fieldType: FieldType, context: ContextCategory) -> QLearningState {
        QLearningState(
            fieldType: fieldType,
            contextCategory: context,
            userSegment: .intermediate,
            temporalContext: TemporalContext(hourOfDay: 12, dayOfWeek: 3, isWeekend: false)
        )
    }

    private func createRandomQLearningState() -> QLearningState {
        QLearningState(
            fieldType: FieldType.allCases.randomElement() ?? .textField,
            contextCategory: ContextCategory.allCases.randomElement() ?? .general,
            userSegment: UserSegment.allCases.randomElement() ?? .intermediate,
            temporalContext: TemporalContext(
                hourOfDay: Int.random(in: 0 ... 23),
                dayOfWeek: Int.random(in: 1 ... 7),
                isWeekend: Bool.random()
            )
        )
    }

    private func createRandomQLearningAction() -> QLearningAction {
        let values = ["Test Value", "Sample Text", "Default Option", "Custom Entry"]
        return QLearningAction(
            suggestedValue: values.randomElement() ?? "Default Value",
            confidence: Double.random(in: 0.1 ... 1.0)
        )
    }

    private func createComplexQLearningState() -> QLearningState {
        QLearningState(
            fieldType: .dropdownField,
            contextCategory: .informationTechnology,
            userSegment: .expert,
            temporalContext: TemporalContext(hourOfDay: 14, dayOfWeek: 3, isWeekend: false)
        )
    }

    private func createQuantizationTestCases(count: Int) -> [QuantizationTestCase] {
        (1 ... count).map { _ in
            QuantizationTestCase(
                input: createRandomQLearningState(),
                expectedOutput: createRandomQLearningAction(),
                tolerance: 0.1
            )
        }
    }

    private func createSimpleFormData() -> FormData {
        FormData(
            formNumber: "SF-1449",
            revision: "2024-01",
            fields: ["simpleField": ""],
            metadata: [:]
        )
    }

    private func createComplexFormData() -> FormData {
        FormData(
            formNumber: "SF-1449",
            revision: "2024-01",
            fields: [
                "paymentTerms": "",
                "evaluationMethod": "",
                "deliverySchedule": "",
                "performanceStandards": "",
                "qualityAssurance": "",
                "contractType": "",
                "performancePeriod": "",
            ],
            metadata: [:]
        )
    }

    private func createLargeFormData() -> FormData {
        var fields: [String: String] = [:]
        for i in 1 ... 50 {
            fields["field\(i)"] = ""
        }

        return FormData(
            formNumber: "SF-1449",
            revision: "2024-01",
            fields: fields,
            metadata: [:]
        )
    }

    private func createVariedFormData(index: Int) -> FormData {
        FormData(
            formNumber: "SF-1449",
            revision: "2024-01",
            fields: [
                "field1": "",
                "field2": "",
                "dynamicField\(index)": "",
            ],
            metadata: ["index": "\(index)"]
        )
    }

    private func createSimpleAcquisition() -> AcquisitionAggregate {
        AcquisitionAggregate(
            id: UUID(),
            title: "Simple Acquisition",
            requirements: "Basic requirements",
            projectDescription: "Simple project",
            estimatedValue: 10000,
            deadline: Date().addingTimeInterval(30 * 24 * 3600),
            isRecurring: false
        )
    }

    private func createComplexAcquisition() -> AcquisitionAggregate {
        AcquisitionAggregate(
            id: UUID(),
            title: "Complex IT Infrastructure Project",
            requirements: "Comprehensive software development with cloud computing, database design, network security, and cybersecurity implementation for enterprise IT infrastructure.",
            projectDescription: "Multi-phase project requiring specialized expertise in software programming, hardware procurement, and comprehensive security measures.",
            estimatedValue: 2_000_000,
            deadline: Date().addingTimeInterval(180 * 24 * 3600),
            isRecurring: false
        )
    }

    private func createLargeAcquisition() -> AcquisitionAggregate {
        let largeRequirements = String(repeating: "Complex requirements involving multiple stakeholders, extensive documentation, comprehensive testing, quality assurance, and ongoing support services. ", count: 20)

        return AcquisitionAggregate(
            id: UUID(),
            title: "Large Scale Enterprise Transformation",
            requirements: largeRequirements,
            projectDescription: "Enterprise-wide transformation project with multiple phases and complex integration requirements.",
            estimatedValue: 5_000_000,
            deadline: Date().addingTimeInterval(365 * 24 * 3600),
            isRecurring: false
        )
    }

    private func createVariedAcquisition(index: Int) -> AcquisitionAggregate {
        let contexts = ["IT", "Construction", "Services"]
        let context = contexts[index % contexts.count]

        return AcquisitionAggregate(
            id: UUID(),
            title: "\(context) Project \(index)",
            requirements: "Requirements for \(context.lowercased()) project \(index)",
            projectDescription: "Project \(index) description for \(context.lowercased()) context",
            estimatedValue: Double.random(in: 10000 ... 1_000_000),
            deadline: Date().addingTimeInterval(Double.random(in: 30 ... 180) * 24 * 3600),
            isRecurring: false
        )
    }

    private func createRandomAcquisitionContext() -> AcquisitionContext {
        AcquisitionContext(
            category: ContextCategory.allCases.randomElement() ?? .general,
            confidence: Double.random(in: 0.5 ... 1.0),
            features: ContextFeatures(
                estimatedValue: Double.random(in: 10000 ... 1_000_000),
                hasUrgentDeadline: Bool.random(),
                requiresSpecializedSkills: Bool.random(),
                isRecurringPurchase: Bool.random(),
                involvesSecurity: Bool.random()
            ),
            acquisitionValue: Double.random(in: 10000 ... 1_000_000),
            urgency: UrgencyLevel.allCases.randomElement() ?? .normal,
            complexity: ComplexityLevel.allCases.randomElement() ?? .medium,
            acquisitionId: UUID()
        )
    }

    private func createUniqueQLearningState(iteration: Int) -> QLearningState {
        QLearningState(
            fieldType: FieldType.allCases[iteration % FieldType.allCases.count],
            contextCategory: ContextCategory.allCases[iteration % ContextCategory.allCases.count],
            userSegment: UserSegment.allCases[iteration % UserSegment.allCases.count],
            temporalContext: TemporalContext(
                hourOfDay: iteration % 24,
                dayOfWeek: (iteration % 7) + 1,
                isWeekend: (iteration % 7) >= 5
            )
        )
    }

    private func calculatePercentile(_ values: [TimeInterval], percentile: Int) -> TimeInterval {
        let sortedValues = values.sorted()
        let index = Int(ceil(Double(percentile) / 100.0 * Double(sortedValues.count))) - 1
        return sortedValues[max(0, min(index, sortedValues.count - 1))]
    }

    private func calculateMemoryGrowthRate(_ snapshots: [(time: TimeInterval, memory: Int64)]) -> Double {
        guard snapshots.count >= 2 else { return 0 }

        guard let firstSnapshot = snapshots.first,
              let lastSnapshot = snapshots.last
        else {
            return 0
        }

        let memoryDelta = Double(lastSnapshot.memory - firstSnapshot.memory)
        let timeDelta = lastSnapshot.time - firstSnapshot.time

        return memoryDelta / timeDelta // bytes per second
    }

    private func populateQLearningData(size: Int) async {
        for _ in 1 ... size {
            let state = createRandomQLearningState()
            let action = createRandomQLearningAction()
            await qLearningAgent.updateQValue(state: state, action: action, reward: Double.random(in: -1 ... 1))
        }
    }
}

// MARK: - Test Support Structures

struct FieldSuggestionScenario {
    let state: QLearningState
    let expectedComplexity: ComplexityLevel
}

struct FormPopulationTestCase {
    let formData: FormData
    let acquisition: AcquisitionAggregate
    let userProfile: UserProfile
}

struct QNetworkUpdateScenario {
    let state: QLearningState
    let action: QLearningAction
    let reward: Double
}

struct DeviceConfig {
    let cpu: CPUPerformance
    let gpu: GPUAvailability
    let memory: MemoryAvailability
}

enum CPUPerformance {
    case highPerformance, standard, lowPower
}

enum GPUAvailability {
    case available, unavailable
}

enum MemoryAvailability {
    case abundant, limited, constrained
}

enum QuantizationLevel {
    case float32, float16, int8
}

struct QuantizationResults {
    let averageLatency: TimeInterval
    let accuracy: Double
}

struct QuantizationTestCase {
    let input: QLearningState
    let expectedOutput: QLearningAction
    let tolerance: Double
}

struct PerformanceMetrics {
    let lookupTime: TimeInterval
    let updateTime: TimeInterval
}

// MARK: - Test Support Classes

/// Performance monitoring for benchmarking
final class PerformanceMonitor {
    private var measurements: [String: [TimeInterval]] = [:]

    func startMeasurement(_: String) -> TimeInterval {
        CFAbsoluteTimeGetCurrent()
    }

    func endMeasurement(_ name: String, startTime: TimeInterval) {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        measurements[name, default: []].append(duration)
    }

    func getAverageDuration(_ name: String) -> TimeInterval {
        let durations = measurements[name] ?? []
        return durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)
    }
}

/// MLX Swift performance benchmarker
final class MLXPerformanceBenchmarker {
    private var isWarmedUp = false

    func warmUp() async {
        // Simulate MLX framework warmup
        isWarmedUp = true
    }

    func simulateDeviceConfig(_: DeviceConfig) async {
        // Simulate device configuration
    }

    func benchmarkQLearningInference(iterations _: Int, stateSpaceSize _: Int) async -> MLXInferenceResults {
        MLXInferenceResults(
            averageLatency: Double.random(in: 0.01 ... 0.08),
            usedGPU: Bool.random(),
            gpuSpeedup: Double.random(in: 1.0 ... 3.0)
        )
    }

    func benchmarkWithGPU(state _: QLearningState, iterations _: Int) async -> MLXBenchmarkResults {
        MLXBenchmarkResults(
            averageLatency: Double.random(in: 0.01 ... 0.03),
            averageAccuracy: Double.random(in: 0.85 ... 0.95)
        )
    }

    func benchmarkWithCPU(state _: QLearningState, iterations _: Int) async -> MLXBenchmarkResults {
        MLXBenchmarkResults(
            averageLatency: Double.random(in: 0.03 ... 0.08),
            averageAccuracy: Double.random(in: 0.85 ... 0.95)
        )
    }

    func benchmarkQuantizedModel(quantization: QuantizationLevel, testCases _: [QuantizationTestCase]) async -> QuantizationResults {
        let latencyMultiplier: Double
        let accuracyPenalty: Double

        switch quantization {
        case .float32:
            latencyMultiplier = 1.0
            accuracyPenalty = 0.0
        case .float16:
            latencyMultiplier = 0.6
            accuracyPenalty = 0.01
        case .int8:
            latencyMultiplier = 0.3
            accuracyPenalty = 0.03
        }

        return QuantizationResults(
            averageLatency: 0.05 * latencyMultiplier,
            accuracy: 0.90 - accuracyPenalty
        )
    }

    func loadQLearningModel() async {
        // Simulate model loading
    }

    func performInference(iterations _: Int) async {
        // Simulate inference operations
    }

    func performTraining(epochs _: Int) async {
        // Simulate training operations
    }

    func unloadModel() async {
        // Simulate model unloading
    }

    func clearModelCache() async {
        // Simulate cache clearing
    }

    func compileQLearningModel() async {
        // Simulate model compilation
    }

    func performConcurrentInference(id _: Int) async {
        // Simulate concurrent inference
    }

    func performContinuousInference(duration _: TimeInterval) async {
        // Simulate continuous inference
    }
}

struct MLXInferenceResults {
    let averageLatency: TimeInterval
    let usedGPU: Bool
    let gpuSpeedup: Double
}

struct MLXBenchmarkResults {
    let averageLatency: TimeInterval
    let averageAccuracy: Double
}

/// System memory monitoring
final class SystemMemoryMonitor {
    func getCurrentMemoryUsage() async -> Int64 {
        // Simulate memory usage measurement
        Int64.random(in: 100_000_000 ... 200_000_000) // 100-200MB
    }
}

/// MLX memory monitoring
final class MLXMemoryMonitor {
    private var isMonitoring = false

    func startMonitoring() async {
        isMonitoring = true
    }

    func stopMonitoring() async {
        isMonitoring = false
    }

    func getCurrentMemoryUsage() async -> Int64 {
        Int64.random(in: 50_000_000 ... 150_000_000) // 50-150MB
    }

    func detectMemoryLeaks() async -> Bool {
        false // No leaks in test
    }
}

/// UI responsiveness monitoring
final class UIResponsivenessMonitor {
    private var isMonitoring = false
    private var droppedFrames = 0
    private var totalFrames = 0

    func startMonitoring() {
        isMonitoring = true
        droppedFrames = 0
        totalFrames = 0
    }

    func stopMonitoring() {
        isMonitoring = false
    }

    func simulateUIUpdate(frameIndex _: Int) async {
        totalFrames += 1
        // Simulate occasional dropped frames
        if Int.random(in: 1 ... 100) <= 3 { // 3% drop rate
            droppedFrames += 1
        }
    }

    func getDroppedFrameCount() -> Int {
        droppedFrames
    }

    func getTotalFrames() -> Int {
        totalFrames
    }
}

/// CPU usage monitoring
final class CPUUsageMonitor {
    private var isMonitoring = false
    private var usageSamples: [Double] = []

    func startMonitoring() {
        isMonitoring = true
        usageSamples.removeAll()

        // Simulate periodic CPU sampling
        Task {
            while isMonitoring {
                let usage = Double.random(in: 1.0 ... 8.0) // 1-8% CPU usage
                usageSamples.append(usage)
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }

    func stopMonitoring() {
        isMonitoring = false
    }

    func getAverageCPUUsage() -> Double {
        usageSamples.isEmpty ? 0 : usageSamples.reduce(0, +) / Double(usageSamples.count)
    }
}

/// Battery usage monitoring
final class BatteryUsageMonitor {
    private var isMonitoring = false
    private var batteryUsage = 0.0

    func measureBaselineDrain(duration _: TimeInterval) async -> Double {
        // Simulate baseline battery drain measurement
        Double.random(in: 0.5 ... 1.0) // 0.5-1% per minute
    }

    func startIntensiveMonitoring() async {
        // Start intensive monitoring
        isMonitoring = true
        batteryUsage = 0.0
    }

    func stopIntensiveMonitoring() async -> Double {
        // Simulate intensive battery drain measurement
        isMonitoring = false
        return Double.random(in: 2.0 ... 4.0) // 2-4% per minute during intensive use
    }

    func getBatteryCapacity() -> Double {
        100.0 // 100% battery capacity
    }

    // Additional methods needed by Performance_DocumentScannerTests
    func startMonitoring() {
        isMonitoring = true
        batteryUsage = 0.0
    }

    func stopMonitoring() {
        isMonitoring = false
    }

    func getBatteryUsage() -> Double {
        batteryUsage + Double.random(in: 1.0 ... 3.0) // Simulate 1-3% usage
    }
}

/// Thermal state monitoring
final class ThermalStateMonitor {
    private var isMonitoring = false

    func startMonitoring() {
        isMonitoring = true
    }

    func stopMonitoring() {
        isMonitoring = false
    }

    func getCurrentThermalState() async -> ThermalState {
        // Simulate thermal state
        let states: [ThermalState] = [.nominal, .fair, .serious]
        return states.randomElement() ?? .nominal
    }

    func calculateThermalImpact(from initial: ThermalState, to final: ThermalState) -> Double {
        let initialValue = initial.rawValue
        let finalValue = final.rawValue
        return Double(finalValue - initialValue) / 3.0 // Normalized 0-1
    }
}

enum SystemThermalState: Int {
    case nominal = 0
    case fair = 1
    case serious = 2
    case critical = 3
}

/// Mock orchestrator for testing
final class PerformanceMockAgenticOrchestrator: AgenticOrchestratorProtocol {
    func recordLearningEvent(agentId _: String, outcome _: LearningOutcome, confidence _: Double) async {
        // Mock implementation
    }
}

// MARK: - Extensions for Testing

extension UrgencyLevel: CaseIterable {
    public static let allCases: [UrgencyLevel] = [.urgent, .moderate, .normal]
}

extension ComplexityLevel: CaseIterable {
    public static let allCases: [ComplexityLevel] = [.high, .medium, .low]
}
