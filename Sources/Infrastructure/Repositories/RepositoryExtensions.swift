import AppCore
import CoreData
import Foundation

// Note: CoreDataRepository cannot directly conform to RepositoryProtocol
// because NSManagedObject entities are not Sendable.
// Services should use specific repositories that return Sendable DTOs instead.

// Acquisition and AcquisitionDocument already conform to Identifiable in their Core Data definitions

// Additional extensions for missing properties
extension Acquisition {
    var estimatedValue: Decimal {
        // Would be stored in documentChainMetadata or computed from requirements
        0
    }

    var requiredDocuments: [DocumentType] {
        // This would be computed based on business rules
        []
    }
}
