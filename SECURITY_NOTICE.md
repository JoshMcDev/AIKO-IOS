# URGENT SECURITY NOTICE

## API Key Exposure Incident

**Date**: January 2025
**Severity**: CRITICAL
**Status**: REMEDIATED

### What Happened
The Perplexity API key was accidentally committed to the public GitHub repository in the file `.taskmaster/config.json`.

### Immediate Actions Taken
1. ✅ Removed API key from config.json
2. ✅ Updated .gitignore to prevent future exposure
3. ✅ Created secure configuration templates
4. ⚠️ **YOU MUST**: Revoke the exposed key in your Perplexity account immediately

### Exposed Key (NOW INVALID - MUST BE REVOKED)
```
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
```

### Steps to Complete Security Fix

1. **Revoke the Exposed Key**:
   - Log into Perplexity.ai
   - Go to Settings → API Keys
   - Delete/Revoke the exposed key
   - Generate a new API key

2. **Remove from Git History** (if needed):
   ```bash
   # This will rewrite Git history - use with caution
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch .taskmaster/config.json" \
     --prune-empty --tag-name-filter cat -- --all
   ```

3. **Set Up Environment Variables**:
   ```bash
   # Copy the example file
   cp .env.example .env.local
   
   # Edit .env.local and add your new API key
   # PERPLEXITY_API_KEY=your_new_key_here
   ```

4. **Update Task Master Configuration**:
   - The config.json now references environment variables
   - Ensure your Task Master setup reads from environment

### Prevention Measures
- Never commit API keys to version control
- Always use environment variables for secrets
- Review commits before pushing to public repos
- Use git-secrets or similar tools to prevent accidental commits
- Enable GitHub secret scanning alerts

### Additional Security Recommendations
1. Enable 2FA on all service accounts
2. Rotate all API keys regularly
3. Use least-privilege access principles
4. Monitor API usage for anomalies
5. Consider using a secrets management service

### Contact
If you notice any unauthorized usage of your Perplexity account, contact their support immediately.