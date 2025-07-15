//
//  UserBehaviorAnalytics.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import Foundation
import UIKit
import Combine
import os.log

/// Collects and analyzes user behavior for pattern learning
@MainActor
final class UserBehaviorAnalytics: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.aiko", category: "BehaviorAnalytics")
    
    /// Analytics event handler
    private var eventHandler: ((AnalyticsEvent) -> Void)?
    
    /// Event buffer for batching
    private var eventBuffer: [AnalyticsEvent] = []
    private let bufferSize = 50
    private let flushInterval: TimeInterval = 30 // seconds
    
    /// Timer for periodic flushing
    private var flushTimer: Timer?
    
    /// Interaction tracking
    private var interactionTracker = InteractionTracker()
    
    /// Session tracker
    private var sessionTracker = SessionTracker()
    
    /// Performance monitor
    private var performanceMonitor = PerformanceMonitor()
    
    /// Gesture recognizer for advanced tracking
    private var gestureAnalyzer = GestureAnalyzer()
    
    /// Event aggregator
    private var eventAggregator = EventAggregator()
    
    /// Active tracking flags
    @Published var isTrackingEnabled = true
    @Published var detailedTrackingEnabled = false
    
    /// Privacy settings
    private var privacySettings = PrivacySettings()
    
    // MARK: - Initialization
    
    init() {
        setupTracking()
        loadPrivacySettings()
    }
    
    deinit {
        stopCollection()
    }
    
    // MARK: - Public Methods
    
    /// Start analytics collection
    func startCollection(handler: @escaping (AnalyticsEvent) -> Void) {
        eventHandler = handler
        isTrackingEnabled = true
        
        // Start flush timer
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            self?.flushEventBuffer()
        }
        
        // Start session
        sessionTracker.startSession()
        
        logger.info("Started behavior analytics collection")
    }
    
    /// Stop analytics collection
    func stopCollection() {
        isTrackingEnabled = false
        flushTimer?.invalidate()
        flushTimer = nil
        
        // Flush remaining events
        flushEventBuffer()
        
        // End session
        sessionTracker.endSession()
        
        logger.info("Stopped behavior analytics collection")
    }
    
    /// Track a user interaction
    func trackInteraction(_ interaction: Interaction) {
        guard isTrackingEnabled else { return }
        
        // Apply privacy filters
        let filteredInteraction = privacySettings.filterInteraction(interaction)
        
        // Create analytics event
        let event = AnalyticsEvent(
            type: "interaction_\(filteredInteraction.type.rawValue)",
            timestamp: Date(),
            properties: filteredInteraction.toProperties()
        )
        
        // Add to buffer
        addEvent(event)
        
        // Update trackers
        interactionTracker.track(filteredInteraction)
        
        if detailedTrackingEnabled {
            // Track additional metrics
            trackDetailedMetrics(for: filteredInteraction)
        }
    }
    
    /// Track screen view
    func trackScreenView(_ screenName: String, properties: [String: Any] = [:]) {
        guard isTrackingEnabled else { return }
        
        var props = properties
        props["screen_name"] = screenName
        props["view_duration"] = interactionTracker.getCurrentScreenDuration()
        
        let event = AnalyticsEvent(
            type: "screen_view",
            timestamp: Date(),
            properties: props
        )
        
        addEvent(event)
        interactionTracker.updateCurrentScreen(screenName)
    }
    
    /// Track form interaction
    func trackFormInteraction(
        formType: String,
        fieldName: String,
        action: FormAction,
        value: Any? = nil
    ) {
        guard isTrackingEnabled else { return }
        
        var properties: [String: Any] = [
            "formType": formType,
            "fieldName": fieldName,
            "action": action.rawValue
        ]
        
        // Don't track sensitive values
        if let value = value, !privacySettings.isSensitiveField(fieldName) {
            properties["value"] = "\(value)"
        }
        
        let event = AnalyticsEvent(
            type: "form_interaction",
            timestamp: Date(),
            properties: properties
        )
        
        addEvent(event)
    }
    
    /// Track workflow step
    func trackWorkflowStep(
        workflowId: String,
        stepName: String,
        stepIndex: Int,
        metadata: [String: Any] = [:]
    ) {
        guard isTrackingEnabled else { return }
        
        var properties = metadata
        properties["workflowId"] = workflowId
        properties["stepName"] = stepName
        properties["stepIndex"] = stepIndex
        properties["timestamp"] = Date().timeIntervalSince1970
        
        let event = AnalyticsEvent(
            type: "workflow_step",
            timestamp: Date(),
            properties: properties
        )
        
        addEvent(event)
        
        // Track workflow patterns
        sessionTracker.addWorkflowStep(workflowId: workflowId, step: stepName)
    }
    
    /// Track error occurrence
    func trackError(
        errorType: String,
        errorContext: String,
        recovery: String? = nil
    ) {
        guard isTrackingEnabled else { return }
        
        var properties: [String: Any] = [
            "errorType": errorType,
            "errorContext": errorContext
        ]
        
        if let recovery = recovery {
            properties["recovery"] = recovery
        }
        
        let event = AnalyticsEvent(
            type: "error",
            timestamp: Date(),
            properties: properties
        )
        
        addEvent(event)
        
        // Track error patterns
        interactionTracker.recordError(type: errorType)
    }
    
    /// Track performance metric
    func trackPerformance(
        metric: PerformanceMetric,
        value: Double,
        context: String? = nil
    ) {
        guard isTrackingEnabled else { return }
        
        performanceMonitor.record(metric: metric, value: value)
        
        var properties: [String: Any] = [
            "metric": metric.rawValue,
            "value": value
        ]
        
        if let context = context {
            properties["context"] = context
        }
        
        let event = AnalyticsEvent(
            type: "performance",
            timestamp: Date(),
            properties: properties
        )
        
        addEvent(event)
    }
    
    /// Get current session summary
    func getSessionSummary() -> SessionSummary {
        return sessionTracker.getCurrentSummary()
    }
    
    /// Get interaction patterns
    func getInteractionPatterns() -> [InteractionPattern] {
        return interactionTracker.getPatterns()
    }
    
    /// Get performance report
    func getPerformanceReport() -> PerformanceReport {
        return performanceMonitor.generateReport()
    }
    
    // MARK: - Private Methods
    
    private func setupTracking() {
        // Set up UI tracking
        setupUITracking()
        
        // Set up gesture tracking
        if detailedTrackingEnabled {
            setupGestureTracking()
        }
        
        // Set up performance monitoring
        performanceMonitor.startMonitoring()
    }
    
    private func setupUITracking() {
        // Track app lifecycle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    private func setupGestureTracking() {
        // Advanced gesture tracking for detailed analytics
        gestureAnalyzer.startAnalysis { [weak self] gesture in
            self?.trackGesture(gesture)
        }
    }
    
    @objc private func appDidBecomeActive() {
        trackInteraction(Interaction(
            type: .appLaunch,
            target: "application",
            metadata: ["source": "foreground"]
        ))
    }
    
    @objc private func appWillResignActive() {
        trackInteraction(Interaction(
            type: .appBackground,
            target: "application",
            metadata: ["duration": sessionTracker.getCurrentSessionDuration()]
        ))
    }
    
    private func trackGesture(_ gesture: GestureData) {
        guard detailedTrackingEnabled else { return }
        
        let event = AnalyticsEvent(
            type: "gesture_\(gesture.type)",
            timestamp: Date(),
            properties: gesture.toProperties()
        )
        
        addEvent(event)
    }
    
    private func trackDetailedMetrics(for interaction: Interaction) {
        // Track interaction velocity
        let velocity = interactionTracker.calculateInteractionVelocity()
        trackPerformance(metric: .interactionVelocity, value: velocity)
        
        // Track context switches
        if interaction.type == .navigation {
            let switches = interactionTracker.getContextSwitchCount()
            trackPerformance(metric: .contextSwitches, value: Double(switches))
        }
    }
    
    private func addEvent(_ event: AnalyticsEvent) {
        eventBuffer.append(event)
        
        // Aggregate event
        eventAggregator.aggregate(event)
        
        // Flush if buffer is full
        if eventBuffer.count >= bufferSize {
            flushEventBuffer()
        }
    }
    
    private func flushEventBuffer() {
        guard !eventBuffer.isEmpty else { return }
        
        let eventsToFlush = eventBuffer
        eventBuffer.removeAll()
        
        // Process events
        for event in eventsToFlush {
            eventHandler?(event)
        }
        
        logger.debug("Flushed \(eventsToFlush.count) analytics events")
    }
    
    private func loadPrivacySettings() {
        // Load from UserDefaults or configuration
        privacySettings = PrivacySettings.load()
    }
}

