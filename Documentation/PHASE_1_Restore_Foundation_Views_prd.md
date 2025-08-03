# PHASE 1: Restore Foundation Views - Product Requirements Document (PRD)

**Project**: AIKO (Adaptive Intelligence for Kontract Optimization)  
**Phase**: Phase 1 Foundation Views Restoration  
**Priority**: CRITICAL - Emergency Functionality Restoration  
**Date**: August 2, 2025  
**Version**: 1.0  

## 🚨 EMERGENCY CONTEXT

### Critical Situation Analysis
- **ROOT CAUSE**: Core user-facing views were disabled during TCA cleanup operations
- **IMPACT**: ~35% functional app, major user interface components non-operational
- **USER EXPERIENCE**: App largely unusable for end users in current state
- **BUSINESS RISK**: Complete functionality loss blocking all value delivery
- **DEVELOPMENT BLOCKER**: All architectural improvements blocked until views restored

### VanillaIce Consensus Validation ✅
**Reviewed by**: 5 iOS-specialized models (Code Refactoring Specialist, Swift Test Engineer, Swift Implementation Expert, Utility Code Generator, SwiftUI Sprint Leader)  
**Verdict**: **FEASIBLE as tactical patch** with strict scope discipline and realistic timeline  
**Key Recommendation**: Treat existing components as "design artifacts + data models", not drop-in TCA views

### Foundation Views Status Assessment

#### ✅ EXISTING Components (Need Restoration)
- **AppView.swift** - EXISTS (1294 lines, SwiftUI @Observable implementation)
  - Has comprehensive structure with iOS/macOS platform-specific implementations
  - References child components that may have import/dependency issues
  - Uses modern @Observable pattern instead of TCA
  
- **AppViewModel.swift** - EXISTS (917 lines, comprehensive ViewModel)
  - Contains all necessary child ViewModels (DocumentGenerationViewModel, ProfileViewModel, OnboardingViewModel, etc.)
  - Modern @MainActor @Observable implementation
  - Complete navigation state and functionality

- **Supporting UI Components** - ALL EXIST
  - DocumentTypesSection: `/Sources/AppCore/Views/SharedComponents.swift`
  - InputArea: `/Sources/AppCore/Views/InputArea.swift`
  - AgentChatInterface: `/Sources/Views/Components/AgentChatInterface.swift`
  - OriginalSAMGovInterface: `/Sources/Views/Components/OriginalSAMGovInterface.swift`

#### 🚨 MISSING Components (Need Creation)
- **OnboardingView.swift** - COMPLETELY MISSING
- **SettingsView.swift** - COMPLETELY MISSING

## 📋 PHASE 1 REQUIREMENTS

### Primary Objective
Restore essential Foundation Views to enable basic app functionality and user access, transitioning from disabled TCA architecture to functional SwiftUI @Observable patterns.

### Success Criteria
1. **AppView Functional** - Main app view loads without compilation errors
2. **OnboardingView Created** - New user setup and provider configuration accessible  
3. **SettingsView Created** - App configuration and user preferences accessible
4. **Navigation Working** - Users can navigate between foundation views
5. **Build Success** - Clean compilation with zero errors
6. **Basic User Flow** - New users can onboard, existing users can access settings

## 🎯 DETAILED REQUIREMENTS

### 1. AppView Restoration (HIGH PRIORITY)

**Current State**: AppView.swift exists but may have dependency/import issues preventing compilation

**Requirements**:
- **Import Resolution**: Fix any missing imports for referenced UI components
- **Dependency Injection**: Ensure all required services are properly injected
- **Component References**: Verify all referenced components (DocumentTypesSection, InputArea, etc.) are accessible
- **Platform Separation**: Maintain iOS/macOS platform-specific implementations
- **@Observable Integration**: Ensure proper SwiftUI @Observable ViewModel binding
- **Navigation Structure**: Functional navigation with proper NavigationStack implementation

**Technical Specifications**:
```swift
// AppView.swift structure validation
public struct AppView: View {
    @State private var appViewModel = AppViewModel()
    
    public var body: some View {
        #if os(iOS)
        iOSAppView(viewModel: appViewModel)
        #elseif os(macOS)
        macOSAppView(viewModel: appViewModel)
        #endif
    }
}
```

