# Contributing to AIKO

Thank you for your interest in contributing to AIKO! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Process](#development-process)
4. [Coding Standards](#coding-standards)
5. [Testing Requirements](#testing-requirements)
6. [Submitting Changes](#submitting-changes)
7. [Review Process](#review-process)

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on what is best for the project and community
- Show empathy towards other contributors

### Unacceptable Behavior

- Harassment, discrimination, or offensive comments
- Publishing others' private information
- Trolling or insulting/derogatory comments
- Public or private harassment

## Getting Started

### Prerequisites

- macOS 14.0+ with Xcode 15.0+
- Swift 5.9+
- Git configured with signed commits
- Familiarity with The Composable Architecture (TCA)

### Setting Up Your Development Environment

1. **Fork the Repository**
   ```bash
   # Fork via GitHub UI, then clone your fork
   git clone https://github.com/YOUR-USERNAME/AIKO.git
   cd aiko
   ```

2. **Add Upstream Remote**
   ```bash
   git remote add upstream https://github.com/JoshMcDev/AIKO.git
   ```

3. **Install Dependencies**
   ```bash
   swift package resolve
   ```

4. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Process

### Branch Naming Convention

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions or fixes

### Task Management

We use Claude's TodoWrite tool for task management. When working on a feature:

1. Check existing tasks in the current development plan
2. Create subtasks for your work
3. Update task status as you progress
4. Mark tasks complete when finished

### Workflow

1. **Sync with Upstream**
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/adaptive-defaults
   ```

3. **Make Changes**
   - Write clean, documented code
   - Follow Swift style guidelines
   - Add tests for new functionality

4. **Test Your Changes**
   ```bash
   swift test
   swift build
   ```

5. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: Add smart defaults to adaptive prompting engine"
   ```

## Coding Standards

### Swift Style Guide

1. **Naming Conventions**
   ```swift
   // Classes, Structs, Enums - UpperCamelCase
   struct AdaptivePromptingEngine { }
   
   // Functions, Variables - lowerCamelCase
   func extractContext(from document: Document) { }
   let extractedData = process(document)
   
   // Constants - lowerCamelCase
   let maximumRetryCount = 3
   ```

2. **Code Organization**
   ```swift
   // MARK: - Properties
   private let apiClient: APIClient
   @Published var state: State
   
   // MARK: - Lifecycle
   init(apiClient: APIClient) {
       self.apiClient = apiClient
   }
   
   // MARK: - Public Methods
   func process(_ document: Document) async throws -> ExtractedData {
       // Implementation
   }
   
   // MARK: - Private Methods
   private func validateData(_ data: ExtractedData) -> Bool {
       // Implementation
   }
   ```

3. **TCA Conventions**
   ```swift
   @Reducer
   struct Feature {
       @ObservableState
       struct State: Equatable {
           // State properties
       }
       
       enum Action {
           // User actions
           case buttonTapped
           // Internal actions
           case _internal(Internal)
           
           enum Internal {
               case dataLoaded(Result<Data, Error>)
           }
       }
       
       var body: some Reducer<State, Action> {
           Reduce { state, action in
               // Handle actions
           }
       }
   }
   ```

4. **Documentation**
   ```swift
   /// Processes a document and extracts relevant acquisition data.
   /// 
   /// - Parameters:
   ///   - document: The document to process
   ///   - options: Processing options
   /// - Returns: Extracted acquisition data
   /// - Throws: `ProcessingError` if extraction fails
   func processDocument(
       _ document: Document,
       options: ProcessingOptions = .default
   ) async throws -> AcquisitionData {
       // Implementation
   }
   ```

### File Organization

- One type per file (struct, class, enum)
- Group related files in folders
- Use clear, descriptive file names
- Keep files under 400 lines when possible

## Testing Requirements

### Test Coverage

- Minimum 80% code coverage for new features
- All public APIs must have tests
- Edge cases and error conditions must be tested

### Test Structure

```swift
import XCTest
@testable import AIKO
import ComposableArchitecture

final class AdaptivePromptingTests: XCTestCase {
    func testExtractsDataFromDocument() async throws {
        let store = TestStore(
            initialState: AdaptivePrompting.State()
        ) {
            AdaptivePrompting()
        }
        
        // Test implementation
    }
}
```

### Test Naming

```swift
// Format: test_[condition]_[expectedResult]
func test_whenDocumentUploaded_extractsVendorInformation()
func test_whenExtractionFails_showsErrorAlert()
func test_whenUserAnswersQuestion_updatesState()
```

## Submitting Changes

### Commit Message Format

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Test additions or fixes
- `chore`: Build process or auxiliary tool changes

**Examples:**
```bash
feat(prompting): Add pattern learning to adaptive engine

Implements user pattern detection and learning to pre-fill
common fields based on historical data.

Closes #123
```

### Pull Request Process

1. **Update Your Branch**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature
   ```

3. **Create Pull Request**
   - Use a clear, descriptive title
   - Reference any related issues
   - Include screenshots for UI changes
   - List any breaking changes

4. **PR Description Template**
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update
   
   ## Testing
   - [ ] Unit tests pass
   - [ ] Integration tests pass
   - [ ] Manual testing completed
   
   ## Screenshots (if applicable)
   
   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Comments added for complex code
   - [ ] Documentation updated
   - [ ] No new warnings
   ```

## Review Process

### Review Criteria

1. **Code Quality**
   - Follows coding standards
   - Clear and maintainable
   - Properly documented

2. **Functionality**
   - Meets requirements
   - No regressions
   - Edge cases handled

3. **Performance**
   - No performance degradation
   - Efficient algorithms
   - Memory usage considered

4. **Testing**
   - Adequate test coverage
   - Tests are clear and focused
   - All tests pass

### Review Timeline

- Initial review within 48 hours
- Address feedback promptly
- Re-review within 24 hours of updates

### Merge Requirements

- Approved by at least one maintainer
- All CI checks pass
- No unresolved conversations
- Branch is up to date with main

## Getting Help

- **Discord**: [AIKO Development](https://discord.gg/aiko-dev)
- **Issues**: [GitHub Issues](https://github.com/JoshMcDev/AIKO/issues)
- **Discussions**: [GitHub Discussions](https://github.com/JoshMcDev/AIKO/discussions)

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Given credit in documentation

Thank you for contributing to AIKO! 🚀