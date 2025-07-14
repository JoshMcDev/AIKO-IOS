# TestFlight Setup for AIKO

## Manual TestFlight Configuration

Since the MCP server installation has permission issues, here's how to set up TestFlight for AIKO:

### 1. App Store Connect Setup

1. **Create App ID**:
   - Go to developer.apple.com
   - Certificates, Identifiers & Profiles → Identifiers
   - Create new App ID for "com.aiko.acquisitionassistant"

2. **Generate API Key for Automation**:
   - App Store Connect → Users and Access → Keys
   - Generate new API key with "App Manager" role
   - Download the .p8 file (save securely)
   - Note the Key ID and Issuer ID

### 2. Xcode Configuration

```bash
# In Xcode:
1. Select AIKO target
2. Signing & Capabilities:
   - Team: Your Developer Team
   - Bundle ID: com.aiko.acquisitionassistant
   - Enable "Automatically manage signing"
```

### 3. TestFlight Build Upload

**Using Xcode (Manual)**:
1. Product → Archive
2. Distribute App → App Store Connect → Upload
3. Wait for processing (~30 minutes)

**Using Fastlane (Automated)**:
```bash
# Install Fastlane
gem install fastlane

# Initialize in project
cd /Users/J/aiko
fastlane init

# Create Fastfile for TestFlight
```

### 4. Fastlane Configuration

Create `/Users/J/aiko/fastlane/Fastfile`:
```ruby
default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    increment_build_number(xcodeproj: "AIKO.xcodeproj")
    build_app(scheme: "AIKO")
    upload_to_testflight
  end
end
```

### 5. Environment Variables for API Access

Add to `.env.local`:
```bash
APP_STORE_CONNECT_API_KEY_ID=your_key_id
APP_STORE_CONNECT_API_KEY_ISSUER_ID=your_issuer_id
APP_STORE_CONNECT_API_KEY_P8_PATH=/path/to/your/key.p8
```

### 6. TestFlight Beta Testing Groups

1. **Internal Testing** (up to 100 testers):
   - Immediate availability
   - No review required
   - Add team members

2. **External Testing** (up to 10,000 testers):
   - Requires beta app review
   - Create groups:
     - "Government Contractors" - Primary users
     - "Early Access" - Power users
     - "General Beta" - Wider testing

### 7. Beta Test Information

Prepare for TestFlight:
- **What to Test**: Document generation, FAR compliance, offline mode
- **App Description**: "AIKO helps government contracting officers streamline acquisition workflows"
- **Beta Notes**: Include known issues and focus areas

### 8. Automated Distribution Script

Create `/Users/J/aiko/scripts/deploy_beta.sh`:
```bash
#!/bin/bash

# Increment build number
agvtool next-version -all

# Build and upload
fastlane beta

# Notify testers
echo "Beta build uploaded to TestFlight"
```

### 9. TestFlight API Integration (Future)

For programmatic access:
```swift
// Future integration with App Store Connect API
import AppStoreConnect_Swift_SDK

let client = APIClient(
    configuration: APIConfiguration(
        issuerID: "your-issuer-id",
        privateKeyID: "your-key-id",
        privateKey: "your-p8-content"
    )
)
```

### 10. Beta Testing Timeline

**Week 1-2**: Internal testing with team
**Week 3-4**: Closed beta (50 users)
**Week 5-6**: Expanded beta (200 users)
**Week 7-8**: Open beta (500+ users)
**Week 9-10**: Final beta validation
**Week 11-12**: Production candidate
**Week 13-14**: App Store submission

This manual setup will work until we can resolve the MCP server installation permissions issue.