**Deliverables**:
- ✅ AppView compiles without errors
- ✅ All component imports resolved
- ✅ Navigation functional
- ✅ Platform-specific implementations working

### 2. OnboardingView Creation (HIGH PRIORITY)

**Current State**: COMPLETELY MISSING - needs full implementation

**Requirements**:
- **Welcome Screen**: App introduction and value proposition
- **LLM Provider Setup**: Guide users through API key configuration (OpenAI, Claude, Gemini, Azure)
- **Provider Testing**: Validate API connections before proceeding
- **Biometric Authentication**: Face ID/Touch ID setup if desired
- **Google Maps API**: Optional Google Maps API key for vendor search
- **First-Time Setup**: Initial app configuration and preferences
- **Skip Options**: Allow advanced users to skip non-essential setup steps

**User Flow**:
1. Welcome & app introduction
2. Choose LLM provider (with explanations)
3. Enter and validate API key
4. Optional: Enable biometric authentication
5. Optional: Google Maps API setup
6. Complete setup and enter main app

**Technical Specifications**:
```swift
public struct OnboardingView: View {
    @State private var onboardingViewModel: OnboardingViewModel
    @State private var currentStep: OnboardingStep = .welcome
    
    public init(onboardingViewModel: OnboardingViewModel) {
        self._onboardingViewModel = State(initialValue: onboardingViewModel)
    }
    
    public var body: some View {
        NavigationStack {
            // Multi-step onboarding flow
        }
    }
}
```

**Deliverables**:
- 🆕 Complete OnboardingView implementation
- 🆕 Multi-step setup wizard
- 🆕 LLM provider configuration
- 🆕 API key validation
- 🆕 Biometric authentication setup

### 3. SettingsView Creation (HIGH PRIORITY)

**Current State**: COMPLETELY MISSING - needs full implementation

**Requirements**:
- **LLM Provider Management**: Switch providers, update API keys
- **API Key Management**: Secure viewing/editing of stored keys
- **Provider Testing**: Test connections for configured providers
- **App Preferences**: Theme, notifications, default behaviors
- **Biometric Settings**: Enable/disable Face ID/Touch ID
- **Data Management**: Clear cache, export/import settings
- **About Section**: App version, build info, privacy policy
- **Reset Options**: Reset to defaults, clear all data

**Settings Sections**:
1. **LLM Providers**: Current provider, API keys, connection status
2. **Security**: Biometric authentication preferences
3. **Appearance**: Theme selection, interface preferences
4. **Data & Privacy**: Cache management, data export/import
5. **About**: Version info, support links, legal information

**Technical Specifications**:
```swift
public struct SettingsView: View {
    @State private var settingsViewModel: SettingsViewModel
    
    public init(settingsViewModel: SettingsViewModel) {
        self._settingsViewModel = State(initialValue: settingsViewModel)
    }
    
    public var body: some View {
        NavigationStack {
            // Settings sections and preferences
        }
    }
}
```

**Deliverables**:
- 🆕 Complete SettingsView implementation
- 🆕 LLM provider management interface
- 🆕 Security and privacy controls
- 🆕 App preferences configuration
- 🆕 Data management tools

## 🏗️ TECHNICAL IMPLEMENTATION STRATEGY

### Architecture Approach
- **SwiftUI @Observable Pattern**: Use modern SwiftUI with @Observable ViewModels (no TCA)
- **Platform Separation**: Maintain clean iOS/macOS implementations
- **Dependency Injection**: Proper service injection for testability
- **Error Handling**: Comprehensive error states and recovery
- **Accessibility**: Full VoiceOver and accessibility support

### Development Priorities
1. **AppView Restoration** (Week 1, Days 1-3)
   - Fix imports and dependencies
   - Resolve compilation errors
   - Test navigation functionality

2. **OnboardingView Creation** (Week 1, Days 3-5)  
   - Implement multi-step wizard
   - LLM provider configuration
   - API key validation logic

3. **SettingsView Creation** (Week 2, Days 1-3)
   - Settings interface implementation
   - Provider management functionality
   - Data management tools

