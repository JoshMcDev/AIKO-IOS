# AIKO-IOS Project Configuration
> **Project-Level CLAUDE.md - Works in Harmony with Global CLAUDE.md**
> **Production-Ready MVP Framework v2.0 Implementation**

---

## 🔗 Integration with Global CLAUDE.md

This project-level CLAUDE.md complements the global configuration at `/Users/J/.claude/CLAUDE.md`:
- **Global CLAUDE.md**: Handles system configuration, MCP tools, cognitive frameworks, workflow patterns
- **This File**: Handles AIKO-specific requirements, production metrics, custom commands, UI preferences

**MCP Tool Display**: When using MCP tools, always show:
```
**MCP Server**: [server-name]  
**Tool**: [tool-name]
```

---

## 🚀 Production-Ready MVP Framework (95% Standard)

### Core Philosophy: "Production-Ready First, Certify at 95%, Then Expand"

This project follows the Production-Ready MVP-First Strategy Framework v2.0:
- **Every feature must be fully functional and production-ready**
- **Minimum score of 95/100 required for certification**
- **Zero technical debt in MVP**
- **Test Everything at Scale**

### 📊 Production Status Dashboard

| Metric | Current | Target | Status |
|--------|---------|--------|---------|
| Overall Score | 92/100 | 95/100 | 🟡 |
| Test Coverage | 78% | 100% | 🟡 |
| Performance SLA | 180ms | <200ms | 🟢 |
| Security Score | 9/10 | 10/10 | 🟡 |
| Crash-Free Rate | 99.7% | 99.9% | 🟡 |

---

## 🎯 Current MVP: Core SAM.gov Integration

### Production Acceptance Criteria
- [x] All features fully functional in production environment
- [x] Performance: <200ms response time for all operations
- [ ] Security: Passes iOS security audit (pending)
- [x] Reliability: 99.9% crash-free rate capability
- [x] Scalability: Handles concurrent user operations
- [ ] Monitoring: Full Crashlytics and analytics deployed
- [x] Documentation: Complete user guide and tooltips
- [ ] Recovery: iCloud backup and restore implementation

### 📈 Scoring Breakdown (92/100)

| Category | Score | Details |
|----------|-------|---------|
| Functionality | 24/25 | Missing offline sync completion |
| Performance | 19/20 | Excellent response times |
| Security | 18/20 | Pending security audit |
| Reliability | 13/15 | 99.7% crash-free (needs 99.9%) |
| Code Quality | 9/10 | Clean SwiftUI architecture |
| User Experience | 9/10 | Intuitive with comprehensive guide |

### Production Blockers (MUST RESOLVE for 95%)
- [ ] Complete iOS security audit
- [ ] Achieve 100% test coverage for critical paths
- [ ] Implement comprehensive crash reporting
- [ ] Complete offline sync capabilities
- [ ] Pass accessibility audit

---

## 🏗️ Project Structure & Configuration

### Xcode Project Structure
**CRITICAL**: Always use the Swift Package structure:
```bash
# CORRECT - Open via:
/Users/J/aiko/Package.swift

# WRONG - DO NOT use:
/Users/J/aiko/AIKO/AIKO.xcodeproj
```

### Build Instructions
1. Open Xcode with Package.swift
2. Wait for package resolution
3. Select AIKO scheme
4. Build with ⌘B
5. Run tests with ⌘U

---

## 🛠️ Project-Specific Commands & Workflows

### Custom Commands
- **/err**: Reads error log from desktop and uses ast-grep to fix issues
- **ast-grep**: ALWAYS use for code searching (structural analysis preferred)

### Daily Production Cycle
```bash
# Morning: Verify production readiness [THINK HARDER]
"Check AIKO app production readiness metrics"
"Run XCTest suite including UI tests"
"Review Xcode static analysis results"
"Verify progress toward 95% threshold"

# Development: Maintain production standards [ULTRATHINK]
"Implement feature with SwiftUI best practices"
"Write comprehensive XCTest before implementation"
"Profile memory usage - ensure zero leaks"
"Verify accessibility compliance"

# Evening: Production validation [THINK HARDER]
"Run Instruments performance profiling"
"Execute stress tests on physical device"
"Update production readiness dashboard"
"Document any new technical decisions"
```

### iOS-Specific MCP Tools Usage
```bash
# Build and Test
/xcodebuild.build_ios_simulator project:Package.swift scheme:AIKO
/ios-simulator.boot_simulator device:"iPhone 15 Pro"
/swiftformat.format_directory directoryPath:/Users/J/aiko

# Database Debugging
/coredata-sqlite.find_databases appIdentifier:AIKO
/coredata-sqlite.inspect_schema dbPath:[found-path]

# Visual Debugging
/desktop-automation.screenshot
/ios-simulator.capture_screenshot device:"iPhone 15 Pro" outputPath:debug.png
```

