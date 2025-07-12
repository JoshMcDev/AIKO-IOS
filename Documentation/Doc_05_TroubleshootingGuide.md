# AIKO Troubleshooting Guide

## Common Issues and Solutions

### Build Errors

#### Duplicate Symbol Errors
**Problem**: "Ambiguous for type lookup in this context"
**Solution**: 
1. Check for duplicate struct/class definitions
2. Rename conflicting types with specific prefixes
3. Use module namespacing if needed

#### Swift Package Resolution Failed
**Problem**: Package dependencies not resolving
**Solution**:
1. Clean build folder: `cmd+shift+K`
2. Reset package caches: `File > Packages > Reset Package Caches`
3. Delete `.build` and `.swiftpm` folders
4. Re-open Package.swift

### Runtime Issues

#### Biometric Authentication Fails
**Problem**: Face ID/Touch ID not working
**Solution**:
1. Check Info.plist for `NSFaceIDUsageDescription`
2. Verify simulator has Face ID enrolled
3. Reset biometric settings in device
4. Check LAContext error codes

#### Document Generation Hangs
**Problem**: AI generation times out
**Solution**:
1. Check network connectivity
2. Verify API key is valid
3. Reduce document complexity
4. Implement retry logic with exponential backoff

#### Core Data Migration Errors
**Problem**: App crashes on update
**Solution**:
1. Implement lightweight migration
2. Add versioning to data model
3. Test migration path thoroughly
4. Provide fallback for failed migrations

### API Integration Issues

#### SAM.gov API Returns 401
**Problem**: Unauthorized error
**Solution**:
1. Verify API key is current
2. Check rate limiting
3. Ensure proper header format
4. Contact SAM.gov support if persistent

#### Claude API Context Limit
**Problem**: "Context length exceeded"
**Solution**:
1. Implement text chunking
2. Summarize previous context
3. Use streaming responses
4. Upgrade to higher tier if needed

### Performance Issues

#### Slow Document Parsing
**Problem**: PDF/Word parsing takes too long
**Solution**:
1. Process in background queue
2. Show progress indicators
3. Implement caching for parsed content
4. Optimize OCR settings for speed vs accuracy

#### Memory Warnings
**Problem**: App receives memory pressure
**Solution**:
1. Profile with Instruments
2. Release large objects promptly
3. Use autoreleasepool for loops
4. Implement image downsampling

### Debugging Tools

#### Xcode Debugging
```bash
# Enable verbose logging
defaults write com.aiko.app LogLevel -int 3

# View Core Data SQL
-com.apple.CoreData.SQLDebug 1

# Network debugging
-com.apple.CFNetwork.Diagnostics 3
```

#### Console Commands
```bash
# View app container
xcrun simctl get_app_container booted com.aiko.app

# Export Core Data store
sqlite3 /path/to/store.sqlite ".dump" > backup.sql

# Check provisioning profile
security cms -D -i embedded.mobileprovision
```

### Error Codes Reference

| Code | Description | Solution |
|------|-------------|----------|
| 1001 | Network timeout | Retry with longer timeout |
| 2001 | Invalid document format | Check file type support |
| 3001 | Authentication failed | Re-authenticate user |
| 4001 | Storage full | Clear cache/old documents |
| 5001 | API limit exceeded | Implement rate limiting |

### Support Escalation

1. **Level 1**: Check this guide
2. **Level 2**: Search known issues
3. **Level 3**: Contact development team
4. **Level 4**: File bug report with:
   - Device/OS version
   - Steps to reproduce
   - Error logs
   - Expected vs actual behavior

---

**Document Version**: 1.0  
**Last Updated**: 2025-07-11  
**Support Contact**: support@aiko.app