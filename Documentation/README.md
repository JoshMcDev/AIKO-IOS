2# AIKO - AI Contract Intelligence Officer

A powerful iOS application for generating federal contract documents using AI with intelligent requirement analysis and multi-format input support.

## 📚 Table of Contents

- [Quick Start Guide](#quick-start-guide)
- [Features](#features)
- [Installation Guide](#installation-guide)
- [User Guide](#user-guide)
- [Architecture](#architecture)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Contributing](#contributing)

## Features

### 🤖 **Intelligent Requirement Analysis**
- **Multi-Format Input**: Text input, PDF/DOCX upload, or photo capture of requirements
- **LLM-Powered Analysis**: Advanced AI analysis with completeness scoring (1-10 scale)
- **Smart Completeness Detection**: Document modules turn green when ≥5 completeness score achieved
- **Interactive Guidance**: AI prompts for missing information and recommends next steps
- **Minimal Information Requirement**: Only asks for essential details needed for generation

### 📄 **Document Processing & Parsing**
- **PDF Parser**: Extract text from uploaded PDF documents
- **DOCX Support**: Handle Microsoft Word documents and text files
- **OCR Capability**: Process images and photos using Vision framework
- **Federal Acquisitions Regulation (FAR) Compliance**: Built-in compliance checking and recommendations

### 📋 **AI-Powered Document Generation**
- **Professional Contract Documents**: SOW, PWS, QASP, Contract Scaffold, and IGCE
- **Auto-Generation Option**: AI automatically generates all recommended documents
- **Manual Selection**: Choose specific documents to generate
- **FAR-Compliant Output**: All documents meet federal contracting standards

### 📤 **Export & Delivery Options**
- **PDF Export**: Professional PDF generation with proper formatting
- **DOCX Export**: Microsoft Word-compatible document export  
- **Email Delivery**: Send documents directly to email with confirmation
- **Profile Integration**: Uses default profile email or custom address
- **Batch Processing**: Generate and deliver multiple documents simultaneously

### 🎯 **Smart Visual Indicators**
- **Green Status Indicators**: Document types turn green when ready to generate
- **Status System**: Ready/Needs More Info/Not Ready visual feedback
- **Interactive Selection**: Easy document type selection interface

### 🔒 **Security & Management**
- **Subscription Tiers**: Free, Trial, Basic ($9.99/mo), and Pro ($29.99/mo) plans
- **Secure API Management**: Keychain-based API key storage with environment variable support
- **Cross-Platform**: Built with SwiftUI for iOS 16.0+ and macOS 13.0+
- **The Composable Architecture**: Modern, testable architecture with TCA

### 📖 **In-App Resources**
- **User Guide**: Comprehensive guide accessible from the menu (☰ → User Guide)
- **Quick References**: Access to Acquisition.gov, SAM.gov, and FPDS-NG
- **Search Templates**: Browse and search document templates
- **My Acquisitions**: View and manage your acquisition history

## Architecture

This project uses:
- **Swift Package Manager** for dependency management
- **The Composable Architecture (TCA)** for state management and reactive programming
- **OpenAI Swift SDK** for LLM integration and requirement analysis
- **PDFKit** for PDF parsing and generation
- **Vision Framework** for OCR and image text recognition
- **MessageUI** for email delivery functionality
- **StoreKit** for subscription management
- **SwiftUI** for cross-platform UI

## Project Structure

```
Sources/
├── Models/
│   └── DocumentType.swift          # Contract document type definitions
├── Core/Configuration/
│   └── APIConfiguration.swift      # API configuration and key management
├── Services/
│   ├── AIDocumentGenerator.swift   # Document generation service
│   ├── RequirementAnalyzer.swift   # LLM-powered requirement analysis
│   ├── DocumentParser.swift        # PDF/DOCX/Image parsing service
│   ├── DocumentDeliveryService.swift # Export and email delivery
│   └── FARCompliance.swift         # Federal Acquisition Regulation compliance
├── Features/
│   ├── App/                        # Main app feature and coordination
│   │   └── AppFeature.swift
│   ├── DocumentGeneration/         # Core document generation workflow
│   │   └── DocumentGenerationFeature.swift
│   └── Subscription/               # Subscription management
│       └── SubscriptionFeature.swift
└── UI/
    ├── Theme.swift                 # Design system and styling
    ├── AppView.swift               # Main application UI
    └── DialogViews.swift           # Modal dialogs and interactions
```

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 16.0 or later / macOS 13.0 or later
- OpenAI API key (for LLM-powered requirement analysis)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd AIKO-iOS
   ```

2. Set up your OpenAI API key:
   ```bash
   export OPENAI_API_KEY="your-api-key-here"
   ```

3. Build the project:
   ```bash
   make build
   # or
   swift build
   ```

4. Open in Xcode to run on iOS device/simulator:
   ```bash
   open AIKO.xcodeproj
   ```

### Configuration

The app supports configuration through environment variables:

- `OPENAI_API_KEY`: Your OpenAI API key
- `OPENAI_BASE_URL`: Custom OpenAI API base URL (optional)
- `ENVIRONMENT`: Set to "production" for production builds

API keys are securely stored in the iOS Keychain after first use.

## User Workflow

### 1. **Requirement Input** 
- Enter requirements via text box
- Upload PDF/DOCX documents 
- Capture photos of requirement documents
- Multiple input methods can be combined

### 2. **AI Analysis**
- LLM analyzes uploaded content for completeness
- Scores requirements on 1-10 scale
- Identifies missing information gaps
- Provides interactive guidance for improvements

### 3. **Document Readiness**
- Document modules turn **green** when completeness ≥5 score
- Visual indicators show Ready/Needs More Info/Not Ready status
- FAR compliance recommendations provided

### 4. **Generation Options**
- **Auto-Generate**: AI selects and generates all recommended documents
- **Manual Selection**: Choose specific document types to generate
- Real-time preview of selected documents

### 5. **Delivery & Export**
- **Download**: PDF and DOCX files saved to device
- **Email**: Professional delivery with formatted email template
- **Format Options**: Both PDF and DOCX generated simultaneously

## Document Types

### Free Tier
- **Statement of Work (SOW)**: Detailed scope, deliverables, and timeline
- **Performance Work Statement (PWS)**: Performance-based requirements and metrics

### Pro Features  
- **Quality Assurance Surveillance Plan (QASP)**: Quality monitoring and standards
- **Contract Scaffold**: Complete acquisition strategy framework
- **Independent Government Cost Estimate (IGCE)**: Detailed cost breakdown and analysis

## Subscription Tiers

- **Free**: 2 documents/month, basic document types
- **Trial**: 7-day full access trial
- **Basic ($9.99/mo)**: 50 documents/month, all document types
- **Pro ($29.99/mo)**: Unlimited documents, advanced features, API access

## Development

### Building
```bash
make build
```

### Testing
Tests require Xcode for iOS platform testing:
```bash
xcodebuild test -scheme AIKO
```

### Cleaning
```bash
make clean
```

## Technical Highlights

### **AI-Powered Analysis Engine**
- OpenAI GPT-4 integration for requirement analysis
- Intelligent completeness scoring algorithm
- Context-aware missing information detection
- FAR compliance validation and recommendations

### **Multi-Format Document Processing**
- PDF text extraction using PDFKit
- DOCX and text file parsing
- Vision framework OCR for image/photo processing
- Unified parsing interface across all formats

### **Professional Document Generation**
- Template-based PDF generation with proper formatting
- RTF/DOCX export with Microsoft Word compatibility
- Batch processing for multiple document types
- Professional styling and layout

### **Advanced User Experience**
- Real-time visual status indicators
- Interactive confirmation dialogs
- Progressive disclosure of complexity
- Comprehensive error handling and recovery

## Security

- API keys stored securely in iOS Keychain
- No hardcoded secrets in source code  
- Environment-based configuration for production
- FAR-compliant document generation with audit trails
- Secure document processing and temporary file handling

## License

[License information here]

## Quick Start Guide

### 🚀 First Time Setup (5 minutes)

1. **Download AIKO** from the App Store
2. **Launch the app** and create your profile
3. **Add your API key** (Settings → API Configuration)
4. **Start your first acquisition**:
   - Tap "New Acquisition"
   - Enter a brief description of what you need
   - Let AIKO analyze and suggest documents
   - Generate your first document package

### 💡 Pro Tips for Beginners

- **Start simple**: Enter basic requirements first, AIKO will ask for details
- **Use templates**: Browse pre-built templates for common acquisitions
- **Trust the AI**: Let AIKO guide you through the process
- **Save frequently**: Your work auto-saves, but manual saves ensure nothing is lost

## User Guide

### 📱 Getting Started with AIKO

#### Step 1: Setting Up Your Profile

1. **Open AIKO** and tap "Create Profile"
2. **Enter your information**:
   - Name and title
   - Organization/agency
   - Default email for document delivery
   - Contracting level (optional)
3. **Save your profile** - you can update it anytime

#### Step 2: Creating Your First Acquisition

1. **Tap "New Acquisition"** from the home screen
2. **Choose your input method**:
   - **Text Input**: Type or paste requirements
   - **Upload Document**: Import PDF/DOCX files
   - **Capture Photo**: Take a picture of printed requirements
3. **Enter basic information**:
   - Acquisition title
   - Estimated value (if known)
   - Type of requirement (supplies, services, construction)

#### Step 3: Understanding AIKO's Analysis

AIKO uses a **Completeness Score** (1-10) to guide you:

- **Score 1-4 (Red)**: Missing critical information
- **Score 5-7 (Yellow)**: Basic information present, more details helpful
- **Score 8-10 (Green)**: Ready to generate high-quality documents

**Interactive Guidance**:
- AIKO asks targeted questions to improve completeness
- Suggests missing elements based on requirement type
- Provides examples of well-written requirements

#### Step 4: Generating Documents

**Auto-Generation Mode** (Recommended for beginners):
1. Click "Auto-Generate Recommended Documents"
2. AIKO selects appropriate documents based on your requirements
3. Review the list and remove any you don't need
4. Click "Generate All"

**Manual Selection Mode**:
1. Review the document list
2. Green indicators show which documents are ready
3. Select the documents you need
4. Click "Generate Selected"

#### Step 5: Reviewing and Exporting

1. **Preview each document** in the app
2. **Make edits** if needed (tap the edit icon)
3. **Run compliance check** to ensure FAR compliance
4. **Export options**:
   - **Download**: Save PDF and DOCX to your device
   - **Email**: Send to yourself or team members
   - **Share**: Use iOS share sheet for other apps

### 🎯 Common Use Cases

#### Use Case 1: Simple Purchase Request

**Scenario**: You need to buy 50 laptops for your office

1. Create new acquisition
2. Enter: "Purchase 50 Dell Latitude laptops with 16GB RAM, 512GB SSD"
3. AIKO suggests: RFQ (Request for Quote)
4. Generate and you're done!

#### Use Case 2: Complex Service Contract

**Scenario**: IT support services for 3 years

1. Create new acquisition
2. Upload existing requirements document
3. AIKO analyzes and scores completeness
4. Suggests: SOW, QASP, IGCE, Evaluation Criteria
5. Answer AIKO's questions about SLAs, staffing, etc.
6. Generate complete package

#### Use Case 3: Sole Source Justification

**Scenario**: Only one vendor can provide specialized equipment

1. Create new acquisition  
2. Describe the requirement and why it's unique
3. AIKO recognizes sole source need
4. Generates: J&A, Market Research, Determination & Findings
5. Includes all required FAR citations

### 📋 Document Types Explained

#### Basic Documents (Free Tier)

**Statement of Work (SOW)**
- **When to use**: Detailed requirements for any acquisition
- **What it includes**: Scope, tasks, deliverables, timeline
- **Tips**: Be specific about deliverables and deadlines

**Performance Work Statement (PWS)**  
- **When to use**: When outcomes matter more than methods
- **What it includes**: Performance standards, metrics, SLAs
- **Tips**: Focus on "what" not "how"

#### Advanced Documents (Pro Tier)

**Quality Assurance Surveillance Plan (QASP)**
- **When to use**: With every PWS or complex SOW
- **What it includes**: Inspection methods, performance standards
- **Tips**: Align metrics with PWS requirements

**Contract Scaffold**
- **When to use**: Planning complex acquisitions
- **What it includes**: Complete acquisition framework
- **Tips**: Use for acquisitions over $1M

**Independent Government Cost Estimate (IGCE)**
- **When to use**: All acquisitions requiring cost analysis
- **What it includes**: Detailed cost breakdown, assumptions
- **Tips**: Update with current market data

### 🛠️ Advanced Features

#### Requirement Analysis Deep Dive

**Understanding Completeness Scoring**:

The AI evaluates requirements across multiple dimensions:

1. **Clarity** (20%): How clear and unambiguous are the requirements?
2. **Specificity** (20%): Are quantities, specifications, and standards defined?
3. **Completeness** (20%): Are all necessary elements present?
4. **Feasibility** (20%): Can the requirements be reasonably fulfilled?
5. **Compliance** (20%): Do requirements align with federal regulations?

**Improving Your Score**:

- **Add quantities**: Instead of "computers", specify "25 desktop computers"
- **Include standards**: Reference specific models, brands, or specifications
- **Set timelines**: Add delivery dates, period of performance
- **Define locations**: Specify delivery or performance locations
- **Include constraints**: Budget limitations, security requirements

#### Using Document Templates

AIKO includes templates for common acquisitions:

1. **IT Hardware**: Computers, servers, network equipment
2. **Professional Services**: Consulting, analysis, studies
3. **Maintenance**: Equipment service, facility maintenance  
4. **Construction**: Minor construction, repairs
5. **R&D**: Research projects, prototypes

**To use a template**:
1. Select "Browse Templates" when creating acquisition
2. Choose the closest match
3. Customize the pre-filled requirements
4. Generate documents

#### Batch Processing

**For multiple similar acquisitions**:

1. Create your first acquisition completely
2. Select "Duplicate as Template"
3. Create new acquisitions from template
4. Modify only the changing elements
5. Batch generate all documents

### 💼 For Different User Roles

#### Contracting Officers

- Use **Compliance Check** before every document export
- Enable **FAR Clause Validation** in settings
- Set up **approval workflows** for team review
- Use **audit trail** features for documentation

#### Program Managers

- Focus on **requirements clarity** for better documents
- Use **QASP generator** for performance management
- Export **IGCE** for budget planning
- Share drafts with technical team for review

#### Small Business Owners

- Start with **Free Tier** for basic documents
- Use **templates** to save time
- Focus on **SOW/PWS** for clear requirements
- Upgrade to Pro for unlimited documents

## Installation Guide

### 📱 iOS App Installation

#### From App Store (Recommended)

1. **Open App Store** on your iOS device
2. **Search** for "AIKO Federal"
3. **Tap "Get"** to download
4. **Open** the app once installed

#### Requirements

- **iOS Version**: 16.0 or later
- **Device**: iPhone, iPad, or Mac with Apple Silicon
- **Storage**: 100MB free space
- **Network**: Internet connection required

### 🔧 Development Setup

#### Prerequisites

- **Xcode**: Version 15.0 or later
- **macOS**: Ventura 13.0 or later
- **Swift**: 5.9 or later
- **Git**: For cloning repository

#### Installation Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-org/AIKO-IOS.git
   cd AIKO-IOS
   ```

2. **Install dependencies**:
   ```bash
   # Using Swift Package Manager (automatic in Xcode)
   open Package.swift
   ```

3. **Configure environment**:
   ```bash
   # Create .env file
   cp .env.example .env
   
   # Add your OpenAI API key
   echo "OPENAI_API_KEY=your-key-here" >> .env
   ```

4. **Build the project**:
   ```bash
   # Command line
   make build
   
   # Or in Xcode
   # Select scheme and build (⌘+B)
   ```

5. **Run the app**:
   ```bash
   # Select target device in Xcode
   # Press Run (⌘+R)
   ```

### 🔑 API Configuration

#### Setting Up OpenAI API

1. **Get an API key** from [OpenAI Platform](https://platform.openai.com)
2. **In AIKO app**:
   - Go to Settings → API Configuration
   - Tap "Add API Key"
   - Paste your key
   - Tap "Verify"

#### Security Best Practices

- **Never share** your API key
- **Use environment variables** for development
- **Rotate keys** regularly
- **Set usage limits** in OpenAI dashboard

## API Reference

### 🔌 Core Services

#### AIDocumentGenerator

**Purpose**: Generates federal acquisition documents using AI

```swift
class AIDocumentGenerator {
    func generateDocument(
        type: DocumentType,
        requirements: String,
        context: AcquisitionContext
    ) async throws -> GeneratedDocument
}
```

**Parameters**:
- `type`: The document type to generate (SOW, PWS, etc.)
- `requirements`: User-provided requirements text
- `context`: Additional context (value, timeline, etc.)

**Returns**: `GeneratedDocument` with content and metadata

#### RequirementAnalyzer

**Purpose**: Analyzes requirement completeness and quality

```swift
class RequirementAnalyzer {
    func analyzeRequirements(
        _ text: String,
        documentType: DocumentType?
    ) async throws -> RequirementAnalysis
}
```

**Returns**: Analysis with score (1-10) and improvement suggestions

### 📊 Data Models

#### DocumentType

```swift
enum DocumentType: String, CaseIterable {
    case sow = "Statement of Work"
    case pws = "Performance Work Statement"
    case qasp = "Quality Assurance Surveillance Plan"
    case igce = "Independent Government Cost Estimate"
    // ... more types
}
```

#### AcquisitionContext

```swift
struct AcquisitionContext {
    let title: String
    let estimatedValue: Double?
    let naicsCode: String?
    let setAsideType: SetAsideType?
    let urgency: UrgencyLevel
}
```

### 🔄 Workflow States

```swift
enum WorkflowState {
    case draft
    case analyzing
    case readyToGenerate
    case generating
    case review
    case complete
}
```

## Troubleshooting

### Common Issues and Solutions

#### "Cannot connect to AI service"

**Symptoms**: Error when generating documents

**Solutions**:
1. Check internet connection
2. Verify API key in Settings
3. Ensure API key has credits
4. Try again in 30 seconds (rate limit)

#### "Document generation failed"

**Symptoms**: Error after starting generation

**Solutions**:
1. Simplify complex requirements
2. Break into smaller sections
3. Check for special characters
4. Update to latest app version

#### "Completeness score not updating"

**Symptoms**: Score stays red despite adding information

**Solutions**:
1. Be more specific (quantities, dates)
2. Add missing sections AIKO suggests
3. Use complete sentences
4. Include acceptance criteria

#### "Export not working"

**Symptoms**: Cannot download or email documents

**Solutions**:
1. Check device storage space
2. Verify email settings
3. Try different export format
4. Grant necessary permissions

### 🔍 Advanced Troubleshooting

#### Debug Mode

Enable debug mode for detailed logs:
1. Go to Settings → Advanced
2. Toggle "Debug Mode"
3. Reproduce issue
4. Share logs with support

#### Cache Issues

Clear app cache:
1. Settings → Storage
2. Tap "Clear Cache"
3. Restart app

#### Sync Problems

Force sync with cloud:
1. Settings → Account
2. Pull down to refresh
3. Check sync status

### 📞 Getting Help

#### In-App Support

- Tap the **☰** menu icon and select **User Guide** for comprehensive help
- Use the **?** icon for contextual help
- Use **Report Issue** for bug reports
- Check **FAQ** for common questions
- Access the User Guide anytime from Settings → User Guide

#### Contact Support

- **Email**: support@aiko-federal.com
- **Response time**: Within 24 hours
- **Include**: Screenshot, device info, steps to reproduce

## Performance Optimization

### 💨 Speed Tips

#### Faster Document Generation

1. **Pre-process requirements**: Clean formatting before input
2. **Use templates**: Start from existing templates
3. **Batch operations**: Generate multiple documents together
4. **Optimal length**: 500-2000 words for requirements

#### Reducing API Costs

1. **Draft locally**: Write complete requirements before analyzing
2. **Reuse analyses**: Save good requirements as templates
3. **Selective generation**: Only generate needed documents
4. **Use caching**: Enable smart caching in settings

### 📱 Device Optimization

#### Storage Management

- **Auto-cleanup**: Enable in Settings → Storage
- **Export regularly**: Don't store all documents locally
- **Cloud sync**: Use iCloud for backup

#### Battery Life

- **Reduce animations**: Settings → Accessibility
- **Offline mode**: When not generating documents
- **Background refresh**: Disable if not needed

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### How to Contribute

1. **Report bugs**: Use GitHub issues
2. **Suggest features**: Discussion forum
3. **Submit pull requests**: Follow coding standards
4. **Improve documentation**: Edit wiki
5. **Share templates**: Submit to template library
