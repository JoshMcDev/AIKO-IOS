# AppView Adapter + ObservableShell Scaffolding - TDD Rubric

**Task**: AppView adapter + ObservableShell scaffolding (Days 1-2)  
**Phase**: PHASE 1 Foundation Views Restoration  
**Priority**: CRITICAL - Emergency functionality restoration  
**Date**: August 2, 2025  

## TDD RUBRIC OVERVIEW

This rubric defines the testing framework, acceptance criteria, and validation metrics for the AppView adapter + ObservableShell scaffolding implementation that serves as the foundation for AIKO's emergency functionality restoration.

---

## MEASURES OF EFFECTIVENESS (MoE)

### Primary MoE: Compilation & Launch Success
**Definition**: AppView compiles cleanly and launches successfully on both iOS and macOS platforms

**Success Criteria**:
- [ ] **Clean iOS Compilation**: Zero compilation errors for iOS target
- [ ] **Clean macOS Compilation**: Zero compilation errors for macOS target  
- [ ] **Successful iOS Launch**: App launches in iOS simulator without crashes
- [ ] **Successful macOS Launch**: App launches on macOS without crashes
- [ ] **AppViewModel Integration**: Existing @Observable AppViewModel continues to function

**Test Methods**:
```bash
# iOS Compilation Test
cd /Users/J/aiko && xcodebuild -scheme AIKO -destination "platform=iOS Simulator,name=iPhone 16 Pro" build

# macOS Compilation Test  
xcodebuild -scheme AIKO -destination "platform=macOS" build

# Launch Tests
# iOS: Launch in simulator and verify main interface displays
# macOS: Launch app and verify main interface displays
```

### Secondary MoE: Navigation Foundation
**Definition**: Basic navigation structure works without crashes and provides foundation for missing views

**Success Criteria**:
- [ ] **NavigationStack Implementation**: SwiftUI NavigationStack works in both iOSAppView and macOSAppView
- [ ] **Safe Navigation**: Navigation between functional views works without crashes
- [ ] **Placeholder Integration**: Missing OnboardingView/SettingsView show "Coming Soon" placeholders
- [ ] **Navigation State Management**: @Observable navigation state management functional
- [ ] **Platform-Specific Navigation**: iOS and macOS navigation patterns work correctly

**Test Methods**:
- Manual navigation testing between all functional views
- Placeholder view navigation and return to main app
- Platform-specific navigation behavior validation
- State persistence across navigation actions

### Tertiary MoE: Platform Separation Integrity
**Definition**: Platform separation (153+ eliminated conditionals) remains intact during restoration

**Success Criteria**:
- [ ] **No Platform Conditionals Added**: Zero new #if os() conditionals introduced in AppCore
- [ ] **iOS Implementation Works**: iOSAppView-specific features function correctly
- [ ] **macOS Implementation Works**: macOSAppView-specific features function correctly
- [ ] **Clean Dependency Injection**: Platform clients remain properly injected
- [ ] **Existing Architecture Preserved**: No regression in platform separation achievements

**Test Methods**:
- Static code analysis for new platform conditionals
- Platform-specific functionality testing
- Dependency injection validation
- Architecture compliance verification

---

## MEASURES OF PERFORMANCE (MoP)

### MoP1: Build Performance
**Metric**: Compilation time should not significantly regress from current baseline

**Performance Targets**:
- **iOS Build Time**: ≤ 20 seconds (current baseline ~16.45s)
- **macOS Build Time**: ≤ 25 seconds
- **Clean Build Success Rate**: 100% (zero build failures)
- **Incremental Build Time**: ≤ 5 seconds for single file changes

**Test Methods**:
```bash
# Measure build times
time xcodebuild -scheme AIKO -destination "platform=iOS Simulator,name=iPhone 16 Pro" build
time xcodebuild -scheme AIKO -destination "platform=macOS" build

# Test incremental builds with single file changes
```

### MoP2: App Launch Performance  
**Metric**: App launch time should remain within acceptable limits

