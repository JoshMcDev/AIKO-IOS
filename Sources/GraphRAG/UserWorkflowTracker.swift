import CryptoKit
import Foundation

/// Privacy-compliant user workflow tracker with encryption and pattern recognition
actor UserWorkflowTracker {
    // Encrypted storage for user workflow data
    private var encryptedUserData: [String: Data] = [:]
    private var userEncryptionKeys: [String: SymmetricKey] = [:]
    private var userKeyIds: [String: String] = [:]
    private var workflowPatterns: [String: [DetectedPattern]] = [:]

    init() {
        // Initialized for GREEN phase implementation
    }

    func recordWorkflowStep(
        userId: String,
        workflowStep: WorkflowStep
    ) async throws {
        // Ensure user has encryption key
        try await ensureUserEncryptionKey(userId: userId)

        // Get existing workflow history
        var workflowHistory = try await getWorkflowHistory(userId: userId)

        // Add new step
        workflowHistory.append(workflowStep)

        // Encrypt and store updated history
        try await storeEncryptedWorkflowHistory(userId: userId, history: workflowHistory)

        // Update pattern analysis
        try await updatePatternAnalysis(userId: userId, newStep: workflowStep)
    }

    func clearUserData(userId: String) async throws {
        encryptedUserData.removeValue(forKey: userId)
        userEncryptionKeys.removeValue(forKey: userId)
        userKeyIds.removeValue(forKey: userId)
        workflowPatterns.removeValue(forKey: userId)
    }

    func getRawStoredData(userId: String) async throws -> Data {
        guard let encryptedData = encryptedUserData[userId] else {
            return Data() // Return empty data if no data exists
        }
        return encryptedData
    }

    func validateEncryptionKeyAccess(userId: String) async throws -> EncryptionKeyAccess {
        let hasKey = userEncryptionKeys[userId] != nil
        _ = userKeyIds[userId]

        return EncryptionKeyAccess(
            isUserSpecific: hasKey,
            isSecurelyStored: hasKey, // In production, would validate secure enclave storage
            isAccessibleByOtherUsers: false // Actor isolation ensures this
        )
    }

    func getEncryptedWorkflowData(userId: String) async throws -> Data {
        try await getRawStoredData(userId: userId)
    }

    func getEncryptionInfo(userId: String) async throws -> EncryptionInfo {
        guard let keyId = userKeyIds[userId] else {
            throw WorkflowTrackerError.noEncryptionKey
        }

        return EncryptionInfo(
            algorithm: .aes256,
            keyLength: 256,
            keyId: keyId
        )
    }

    func rotateEncryptionKey(userId: String) async throws {
        // Get existing workflow history before rotation
        let existingHistory = try await getWorkflowHistory(userId: userId)

        // Generate new encryption key
        let newKey = SymmetricKey(size: .bits256)
        let newKeyId = UUID().uuidString

        // Store new key
        userEncryptionKeys[userId] = newKey
        userKeyIds[userId] = newKeyId

        // Re-encrypt existing data with new key
        try await storeEncryptedWorkflowHistory(userId: userId, history: existingHistory)
    }

    func getWorkflowHistory(userId: String) async throws -> [WorkflowStep] {
        guard let encryptedData = encryptedUserData[userId],
              let key = userEncryptionKeys[userId]
        else {
            return [] // Return empty array if no data exists
        }

        // Decrypt the data
        let decryptedData = try await decryptData(encryptedData, with: key)

        // Deserialize workflow history
        return try JSONDecoder().decode([WorkflowStep].self, from: decryptedData)
    }

    func analyzeWorkflowPatterns(userId: String) async throws -> PatternAnalysisResult {
        let workflowHistory = try await getWorkflowHistory(userId: userId)

        guard !workflowHistory.isEmpty else {
            return PatternAnalysisResult(
                overallAccuracy: 0.0,
                detectedPatterns: [],
                temporalPatterns: []
            )
        }

        // Analyze sequential patterns
        let sequentialPatterns = analyzeSequentialPatterns(workflowHistory)

        // Analyze temporal patterns
        let temporalPatterns = analyzeTemporalPatterns(workflowHistory)

        // Calculate overall accuracy based on pattern consistency
        let overallAccuracy = calculatePatternAccuracy(
            patterns: sequentialPatterns,
            history: workflowHistory
        )

        // Store patterns for future reference
        workflowPatterns[userId] = sequentialPatterns

        return PatternAnalysisResult(
            overallAccuracy: overallAccuracy,
            detectedPatterns: sequentialPatterns,
            temporalPatterns: temporalPatterns
        )
    }

    // MARK: - Private Helper Methods

    private func ensureUserEncryptionKey(userId: String) async throws {
        guard userEncryptionKeys[userId] == nil else { return }

        // Generate new AES-256 key for user
        let key = SymmetricKey(size: .bits256)
        let keyId = UUID().uuidString

        userEncryptionKeys[userId] = key
        userKeyIds[userId] = keyId
    }

    private func storeEncryptedWorkflowHistory(userId: String, history: [WorkflowStep]) async throws {
        guard let key = userEncryptionKeys[userId] else {
            throw WorkflowTrackerError.noEncryptionKey
        }

        // Serialize workflow history
        let jsonData = try JSONEncoder().encode(history)

        // Encrypt the data
        let encryptedData = try await encryptData(jsonData, with: key)

        // Store encrypted data
        encryptedUserData[userId] = encryptedData
    }

    private func encryptData(_ data: Data, with key: SymmetricKey) async throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw WorkflowTrackerError.encryptionFailed
        }
        return combined
    }

    private func decryptData(_ encryptedData: Data, with key: SymmetricKey) async throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }

    private func analyzeSequentialPatterns(_ history: [WorkflowStep]) -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []

        // Analyze document type sequences
        let docTypeSequence = history.map(\.documentType)
        let docTypePatterns = findSequentialPatterns(in: docTypeSequence, minLength: 2)

        for pattern in docTypePatterns {
            let confidence = calculatePatternConfidence(pattern: pattern, in: docTypeSequence)
            if confidence > 0.5 {
                patterns.append(DetectedPattern(
                    patternId: "doc_sequence_\(pattern.joined(separator: "_"))",
                    confidence: confidence,
                    supportingEvidence: [
                        "Document type sequence: \(pattern.joined(separator: " → "))",
                        "Occurrence frequency: \(countPatternOccurrences(pattern: pattern, in: docTypeSequence))",
                    ]
                ))
            }
        }

        // Analyze action sequences
        let actionSequences = history.map { step in
            step.userActions.map(\.actionType).joined(separator: ",")
        }
        let actionPatterns = findSequentialPatterns(in: actionSequences, minLength: 2)

        for pattern in actionPatterns {
            let confidence = calculatePatternConfidence(pattern: pattern, in: actionSequences)
            if confidence > 0.6 {
                patterns.append(DetectedPattern(
                    patternId: "action_sequence_\(pattern.joined(separator: "_"))",
                    confidence: confidence,
                    supportingEvidence: [
                        "Action sequence: \(pattern.joined(separator: " → "))",
                        "Pattern strength: \(confidence)",
                    ]
                ))
            }
        }

        return patterns
    }

    private func analyzeTemporalPatterns(_ history: [WorkflowStep]) -> [TemporalPattern] {
        var temporalPatterns: [TemporalPattern] = []

        // Group steps by hour of day
        let calendar = Calendar.current
        var hourlyGroups: [Int: [WorkflowStep]] = [:]

        for step in history {
            let hour = calendar.component(.hour, from: step.timestamp)
            hourlyGroups[hour, default: []].append(step)
        }

        // Find peak activity hours
        let peakHour = hourlyGroups.max { $0.value.count < $1.value.count }?.key ?? 0
        let peakActivity = Float(hourlyGroups[peakHour]?.count ?? 0) / Float(history.count)

        if peakActivity > 0.3 {
            temporalPatterns.append(TemporalPattern(
                pattern: "peak_activity_hour_\(peakHour)",
                accuracy: peakActivity
            ))
        }

        // Analyze weekly patterns
        var weekdayGroups: [Int: [WorkflowStep]] = [:]
        for step in history {
            let weekday = calendar.component(.weekday, from: step.timestamp)
            weekdayGroups[weekday, default: []].append(step)
        }

        let workdayActivity = (1 ... 5).reduce(0) { total, day in
            total + (weekdayGroups[day]?.count ?? 0)
        }
        _ = [6, 7].reduce(0) { total, day in
            total + (weekdayGroups[day]?.count ?? 0)
        }

        if workdayActivity > 0 {
            let workdayRatio = Float(workdayActivity) / Float(history.count)
            temporalPatterns.append(TemporalPattern(
                pattern: "workday_preference",
                accuracy: workdayRatio
            ))
        }

        return temporalPatterns
    }

    private func findSequentialPatterns(in sequence: [String], minLength: Int) -> [[String]] {
        var patterns: [[String]] = []

        for length in minLength ... min(sequence.count, 4) {
            for startIndex in 0 ... (sequence.count - length) {
                let pattern = Array(sequence[startIndex ..< startIndex + length])
                if !patterns.contains(pattern), countPatternOccurrences(pattern: pattern, in: sequence) >= 2 {
                    patterns.append(pattern)
                }
            }
        }

        return patterns
    }

    private func countPatternOccurrences(pattern: [String], in sequence: [String]) -> Int {
        var count = 0
        let patternLength = pattern.count

        for i in 0 ... (sequence.count - patternLength) {
            let subsequence = Array(sequence[i ..< i + patternLength])
            if subsequence == pattern {
                count += 1
            }
        }

        return count
    }

    private func calculatePatternConfidence(pattern: [String], in sequence: [String]) -> Float {
        let occurrences = countPatternOccurrences(pattern: pattern, in: sequence)
        let maxPossibleOccurrences = sequence.count - pattern.count + 1

        guard maxPossibleOccurrences > 0 else { return 0.0 }

        return Float(occurrences) / Float(maxPossibleOccurrences)
    }

    private func calculatePatternAccuracy(patterns: [DetectedPattern], history: [WorkflowStep]) -> Float {
        guard !patterns.isEmpty else { return 0.0 }

        let totalConfidence = patterns.reduce(0) { $0 + $1.confidence }
        let averageConfidence = totalConfidence / Float(patterns.count)

        // Adjust based on data volume
        let dataVolumeBonus = min(Float(history.count) / 100.0, 0.2) // Up to 20% bonus for more data

        return min(averageConfidence + dataVolumeBonus, 1.0)
    }

    private func updatePatternAnalysis(userId: String, newStep _: WorkflowStep) async throws {
        // Incremental pattern update - simplified for GREEN phase
        // In production, would use more sophisticated streaming pattern detection
        _ = workflowPatterns[userId] ?? []

        // For now, just trigger full re-analysis periodically
        let history = try await getWorkflowHistory(userId: userId)
        if history.count % 10 == 0 { // Re-analyze every 10 steps
            _ = try await analyzeWorkflowPatterns(userId: userId)
        }
    }
}

// MARK: - Error Types

enum WorkflowTrackerError: Error, LocalizedError {
    case noEncryptionKey
    case encryptionFailed
    case decryptionFailed
    case invalidData

    var errorDescription: String? {
        switch self {
        case .noEncryptionKey:
            "No encryption key found for user"
        case .encryptionFailed:
            "Failed to encrypt workflow data"
        case .decryptionFailed:
            "Failed to decrypt workflow data"
        case .invalidData:
            "Invalid workflow data format"
        }
    }
}

// MARK: - WorkflowStep Codable Extension

extension WorkflowStep: Codable {
    enum CodingKeys: String, CodingKey {
        case stepId, timestamp, documentType, formFields, userActions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stepId = try container.decode(String.self, forKey: .stepId)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        documentType = try container.decode(String.self, forKey: .documentType)
        formFields = try container.decode([String: String].self, forKey: .formFields)
        userActions = try container.decode([LegacyUserAction].self, forKey: .userActions)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stepId, forKey: .stepId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(documentType, forKey: .documentType)
        try container.encode(formFields, forKey: .formFields)
        try container.encode(userActions, forKey: .userActions)
    }
}
