import ComposableArchitecture
import Foundation

/// Demo showcasing cache performance analytics capabilities
@MainActor
public func demonstrateCachePerformanceAnalytics() async throws {
    print("📊 Cache Performance Analytics Demo")
    print("==================================\n")

    // Setup dependencies
    @Dependency(\.cachePerformanceAnalytics) var analytics

    // 1. Simulate cache access events
    print("1️⃣ Simulating Cache Access Events")
    print("   Recording 1000 cache access events...")

    let events = generateSimulatedEvents(count: 1000)
    for event in events {
        await analytics.recordAccess(event)
    }

    print("   ✅ Events recorded successfully")

    // 2. Get performance dashboard
    print("\n2️⃣ Performance Dashboard")
    let dashboard = await analytics.getPerformanceDashboard()

    print("   📈 Current Metrics:")
    print("      Hit Rate: \(String(format: "%.1f%%", dashboard.currentMetrics.hitRate * 100))")
    print("      Average Latency: \(String(format: "%.2fms", dashboard.currentMetrics.averageLatency * 1000))")
    print("      Requests/sec: \(String(format: "%.1f", dashboard.currentMetrics.requestsPerSecond))")
    print("      Memory Usage: \(String(format: "%.1f%%", dashboard.currentMetrics.memoryUsage * 100))")
    print("      Active Entries: \(dashboard.currentMetrics.activeCacheEntries)")

    if !dashboard.alerts.isEmpty {
        print("\n   ⚠️ Active Alerts:")
        for alert in dashboard.alerts {
            print("      - [\(alert.severity)] \(alert.details)")
        }
    }

    if !dashboard.recommendations.isEmpty {
        print("\n   💡 Recommendations:")
        for recommendation in dashboard.recommendations.prefix(3) {
            print("      - \(recommendation.title)")
            print("        Expected: \(String(format: "%.0f%%", recommendation.expectedImprovement.expectedValue * 100)) \(recommendation.expectedImprovement.metric)")
        }
    }

    // 3. Generate analytics report
    print("\n3️⃣ Analytics Report Generation")
    let period = DateInterval(
        start: Date().addingTimeInterval(-3600), // Last hour
        end: Date()
    )

    let report = await analytics.generateAnalyticsReport(
        period: period,
        includeRecommendations: true
    )

    print("   📋 Report Summary:")
    print("      Total Requests: \(report.summary.totalRequests)")
    print("      Average Hit Rate: \(String(format: "%.1f%%", report.summary.averageHitRate * 100))")
    print("      Average Latency: \(String(format: "%.2fms", report.summary.averageLatency * 1000))")
    print("      Performance Score: \(String(format: "%.2f/1.00", report.performanceScore))")

    if !report.patterns.isEmpty {
        print("\n   🔍 Detected Patterns:")
        for pattern in report.patterns {
            print("      - \(pattern.type): \(pattern.description)")
            print("        Frequency: \(String(format: "%.0f%%", pattern.frequency * 100)), Impact: \(pattern.impact)")
        }
    }

    // 4. Performance prediction
    print("\n4️⃣ Performance Prediction")
    let prediction = await analytics.predictPerformance(timeHorizon: 3600) // Next hour

    print("   🔮 Next Hour Predictions:")
    print("      Hit Rate: \(String(format: "%.1f%%", prediction.predictedHitRate.value * 100)) " +
        "(±\(String(format: "%.1f%%", (prediction.predictedHitRate.confidenceInterval.upperBound - prediction.predictedHitRate.value) * 100)))")
    print("      Latency: \(String(format: "%.2fms", prediction.predictedLatency.value * 1000)) " +
        "(±\(String(format: "%.2fms", (prediction.predictedLatency.confidenceInterval.upperBound - prediction.predictedLatency.value) * 1000)))")
    print("      Memory: \(String(format: "%.1f%%", prediction.predictedMemoryUsage.value * 100)) " +
        "(±\(String(format: "%.1f%%", (prediction.predictedMemoryUsage.confidenceInterval.upperBound - prediction.predictedMemoryUsage.value) * 100)))")
    print("      Confidence: \(String(format: "%.0f%%", prediction.confidence * 100))")

    // 5. Real-time monitoring
    print("\n5️⃣ Real-Time Monitoring")
    print("   Starting real-time monitoring stream...")

    let monitoringTask = Task {
        let stream = await analytics.startRealTimeMonitoring()
        var updateCount = 0

        for await update in stream {
            updateCount += 1
            print("   📡 Update #\(updateCount): Hit Rate: \(String(format: "%.1f%%", update.metrics.hitRate * 100)), " +
                "RPS: \(String(format: "%.1f", update.metrics.requestsPerSecond))")

            if updateCount >= 3 {
                break // Show only 3 updates for demo
            }
        }
    }

    // Let monitoring run briefly
    try await Task.sleep(nanoseconds: 3_500_000_000) // 3.5 seconds
    monitoringTask.cancel()
    print("   ⏹️ Monitoring stopped")

    // 6. Cache optimization
    print("\n6️⃣ Cache Configuration Optimization")
    let optimizationPlan = await analytics.optimizeCacheConfiguration()

    if !optimizationPlan.recommendations.isEmpty {
        print("   🔧 Optimization Plan:")
        for change in optimizationPlan.recommendations.prefix(3) {
            print("      - \(change.parameter):")
            print("        Current: \(change.currentValue)")
            print("        Recommended: \(change.recommendedValue)")
            print("        Rationale: \(change.rationale)")
        }

        print("\n   📈 Expected Improvements:")
        for (metric, improvement) in optimizationPlan.expectedImprovements {
            print("      - \(metric): +\(String(format: "%.0f%%", improvement * 100))")
        }
    } else {
        print("   ✅ Cache configuration is already optimal")
    }

    // 7. Advanced analytics scenarios
    print("\n7️⃣ Advanced Analytics Scenarios")
    await demonstrateAdvancedAnalytics()

    print("\n✅ Cache performance analytics demo complete!")
}