**Performance Targets**:
- **iOS Launch Time**: ≤ 3 seconds from tap to main interface
- **macOS Launch Time**: ≤ 2 seconds from launch to main interface
- **Memory Usage**: ≤ 200MB on launch (iOS), ≤ 250MB (macOS)
- **CPU Usage**: ≤ 50% during launch phase

**Test Methods**:
- Instruments Time Profiler for launch time measurement
- Memory and CPU usage monitoring during app launch
- Multiple launch cycles to verify consistency

### MoP3: Navigation Performance
**Metric**: Navigation between views should be responsive and smooth

**Performance Targets**:
- **Navigation Response Time**: ≤ 100ms from tap to view transition
- **View Transition Animation**: Smooth 60fps animations
- **State Management Overhead**: ≤ 10ms for @Observable state updates
- **Memory Leak Prevention**: Zero memory leaks during navigation cycles

**Test Methods**:
- Manual navigation timing with stopwatch
- Instruments Core Animation profiler for animation smoothness
- Memory leak detection with repeated navigation cycles

---

## DEFINITION OF SUCCESS (DoS)

### Critical Success Requirements
**ALL of these must be achieved for task completion**:

1. **Compilation Success**: Both iOS and macOS targets compile with zero errors
2. **Launch Success**: App launches successfully on both platforms without crashes  
3. **Basic Navigation**: Users can navigate between functional views without app crashes
4. **Platform Integrity**: No regression in platform separation (153+ conditionals remain eliminated)
5. **Foundation Readiness**: Clear integration contracts established for OnboardingView/SettingsView

### Success Validation Process
```
Step 1: Run automated build tests → PASS/FAIL
Step 2: Manual launch testing → PASS/FAIL  
Step 3: Navigation flow testing → PASS/FAIL
Step 4: Platform separation audit → PASS/FAIL
Step 5: Integration contract review → PASS/FAIL

ALL STEPS MUST PASS for DoS achievement
```

---

## DEFINITION OF DONE (DoD)

### Completion Checklist
**Task is complete when ALL items are checked**:

