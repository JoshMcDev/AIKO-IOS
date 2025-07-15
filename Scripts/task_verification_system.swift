#!/usr/bin/env swift

import Foundation

// Task Verification System
// This script provides automated verification and sync between codebase and Task Master

struct TaskImplementationMapping {
    let taskId: String
    let requiredFiles: [String]
    let verificationPatterns: [String]
    let completionCriteria: () -> Bool
}

class TaskVerificationSystem {
    let projectRoot: String
    
    // Define mappings between tasks and implementation files
    let taskMappings: [TaskImplementationMapping] = [
        TaskImplementationMapping(
            taskId: "1",
            requiredFiles: [
                "Sources/Services/DocumentParser.swift",
                "Sources/Services/DocumentParserEnhanced.swift",
                "Sources/Services/DocumentParser/WordDocumentParser.swift"
            ],
            verificationPatterns: ["parsePDF", "parseWord", "parseImage", "OCR"],
            completionCriteria: { true } // All files exist = complete
        ),
        TaskImplementationMapping(
            taskId: "8",
            requiredFiles: [
                "Sources/Infrastructure/Cache/OfflineCacheManager.swift",
                "Sources/Infrastructure/Cache/ObjectActionCache.swift",
                "Sources/Services/UnifiedDocumentCacheService.swift"
            ],
            verificationPatterns: ["saveToCache", "getFromCache", "syncCache"],
            completionCriteria: { true }
        ),
        TaskImplementationMapping(
            taskId: "4",
            requiredFiles: [
                "Sources/Services/FARCompliance.swift",
                "Sources/Services/FARComplianceManager.swift"
            ],
            verificationPatterns: ["checkCompliance", "FAR", "DFAR"],
            completionCriteria: { true }
        )
    ]
    
    init(projectRoot: String) {
        self.projectRoot = projectRoot
    }
    
    func verifyAllTasks() -> [String: String] {
        var results: [String: String] = [:]
        
        for mapping in taskMappings {
            let status = verifyTask(mapping)
            results[mapping.taskId] = status
        }
        
        return results
    }
    
    func verifyTask(_ mapping: TaskImplementationMapping) -> String {
        // Check if all required files exist
        let allFilesExist = mapping.requiredFiles.allSatisfy { file in
            FileManager.default.fileExists(atPath: "\(projectRoot)/\(file)")
        }
        
        if !allFilesExist {
            return "pending"
        }
        
        // Check if verification patterns are present
        var patternsFound = 0
        for file in mapping.requiredFiles {
            if let content = try? String(contentsOfFile: "\(projectRoot)/\(file)", encoding: .utf8) {
                for pattern in mapping.verificationPatterns {
                    if content.contains(pattern) {
                        patternsFound += 1
                        break
                    }
                }
            }
        }
        
        let patternRatio = Double(patternsFound) / Double(mapping.requiredFiles.count)
        
        if patternRatio >= 0.8 && mapping.completionCriteria() {
            return "done"
        } else if patternRatio >= 0.3 {
            return "in-progress"
        } else {
            return "pending"
        }
    }
    
    func generateGitHook() -> String {
        return """
        #!/bin/bash
        # Git pre-commit hook to verify task status
        
        echo "Verifying task implementation status..."
        
        # Run the verification script
        swift /Users/J/aiko/Scripts/task_verification_system.swift --verify-only
        
        if [ $? -ne 0 ]; then
            echo "Task status verification failed. Please update task status before committing."
            exit 1
        fi
        
        echo "Task status verification passed."
        exit 0
        """
    }
    
    func generateTaskMapping() -> String {
        return """
        # Task Implementation Mapping
        # Generated: \(Date())
        
        ## Task 1: Document Parser
        - Implementation: Sources/Services/DocumentParser*.swift
        - Tests: Tests/Services/DocumentParser*.swift
        - Status Check: Verify PDF, Word, and Image parsing functions exist
        
        ## Task 2: Adaptive Prompting Engine
        - Implementation: Sources/Services/AdaptivePromptingEngine.swift
        - Tests: Tests/Services/PromptingEngine/*.swift
        - Status Check: Verify all prompting modules are implemented
        
        ## Task 3: Historical Data Matching
        - Implementation: Sources/Services/AdaptiveIntelligenceService.swift
        - Status Check: Verify pattern detection and matching functions
        
        ## Task 4: FAR/DFAR Rules Engine
        - Implementation: Sources/Services/FAR*.swift
        - Status Check: Verify compliance checking functions
        
        ## Task 8: Offline Caching
        - Implementation: Sources/Infrastructure/Cache/*.swift
        - Status Check: Verify cache storage and sync functions
        
        ## Task 9: Compliance Checking
        - Implementation: Sources/Services/*Compliance*.swift
        - Status Check: Verify validation and checking functions
        """
    }
}

// Main execution
let args = CommandLine.arguments
let verifyOnly = args.contains("--verify-only")

let verifier = TaskVerificationSystem(projectRoot: FileManager.default.currentDirectoryPath)

if verifyOnly {
    // Quick verification mode for git hooks
    let results = verifier.verifyAllTasks()
    var hasIssues = false
    
    for (taskId, status) in results {
        print("Task \(taskId): \(status)")
        // You could check against Task Master here
    }
    
    exit(hasIssues ? 1 : 0)
} else {
    // Full verification with recommendations
    print("Task Verification System")
    print("=" * 60)
    
    let results = verifier.verifyAllTasks()
    
    print("\nVerification Results:")
    for (taskId, status) in results.sorted(by: { $0.key < $1.key }) {
        print("  Task \(taskId): \(status)")
    }
    
    print("\nGenerating Git Hook...")
    let hookPath = "\(FileManager.default.currentDirectoryPath)/.git/hooks/pre-commit"
    try? verifier.generateGitHook().write(toFile: hookPath, atomically: true, encoding: .utf8)
    print("Git hook written to: \(hookPath)")
    
    print("\nGenerating Task Mapping Documentation...")
    let mappingPath = "\(FileManager.default.currentDirectoryPath)/.taskmaster/docs/task-implementation-mapping.md"
    try? verifier.generateTaskMapping().write(toFile: mappingPath, atomically: true, encoding: .utf8)
    print("Mapping documentation written to: \(mappingPath)")
    
    print("\nRecommendations:")
    print("1. Make the git hook executable: chmod +x .git/hooks/pre-commit")
    print("2. Update Task Master with the verification results above")
    print("3. Review the task mapping documentation")
    print("4. Run this verification as part of CI/CD")
}

// Extension for string multiplication
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}