// MARK: - Supporting Types

struct Interaction {
    let type: InteractionType
    let target: String
    let metadata: [String: Any]
    let timestamp: Date = Date()
    
    func toProperties() -> [String: Any] {
        var props = metadata
        props["type"] = type.rawValue
        props["target"] = target
        props["timestamp"] = timestamp.timeIntervalSince1970
        return props
    }
}

enum InteractionType: String {
    case tap = "tap"
    case swipe = "swipe"
    case longPress = "long_press"
    case navigation = "navigation"
    case formInput = "form_input"
    case buttonClick = "button_click"
    case appLaunch = "app_launch"
    case appBackground = "app_background"
}

enum FormAction: String {
    case focus = "focus"
    case blur = "blur"
    case change = "change"
    case submit = "submit"
    case clear = "clear"
}

enum PerformanceMetric: String {
    case screenLoadTime = "screen_load_time"
    case apiResponseTime = "api_response_time"
    case formCompletionTime = "form_completion_time"
    case workflowCompletionTime = "workflow_completion_time"
    case interactionVelocity = "interaction_velocity"
    case contextSwitches = "context_switches"
    case memoryUsage = "memory_usage"
    case cpuUsage = "cpu_usage"
}

// MARK: - Tracking Components

class InteractionTracker {
    private var interactions: [Interaction] = []
    private var currentScreen: String?
    private var screenStartTime: Date?
    private var errorCounts: [String: Int] = [:]
    private var lastInteractionTime: Date?
    
