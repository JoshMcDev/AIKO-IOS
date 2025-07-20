//
//  PatternLearningEntities.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import CoreData
import Foundation

// MARK: - Pattern Entity

@objc(PatternEntity)
public class PatternEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var value: String?
    @NSManaged public var context: Data?
    @NSManaged public var occurrences: Int32
    @NSManaged public var confidence: Double
    @NSManaged public var lastOccurrence: Date?
    @NSManaged public var metadata: Data?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

public extension PatternEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<PatternEntity> {
        NSFetchRequest<PatternEntity>(entityName: "PatternEntity")
    }
}

// MARK: - Interaction Entity

@objc(InteractionEntity)
public class InteractionEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var metadata: Data?
    @NSManaged public var userId: String?
    @NSManaged public var sessionId: UUID?
    @NSManaged public var contextType: String?
}

public extension InteractionEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<InteractionEntity> {
        NSFetchRequest<InteractionEntity>(entityName: "InteractionEntity")
    }
}

// MARK: - Session Entity

@objc(SessionEntity)
public class SessionEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var userId: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var contextType: String?
    @NSManaged public var interactionCount: Int32
    @NSManaged public var metadata: Data?
}

public extension SessionEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SessionEntity> {
        NSFetchRequest<SessionEntity>(entityName: "SessionEntity")
    }
}

// MARK: - Preference Entity

@objc(PreferenceEntity)
public class PreferenceEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var userId: String?
    @NSManaged public var key: String?
    @NSManaged public var category: String?
    @NSManaged public var valueData: Data?
    @NSManaged public var valueType: String?
    @NSManaged public var confidence: Double
    @NSManaged public var contextData: Data?
    @NSManaged public var lastModified: Date?
    @NSManaged public var usageCount: Int32
    @NSManaged public var createdAt: Date?
}

public extension PreferenceEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<PreferenceEntity> {
        NSFetchRequest<PreferenceEntity>(entityName: "PreferenceEntity")
    }
}

// MARK: - Core Data Model Definition

extension PersistenceController {
    /// Create the Core Data model programmatically
    static func createPatternLearningModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Pattern Entity
        let patternEntity = NSEntityDescription()
        patternEntity.name = "PatternEntity"
        patternEntity.managedObjectClassName = "PatternEntity"

        let patternAttributes = [
            createAttribute(name: "id", type: .UUIDAttributeType),
            createAttribute(name: "type", type: .stringAttributeType),
            createAttribute(name: "value", type: .stringAttributeType),
            createAttribute(name: "context", type: .binaryDataAttributeType, optional: true),
            createAttribute(name: "occurrences", type: .integer32AttributeType, defaultValue: 0),
            createAttribute(name: "confidence", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute(name: "lastOccurrence", type: .dateAttributeType),
            createAttribute(name: "metadata", type: .binaryDataAttributeType, optional: true),
            createAttribute(name: "createdAt", type: .dateAttributeType),
            createAttribute(name: "updatedAt", type: .dateAttributeType),
        ]
        patternEntity.properties = patternAttributes

        // Interaction Entity
        let interactionEntity = NSEntityDescription()
        interactionEntity.name = "InteractionEntity"
        interactionEntity.managedObjectClassName = "InteractionEntity"

        let interactionAttributes = [
            createAttribute(name: "id", type: .UUIDAttributeType),
            createAttribute(name: "type", type: .stringAttributeType),
            createAttribute(name: "timestamp", type: .dateAttributeType),
            createAttribute(name: "metadata", type: .binaryDataAttributeType, optional: true),
            createAttribute(name: "userId", type: .stringAttributeType, optional: true),
            createAttribute(name: "sessionId", type: .UUIDAttributeType, optional: true),
            createAttribute(name: "contextType", type: .stringAttributeType, optional: true),
        ]
        interactionEntity.properties = interactionAttributes

        // Session Entity
        let sessionEntity = NSEntityDescription()
        sessionEntity.name = "SessionEntity"
        sessionEntity.managedObjectClassName = "SessionEntity"

        let sessionAttributes = [
            createAttribute(name: "id", type: .UUIDAttributeType),
            createAttribute(name: "userId", type: .stringAttributeType),
            createAttribute(name: "startTime", type: .dateAttributeType),
            createAttribute(name: "endTime", type: .dateAttributeType, optional: true),
            createAttribute(name: "contextType", type: .stringAttributeType),
            createAttribute(name: "interactionCount", type: .integer32AttributeType, defaultValue: 0),
            createAttribute(name: "metadata", type: .binaryDataAttributeType, optional: true),
        ]
        sessionEntity.properties = sessionAttributes

        // Preference Entity
        let preferenceEntity = NSEntityDescription()
        preferenceEntity.name = "PreferenceEntity"
        preferenceEntity.managedObjectClassName = "PreferenceEntity"

        let preferenceAttributes = [
            createAttribute(name: "id", type: .UUIDAttributeType),
            createAttribute(name: "userId", type: .stringAttributeType),
            createAttribute(name: "key", type: .stringAttributeType),
            createAttribute(name: "category", type: .stringAttributeType),
            createAttribute(name: "valueData", type: .binaryDataAttributeType),
            createAttribute(name: "valueType", type: .stringAttributeType),
            createAttribute(name: "confidence", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute(name: "contextData", type: .binaryDataAttributeType, optional: true),
            createAttribute(name: "lastModified", type: .dateAttributeType),
            createAttribute(name: "usageCount", type: .integer32AttributeType, defaultValue: 0),
            createAttribute(name: "createdAt", type: .dateAttributeType),
        ]
        preferenceEntity.properties = preferenceAttributes

        // Add entities to model
        model.entities = [patternEntity, interactionEntity, sessionEntity, preferenceEntity]

        return model
    }

    private static func createAttribute(
        name: String,
        type: NSAttributeType,
        optional: Bool = false,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional

        if let defaultValue {
            attribute.defaultValue = defaultValue
        }

        return attribute
    }
}
