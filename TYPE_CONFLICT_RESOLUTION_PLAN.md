# Type Conflict Resolution Plan: AppCore.Acquisition vs AIKO.Acquisition

## Problem Analysis

The codebase has two different `Acquisition` types causing compilation conflicts:

1. **AppCore.Acquisition** (Sources/AppCore/Models/Acquisition.swift)
   - Swift struct
   - Platform-agnostic 
   - Used for business logic and UI layer
   - Conforms to Identifiable, Equatable, Sendable

2. **CoreData Acquisition** (Sources/Models/CoreData/Acquisition+CoreDataClass.swift)
   - NSManagedObject subclass
   - Used for persistence layer
   - Has relationships to other CoreData entities
   - This is the "AIKO.Acquisition" mentioned in error messages

## Root Cause

Files that import both `AppCore` and `CoreData` have ambiguous type resolution for unqualified `Acquisition` references.

## Migration Strategy

### Phase 1: Explicit Type Qualification
- Replace all unqualified `Acquisition` with explicit module prefixes
- Use `AppCore.Acquisition` for business logic
- Use qualified CoreData references for persistence operations

### Phase 2: Consistent Import Strategy  
- Be specific about which types are needed from each module
- Use typealiases where helpful for readability

### Phase 3: Mapping Layer Enhancement
- Ensure robust conversion between the two types
- Standardize on mapping patterns

## Files Requiring Updates

Based on ast-grep analysis, the following files need type qualification:

### High Priority (Direct Conflicts)
1. `Sources/Services/AcquisitionService.swift` - Uses unqualified Acquisition for CoreData operations
2. `Sources/Services/DocumentChainManager.swift` - NSFetchRequest<Acquisition> ambiguity
3. `Sources/Infrastructure/Repositories/AcquisitionRepository.swift` - Multiple unqualified usages
4. `Sources/Views/AcquisitionsListView.swift` - UI layer using unqualified Acquisition.Status
5. `Sources/AppCore/Dependencies/AcquisitionClient.swift` - Interface using unqualified Acquisition.Status

### Medium Priority (Potential Conflicts)
6. `Sources/Services/GovernmentFormService.swift` - NSFetchRequest usage
7. `Sources/Infrastructure/Repositories/DocumentRepository.swift` - Acquisition.fetchRequest() calls
8. `Tests/Unit/Services/Unit_DocumentChainMetadataTests.swift` - Test using unqualified type

## Implementation Plan

### Step 1: Update Mapping File
Enhance `Sources/Infrastructure/Extensions/Acquisition+Mapping.swift` with clear typealiases.

### Step 2: Fix Service Layer
Update `AcquisitionService.swift` to use qualified types.

### Step 3: Fix Repository Layer  
Update `AcquisitionRepository.swift` and `DocumentRepository.swift`.

### Step 4: Fix UI Layer
Update views to use appropriate types.

### Step 5: Fix Tests
Update test files to use qualified types.

### Step 6: Verification
Ensure all compilation errors are resolved.

## Type Usage Guidelines

**Use AppCore.Acquisition when:**
- Passing data between layers
- In UI/View layer
- In business logic
- For API responses
- In feature modules

**Use CoreData Acquisition when:**
- Performing Core Data operations
- In repository implementations  
- When working with NSManagedObjectContext
- For persistence-specific operations

## Expected Benefits

1. **Eliminates compilation ambiguity** - No more type resolution conflicts
2. **Clearer separation of concerns** - Business logic vs persistence
3. **Better maintainability** - Explicit type usage is self-documenting
4. **Consistent patterns** - Standardized approach across codebase