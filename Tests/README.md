# AIKO Test Suite Organization

## Structure Overview
```
Tests/
├── Unit/                           # Fast, isolated unit tests
│   ├── Features/                   # TCA Reducer tests
│   │   ├── Unit_AuthenticationFeatureTests.swift
│   │   ├── Unit_NavigationFeatureTests.swift
│   │   └── Unit_ShareFeatureTests.swift
│   ├── Services/                   # Service layer tests
│   │   ├── Unit_AdaptiveDocumentCacheTests.swift
│   │   ├── Unit_DocumentChainMetadataTests.swift
│   │   ├── Unit_DocumentManagementTests.swift
│   │   ├── Unit_FARComplianceManagerTests.swift
│   │   ├── Unit_OptimizedDocumentTests.swift
│   │   ├── Unit_UnifiedDocumentCacheServiceTests.swift
│   │   └── Unit_UnifiedTemplateServiceTests.swift
│   └── Unit_AIKOModuleTests.swift
├── Integration/                    # Multi-component integration tests
│   ├── API/                        # External API tests
│   │   ├── Integration_FARPart53Tests.swift
│   │   ├── Integration_SAMGov.swift
│   │   ├── Integration_SAMGovComplete.swift
│   │   └── Integration_SAMGovMock.swift
│   └── Database/                   # Database integration tests
│       └── Integration_CoreDataBackupTests.swift
├── UI/                             # User interface tests
│   ├── Screens/                    # Full screen tests
│   │   └── UI_EnhancementTests.swift
│   └── Components/                 # Component tests
│       └── UI_ErrorAlertTests.swift
├── Performance/                    # Performance and stress tests
│   ├── Performance_CriticalPathTests.swift
│   ├── Performance_TestRunner.swift
│   └── Performance_TestSuite.swift
├── Security/                       # Security and auth tests
│   └── Security_BiometricAuthenticationTests.swift
├── Accessibility/                  # Accessibility compliance tests
├── Templates/                      # Test templates and guides
│   ├── IntegrationTestTemplate.swift
│   ├── PerformanceTestTemplate.swift
│   ├── TestNamingConvention.md
│   ├── UITestTemplate.swift
│   └── UnitTestTemplate.swift
├── Test_Runner_Comprehensive.swift # Comprehensive test runner
├── Test_Runner_Main.swift          # Main test runner
└── Test_Suite_Regression.swift     # Regression test suite
```

## Running Tests

### All Tests
```bash
swift test
```

### Specific Category
```bash
swift test --filter Unit
swift test --filter Integration
swift test --filter Performance
```

### Single Test File
```bash
swift test --filter Unit_AuthenticationFeatureTests
```

## Test Coverage Requirements

Per CLAUDE.md production requirements (95% score):
- **Critical Paths**: 100% coverage
- **Business Logic**: 95% coverage  
- **UI Components**: 80% coverage
- **Overall Target**: 100% (currently at 78%)

## Adding New Tests

1. Use appropriate template from `Templates/` folder
2. Follow naming convention: `[Category]_[TargetName]Tests.swift`
3. Place in correct folder based on test type
4. Update coverage metrics after adding tests