/// Generate simulated cache access events
private func generateSimulatedEvents(count: Int) -> [CacheAccessEvent] {
    var events: [CacheAccessEvent] = []
    let baseTime = Date().addingTimeInterval(-3600) // Start 1 hour ago

    // Common cache keys for realistic patterns
    let commonKeys = [
        "user:profile:123",
        "document:template:invoice",
        "config:system:main",
        "session:active:abc",
        "data:report:monthly",
    ]

    // Generate events with realistic patterns
    for i in 0 ..< count {
        let timestamp = baseTime.addingTimeInterval(Double(i) * 3.6) // Spread over 1 hour

        // 80% hit rate
        let isHit = Double.random(in: 0 ... 1) < 0.8

        // Use common keys 70% of the time
        let key = Double.random(in: 0 ... 1) < 0.7 ?
            (commonKeys.randomElement() ?? "user:profile:123") :
            "random:key:\(UUID().uuidString.prefix(8))"

        // Vary latency based on tier and hit type
        let tier = selectTier()
        let baseLatency: TimeInterval = switch tier {
        case .l1Memory: 0.001 // 1ms
        case .l2SSD: 0.005 // 5ms
        case .l3Distributed: 0.02 // 20ms
        case .l4CloudStorage: 0.1 // 100ms
        }

        let latency = isHit ?
            baseLatency * Double.random(in: 0.8 ... 1.2) :
            baseLatency * Double.random(in: 2 ... 5)

        events.append(CacheAccessEvent(
            timestamp: timestamp,
            cacheKey: key,
            tier: tier,
            hitType: isHit ? .hit : .miss,
            latency: latency,
            dataSize: Int.random(in: 100 ... 10000),
            metadata: [
                "source": "demo",
                "userId": "user-\(i % 10)",
            ]
        ))
    }

    return events
}

private func selectTier() -> CacheAccessEvent.CacheTier {
    let random = Double.random(in: 0 ... 1)
    if random < 0.6 {
        return .l1Memory
    } else if random < 0.85 {
        return .l2SSD
    } else if random < 0.95 {
        return .l3Distributed
    } else {
        return .l4CloudStorage
    }
}

/// Demonstrate advanced analytics scenarios
private func demonstrateAdvancedAnalytics() async {
    @Dependency(\.cachePerformanceAnalytics) var analytics

    print("   📊 Scenario: Peak Hour Analysis")

    // Simulate peak hour traffic
    let peakEvents = (0 ..< 500).map { i in
        CacheAccessEvent(
            timestamp: Date(),
            cacheKey: "peak:request:\(i % 50)",
            tier: .l1Memory,
            hitType: i % 10 == 0 ? .miss : .hit,
            latency: Double.random(in: 0.001 ... 0.003),
            dataSize: 1000,
            metadata: ["scenario": "peak"]
        )
    }

    for event in peakEvents {
        await analytics.recordAccess(event)
    }

    print("      - Simulated 500 peak hour requests")
    print("      - Higher hit rate expected for repeated keys")

    print("\n   🔄 Scenario: Cache Invalidation Storm")

    // Simulate invalidation storm
    let stormEvents = (0 ..< 100).map { i in
        CacheAccessEvent(
            timestamp: Date(),
            cacheKey: "invalidated:key:\(i)",
            tier: .l1Memory,
            hitType: .miss,
            latency: Double.random(in: 0.01 ... 0.05),
            dataSize: 5000,
            metadata: ["scenario": "invalidation"]
        )
    }

    for event in stormEvents {
        await analytics.recordAccess(event)
    }

    print("      - Simulated 100 cache misses from invalidation")
    print("      - Performance alerts likely triggered")

    print("\n   🌐 Scenario: Distributed Cache Failover")

    // Simulate distributed cache failover
    let failoverEvents = (0 ..< 50).map { i in
        CacheAccessEvent(
            timestamp: Date(),
            cacheKey: "distributed:data:\(i)",
            tier: i < 25 ? .l3Distributed : .l4CloudStorage,
            hitType: .hit,
            latency: i < 25 ? 0.02 : 0.15, // Fallback to cloud is slower
            dataSize: 10000,
            metadata: ["scenario": "failover"]
        )
    }

    for event in failoverEvents {
        await analytics.recordAccess(event)
    }

    print("      - Simulated distributed cache failover")
    print("      - Latency spike expected during failover")
}

// MARK: - Demo Runner

/// Main entry point for the cache performance analytics demo
public enum CachePerformanceAnalyticsDemoRunner {
    public static func main() async {
        print("Starting Cache Performance Analytics Demo...\n")

        do {
            // Initialize dependencies
            try await withDependencies {
                $0.cachePerformanceAnalytics = CachePerformanceAnalytics()
            } operation: {
                try await demonstrateCachePerformanceAnalytics()
            }
        } catch {
            print("❌ Error: \(error)")
        }
    }
}
