# AIKO Tests Directory

This directory contains all test files for the AIKO project, organized by test type and following consistent naming conventions.

## 📁 Folder Structure
```
Tests/
├── README.md                       # This file (CAPITALS first)
├── Accessibility/                  # Accessibility and VoiceOver tests
├── Integration/                    # Integration tests
│   ├── API/                        # API integration tests
│   └── Database/                   # Database integration tests
├── Performance/                    # Performance and benchmark tests
├── Security/                       # Security-focused tests
├── Templates/                      # Test templates for consistency
├── Test_Documentation/             # Test documentation and reports
├── TestRunners/                    # Test execution runners
├── UI/                             # UI/UX tests
│   ├── Components/                 # Component-level UI tests
│   └── Screens/                    # Screen-level UI tests
└── Unit/                           # Unit tests
    ├── Features/                   # Feature-level unit tests
    ├── Models/                     # Model unit tests
    └── Services/                   # Service unit tests
```

##  Naming Conventions

### Files
- **Test Files**: `TestType_##_DescriptiveName.swift`
  - Examples: `Unit_01_Authentication.swift`, `Integration_02_SAMGovAPI.swift`
- **Documentation**: `TestDoc_##_DocumentName.md`
  - Examples: `TestDoc_01_AppTestFramework.md`
- **Templates**: `Template_##_TemplateName.swift`
  - Examples: `Template_01_IntegrationTest.swift`
- **Runners**: `TestRunner_##_RunnerName.swift`
  - Examples: `TestRunner_01_Comprehensive.swift`

### Test Types
- **Unit**: Tests individual components in isolation
- **Integration**: Tests component interactions
- **UI**: Tests user interface behavior
- **Performance**: Tests speed and resource usage
- **Security**: Tests security features
- **Accessibility**: Tests VoiceOver and accessibility

##  Test Coverage Goals

| Category | Current | Target | Status |
|----------|---------|--------|--------|
| Unit Tests | 78% | 100% | 🟡 |
| Integration | 65% | 95% | 🟡 |
| UI Tests | 70% | 90% | 🟡 |
| Performance | 85% | 95% | 🟡 |
| Security | 90% | 100% | 🟡 |

## 🏃 Running Tests

### All Tests
```bash
swift test
```

### Specific Test Suite
```bash
swift test --filter AIKOTests.Unit
```

### Performance Tests
```bash
swift test --filter Performance --configuration release
```

### UI Tests (Xcode)
```bash
xcodebuild test -scheme AIKO -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

##  Test Documentation

Key documentation files in `Test_Documentation/`:
- `TestDoc_01_AppTestFramework.md` - Overall testing strategy
- `TestDoc_02_ComprehensiveTestReport.md` - Latest test results
- `TestDoc_03_MCPTestFramework.md` - MCP-specific testing
- `TestDoc_04_TestResultsTemplate.md` - Template for test reports
- `TestDoc_05_TestScenarios.md` - Detailed test scenarios

##  Test Requirements

All tests must:
1. Follow naming conventions
2. Include proper documentation
3. Be deterministic (no flaky tests)
4. Run in < 10 seconds (unit) or < 30 seconds (integration)
5. Have clear assertions and failure messages
6. Support both Xcode and SPM test runners

##  Creating New Tests

Use templates in the `Templates/` folder:
1. Copy appropriate template
2. Rename following conventions
3. Implement test logic
4. Add to appropriate test suite
5. Update coverage metrics

---

**Project Owner**: Mr. Joshua  
**Last Updated**: 2025-07-11  
**Test Framework**: XCTest + Swift Testing