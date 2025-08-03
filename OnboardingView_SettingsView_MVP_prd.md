# OnboardingView & SettingsView MVP Creation PRD

**Project**: AIKO (Adaptive Intelligence for Kontract Optimization)  
**Phase**: PHASE 1 - Foundation Views Restoration  
**Version**: 1.0  
**Date**: August 2, 2025  
**Status**: ✅ VanillaIce Consensus Validated - Ready for Implementation  

---

## VanillaIce Consensus Validation Results ✅

**Consensus Status**: ✅ **APPROVED** (5/5 models consensus)  
**Models Consulted**: mistralai/codestral-2501, moonshotai/kimi-k2, codex-mini-latest, qwen/qwen-2.5-coder-32b-instruct, gemini-2.5-flash  
**Validation Date**: August 2, 2025  

### Consensus Summary
The VanillaIce consensus engine validated all key aspects of the PRD:

1. **✅ MVP Scope Appropriateness**: Well-scoped, addresses immediate foundational needs for user onboarding and settings configuration
2. **✅ Technical Architecture Soundness**: Sound architecture leveraging modern SwiftUI @Observable patterns and existing ViewModel structures
3. **✅ Timeline Realism**: Realistic 3-4 day implementation timeline given focused scope and existing foundation
4. **✅ Risk Assessment Completeness**: Comprehensive risk coverage with actionable mitigation strategies for integration, state management, and compatibility
5. **✅ Integration Strategy Effectiveness**: Effective modular design approach utilizing reusable components and existing structures

### Consensus Recommendation
**Proceed with implementation** - The PRD provides a solid foundation for the emergency functionality restoration phase with clear scope, realistic timeline, and comprehensive technical approach.

---

## Executive Summary

This PRD outlines the creation of OnboardingView and SettingsView MVP implementations to restore critical foundation functionality in the AIKO iOS app. These views are essential components of the emergency functionality restoration initiative, representing core user-facing features that were disabled during TCA cleanup operations.

### Strategic Objectives
1. **Restore Critical User Onboarding**: Implement functional onboarding flow for first-time users
2. **Enable Settings Management**: Provide comprehensive settings interface for app configuration
3. **Integration with Existing Architecture**: Seamlessly integrate with established SwiftUI @Observable patterns
4. **Emergency Functionality Priority**: Restore basic app functionality to support subsequent restoration phases
5. **Swift 6 Compliance**: Maintain strict concurrency compliance and modern SwiftUI patterns

---

## Background & Context

### Current Emergency Status
- **Functionality Level**: ~35% of app functionality operational
- **Root Cause**: TCA cleanup operations disabled core foundation views
- **User Impact**: App likely non-functional for end users without onboarding and settings
- **Development Priority**: All architectural modernization paused until basic functionality restored

### Existing Architecture Foundation
**AppView.swift** already contains integration points:
```swift
// OnboardingView integration (Line 94-95)
if !viewModel.isOnboardingCompleted {
    OnboardingView(viewModel: viewModel.onboardingViewModel)
}

// SettingsView integration (Line 51-53)
.sheet(isPresented: $viewModel.showingSettings) {
    SettingsSheet(viewModel: viewModel.settingsViewModel)
}
```

**AppViewModel.swift** already contains ViewModels:
```swift
public var onboardingViewModel = OnboardingViewModel()  // Line 16
public var settingsViewModel = SettingsViewModel()      // Line 19
```

### Available Data Models
**SettingsData.swift** provides comprehensive settings structure:
- `AppSettingsData`: Theme, accent color, auto-save settings
- `APISettingsData`: API endpoints, keys, model selection
- `DocumentSettingsData`: Template preferences, metadata options
- `NotificationSettingsData`: Notification preferences
- `DataPrivacySettingsData`: Privacy and security settings
- `AdvancedSettingsData`: Debug mode, beta features, performance settings

---

## Problem Statement

### Core Issues
1. **Missing Foundation Views**: OnboardingView and SettingsView do not exist, preventing app functionality
2. **User Experience Breakdown**: New users cannot complete onboarding process
3. **Configuration Inaccessible**: Users cannot modify app settings or API configurations
4. **Architectural Integration Gap**: ViewModels exist but corresponding views are missing
5. **Emergency Restoration Blocker**: Cannot proceed to Phase 2 business logic restoration without foundation views

### Business Impact
- **User Adoption**: New users cannot onboard to use the app
- **Existing Users**: Cannot configure LLM providers or adjust app settings
- **Development Velocity**: Phase 2-4 restoration blocked until foundation views operational
- **Market Readiness**: App unusable in current state for deployment

---

## Proposed Solution

### OnboardingView MVP Implementation

#### Core Functionality
1. **Welcome Screen**: App introduction and value proposition
2. **API Provider Setup**: LLM provider selection and API key configuration
3. **Permissions Requests**: Face ID/Touch ID authentication setup
4. **Usage Introduction**: Key feature overview and navigation guidance
5. **Completion State**: Mark onboarding as completed and transition to main app

