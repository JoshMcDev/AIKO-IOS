#!/usr/bin/env swift

// ObjectBox Model Generation Script for AIKO
// This script generates the ObjectBox model files needed for compilation

import Foundation
import ObjectBox

// Define entities that need to be registered
let entities: [ObjectBoxEntity.Type] = [
    RegulationEmbedding.self,
    UserWorkflowEmbedding.self
]

// Create ObjectBox model
print("Generating ObjectBox model...")

do {
    let model = try createObjectBoxModel()
    print("ObjectBox model generation completed successfully")
    print("Model entities: \(model.entities)")
} catch {
    print("ObjectBox model generation failed: \(error)")
    exit(1)
}

func createObjectBoxModel() throws -> Model {
    let model = Model()
    
    // Register entities with model
    for entity in entities {
        try model.entity(for: entity)
    }
    
    return model
}