    func track(_ interaction: Interaction) {
        interactions.append(interaction)
        lastInteractionTime = Date()
        
        // Keep only recent interactions
        if interactions.count > 1000 {
            interactions.removeFirst(500)
        }
    }
    
    func updateCurrentScreen(_ screen: String) {
        currentScreen = screen
        screenStartTime = Date()
    }
    
    func getCurrentScreenDuration() -> TimeInterval {
        guard let startTime = screenStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    func recordError(type: String) {
        errorCounts[type, default: 0] += 1
    }
    
    func calculateInteractionVelocity() -> Double {
        guard interactions.count >= 2 else { return 0 }
        
        let recentInteractions = interactions.suffix(10)
        guard recentInteractions.count >= 2 else { return 0 }
        
        let timeSpan = recentInteractions.last!.timestamp.timeIntervalSince(recentInteractions.first!.timestamp)
        return timeSpan > 0 ? Double(recentInteractions.count) / timeSpan : 0
    }
    
    func getContextSwitchCount() -> Int {
        var switches = 0
        var lastContext: String?
        
        for interaction in interactions where interaction.type == .navigation {
            if let context = interaction.metadata["context"] as? String,
               context != lastContext {
                switches += 1
                lastContext = context
            }
        }
        
        return switches
    }
    
    func getPatterns() -> [InteractionPattern] {
        // Analyze interaction sequences for patterns
        var patterns: [InteractionPattern] = []
        
        // Find common sequences
        let sequences = findCommonSequences()
        for sequence in sequences {
            patterns.append(InteractionPattern(
                sequence: sequence.interactions,
                frequency: sequence.count,
                averageDuration: sequence.duration
            ))
        }
        
        return patterns
    }
    
    private func findCommonSequences() -> [(interactions: [InteractionType], count: Int, duration: TimeInterval)] {
        // Simplified pattern detection
        var sequences: [[InteractionType]: (count: Int, totalDuration: TimeInterval)] = [:]
        
        for i in 0..<max(0, interactions.count - 2) {
            let sequence = [
                interactions[i].type,
                interactions[i + 1].type,
                interactions[i + 2].type
            ]
            
            let duration = interactions[i + 2].timestamp.timeIntervalSince(interactions[i].timestamp)
            
            if var existing = sequences[sequence] {
                existing.count += 1
                existing.totalDuration += duration
                sequences[sequence] = existing
            } else {
                sequences[sequence] = (count: 1, totalDuration: duration)
            }
        }
        
        return sequences.compactMap { key, value in
            guard value.count >= 3 else { return nil }
            return (interactions: key, count: value.count, duration: value.totalDuration / Double(value.count))
        }
    }
}

class SessionTracker {
    private var sessionId: UUID?
    private var sessionStartTime: Date?
    private var workflowSteps: [String: [String]] = [:]
    private var screenViews: [String] = []
    
    func startSession() {
        sessionId = UUID()
        sessionStartTime = Date()
        workflowSteps.removeAll()
        screenViews.removeAll()
    }
    
    func endSession() {
        sessionId = nil
        sessionStartTime = nil
    }
    
    func addWorkflowStep(workflowId: String, step: String) {
        workflowSteps[workflowId, default: []].append(step)
    }
    
    func getCurrentSessionDuration() -> TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    func getCurrentSummary() -> SessionSummary {
        return SessionSummary(
            sessionId: sessionId,
            duration: getCurrentSessionDuration(),
            workflowCount: workflowSteps.count,
            screenViewCount: screenViews.count,
            completedWorkflows: workflowSteps.filter { isWorkflowComplete($0.value) }.count
        )
    }
    
