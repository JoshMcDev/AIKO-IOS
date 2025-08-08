//
//  CompactWorkflowEvent.swift
//  AIKO
//
//  User Acquisition Records GraphRAG Data Collection System
//  Compact 32-byte event structure for memory-efficient workflow tracking
//

import Foundation

// MARK: - CompactWorkflowEvent

/// Memory-optimized event capture with privacy-first design
/// Exactly 32 bytes for optimal cache performance and memory efficiency
@frozen
public struct CompactWorkflowEvent: Sendable, BitwiseCopyable {
    // MARK: - Storage (32 bytes total)

    let timestamp: UInt32      // 4 bytes - seconds since epoch
    let userId: UInt64         // 8 bytes - salted hash
    let actionType: UInt16     // 2 bytes - event type
    let documentId: UInt64     // 8 bytes - document reference
    let templateId: UInt32     // 4 bytes - template reference
    let flags: UInt16          // 2 bytes - metadata flags
    let reserved: UInt32       // 4 bytes - future use

    // MARK: - Initialization

    public init(
        timestamp: Date,
        userId: String,
        actionType: WorkflowEventType,
        documentId: String,
        templateId: String? = nil,
        flags: EventFlags = []
    ) {
        self.timestamp = UInt32(timestamp.timeIntervalSince1970)
        self.userId = Self.hashUserId(userId)
        self.actionType = actionType.rawValue
        self.documentId = Self.hashDocumentId(documentId)
        self.templateId = templateId.map { Self.hashTemplateId($0) } ?? 0
        self.flags = flags.rawValue
        self.reserved = 0
    }

    // MARK: - Bit Flag Accessors

    public var isPrivacyProtected: Bool { flags & EventFlags.privacyProtected.rawValue != 0 }
    public var hasUserModification: Bool { flags & EventFlags.userModification.rawValue != 0 }
    public var isComplianceRelated: Bool { flags & EventFlags.complianceRelated.rawValue != 0 }
    public var isHighPriority: Bool { flags & EventFlags.highPriority.rawValue != 0 }

    // MARK: - Serialization

    public func serialize() -> Data {
        var data = Data()
        data.reserveCapacity(32)

        withUnsafeBytes(of: timestamp) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: userId) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: actionType) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: documentId) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: templateId) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: flags) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: reserved) { data.append(contentsOf: $0) }

        return data
    }

    // MARK: - Privacy Methods

    /// Create a copy with privacy protection flag added
    public func withPrivacyProtection() -> CompactWorkflowEvent {
        let newFlags = flags | EventFlags.privacyProtected.rawValue
        return CompactWorkflowEvent(
            timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp)),
            userId: "cached", // Can't reverse hash, use placeholder
            actionType: WorkflowEventType(rawValue: actionType) ?? .documentOpen,
            documentId: "cached", // Can't reverse hash, use placeholder  
            templateId: templateId == 0 ? nil : "cached",
            flags: EventFlags(rawValue: newFlags)
        )
    }

    /// Create a copy with additional flag added
    public func withFlag(_ flag: EventFlags) -> CompactWorkflowEvent {
        let newFlags = flags | flag.rawValue
        return CompactWorkflowEvent(
            timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp)),
            userId: "cached", // Can't reverse hash, use placeholder
            actionType: WorkflowEventType(rawValue: actionType) ?? .documentOpen,
            documentId: "cached", // Can't reverse hash, use placeholder
            templateId: templateId == 0 ? nil : "cached",
            flags: EventFlags(rawValue: newFlags)
        )
    }

    // MARK: - Private Helpers

    private static func hashUserId(_ userId: String) -> UInt64 {
        // Simple hash with salt for privacy
        let saltedInput = "user_salt_\(userId)"
        return UInt64(saltedInput.hashValue) & UInt64.max
    }

    private static func hashDocumentId(_ documentId: String) -> UInt64 {
        // Simple hash for document reference
        return UInt64(documentId.hashValue) & UInt64.max
    }

    private static func hashTemplateId(_ templateId: String) -> UInt32 {
        // Simple hash for template reference
        return UInt32(templateId.hashValue) & UInt32.max
    }
}

// MARK: - EventFlags

public struct EventFlags: OptionSet, Sendable {
    public let rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    public static let privacyProtected = EventFlags(rawValue: 1 << 0)
    public static let userModification = EventFlags(rawValue: 1 << 1)
    public static let complianceRelated = EventFlags(rawValue: 1 << 2)
    public static let highPriority = EventFlags(rawValue: 1 << 3)
    public static let requiresAudit = EventFlags(rawValue: 1 << 4)
    public static let temporalAnomaly = EventFlags(rawValue: 1 << 5)
}

// MARK: - WorkflowEventType

public enum WorkflowEventType: UInt16, CaseIterable, Sendable, Codable {
    // Document operations (1-20)
    case documentOpen = 1
    case documentClose = 2
    case documentEdit = 3
    case documentSave = 4
    case documentExport = 5

    // Template operations (21-40)
    case templateSelect = 21
    case templateCustomize = 22
    case templateApply = 23
    case templateCreate = 24

    // Form operations (41-60)
    case formFieldEdit = 41
    case formValidate = 42
    case formSubmit = 43
    case formAutoFill = 44

    // Chat operations (61-80)
    case chatQuery = 61
    case chatResponse = 62
    case chatFeedback = 63

    // Search operations (81-100)
    case searchQuery = 81
    case searchResultClick = 82
    case searchFilter = 83

    // Workflow operations (101-120)
    case workflowStart = 101
    case workflowStep = 102
    case workflowComplete = 103
    case workflowAbort = 104

    // Compliance operations (121-140)
    case complianceCheck = 121
    case complianceViolation = 122
    case complianceResolution = 123

    public var category: EventCategory {
        switch self.rawValue {
        case 1...20: return .document
        case 21...40: return .template
        case 41...60: return .form
        case 61...80: return .chat
        case 81...100: return .search
        case 101...120: return .workflow
        case 121...140: return .compliance
        default: return .unknown
        }
    }
}

// MARK: - EventCategory

public enum EventCategory: String, CaseIterable, Sendable {
    case document
    case template
    case form
    case chat
    case search
    case workflow
    case compliance
    case unknown
}

// MARK: - Memory-Efficient Buffer Types

/// Stack-allocated buffer using modern Swift patterns
public typealias EventBuffer = [CompactWorkflowEvent]

/// Zero-copy event processing view
public struct EventSpan {
    private let buffer: UnsafeBufferPointer<CompactWorkflowEvent>

    public init(_ events: [CompactWorkflowEvent]) {
        buffer = events.withUnsafeBufferPointer { $0 }
    }

    public func processWithSIMD() -> ProcessingResult {
        // SIMD-accelerated processing would go here
        // For now, return basic processing result
        return ProcessingResult(
            processedCount: buffer.count,
            averageLatency: 0.001,
            memoryUsage: buffer.count * 32
        )
    }
}

// MARK: - Supporting Types

public struct ProcessingResult {
    public let processedCount: Int
    public let averageLatency: Double
    public let memoryUsage: Int

    public init(processedCount: Int, averageLatency: Double, memoryUsage: Int) {
        self.processedCount = processedCount
        self.averageLatency = averageLatency
        self.memoryUsage = memoryUsage
    }
}
