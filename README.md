# AIKO
**Adaptive Intelligence for Kontract Optimization**
**KO Design Environment (KODE)**

A modern iOS and macOS application for government contracting professionals, leveraging Large Language Models to streamline document generation, compliance validation, and workflow automation.

## Overview

AIKO is a SwiftUI-based application that helps government contracting officers and acquisition professionals automate repetitive tasks, generate compliant documents, and navigate complex regulations. The app integrates with various LLM providers (OpenAI, Anthropic, Google) while keeping all data processing on-device for maximum privacy and security.

## Key Features

- **Document Generation**: Automated creation of government forms, statements of work, and contract documents
- **Regulatory Compliance**: Built-in FAR/DFARS validation and citation checking
- **Multi-Platform**: Native iOS and macOS applications with shared business logic
- **LLM Integration**: Support for multiple AI providers with your own API keys
- **Document Scanning**: OCR and intelligent form processing using VisionKit
- **Semantic Vector Database**: ObjectBox-based vector search with configurable mock/production backends for regulatory knowledge retrieval
- **Privacy-First**: All processing happens locally, no data sent to AIKO servers

## Technology Stack

- **Platform**: iOS 17+, macOS 14+
- **Language**: Swift 6.0 with strict concurrency
- **UI Framework**: SwiftUI with @Observable patterns
- **Architecture**: Clean architecture with protocol-based dependency injection
- **Dependencies**: SwiftAnthropic, MLX Swift, Swift Collections, MultipartKit
- **Database**: Core Data for local storage, ObjectBox Semantic Index for vector search (with mock fallback)
- **AI/ML**: On-device LFM2 model for embeddings, LLM API integrations

## Project Structure

```
AIKO/
├── Sources/
│   ├── AIKO/           # Main application target
│   ├── AppCore/        # Shared business logic (platform-agnostic)
│   ├── AIKOiOS/        # iOS-specific implementations
│   ├── AIKOmacOS/      # macOS-specific implementations
│   ├── AikoCompat/     # Compatibility layer for dependencies
│   └── GraphRAG/       # Semantic search and regulatory knowledge
├── Tests/              # Comprehensive test suite
├── Documentation/      # Technical documentation
└── Package.swift       # Swift Package Manager configuration
```

## Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 17.0+ device/simulator or macOS 14.0+
- Swift 6.0+

### Installation

1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd AIKO
   ```

2. Open in Xcode:
   ```bash
   open Package.swift
   ```

3. Build and run:
   - Select the appropriate scheme (iOS or macOS)
   - Press ⌘+R to build and run

### Configuration

On first launch, you'll need to configure:
- LLM provider credentials (stored securely in Keychain)
- Document templates and preferences
- Regulatory database updates

#### Vector Database Configuration

AIKO includes a sophisticated semantic search system with flexible backend options:

**Mock Implementation (Default)**
- Immediate development and testing capability
- Full API compatibility with production ObjectBox
- Sub-second build times (0.18s vs potential timeouts)
- Functional vector similarity calculations for development

**ObjectBox Integration (Optional)**
- Enable by uncommenting ObjectBox dependency in Package.swift
- Add ObjectBox product reference to GraphRAG target
- High-performance native vector operations
- Transparent migration from mock implementation

The mock-first architecture ensures reliable development velocity while maintaining clear production deployment paths.

## Architecture

AIKO follows a clean architecture pattern with five core engines:

1. **AIOrchestrator**: Central coordination hub for all AI operations
2. **DocumentEngine**: Document generation and template management
3. **PromptRegistry**: Optimized prompts for different document types
4. **ComplianceValidator**: Automated FAR/DFARS compliance checking
5. **PersonalizationEngine**: User preference learning and adaptation

The application maintains strict separation between platform-agnostic business logic (AppCore) and platform-specific implementations (AIKOiOS/AIKOmacOS).

## Development Status

Current progress: **49% complete** (27/55 tasks)

### Completed Components
- Core architecture and dependency injection
- Multi-platform SwiftUI implementation
- LLM provider integrations
- Document scanning and OCR
- Basic compliance validation
- Test infrastructure

### In Progress
- GraphRAG semantic search system
- Advanced document generation workflows
- Enhanced regulatory knowledge base
- Behavioral analytics and user learning

## Testing

Run the full test suite:
```bash
swift test
```

Run specific test targets:
```bash
swift test --filter AppCoreTests
swift test --filter AIKOiOSTests
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/name`)
3. Make your changes following the existing code style
4. Add tests for new functionality
5. Ensure all tests pass (`swift test`)
6. Submit a pull request

## License

This project is proprietary software. All rights reserved.

## Contact

For questions or support, please refer to the project documentation or contact the development team.
