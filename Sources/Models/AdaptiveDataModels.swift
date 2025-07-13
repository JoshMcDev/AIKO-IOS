import Foundation
import CoreData

// MARK: - Core Data Extensions for Adaptive Storage

extension DocumentData {
    /// Store extracted data as flexible JSON
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var extractedData: Data?
    @NSManaged public var documentSignature: String?
    @NSManaged public var patternNames: String? // Comma-separated list
    @NSManaged public var attributes: NSSet?
}

extension DocumentAttribute {
    @NSManaged public var id: UUID?
    @NSManaged public var fieldName: String?
    @NSManaged public var fieldValue: String?
    @NSManaged public var dataType: String?
    @NSManaged public var confidence: Double
    @NSManaged public var extractionPattern: String?
    @NSManaged public var document: DocumentData?
}

// MARK: - Pattern Storage Models

@objc(PatternEntity)
public class PatternEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var documentSignatures: String? // JSON array
    @NSManaged public var fieldMappings: Data? // JSON encoded
    @NSManaged public var occurrenceCount: Int32
    @NSManaged public var averageConfidence: Double
    @NSManaged public var lastSeen: Date?
    @NSManaged public var createdAt: Date?
    
    func toLearnedPattern() -> LearnedPattern? {
        guard let id = id,
              let name = name,
              let mappingsData = fieldMappings,
              let signatures = documentSignatures?.components(separatedBy: ",") else {
            return nil
        }
        
        let mappings = (try? JSONDecoder().decode([LearnedPattern.FieldMapping].self, from: mappingsData)) ?? []
        
        return LearnedPattern(
            id: id,
            patternName: name,
            fieldMappings: mappings,
            documentTypeSignatures: signatures,
            occurrenceCount: Int(occurrenceCount),
            averageConfidence: averageConfidence,
            lastSeen: lastSeen ?? Date()
        )
    }
}

// MARK: - Value Object Repository

@MainActor
public class ValueObjectRepository {
    private let container: NSPersistentContainer
    
    nonisolated init(container: NSPersistentContainer) {
        self.container = container
    }
    
    static func shared() -> ValueObjectRepository {
        ValueObjectRepository(container: CoreDataManager.shared.persistentContainer)
    }
    
    // MARK: - Store Dynamic Value Objects
    
    public func store(_ objects: [DynamicValueObject], for documentId: UUID) throws {
        let context = container.viewContext
        
        // Find or create document
        let fetchRequest = NSFetchRequest<DocumentData>(entityName: "DocumentData")
        fetchRequest.predicate = NSPredicate(format: "id == %@", documentId as CVarArg)
        
        let document = try context.fetch(fetchRequest).first ?? DocumentData(context: context)
        document.id = documentId
        document.timestamp = Date()
        
        // Convert objects to JSON for flexible storage
        var jsonData: [String: Any] = [:]
        var attributes = Set<DocumentAttribute>()
        
        for object in objects {
            // Store in JSON structure
            jsonData[object.fieldName] = [
                "value": object.value,
                "type": object.dataType.rawValue,
                "confidence": object.confidence,
                "pattern": object.extractionPattern ?? "",
                "context": [
                    "documentType": object.documentContext.documentType,
                    "section": object.documentContext.section ?? "",
                    "lineNumber": object.documentContext.lineNumber ?? -1
                ]
            ]
            
            // Create searchable attribute
            let attribute = DocumentAttribute(context: context)
            attribute.id = UUID()
            attribute.fieldName = object.fieldName
            attribute.fieldValue = object.value
            attribute.dataType = object.dataType.rawValue
            attribute.confidence = object.confidence
            attribute.extractionPattern = object.extractionPattern
            attribute.document = document
            
            attributes.insert(attribute)
        }
        
        document.extractedData = try JSONSerialization.data(
            withJSONObject: jsonData,
            options: .prettyPrinted
        )
        document.attributes = attributes as NSSet
        
        try context.save()
    }
    
    // MARK: - Query Dynamic Fields
    