---

## 🎨 UI/UX Specifications

### Design Principles
- **Clean UI**: No unnecessary animations
- **Consistency**: Unified components across all views
- **Accessibility**: VoiceOver support required
- **Performance**: Smooth 60fps scrolling

### Component Standards
- **InputArea**: Use for ALL text input interfaces
- **Share Buttons**: Consistent styling (title2 font, aikoPrimary color)
- **Icons**: SAMIcon.png in header, SF Symbols elsewhere
- **Gradients**: Replaced with solid colors for performance

### Color Scheme
- Primary: aikoPrimary (patriotic blue)
- Secondary: aikoSecondary
- Background: SystemBackground
- Text: Label colors for automatic dark mode

---

## ✅ Completed Features (Production-Ready)

1. **User Authentication**
   - Secure implementation with Keychain
   - Biometric support (Face ID/Touch ID)
   - Session management
   - Password recovery

2. **SAM.gov Integration**
   - Real-time search with multiple entries
   - Entity details retrieval
   - Exclusions checking
   - Small Business status indicators

3. **My Acquisitions**
   - Full CRUD operations
   - Document management
   - Share functionality
   - Contract file support

4. **User Guide**
   - Comprehensive in-app documentation
   - Context-sensitive help
   - Interactive tutorials
   - Accessibility compliant

---

## 🐛 Fixed Issues Log

### Performance Optimizations
- LinearGradient replaced with solid colors (40% render improvement)
- Complex expressions refactored to computed properties
- Lazy loading implemented for large lists

### UI/UX Fixes
- Share buttons unified across all views
- SAM Report "NO" → "No" for better readability
- Removed confusing "likely means no issues" text
- Added document selection sheet for sharing

### Technical Debt Resolved
- Type conversion: AcquisitionChatFeature.UploadedDocument → base type
- Opacity ambiguity issues resolved
- Memory leaks in observation cycles fixed
- SwiftUI state management optimized

---

## 🚀 Next MVP: Advanced Analytics (Post-95% Certification)

Once current MVP achieves 95%:

### Phase 2 Features
1. **User Analytics Dashboard**
   - Acquisition success rates
   - Time-to-contract metrics
   - Cost savings analysis

2. **SAM.gov Insights**
   - Trend analysis
   - Predictive alerts
   - Competitor tracking

3. **AI-Powered Recommendations**
   - Contract optimization
   - Vendor suggestions
   - Risk assessments

### Production Criteria (Same 95% Standard)
- All analytics real-time
- Privacy-compliant data handling
- Export capabilities
- Offline analytics storage

---

## 🔧 Development Guidelines

### Code Quality Standards
```swift
// ALWAYS follow these patterns:

// 1. Dependency Injection
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    
    init(dependency: Dependency) {
        _viewModel = StateObject(wrappedValue: MyViewModel(dependency: dependency))
    }
}

// 2. Error Handling
do {
    try await performOperation()
} catch {
    // Log to Crashlytics
    // Present user-friendly error
    // Attempt recovery if possible
}

// 3. Performance Monitoring
let startTime = CFAbsoluteTimeGetCurrent()
// ... operation ...
let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
Analytics.log("operation_time", timeElapsed)
```

### Testing Requirements
- Unit tests for all business logic
- UI tests for critical user paths
- Performance tests for all network calls
- Accessibility tests for all screens

---

## 📝 Context Management Protocol

### When Context Window < 5%
1. **IMMEDIATELY save to Memory MCP**:
   ```javascript
   {
     "project": "AIKO",
     "currentTask": "[active task]",
     "completedSteps": ["step1", "step2"],
     "pendingWork": ["step3", "step4"],
     "criticalDecisions": {},
     "productionScore": 92,
     "blockers": ["security audit", "test coverage"]
   }
   ```

2. **Document any in-progress work**
3. **Save file paths being edited**
4. **Note any unresolved errors**

### Session Continuation
When resuming after context reset:
1. Load memory state
2. Check production dashboard
3. Review blockers
4. Continue from last checkpoint

---

## 🎯 Remember

**Production-Ready Mindset**:
- "It works" ❌ → "It's production-ready" ✅
- "We'll fix it later" ❌ → "Fix it before shipping" ✅
- "Good enough" ❌ → "95% excellence required" ✅

**Every commit must**:
- Maintain or improve the production score
- Include appropriate tests
- Pass all quality gates
- Move us closer to 95% certification

---

*This project-level CLAUDE.md works in harmony with the global CLAUDE.md to ensure consistent, high-quality development practices while maintaining project-specific requirements and standards.*