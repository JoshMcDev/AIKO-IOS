# Changelog

All notable changes to AIKO will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-07-14

### Changed
- **BREAKING**: Migrated to TodoWrite-only task management system
- Removed Task Master AI integration completely
- Removed Todo folder and markdown-based task tracking
- Updated all documentation to reflect new task management approach
- Fixed all date references from January 2025 to July 14, 2025

### Removed
- Task Master AI MCP server and configuration
- Todo folder with all task markdown files
- 46 Quick Reference Guide files
- 12 unnecessary scripts
- All example files in Examples/ directory
- All demo executables in DemoExecutables/ directory
- VanillaIce-QuickWin-Optimizations.swift (moved to .claude/)
- Empty test directories

### Fixed
- Package.swift warnings for non-existent exclude paths
- AdaptiveConversationOrchestrator.swift unused variable warning
- Xcode user state merge conflicts

### Added
- New project README.md with current architecture
- Updated documentation structure in Documentation/ folder
- Forms moved from KnowledgeBase/ to Resources/

## [1.9.0] - 2025-01-14

### Added
- Adaptive Prompting Engine with minimal questioning
- Conversational Flow Architecture
- Context extraction from documents
- User pattern learning capabilities
- Smart defaults system

### Enhanced
- Document processing with 96% OCR accuracy
- Compliance checking with FAR/DFAR validation
- Performance optimizations for large documents

## [1.8.0] - 2025-01-12

### Added
- Complete regulation database (10,887 HTML files)
- FAR, DFARS, and service supplement integration
- Clause selection engine
- Document chain metadata management

## [1.7.0] - 2025-01-10

### Added
- Core Data backup and restore functionality
- Settings persistence
- Error alert system
- Document upload/download features

## [1.6.0] - 2025-01-08

### Added
- The Composable Architecture integration
- SwiftUI views for iOS and macOS
- Basic document upload functionality
- Initial Core Data models

## [1.0.0] - 2025-01-01

### Added
- Initial project setup
- Basic project structure
- Swift Package Manager configuration
- README and documentation templates