    public func findDocuments(with criteria: SearchCriteria) throws -> [DocumentResult] {
        let context = container.viewContext
        let request = NSFetchRequest<DocumentAttribute>(entityName: "DocumentAttribute")
        
        var predicates: [NSPredicate] = []
        
        // Build dynamic predicates
        if let fieldName = criteria.fieldName {
            predicates.append(NSPredicate(format: "fieldName == %@", fieldName))
        }
        
        if let fieldValue = criteria.fieldValue {
            if criteria.exactMatch {
                predicates.append(NSPredicate(format: "fieldValue == %@", fieldValue))
            } else {
                predicates.append(NSPredicate(format: "fieldValue CONTAINS[cd] %@", fieldValue))
            }
        }
        
        if let dataType = criteria.dataType {
            predicates.append(NSPredicate(format: "dataType == %@", dataType.rawValue))
        }
        
        if let minConfidence = criteria.minConfidence {
            predicates.append(NSPredicate(format: "confidence >= %f", minConfidence))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        let attributes = try context.fetch(request)
        
        // Group by document
        let groupedByDocument = Dictionary(grouping: attributes) { $0.document }
        
        return groupedByDocument.compactMap { (document, attributes) -> DocumentResult? in
            guard let doc = document,
                  let docId = doc.id else { return nil }
            
            let valueObjects = attributes.compactMap { attr -> DynamicValueObject? in
                guard let fieldName = attr.fieldName,
                      let fieldValue = attr.fieldValue,
                      let dataTypeString = attr.dataType,
                      let dataType = DynamicValueObject.DataType(rawValue: dataTypeString) else {
                    return nil
                }
                
                return DynamicValueObject(
                    fieldName: fieldName,
                    value: fieldValue,
                    dataType: dataType,
                    confidence: attr.confidence,
                    extractionPattern: attr.extractionPattern,
                    documentContext: DocumentContext(
                        documentType: doc.documentSignature ?? "unknown",
                        section: nil,
                        lineNumber: nil,
                        surroundingText: nil,
                        relatedFields: []
                    )
                )
            }
            
            return DocumentResult(
                documentId: docId,
                timestamp: doc.timestamp ?? Date(),
                signature: doc.documentSignature ?? "unknown",
                valueObjects: valueObjects,
                rawData: doc.extractedData
            )
        }
    }
    
    // MARK: - Pattern Management
    
    public func storePattern(_ pattern: LearnedPattern) throws {
        let context = container.viewContext
        
        let fetchRequest = NSFetchRequest<PatternEntity>(entityName: "PatternEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", pattern.id as CVarArg)
        
        let entity = try context.fetch(fetchRequest).first ?? PatternEntity(context: context)
        entity.id = pattern.id
        entity.name = pattern.patternName
        entity.documentSignatures = pattern.documentTypeSignatures.joined(separator: ",")
        entity.fieldMappings = try JSONEncoder().encode(pattern.fieldMappings)
        entity.occurrenceCount = Int32(pattern.occurrenceCount)
        entity.averageConfidence = pattern.averageConfidence
        entity.lastSeen = pattern.lastSeen
        entity.createdAt = entity.createdAt ?? Date()
        
        try context.save()
    }
    
    public func loadPatterns() throws -> [LearnedPattern] {
        let context = container.viewContext
        let request = NSFetchRequest<PatternEntity>(entityName: "PatternEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "occurrenceCount", ascending: false)]
        
        let entities = try context.fetch(request)
        return entities.compactMap { $0.toLearnedPattern() }
    }
}

// MARK: - Search Support

public struct SearchCriteria {
    public let fieldName: String?
    public let fieldValue: String?
    public let dataType: DynamicValueObject.DataType?
    public let minConfidence: Double?
    public let exactMatch: Bool
    public let dateRange: DateInterval?
    
    public init(
        fieldName: String? = nil,
        fieldValue: String? = nil,
        dataType: DynamicValueObject.DataType? = nil,
        minConfidence: Double? = nil,
        exactMatch: Bool = false,
        dateRange: DateInterval? = nil
    ) {
        self.fieldName = fieldName
        self.fieldValue = fieldValue
        self.dataType = dataType
        self.minConfidence = minConfidence
        self.exactMatch = exactMatch
        self.dateRange = dateRange
    }
}

public struct DocumentResult {
    public let documentId: UUID
    public let timestamp: Date
    public let signature: String
    public let valueObjects: [DynamicValueObject]
    public let rawData: Data?
    
    public func getFieldValue(_ fieldName: String) -> String? {
        return valueObjects.first { $0.fieldName == fieldName }?.value
    }
    
    public func toJSON() -> [String: Any]? {
        guard let data = rawData else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
}

// MARK: - Usage Example for Quote Processing

extension AdaptiveDataExtractor {
    
    /// Example of how the system learns from the MTO quote
    public func demonstrateQuoteLearning() async throws {
        // After processing the MTO quote, the system would learn:
        
        let mtoQuotePattern = LearnedPattern(
            id: UUID(),
            patternName: "Government_Technical_Equipment_Quote",
            fieldMappings: [
                LearnedPattern.FieldMapping(
                    standardFieldName: "vendor",
                    variations: ["vendor", "company", "Morgan Technical Offerings LLC", "MTO"],
                    extractionRegex: "^([A-Za-z\\s]+(?:LLC|Inc|Corp))",
                    expectedDataType: .text,
                    isRequired: true,
                    defaultValue: nil
                ),
                LearnedPattern.FieldMapping(
                    standardFieldName: "customer",
                    variations: ["ship to", "address", "customer", "Joint Communications Unit"],
                    extractionRegex: "SHIP TO\\s*\\n([^\\n]+)",
                    expectedDataType: .text,
                    isRequired: true,
                    defaultValue: nil
                ),
                LearnedPattern.FieldMapping(
                    standardFieldName: "aro_days",
                    variations: ["ARO", "awaiting receipt", "lead time"],
                    extractionRegex: "ARO\\s*\\n(\\d+)",
                    expectedDataType: .number,
                    isRequired: false,
                    defaultValue: "30"
                ),
                LearnedPattern.FieldMapping(
                    standardFieldName: "product_description",
                    variations: ["description", "item", "product", "Voyager 2 Plus Chassis"],
                    extractionRegex: "DESCRIPTION\\s*\\n([^\\n]+(?:\\n(?!\\w+:)[^\\n]+)*)",
                    expectedDataType: .text,
                    isRequired: true,
                    defaultValue: nil
                ),
                LearnedPattern.FieldMapping(
                    standardFieldName: "technical_specs",
                    variations: ["features", "specifications", "includes", "- 160W Power"],
                    extractionRegex: "Features\\s*include:\\s*\\n([^\\n]+(?:\\n-[^\\n]+)*)",
                    expectedDataType: .array,
                    isRequired: false,
                    defaultValue: nil
                ),
                LearnedPattern.FieldMapping(
                    standardFieldName: "total_price",
                    variations: ["total", "amount", "price", "$114,439.38"],
                    extractionRegex: "\\$([0-9,]+\\.\\d{2})",
                    expectedDataType: .currency,
                    isRequired: true,
                    defaultValue: nil
                ),
                LearnedPattern.FieldMapping(
                    standardFieldName: "haipe_compatible",
                    variations: ["HAIPE", "KG-250", "encryption"],
                    extractionRegex: "(HAIPE|KG-250)",
                    expectedDataType: .boolean,
                    isRequired: false,
                    defaultValue: "false"
                )
            ],
            documentTypeSignatures: [
                "quote_government_vendor_technical_equipment_pricing",
                "government_communications_equipment",
                "military_technical_quote"
            ],
            occurrenceCount: 1,
            averageConfidence: 0.96,
            lastSeen: Date()
        )
        
        // This pattern would be stored and used for future similar quotes
        print("Learned pattern for government technical equipment quotes")
        print("Future quotes from defense contractors will be processed more accurately")
    }
}