4. **Integration Testing** (Week 2, Days 4-5)
   - Cross-component navigation
   - Data persistence validation
   - Platform compatibility testing

### Risk Mitigation
- **Incremental Implementation**: Build and test each view independently
- **Fallback UI**: Simple backup interfaces if complex features fail
- **Dependency Validation**: Verify all service dependencies before integration
- **Platform Testing**: Test on both iOS and macOS throughout development

## 📊 SUCCESS METRICS

### Functional Metrics
- **Compilation Success**: 100% - all Foundation Views compile without errors
- **Navigation Success**: 100% - users can navigate between all Foundation Views
- **Onboarding Completion**: Users can complete full setup process
- **Settings Access**: Users can modify all app preferences and provider settings
- **API Validation**: LLM provider connections validate successfully

### User Experience Metrics  
- **App Launch**: Users can open app and see functional interface
- **First-Time Setup**: New users can complete onboarding without issues
- **Provider Configuration**: Users can successfully configure LLM providers
- **Settings Changes**: Users can modify app preferences and see changes applied

### Technical Metrics
- **Build Time**: Maintain <20 seconds for full build
- **Code Quality**: Zero SwiftLint violations in new implementations
- **Test Coverage**: >80% test coverage for new ViewModels and logic
- **Memory Usage**: Foundation Views use <50MB memory

## 🚀 IMPLEMENTATION PHASES

### Phase 1A: AppView Restoration (3 days)
- Day 1: Fix imports and resolve compilation errors
- Day 2: Test navigation and component integration  
- Day 3: Platform compatibility validation

### Phase 1B: OnboardingView Creation (3 days)
- Day 1: Basic onboarding structure and welcome screen
- Day 2: LLM provider setup and API key validation
- Day 3: Complete setup flow and navigation integration

### Phase 1C: SettingsView Creation (3 days)  
- Day 1: Settings structure and basic preferences
- Day 2: LLM provider management interface
- Day 3: Advanced settings and data management

### Phase 1D: Integration & Testing (2 days)
- Day 1: Cross-component integration testing
- Day 2: Platform compatibility and final cleanup

**Total Estimated Duration**: 11 days (2.2 weeks)

## 📋 ACCEPTANCE CRITERIA

### AppView Requirements
- [ ] Compiles without errors or warnings
- [ ] All referenced components properly imported and accessible
- [ ] Navigation between views functional
- [ ] iOS and macOS implementations both working
- [ ] @Observable ViewModel integration functional

### OnboardingView Requirements  
- [ ] Complete multi-step onboarding flow
- [ ] LLM provider selection and configuration
- [ ] API key validation with clear success/error states
- [ ] Optional biometric authentication setup
- [ ] Skip options for advanced users
- [ ] Smooth navigation between onboarding steps

### SettingsView Requirements
- [ ] Complete settings interface with all sections
- [ ] LLM provider management (switch providers, update keys)
- [ ] Security settings (biometric authentication)
- [ ] App preferences (theme, notifications, etc.)
- [ ] Data management tools (clear cache, export/import)
- [ ] About section with version info

### Integration Requirements
- [ ] Seamless navigation between all Foundation Views
- [ ] Data persistence across app restarts
- [ ] Proper error handling and recovery
- [ ] Accessibility compliance
- [ ] Platform-specific optimizations working

## 🎯 POST-PHASE 1 READINESS

Upon completion of Phase 1, the app will have:
- **Functional Foundation**: Core user interface operational
- **User Onboarding**: New users can set up and configure the app
- **Settings Management**: Users can modify preferences and provider settings
- **Navigation System**: Basic app navigation restored
- **Platform Compatibility**: Working on both iOS and macOS

This creates the essential foundation needed to proceed with Phase 2 (Business Logic Views) and subsequent restoration phases.

---

**Document Status**: ✅ APPROVED - VanillaIce Consensus Validated  
**VanillaIce Verdict**: FEASIBLE as tactical patch with strict scope discipline  
**Implementation Status**: READY TO START - PRD approved for Phase 1 execution  
**Next Steps**: Begin AppView adapter + ObservableShell scaffolding (Days 1-2)