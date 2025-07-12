# Test Naming Convention & Organization

## Folder Structure
```
Tests/
├── Unit/                    # Fast, isolated unit tests
│   ├── Features/           # TCA Reducer tests
│   ├── Services/           # Service layer tests
│   └── Models/             # Model and data structure tests
├── Integration/            # Tests that verify multiple components work together
│   ├── API/               # External API integration tests
│   └── Database/          # CoreData integration tests
├── UI/                     # UI and view tests
│   ├── Screens/           # Full screen UI tests
│   └── Components/        # Individual component tests
├── Performance/           # Performance and stress tests
├── Security/              # Security and authentication tests
├── Accessibility/         # Accessibility compliance tests
└── Templates/             # Test templates and documentation
```

## File Naming Convention

### Pattern: `[Category][TargetName]Tests.swift`

Examples:
- `Unit_AuthenticationFeatureTests.swift`
- `Integration_SAMGovAPITests.swift`
- `UI_LoginScreenTests.swift`
- `Performance_DocumentGenerationTests.swift`

## Test Method Naming

### Pattern: `test_[MethodOrFeature]_[Condition]_[ExpectedResult]()`

Examples:
```swift
func test_authenticate_withValidBiometrics_returnsSuccess()
func test_searchEntity_withEmptyQuery_throwsValidationError()
func test_documentGeneration_under100Items_completesWithin200ms()
func test_loginButton_whenDisabled_isNotTappable()
```

## Test Categories

### 1. Unit Tests (Target: 80% of all tests)
- Fast, isolated, no external dependencies
- Mock all dependencies
- Test single units of functionality
- Should run in < 0.1 seconds each

### 2. Integration Tests (Target: 15% of all tests)
- Test interaction between components
- May use real services with test endpoints
- Test data flow through the system
- Should run in < 1 second each

### 3. UI Tests (Target: 5% of all tests)
- Test user interactions and flows
- Verify UI elements appear correctly
- Test accessibility
- May run slower (1-5 seconds)

### 4. Performance Tests
- Measure and assert performance metrics
- Test under load conditions
- Memory leak detection
- Must meet SLA targets (< 200ms)

### 5. Security Tests
- Authentication flow tests
- Data encryption verification
- Keychain integration tests
- Authorization tests

## Test Organization Rules

1. **One test class per source file**
   - `AuthenticationFeature.swift` → `Unit_AuthenticationFeatureTests.swift`

2. **Group related tests with MARK comments**
   ```swift
   // MARK: - Success Cases
   // MARK: - Error Cases
   // MARK: - Edge Cases
   ```

3. **Use descriptive test data**
   ```swift
   let validUser = User(id: "test-123", name: "Test User")
   let invalidToken = "expired-token"
   ```

4. **Follow AAA pattern**
   - Arrange (Given)
   - Act (When)
   - Assert (Then)

5. **One assertion focus per test**
   - Test one behavior per method
   - Multiple assertions are OK if testing same behavior

## Required Test Coverage

Per CLAUDE.md requirements for 95% production score:

- **Critical Paths**: 100% coverage required
  - Authentication flows
  - SAM.gov integration
  - Document generation
  - Data persistence

- **Business Logic**: 95% coverage required
  - All reducers
  - All services
  - All data transformations

- **UI Components**: 80% coverage required
  - All screens
  - Interactive components
  - Navigation flows

- **Utilities**: 90% coverage required
  - Formatters
  - Validators
  - Extensions