    private func isWorkflowComplete(_ steps: [String]) -> Bool {
        // Simple heuristic - workflow is complete if it has expected steps
        return steps.contains { $0.lowercased().contains("complete") || $0.lowercased().contains("submit") }
    }
}

class PerformanceMonitor {
    private var metrics: [PerformanceMetric: [Double]] = [:]
    private var monitoringTimer: Timer?
    
    func startMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.collectSystemMetrics()
        }
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    func record(metric: PerformanceMetric, value: Double) {
        metrics[metric, default: []].append(value)
        
        // Keep only recent values
        if metrics[metric]!.count > 100 {
            metrics[metric]!.removeFirst(50)
        }
    }
    
    func generateReport() -> PerformanceReport {
        var report = PerformanceReport()
        
        for (metric, values) in metrics {
            guard !values.isEmpty else { continue }
            
            let stats = PerformanceStats(
                metric: metric,
                average: values.reduce(0, +) / Double(values.count),
                min: values.min() ?? 0,
                max: values.max() ?? 0,
                count: values.count
            )
            
            report.stats.append(stats)
        }
        
        return report
    }
    
    private func collectSystemMetrics() {
        // Memory usage
        let memoryUsage = Double(getMemoryUsage()) / 1024.0 / 1024.0 // MB
        record(metric: .memoryUsage, value: memoryUsage)
        
        // CPU usage would require more complex implementation
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

class GestureAnalyzer {
    private var gestureHandler: ((GestureData) -> Void)?
    
    func startAnalysis(handler: @escaping (GestureData) -> Void) {
        gestureHandler = handler
        // Would integrate with UIGestureRecognizer system
    }
    
    func stopAnalysis() {
        gestureHandler = nil
    }
}

class EventAggregator {
    private var eventCounts: [String: Int] = [:]
    private var eventTimings: [String: [TimeInterval]] = [:]
    
    func aggregate(_ event: AnalyticsEvent) {
        eventCounts[event.type, default: 0] += 1
        
        // Track timing patterns
        if let lastTiming = eventTimings[event.type]?.last {
            let interval = event.timestamp.timeIntervalSince1970 - lastTiming
            eventTimings[event.type, default: []].append(interval)
        } else {
            eventTimings[event.type] = [event.timestamp.timeIntervalSince1970]
        }
    }
    
    func getAggregatedData() -> AggregatedAnalytics {
        return AggregatedAnalytics(
            eventCounts: eventCounts,
            averageIntervals: eventTimings.mapValues { intervals in
                intervals.count > 1 ? intervals.reduce(0, +) / Double(intervals.count) : 0
            }
        )
    }
}

// MARK: - Privacy

struct PrivacySettings {
    var trackSensitiveFields = false
    var sensitiveFieldPatterns = [
        "password", "ssn", "social_security", "credit_card",
        "bank_account", "routing_number", "pin", "cvv"
    ]
    
    func filterInteraction(_ interaction: Interaction) -> Interaction {
        var filtered = interaction
        
        // Remove sensitive metadata
        var filteredMetadata = interaction.metadata
        for (key, _) in filteredMetadata {
            if isSensitiveField(key) {
                filteredMetadata[key] = "[REDACTED]"
            }
        }
        
        return Interaction(
            type: filtered.type,
            target: filtered.target,
            metadata: filteredMetadata
        )
    }
    
    func isSensitiveField(_ fieldName: String) -> Bool {
        let lowercased = fieldName.lowercased()
        return sensitiveFieldPatterns.contains { lowercased.contains($0) }
    }
    
    static func load() -> PrivacySettings {
        // Load from UserDefaults or configuration
        return PrivacySettings()
    }
}

// MARK: - Data Models

struct SessionSummary {
    let sessionId: UUID?
    let duration: TimeInterval
    let workflowCount: Int
    let screenViewCount: Int
    let completedWorkflows: Int
}

struct InteractionPattern {
    let sequence: [InteractionType]
    let frequency: Int
    let averageDuration: TimeInterval
}

struct PerformanceReport {
    var stats: [PerformanceStats] = []
    var timestamp = Date()
}

struct PerformanceStats {
    let metric: PerformanceMetric
    let average: Double
    let min: Double
    let max: Double
    let count: Int
}

struct GestureData {
    let type: String
    let location: CGPoint
    let velocity: CGPoint?
    let duration: TimeInterval?
    
    func toProperties() -> [String: Any] {
        var props: [String: Any] = [
            "type": type,
            "x": location.x,
            "y": location.y
        ]
        
        if let velocity = velocity {
            props["velocity_x"] = velocity.x
            props["velocity_y"] = velocity.y
        }
        
        if let duration = duration {
            props["duration"] = duration
        }
        
        return props
    }
}

struct AggregatedAnalytics {
    let eventCounts: [String: Int]
    let averageIntervals: [String: TimeInterval]
}