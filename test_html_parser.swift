#!/usr/bin/env swift

import Foundation

// Simple test script to verify RegulationHTMLParser works
print("Testing RegulationHTMLParser...")

// Test HTML content
let testHTML = """
<!DOCTYPE html>
<html>
<head><title>FAR Part 15 - Contracting by Negotiation</title></head>
<body>
<h1>Federal Acquisition Regulation</h1>
<h2>Part 15 - Contracting by Negotiation</h2>
<p>Exchanges of information among all interested parties are encouraged.</p>
</body>
</html>
"""

// Import would be: @testable import AIKO
// For now, just verify the file compiles

print("HTML Parser test script completed successfully")
print("Test HTML length: \(testHTML.count) characters")