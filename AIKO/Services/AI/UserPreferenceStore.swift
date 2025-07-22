//
//  UserPreferenceStore.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import CoreData
import Foundation
import os.log

/// Manages storage and retrieval of user preferences learned from patterns
@MainActor
final class UserPreferenceStore {
    // MARK: - Properties

    private let persistenceController = PersistenceController.shared
    private var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }

    private let logger = Logger(subsystem: "com.aiko", category: "PreferenceStore")

    /// In-memory cache for quick access
    private var preferenceCache: [String: UserPreference] = [:]

    /// Cache expiration time (5 minutes)
    private let cacheExpiration: TimeInterval = 300

    /// Last cache update time
    private var lastCacheUpdate: Date = .init()

    // MARK: - Preference Categories

    enum PreferenceCategory: String, CaseIterable {
        case formDefaults = "form_defaults"
        case workflowPreferences = "workflow_preferences"
        case documentTypes = "document_types"
        case fieldValidation = "field_validation"
        case navigationShortcuts = "navigation_shortcuts"
        case automationSettings = "automation_settings"
        case notificationPreferences = "notification_preferences"
        case dataEntryPatterns = "data_entry_patterns"
    }

    // MARK: - Initialization

    init() {
        loadPreferencesIntoCache()
        setupObservers()
    }

    // MARK: - Public Methods

    /// Store a user preference
    func storePreference(_ preference: UserPreference) async throws {
        // Update cache
        let cacheKey = generateCacheKey(for: preference)
        preferenceCache[cacheKey] = preference

        // Persist to Core Data
        try await persistPreference(preference)

        logger.info("Stored preference: \(preference.key) in category: \(preference.category)")
    }

    /// Retrieve a preference by key and category
    func getPreference(key: String, category: PreferenceCategory, userId: String) -> UserPreference? {
        // Check cache first
        if isCacheValid() {
            let cacheKey = "\(userId)_\(category.rawValue)_\(key)"
            if let cached = preferenceCache[cacheKey] {
                return cached
            }
        }

        // Fetch from Core Data
        return fetchPreference(key: key, category: category, userId: userId)
    }

    /// Get all preferences for a category
    func getPreferences(for category: PreferenceCategory, userId: String) -> [UserPreference] {
        if !isCacheValid() {
            refreshCache()
        }

        return preferenceCache.values.filter {
            $0.category == category.rawValue && $0.userId == userId
        }
    }

    /// Get preferences matching a context
    func getContextualPreferences(context: PreferenceContext, userId: String) -> [UserPreference] {
        let allPreferences = getAllUserPreferences(userId: userId)

        return allPreferences.filter { preference in
            preference.matchesContext(context)
        }
    }

    /// Update preference value
    func updatePreference(
        key: String,
        category: PreferenceCategory,
        userId: String,
        newValue: Any,
        confidence: Double? = nil
    ) async throws {
        if var preference = getPreference(key: key, category: category, userId: userId) {
            preference.value = newValue
            preference.lastModified = Date()
            preference.usageCount += 1

            if let confidence {
                preference.confidence = confidence
            }

            try await storePreference(preference)
        } else {
            // Create new preference
            let preference = UserPreference(
                id: UUID(),
                userId: userId,
                key: key,
                category: category.rawValue,
                value: newValue,
                confidence: confidence ?? 0.5,
                context: [:],
                lastModified: Date(),
                usageCount: 1
            )

            try await storePreference(preference)
        }
    }

    /// Delete a preference
    func deletePreference(key: String, category: PreferenceCategory, userId: String) async throws {
        let cacheKey = "\(userId)_\(category.rawValue)_\(key)"
        preferenceCache.removeValue(forKey: cacheKey)

        // Delete from Core Data
        let request: NSFetchRequest<PreferenceEntity> = PreferenceEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "userId == %@ AND category == %@ AND key == %@",
            userId, category.rawValue, key
        )

        do {
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()

            logger.info("Deleted preference: \(key)")
        } catch {
            logger.error("Failed to delete preference: \(error.localizedDescription)")
            throw error
        }
    }

    /// Get preference statistics
    func getPreferenceStatistics(userId: String) -> PreferenceStatistics {
        let allPreferences = getAllUserPreferences(userId: userId)

        var stats = PreferenceStatistics(
            totalPreferences: allPreferences.count,
            categoryCounts: [:],
            averageConfidence: 0,
            mostUsedPreferences: [],
            recentlyModified: []
        )

        // Category counts
        for category in PreferenceCategory.allCases {
            let count = allPreferences.filter { $0.category == category.rawValue }.count
            stats.categoryCounts[category.rawValue] = count
        }

        // Average confidence
        if !allPreferences.isEmpty {
            let totalConfidence = allPreferences.reduce(0) { $0 + $1.confidence }
            stats.averageConfidence = totalConfidence / Double(allPreferences.count)
        }

        // Most used preferences (top 10)
        stats.mostUsedPreferences = Array(
            allPreferences
                .sorted { $0.usageCount > $1.usageCount }
                .prefix(10)
        )

        // Recently modified (last 10)
        stats.recentlyModified = Array(
            allPreferences
                .sorted { $0.lastModified > $1.lastModified }
                .prefix(10)
        )

        return stats
    }

    /// Export preferences for backup
    func exportPreferences(userId: String) throws -> Data {
        let preferences = getAllUserPreferences(userId: userId)

        let exportData = PreferenceExportData(
            version: "1.0",
            exportDate: Date(),
            userId: userId,
            preferences: preferences
        )

        return try JSONEncoder().encode(exportData)
    }

    /// Import preferences from backup
    func importPreferences(data: Data) async throws {
        let exportData = try JSONDecoder().decode(PreferenceExportData.self, from: data)

        // Clear existing preferences for user
        try await clearUserPreferences(userId: exportData.userId)

        // Import new preferences
        for preference in exportData.preferences {
            try await storePreference(preference)
        }

        logger.info("Imported \(exportData.preferences.count) preferences for user \(exportData.userId)")
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observe Core Data changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave(_:)),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }

    @objc private func contextDidSave(_ notification: Notification) {
        // Invalidate cache on external changes
        if notification.object as? NSManagedObjectContext != context {
            lastCacheUpdate = Date.distantPast
        }
    }

    private func loadPreferencesIntoCache() {
        let request: NSFetchRequest<PreferenceEntity> = PreferenceEntity.fetchRequest()

        do {
            let entities = try context.fetch(request)

            for entity in entities {
                if let preference = UserPreference(from: entity) {
                    let cacheKey = generateCacheKey(for: preference)
                    preferenceCache[cacheKey] = preference
                }
            }

            lastCacheUpdate = Date()
            logger.info("Loaded \(preferenceCache.count) preferences into cache")
        } catch {
            logger.error("Failed to load preferences: \(error.localizedDescription)")
        }
    }

    private func isCacheValid() -> Bool {
        Date().timeIntervalSince(lastCacheUpdate) < cacheExpiration
    }

    private func refreshCache() {
        loadPreferencesIntoCache()
    }

    private func generateCacheKey(for preference: UserPreference) -> String {
        "\(preference.userId)_\(preference.category)_\(preference.key)"
    }

    private func persistPreference(_ preference: UserPreference) async throws {
        // Check if preference exists
        let request: NSFetchRequest<PreferenceEntity> = PreferenceEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "id == %@",
            preference.id as CVarArg
        )

        do {
            let entities = try context.fetch(request)

            let entity: PreferenceEntity = if let existingEntity = entities.first {
                existingEntity
            } else {
                PreferenceEntity(context: context)
            }

            // Update entity
            preference.populate(entity)

            try context.save()
        } catch {
            logger.error("Failed to persist preference: \(error.localizedDescription)")
            throw error
        }
    }

    private func fetchPreference(key: String, category: PreferenceCategory, userId: String) -> UserPreference? {
        let request: NSFetchRequest<PreferenceEntity> = PreferenceEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "userId == %@ AND category == %@ AND key == %@",
            userId, category.rawValue, key
        )
        request.fetchLimit = 1

        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                return UserPreference(from: entity)
            }
        } catch {
            logger.error("Failed to fetch preference: \(error.localizedDescription)")
        }

        return nil
    }

    private func getAllUserPreferences(userId: String) -> [UserPreference] {
        if !isCacheValid() {
            refreshCache()
        }

        return preferenceCache.values.filter { $0.userId == userId }
    }

    private func clearUserPreferences(userId: String) async throws {
        // Clear from cache
        preferenceCache = preferenceCache.filter { $0.value.userId != userId }

        // Clear from Core Data
        let request: NSFetchRequest<NSFetchRequestResult> = PreferenceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)

        let batchDelete = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(batchDelete)
            try context.save()
        } catch {
            logger.error("Failed to clear user preferences: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Data Models

struct UserPreference: Identifiable, Codable {
    let id: UUID
    let userId: String
    let key: String
    let category: String
    var value: Any
    var confidence: Double
    var context: [String: Any]
    var lastModified: Date
    var usageCount: Int

    func matchesContext(_ queryContext: PreferenceContext) -> Bool {
        // Check if all query context keys match
        for (key, value) in queryContext.attributes {
            if let storedValue = context[key] as? String,
               let queryValue = value as? String {
                if storedValue != queryValue {
                    return false
                }
            }
        }
        return true
    }

    // Custom Codable implementation to handle Any type
    enum CodingKeys: String, CodingKey {
        case id, userId, key, category, confidence, lastModified, usageCount
        case valueData, valueType, contextData
    }

    init(id: UUID, userId: String, key: String, category: String, value: Any, confidence: Double, context: [String: Any], lastModified: Date, usageCount: Int) {
        self.id = id
        self.userId = userId
        self.key = key
        self.category = category
        self.value = value
        self.confidence = confidence
        self.context = context
        self.lastModified = lastModified
        self.usageCount = usageCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        key = try container.decode(String.self, forKey: .key)
        category = try container.decode(String.self, forKey: .category)
        confidence = try container.decode(Double.self, forKey: .confidence)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
        usageCount = try container.decode(Int.self, forKey: .usageCount)

        // Decode value
        let valueData = try container.decode(Data.self, forKey: .valueData)
        let valueType = try container.decode(String.self, forKey: .valueType)
        value = try decodeValue(from: valueData, type: valueType)

        // Decode context
        let contextData = try container.decode(Data.self, forKey: .contextData)
        context = try JSONSerialization.jsonObject(with: contextData) as? [String: Any] ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(key, forKey: .key)
        try container.encode(category, forKey: .category)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(usageCount, forKey: .usageCount)

        // Encode value
        let (valueData, valueType) = try encodeValue(value)
        try container.encode(valueData, forKey: .valueData)
        try container.encode(valueType, forKey: .valueType)

        // Encode context
        let contextData = try JSONSerialization.data(withJSONObject: context)
        try container.encode(contextData, forKey: .contextData)
    }
}

struct PreferenceContext {
    let attributes: [String: Any]

    init(formType: String? = nil, documentType: String? = nil, workflowPhase: String? = nil) {
        var attrs: [String: Any] = [:]

        if let formType {
            attrs["formType"] = formType
        }
        if let documentType {
            attrs["documentType"] = documentType
        }
        if let workflowPhase {
            attrs["workflowPhase"] = workflowPhase
        }

        attributes = attrs
    }
}

struct PreferenceStatistics {
    let totalPreferences: Int
    var categoryCounts: [String: Int]
    var averageConfidence: Double
    var mostUsedPreferences: [UserPreference]
    var recentlyModified: [UserPreference]
}

struct PreferenceExportData: Codable {
    let version: String
    let exportDate: Date
    let userId: String
    let preferences: [UserPreference]
}

// MARK: - Core Data Extensions

extension UserPreference {
    init?(from entity: PreferenceEntity) {
        guard let id = entity.id,
              let userId = entity.userId,
              let key = entity.key,
              let category = entity.category,
              let lastModified = entity.lastModified,
              let valueData = entity.valueData,
              let valueType = entity.valueType
        else {
            return nil
        }

        self.id = id
        self.userId = userId
        self.key = key
        self.category = category
        confidence = entity.confidence
        self.lastModified = lastModified
        usageCount = Int(entity.usageCount)

        // Decode value
        do {
            value = try decodeValue(from: valueData, type: valueType)
        } catch {
            return nil
        }

        // Decode context
        if let contextData = entity.contextData,
           let context = try? JSONSerialization.jsonObject(with: contextData) as? [String: Any] {
            self.context = context
        } else {
            context = [:]
        }
    }

    func populate(_ entity: PreferenceEntity) {
        entity.id = id
        entity.userId = userId
        entity.key = key
        entity.category = category
        entity.confidence = confidence
        entity.lastModified = lastModified
        entity.usageCount = Int32(usageCount)

        // Encode value
        if let (valueData, valueType) = try? encodeValue(value) {
            entity.valueData = valueData
            entity.valueType = valueType
        }

        // Encode context
        if let contextData = try? JSONSerialization.data(withJSONObject: context) {
            entity.contextData = contextData
        }
    }
}

// MARK: - Value Encoding/Decoding Helpers

private func encodeValue(_ value: Any) throws -> (Data, String) {
    switch value {
    case let string as String:
        return (Data(string.utf8), "String")
    case let int as Int:
        return try (JSONEncoder().encode(int), "Int")
    case let double as Double:
        return try (JSONEncoder().encode(double), "Double")
    case let bool as Bool:
        return try (JSONEncoder().encode(bool), "Bool")
    case let array as [String]:
        return try (JSONEncoder().encode(array), "StringArray")
    case let dict as [String: String]:
        return try (JSONEncoder().encode(dict), "StringDict")
    default:
        // Fallback to JSON serialization
        let data = try JSONSerialization.data(withJSONObject: value)
        return (data, "JSON")
    }
}

private func decodeValue(from data: Data, type: String) throws -> Any {
    switch type {
    case "String":
        return String(data: data, encoding: .utf8) ?? ""
    case "Int":
        return try JSONDecoder().decode(Int.self, from: data)
    case "Double":
        return try JSONDecoder().decode(Double.self, from: data)
    case "Bool":
        return try JSONDecoder().decode(Bool.self, from: data)
    case "StringArray":
        return try JSONDecoder().decode([String].self, from: data)
    case "StringDict":
        return try JSONDecoder().decode([String: String].self, from: data)
    case "JSON":
        return try JSONSerialization.jsonObject(with: data)
    default:
        throw DecodingError.dataCorruptedError(
            in: UnkeyedDecodingContainer.self,
            debugDescription: "Unknown value type: \(type)"
        )
    }
}