#### Technical Architecture
```swift
public struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    public var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            // Step-based onboarding flow
        }
    }
}

@MainActor
@Observable
public final class OnboardingViewModel {
    public var currentStep: OnboardingStep = .welcome
    public var isCompleted: Bool = false
    public var navigationPath = NavigationPath()
    // API setup state
    // Permission state
    // Progress tracking
}
```

#### User Flow
1. **Welcome Step**: App introduction, privacy policy, terms acceptance
2. **API Setup Step**: Provider selection (OpenAI, Claude, Gemini, Custom), API key input
3. **Authentication Step**: Face ID/Touch ID setup (optional)
4. **Feature Overview Step**: Core functionality introduction
5. **Completion Step**: Onboarding completion confirmation

### SettingsView MVP Implementation

#### Core Functionality
1. **App Settings Section**: Theme, font size, auto-save preferences
2. **API Settings Section**: Provider management, model selection, endpoint configuration
3. **Document Settings Section**: Template preferences, formatting options
4. **Privacy Settings Section**: Data encryption, biometric authentication
5. **Advanced Settings Section**: Debug mode, performance tuning, beta features

#### Technical Architecture
```swift
public struct SettingsSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        NavigationStack {
            Form {
                // Settings sections
            }
        }
    }
}

@MainActor
@Observable
public final class SettingsViewModel {
    public var settingsData: SettingsData
    public var isLoading: Bool = false
    public var saveStatus: SaveStatus = .none
    // Section management
    // Data persistence
}
```

#### Settings Sections
1. **General**: Theme selection, accent color, font size
2. **LLM Providers**: API key management, model selection, custom endpoints
3. **Documents**: Default formats, template preferences, metadata options
4. **Notifications**: App notifications, sounds, reminder settings
5. **Privacy & Security**: Data encryption, biometric lock, analytics
6. **Advanced**: Debug mode, cache settings, beta features

---

## Technical Requirements

### Architecture Requirements
- **SwiftUI @Observable Pattern**: Use modern SwiftUI state management with @Observable ViewModels
- **AppCore Integration**: Leverage existing SettingsData models and dependency injection
- **Swift 6 Compliance**: Maintain strict concurrency compliance with @MainActor annotations
- **Platform Compatibility**: Support both iOS and macOS through conditional compilation
- **Error Handling**: Implement robust error handling with user-friendly messages

### Performance Requirements
- **Launch Performance**: OnboardingView must appear within 2 seconds of app launch
- **Settings Responsiveness**: Settings changes must apply within 500ms
- **Memory Efficiency**: Combined memory footprint <50MB for both views
- **Persistence**: Settings changes must persist immediately to UserDefaults/Keychain

### Integration Requirements
- **AppViewModel Integration**: Seamless integration with existing AppViewModel structure
- **Navigation Flow**: Proper integration with AppView navigation stack
- **State Management**: Consistent state management with parent AppViewModel
- **Dependency Injection**: Use established dependency injection patterns

---

## Implementation Phases

### Phase 1: OnboardingView Implementation (Day 1-2)

**Day 1: Foundation**
- Create OnboardingViewModel with @Observable pattern
- Implement basic OnboardingView structure with NavigationStack
- Create OnboardingStep enum and navigation flow
- Implement welcome screen and basic step progression

**Day 2: Core Features**
- Implement API provider setup screen with key validation
- Add biometric authentication setup flow
- Create feature overview screens
- Implement completion flow and state persistence

### Phase 2: SettingsView Implementation (Day 2-3)

**Day 2-3: Settings Foundation**
- Create SettingsViewModel with SettingsData integration
- Implement SettingsSheet structure with Form sections
- Create general app settings section (theme, font, auto-save)
- Implement API settings section with provider management

**Day 3: Advanced Settings**
- Add document settings section with template preferences
- Implement notification settings with toggle controls
- Create privacy & security settings with biometric controls
- Add advanced settings section with debug and performance options

### Phase 3: Integration & Polish (Day 3-4)

**Day 3-4: Integration**
- Ensure seamless AppView integration
- Implement proper error handling and loading states
- Add input validation and user feedback
- Test cross-platform compatibility (iOS/macOS)
- Verify Swift 6 concurrency compliance

---

## Success Criteria

### Functional Criteria
- **OnboardingView**: Complete onboarding flow from welcome to main app
- **SettingsView**: All settings sections functional with data persistence
- **AppView Integration**: Seamless navigation flow without crashes
- **Data Persistence**: Settings and onboarding state properly saved

### Technical Criteria
- **Build Success**: Zero compilation errors across all targets
- **Swift 6 Compliance**: No concurrency warnings or violations
- **Performance**: Meet specified performance requirements
- **Error Handling**: Graceful error handling without crashes

