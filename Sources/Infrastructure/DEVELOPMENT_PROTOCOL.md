# Development Protocol - AIKO Project

## 🚨 MANDATORY: Quality-First Development

### Core Principles

1. **Zero Technical Debt Policy**
   - NEVER proceed with errors
   - NEVER ignore warnings
   - ALWAYS fix issues immediately

2. **Build-Test-Resolve Cycle**
   ```bash
   # After EVERY subtask/task/phase:
   swift build                    # 1. Build
   swift test                     # 2. Test (when applicable)
   # 3. Resolve ALL issues before proceeding
   ```

3. **ULTRATHINK Requirements**
   - ✅ All subtask executions
   - ✅ All task implementations
   - ✅ All phase transitions
   - ✅ All error resolutions
   - ✅ All warning fixes

### Workflow Example

```swift
// WRONG ❌
implement_feature_a()
implement_feature_b()  // Don't proceed without building!
implement_feature_c()
swift build           // Too late!

// CORRECT ✅
implement_feature_a()
swift build          // Build immediately
fix_all_issues()     // Fix ALL issues
implement_feature_b()
swift build          // Build again
fix_all_issues()     // Maintain zero debt
```

### Exception: Nested Dependencies

Only skip intermediate builds when:
1. Subtasks are tightly coupled
2. Final task completion is required for compilation
3. ULTRATHINK confirms this exception applies
4. Document why build was deferred

Example:
```swift
// Creating protocol + implementation together
create_protocol()      // Won't compile alone
create_implementation() // Needs protocol
swift build            // Build after both
```

### Documentation Requirements

After significant changes:
- Update `MIGRATION_GUIDE.md`
- Update `DEVELOPMENT_PROTOCOL.md`
- Update `CLAUDE.md` if patterns change
- Add inline comments for complex logic

### Current Build Status

```bash
# Last verified: 2025-01-12
✅ Build: Success
✅ Warnings: 0
✅ Errors: 0
✅ Technical Debt: 0
```

### Checklist Before Moving Forward

- [ ] `swift build` runs without errors
- [ ] All warnings resolved
- [ ] Tests pass (if applicable)
- [ ] Documentation updated
- [ ] ULTRATHINK applied to next steps
- [ ] Todo list updated

---

**Remember**: Quality compounds. Every clean build makes the next feature easier to implement.