#### Code Quality & Compilation
- [ ] iOS target compiles with zero errors and warnings
- [ ] macOS target compiles with zero errors and warnings  
- [ ] All referenced components are properly imported and accessible
- [ ] No new platform conditionals (#if os()) added to AppCore
- [ ] Code follows existing Swift and SwiftUI patterns

#### Functionality & Testing
- [ ] App launches successfully on iOS simulator (iPhone 16 Pro)
- [ ] App launches successfully on macOS
- [ ] Navigation between functional views works without crashes
- [ ] Placeholder views for OnboardingView/SettingsView display correctly
- [ ] Navigation back from placeholders to main app works
- [ ] Existing functional features remain operational (scanner, LLM, etc.)

#### Platform Compatibility
- [ ] iOSAppView-specific implementations function correctly
- [ ] macOSAppView-specific implementations function correctly
- [ ] Platform-specific behaviors (menus, windows, etc.) preserved
- [ ] No regression in existing platform separation achievements

#### Documentation & Handoff
- [ ] Integration contracts documented for OnboardingView implementation
- [ ] Integration contracts documented for SettingsView implementation  
- [ ] Navigation patterns and state management contracts established
- [ ] Handoff checklist created for Days 3-4 implementation team
- [ ] Critical issues and technical debt documented

#### Performance & Quality Gates
- [ ] Build times remain within acceptable limits (≤20s iOS, ≤25s macOS)
- [ ] App launch performance acceptable (≤3s iOS, ≤2s macOS)
- [ ] Navigation responsiveness maintained (≤100ms response time)
- [ ] Memory usage within limits (≤200MB iOS, ≤250MB macOS)
- [ ] No memory leaks detected during navigation testing

---

## TESTING STRATEGY

### Phase 1: Automated Testing (30 minutes)
**Build & Compilation Tests**
```bash
# Automated test script
#!/bin/bash
echo "Running AppView Adapter TDD Tests..."

# Test iOS compilation
echo "Testing iOS compilation..."
cd /Users/J/aiko
if xcodebuild -scheme AIKO -destination "platform=iOS Simulator,name=iPhone 16 Pro" build > build_ios.log 2>&1; then
    echo "✓ iOS compilation PASSED"
else
    echo "✗ iOS compilation FAILED"
    tail build_ios.log
    exit 1
fi

# Test macOS compilation  
echo "Testing macOS compilation..."
if xcodebuild -scheme AIKO -destination "platform=macOS" build > build_macos.log 2>&1; then
    echo "✓ macOS compilation PASSED"
else
    echo "✗ macOS compilation FAILED"
    tail build_macos.log
    exit 1
fi

echo "All automated tests PASSED ✓"
```

### Phase 2: Manual Testing (90 minutes)
**Launch & Navigation Tests**

**iOS Testing (45 minutes)**:
1. Launch app in iPhone 16 Pro simulator
2. Verify main interface displays correctly
3. Test navigation to all functional views
4. Test navigation to placeholder views
5. Test navigation back from placeholders
6. Verify existing features (scanner, LLM) still work

**macOS Testing (45 minutes)**:
1. Launch app on macOS
2. Verify main interface displays correctly  
3. Test platform-specific behaviors (menus, windows)
4. Test navigation flows
5. Test integration with existing functional features

### Phase 3: Integration Testing (60 minutes)
**End-to-End Workflow Tests**

1. **Document Scanning Workflow**: Test complete document scanning with restored AppView
2. **LLM Provider Interaction**: Test LLM chat functionality through main interface
3. **State Management**: Test @Observable AppViewModel integration
4. **Cross-Platform**: Test same workflows on both iOS and macOS
5. **Performance**: Monitor resource usage during real-world usage

---

## ACCEPTANCE CRITERIA MATRIX

| Test Category | iOS | macOS | Status |
|---------------|-----|-------|---------|
| **Compilation Success** | ☐ | ☐ | REQUIRED |
| **Launch Success** | ☐ | ☐ | REQUIRED |
| **Navigation Functional** | ☐ | ☐ | REQUIRED |
| **Placeholder Views** | ☐ | ☐ | REQUIRED |
| **Existing Features Work** | ☐ | ☐ | REQUIRED |
| **Platform-Specific Behavior** | ☐ | ☐ | REQUIRED |
| **Performance Acceptable** | ☐ | ☐ | REQUIRED |
| **No Memory Leaks** | ☐ | ☐ | REQUIRED |

**ALL boxes must be checked for task completion**

---

## RISK MITIGATION & FALLBACK PLANS

### High Risk: Compilation Failures
**Mitigation**: 
- Front-load dependency analysis in first 60 minutes
- Create minimal stub implementations for missing components
- **Fallback**: Single-platform focus (iOS priority) if cross-platform issues

### Medium Risk: Navigation Complexity
**Mitigation**:
- Start with simple NavigationStack patterns
- Add placeholder views before complex navigation logic
- **Fallback**: Simplified navigation with basic view switching

### Low Risk: Performance Regression  
**Mitigation**:
- Monitor build times throughout development
- Profile app launch performance during testing
- **Fallback**: Accept minor performance regression for functionality

---

## SUCCESS METRICS SUMMARY

**PASS Criteria**: 100% MoE achievement + MoP within acceptable limits + DoS complete + DoD checklist 100%

**Key Success Indicators**:
- ✓ Clean compilation on both platforms
- ✓ Successful app launch without crashes
- ✓ Functional navigation without errors
- ✓ Foundation ready for OnboardingView/SettingsView integration
- ✓ Platform separation integrity maintained

---

**Document Status**: READY FOR IMPLEMENTATION  
**Next Phase**: Begin /dev with failing tests + minimal code scaffolding  
**Timeline**: Days 1-2 of Phase 1 Foundation Views Restoration

<!-- /tdd complete -->