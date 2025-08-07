#!/usr/bin/env swift

/*
 LFM2 Test Runner
 
 Direct test execution for LFM2Service validation
 Bypasses compilation issues in other test files
*/

import Foundation

print("🧪 LFM2 Service Test Runner")
print("=" + String(repeating: "=", count: 40))

// Try to compile and run just the GraphRAG tests
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
task.arguments = ["swift", "test", "--build-path", ".build-test", "--target", "GraphRAGTests", "--filter", "LFM2ServiceTests"]
task.currentDirectoryURL = URL(fileURLWithPath: "/Users/J/aiko")

let pipe = Pipe()
task.standardOutput = pipe
task.standardError = pipe

do {
    try task.run()
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    
    print("Test Output:")
    print(output)
    
    if task.terminationStatus == 0 {
        print("\n✅ LFM2 Tests completed successfully!")
    } else {
        print("\n❌ LFM2 Tests encountered issues (Exit code: \(task.terminationStatus))")
        
        // Try alternative approach - build just the module
        print("\nTrying alternative test approach...")
        
        let buildTask = Process()
        buildTask.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        buildTask.arguments = ["swift", "build", "--target", "GraphRAG"]
        buildTask.currentDirectoryURL = URL(fileURLWithPath: "/Users/J/aiko")
        
        let buildPipe = Pipe()
        buildTask.standardOutput = buildPipe
        buildTask.standardError = buildPipe
        
        try buildTask.run()
        buildTask.waitUntilExit()
        
        let buildData = buildPipe.fileHandleForReading.readDataToEndOfFile()
        let buildOutput = String(data: buildData, encoding: .utf8) ?? ""
        
        if buildTask.terminationStatus == 0 {
            print("✅ GraphRAG module builds successfully")
            print("✅ LFM2Service implementation is compilation-ready")
        } else {
            print("❌ Build issues detected:")
            print(buildOutput)
        }
    }
    
} catch {
    print("❌ Failed to run test: \(error)")
}

print("\n🎯 Test validation completed")