### User Experience Criteria
- **Intuitive Navigation**: Clear progression through onboarding steps
- **Responsive Interface**: Immediate feedback for all user interactions
- **Consistent Design**: Matches existing app design patterns
- **Accessibility**: Proper accessibility support for all controls

---

## Risk Assessment

### High-Risk Areas
1. **API Key Security**: Secure storage and validation of API keys
   - **Mitigation**: Use iOS Keychain for secure storage, implement key validation
2. **Onboarding State Management**: Proper tracking of onboarding completion
   - **Mitigation**: Use UserDefaults with backup state validation
3. **Settings Data Synchronization**: Ensuring settings changes propagate correctly
   - **Mitigation**: Implement immediate persistence with change notifications

### Medium-Risk Areas
1. **Cross-Platform Compatibility**: iOS/macOS differences in UI components
   - **Mitigation**: Platform-specific implementations with shared ViewModels
2. **Navigation Integration**: Seamless integration with existing AppView
   - **Mitigation**: Thorough testing of navigation flows and state transitions

---

## Dependencies

### Completed Prerequisites
- ✅ AppView with OnboardingView and SettingsSheet integration points
- ✅ AppViewModel with OnboardingViewModel and SettingsViewModel declarations
- ✅ SettingsData models with comprehensive settings structure
- ✅ SwiftUI @Observable patterns established
- ✅ Swift 6 strict concurrency compliance achieved

### External Dependencies
- SwiftUI NavigationStack (iOS 16.0+, macOS 13.0+)
- UserDefaults for onboarding state persistence
- Keychain Services for secure API key storage
- LocalAuthentication for biometric setup

### Internal Dependencies
- AppCore SettingsData models
- Established dependency injection patterns
- Existing error handling framework
- AppViewModel state management integration

---

## Testing Strategy

### Unit Testing
- **OnboardingViewModel**: Navigation flow and state management
- **SettingsViewModel**: Settings data persistence and validation
- **API Key Validation**: Security and format validation
- **State Persistence**: UserDefaults and Keychain integration

### Integration Testing
- **AppView Integration**: Navigation flow testing
- **Cross-Platform**: iOS and macOS compatibility
- **Settings Synchronization**: Data persistence and retrieval
- **Error Scenarios**: Network failures and invalid inputs

### User Experience Testing
- **Onboarding Flow**: Complete user journey testing
- **Settings Interface**: All settings sections and controls
- **Navigation**: Back/forward navigation and state preservation
- **Accessibility**: VoiceOver and accessibility feature testing

---

## Documentation Requirements

### Technical Documentation
- **Implementation Guide**: Step-by-step implementation instructions
- **Architecture Overview**: ViewModel and View structure documentation
- **Integration Patterns**: How to integrate with existing AppView/AppViewModel
- **API Reference**: Public interface documentation for ViewModels

### User Documentation
- **Onboarding Guide**: User-facing onboarding flow documentation
- **Settings Reference**: Complete settings options documentation
- **Troubleshooting**: Common issues and resolution steps

---

## Success Metrics & KPIs

### Development Metrics
- **Implementation Time**: Complete implementation within 3-4 days
- **Code Quality**: Zero SwiftLint violations, comprehensive test coverage
- **Build Performance**: Clean builds without errors or warnings
- **Memory Usage**: <50MB combined memory footprint

### User Experience Metrics
- **Onboarding Completion**: >95% completion rate through onboarding flow
- **Settings Usage**: All settings sections accessible and functional
- **Error Rate**: <1% user-facing errors during normal usage
- **Performance**: All interactions complete within specified time limits

### Quality Metrics
- **Test Coverage**: >80% test coverage for all ViewModels
- **Accessibility**: 100% VoiceOver compatibility
- **Cross-Platform**: Identical functionality on iOS and macOS
- **Security**: Secure storage and handling of sensitive data

---

## Conclusion

The OnboardingView & SettingsView MVP creation represents a critical milestone in AIKO's emergency functionality restoration. These foundation views are essential for basic app functionality and user experience. The implementation leverages existing architectural patterns and data models to deliver a complete, production-ready solution.

The 3-4 day timeline is realistic given the existing foundation of AppViewModel integration points and comprehensive SettingsData models. The focus on MVP functionality ensures rapid delivery while maintaining quality and enabling subsequent restoration phases.

This implementation directly enables Phase 2 business logic restoration by providing users with a functional app foundation and configuration interface necessary for advanced features.

---

**Next Steps:**
1. ✅ VanillaIce consensus validation completed - PRD approved for implementation
2. **READY**: Implementation kickoff with OnboardingView creation (Day 1)
3. Daily progress tracking and milestone validation following TDD process
4. Integration testing and quality assurance upon completion

**Implementation Status:** ✅ **APPROVED FOR IMPLEMENTATION** - VanillaIce consensus validation complete with 5/5 model approval