# AIKO GraphRAG Implementation Guide
## Complete Beginner's Guide to On-Device Regulation Intelligence

**Author**: AI Development Team  
**Date**: July 22, 2025  
**Target Audience**: Complete beginners to GraphRAG, embeddings, and vector databases  
**Implementation Complexity**: Advanced (but we'll break it down step-by-step)  

---

## 🎯 What Are We Building?

Imagine asking your iPhone: *"What are the procurement regulations for software contracts over $500K?"* and getting an instant, accurate answer with exact citations—**completely offline**. That's GraphRAG (Graph-Retrieval Augmented Generation).

### The Magic Behind It
- **Your Question** → Converted to mathematical vectors → **Instant Search** through 1000+ regulations → **Perfect Matches** → Fed to your LLM for intelligent response
- **All on your device** - No internet needed after setup
- **Sub-second responses** with perfect citations
- **Always current** through auto-updates

---

## 🏗️ Architecture Overview (For Beginners)

### Think of It Like This:
1. **Library** (ObjectBox Vector Database) = Where we store all regulations
2. **Librarian** (LFM2 Model) = Understands what you're asking and finds relevant documents  
3. **Research Assistant** (Your LLM) = Reads the relevant documents and gives you a perfect answer
4. **Auto-Updater** (RegulationUpdateService) = Keeps the library current automatically

### The Complete Data Flow:
```
📄 HTML Regulations 
    ↓ (regulationParser.ts)
📝 Clean Text Chunks 
    ↓ (LFM2-700M Model)
🔢 Vector Embeddings 
    ↓ (ObjectBox Database)
💾 Searchable Vector Database
    ↓ (User Query)
🔍 Semantic Search Results
    ↓ (Your LLM API)
✨ Intelligent Response with Citations
```

---

## 📚 Essential Concepts for Beginners

### What is an "Embedding"?
Think of embeddings as **GPS coordinates for meaning**. Just like GPS converts your address to numbers (latitude/longitude), embeddings convert text to numbers that represent meaning.

**Example:**
- "software procurement" and "buying computer programs" have similar embeddings
- "software procurement" and "banana recipes" have very different embeddings

### What is "Vector Search"?
Instead of searching for exact words (like Google), vector search finds **similar meanings**:
- **Keyword Search**: "software contract" only finds documents with those exact words
- **Vector Search**: "software contract" finds "software agreements", "IT procurement", "application licensing", etc.

### Why On-Device?
- **Privacy**: Your queries never leave your device
- **Speed**: No internet delays  
- **Reliability**: Works anywhere, even offline
- **Cost**: No API calls for every search

---

## 🛠️ Implementation Plan (12 Major Steps)

### Phase 1: Foundation Setup (Days 1-3)
**Goal**: Get the basic components working

#### Step 1: Download and Prepare LFM2 Model
**What**: Get the AI model that will convert text to embeddings
**File**: LFM2-700M-GGUF Q6_K (612MB - optimal size for iOS)
**Location**: `https://huggingface.co/LiquidAI/LFM2-700M-GGUF`

```bash
# Download the model (do this on your development machine)
git lfs install
git clone https://huggingface.co/LiquidAI/LFM2-700M-GGUF
```

**Expected Outcome**: 612MB model file ready for conversion

#### Step 2: Convert Model to Core ML
**What**: Convert the model to Apple's format for iOS
**Tools Needed**: Python, coremltools, transformers

```bash
# Install required tools
pip install coremltools transformers torch

# Convert GGUF to Core ML (this might take 30-60 minutes)
python convert_lfm2_to_coreml.py --input LFM2-700M-GGUF --output LFM2-700M-Q6K.mlmodel
```

**Expected Outcome**: LFM2-700M-Q6K.mlmodel file (~612MB) ready for iOS

#### Step 3: Add Model to iOS Project
**What**: Embed the model in your app bundle
**Location**: Copy to `Sources/Resources/LFM2-700M-Q6K.mlmodel`

**Expected Outcome**: Model is part of your app, loads automatically

### Phase 2: Vector Database Setup (Days 4-5)

#### Step 4: Install ObjectBox
**What**: Add the vector database to your project
**Tool**: Swift Package Manager

```swift
// In Xcode: File → Add Package Dependencies
// URL: https://github.com/objectbox/objectbox-swift

// Add to your Package.swift dependencies:
.package(url: "https://github.com/objectbox/objectbox-swift", from: "2.0.0")
```

#### Step 5: Design Vector Schema
**What**: Define how we'll store regulation embeddings
**File**: `Sources/Models/RegulationEmbedding.swift`

```swift
import ObjectBox

@Entity
public class RegulationEmbedding {
    @Id public var id: Id = 0
    
    // The regulation content and metadata
    public var regulationNumber: String = ""
    public var sectionTitle: String = ""
    public var content: String = ""
    public var htmlPath: String = ""
    
    // Vector data (768 dimensions for LFM2)
    public var embedding: [Float] = []
    
    // Update tracking
    public var lastUpdated: Date = Date()
    public var source: String = "official" // "official" or "personal"
    public var contentHash: String = ""
    
    public init() {}
}
```

### Phase 3: Core Processing Engine (Days 6-8)

#### Step 6: Create LFM2 Service
**What**: Swift wrapper to use the LFM2 model
**File**: `Sources/Services/LFM2Service.swift`

```swift
import CoreML

actor LFM2Service {
    private var model: MLModel?
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        guard let modelURL = Bundle.main.url(forResource: "LFM2-700M-Q6K", 
                                           withExtension: "mlmodel") else {
            print("❌ Model not found in bundle")
            return
        }
        
        do {
            self.model = try MLModel(contentsOf: modelURL)
            print("✅ LFM2 model loaded successfully")
        } catch {
            print("❌ Failed to load model: \(error)")
        }
    }
    
    // Convert text to embedding (vector)
    func generateEmbedding(text: String) async throws -> [Float] {
        guard let model = model else {
            throw LFM2Error.modelNotLoaded
        }
        
        // Prepare input (implementation depends on model requirements)
        let input = try prepareInput(text: text)
        
        // Get prediction
        let output = try model.prediction(from: input)
        
        // Extract embedding from output
        return try extractEmbedding(from: output)
    }
}
```

#### Step 7: Build Regulation Processing Pipeline
**What**: Convert HTML regulations to searchable embeddings
**File**: `Sources/Services/RegulationProcessor.swift`

```swift
import Foundation

actor RegulationProcessor {
    private let lfm2Service = LFM2Service()
    private let vectorDB = VectorDatabase()
    
    // Process a single regulation file
    func processRegulation(htmlPath: String) async throws {
        print("📄 Processing: \(htmlPath)")
        
        // 1. Parse HTML to extract text
        let content = try parseHTML(at: htmlPath)
        
        // 2. Split into optimal chunks (512 tokens max)
        let chunks = chunkText(content, maxTokens: 512)
        
        // 3. Generate embeddings for each chunk
        for (index, chunk) in chunks.enumerated() {
            let embedding = try await lfm2Service.generateEmbedding(text: chunk.text)
            
            // 4. Store in vector database
            let regulationEmbedding = RegulationEmbedding()
            regulationEmbedding.content = chunk.text
            regulationEmbedding.embedding = embedding
            regulationEmbedding.regulationNumber = extractRegulationNumber(from: htmlPath)
            regulationEmbedding.sectionTitle = chunk.sectionTitle
            regulationEmbedding.htmlPath = htmlPath
            
            try await vectorDB.store(regulationEmbedding)
            
            print("✅ Processed chunk \(index + 1)/\(chunks.count)")
        }
    }
}
```

### Phase 4: Search Engine (Days 9-10)

#### Step 8: Implement Vector Search
**What**: Find regulations similar to user queries
**File**: `Sources/Services/VectorSearchService.swift`

```swift
actor VectorSearchService {
    private let lfm2Service = LFM2Service()
    private let vectorDB = VectorDatabase()
    
    // Search for regulations matching a query
    func search(query: String, maxResults: Int = 10) async throws -> [SearchResult] {
        print("🔍 Searching for: '\(query)'")
        
        // 1. Convert query to embedding
        let queryEmbedding = try await lfm2Service.generateEmbedding(text: query)
        
        // 2. Find similar vectors in database
        let matches = try await vectorDB.findSimilar(
            to: queryEmbedding, 
            limit: maxResults,
            threshold: 0.7 // Minimum similarity score
        )
        
        // 3. Return formatted results
        return matches.map { match in
            SearchResult(
                content: match.content,
                regulationNumber: match.regulationNumber,
                similarity: match.similarityScore,
                source: match.source
            )
        }
    }
}
```

### Phase 5: Auto-Update System (Days 11-12)

#### Step 9: Create Auto-Update Service
**What**: Keep regulations current automatically
**File**: `Sources/Services/RegulationUpdateService.swift`

```swift
actor RegulationUpdateService {
    private let processor = RegulationProcessor()
    
    // Check for and download updated regulations
    func checkForUpdates() async throws {
        print("🔄 Checking for regulation updates...")
        
        // 1. Get latest file list from GSA repository
        let remoteFiles = try await fetchRemoteFileList()
        
        // 2. Compare with local files
        let updatesNeeded = try await compareWithLocal(remoteFiles)
        
        if updatesNeeded.isEmpty {
            print("✅ All regulations are current")
            return
        }
        
        print("📥 Found \(updatesNeeded.count) updates to download")
        
        // 3. Download and process updates
        for file in updatesNeeded {
            try await downloadAndProcess(file)
        }
        
        print("✅ Auto-update complete")
    }
    
    // Run updates in background (called by iOS)
    func performBackgroundUpdate() async {
        do {
            try await checkForUpdates()
        } catch {
            print("❌ Background update failed: \(error)")
        }
    }
}
```

### Phase 6: User Interface Integration (Days 13-14)

#### Step 10: Create Search Interface
**What**: Let users search regulations easily
**File**: `Sources/Features/RegulationSearchFeature.swift`

```swift
import SwiftUI
import ComposableArchitecture

struct RegulationSearchView: View {
    @State private var searchQuery = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    
    private let searchService = VectorSearchService()
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchQuery, onSearchTapped: performSearch)
                
                // Results
                if isSearching {
                    ProgressView("Searching regulations...")
                } else if searchResults.isEmpty && !searchQuery.isEmpty {
                    Text("No results found")
                } else {
                    List(searchResults, id: \.id) { result in
                        SearchResultRow(result: result)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Regulation Search")
        }
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        
        Task {
            do {
                let results = try await searchService.search(query: searchQuery)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    print("Search error: \(error)")
                    self.isSearching = false
                }
            }
        }
    }
}
```

---

## 📁 File Organization (Complete Structure)

```
AIKO/
├── Sources/
│   ├── GraphRAG/
│   │   ├── LFM2Service.swift              # AI model wrapper
│   │   ├── RegulationProcessor.swift      # HTML → embeddings pipeline
│   │   ├── VectorSearchService.swift      # Semantic search engine
│   │   ├── RegulationUpdateService.swift  # Auto-update system
│   │   └── VectorDatabase.swift           # ObjectBox wrapper
│   ├── Models/
│   │   ├── RegulationEmbedding.swift      # Vector storage model
│   │   ├── SearchResult.swift             # Search result model
│   │   └── UpdateStatus.swift             # Update tracking model
│   ├── Features/
│   │   ├── RegulationSearchFeature.swift  # Search UI
│   │   └── UpdateStatusFeature.swift      # Update progress UI
│   └── Resources/
│       └── LFM2-700M-Q6K.mlmodel         # 612MB AI model
├── TestData/
│   └── Regulations/
│       └── AFARS/                         # Your existing test data
│           ├── 5101.101.html
│           ├── 5101.105.html
│           └── ... (1,219 files)
└── Tests/
    ├── GraphRAGTests/
    │   ├── LFM2ServiceTests.swift
    │   ├── VectorSearchTests.swift
    │   └── ProcessingPipelineTests.swift
    └── TestResources/
        └── sample_regulations.html
```

---

## 🧪 Testing Strategy

### Unit Tests (Test Individual Components)

```swift
// Test LFM2 embedding generation
func testEmbeddingGeneration() async throws {
    let service = LFM2Service()
    let text = "Software procurement under $500,000"
    
    let embedding = try await service.generateEmbedding(text: text)
    
    XCTAssertEqual(embedding.count, 768) // LFM2 produces 768-dimension vectors
    XCTAssert(embedding.allSatisfy { $0.isFinite }) // All numbers are valid
}

// Test vector search accuracy
func testSearchAccuracy() async throws {
    let searchService = VectorSearchService()
    
    let results = try await searchService.search(query: "software contracts")
    
    XCTAssertGreaterThan(results.count, 0)
    XCTAssert(results.first?.similarity ?? 0 > 0.7) // Good similarity score
}
```

### Integration Tests (Test Complete Pipeline)

```swift
func testCompleteProcessingPipeline() async throws {
    let processor = RegulationProcessor()
    
    // Process a test regulation
    try await processor.processRegulation(htmlPath: "TestData/sample.html")
    
    // Search for content we know is in the file
    let searchService = VectorSearchService()
    let results = try await searchService.search(query: "known content from test file")
    
    XCTAssertGreaterThan(results.count, 0)
}
```

### Performance Tests
```swift
func testSearchPerformance() async throws {
    let searchService = VectorSearchService()
    
    let startTime = Date()
    _ = try await searchService.search(query: "test query")
    let duration = Date().timeIntervalSince(startTime)
    
    XCTAssertLessThan(duration, 1.0) // Should complete in under 1 second
}
```

---

## 📊 Performance Expectations

### Processing Performance
- **Model Loading**: 2-3 seconds on app startup
- **Embedding Generation**: < 2 seconds per regulation chunk
- **Full Database Processing**: 30-45 minutes for 1,219 regulations (one-time)
- **Incremental Updates**: < 30 seconds for typical daily changes

### Search Performance
- **Query Processing**: < 1 second for typical searches
- **Results**: Top 10 matches with confidence scores
- **Accuracy**: 90%+ relevant results for regulation queries

### Storage Requirements
- **LFM2 Model**: 612MB (in app bundle)
- **Vector Database**: ~100MB for 1,000 regulations
- **Original HTML**: ~50MB for complete regulation set
- **Total**: ~762MB for complete system

### Memory Usage
- **Model in Memory**: ~800MB while processing
- **Background Operations**: ~100MB
- **Search Operations**: ~50MB per query

---

## 🚨 Common Issues and Solutions

### Issue 1: Model Won't Load
**Symptoms**: "Model not found" or crashes on startup
**Solutions**:
1. Verify model file is in bundle: `Bundle.main.url(forResource: "LFM2-700M-Q6K", withExtension: "mlmodel")`
2. Check file size - should be ~612MB
3. Ensure model was converted correctly from GGUF

### Issue 2: Slow Embedding Generation
**Symptoms**: Takes > 5 seconds per regulation
**Solutions**:
1. Check device performance - older devices will be slower
2. Ensure model is running on Neural Engine (check Core ML compilation)
3. Reduce chunk size if memory is constrained

### Issue 3: Poor Search Results
**Symptoms**: Irrelevant results or low similarity scores
**Solutions**:
1. Check embedding quality - ensure model conversion preserved accuracy
2. Adjust similarity threshold (0.7 is recommended starting point)
3. Verify chunking preserves context (don't split mid-sentence)

### Issue 4: Auto-Update Fails
**Symptoms**: Updates don't download or process
**Solutions**:
1. Check network connectivity and GitHub API limits
2. Verify file comparison logic (timestamps, hashes)
3. Ensure background processing permissions are granted

---

## 🔒 Security Considerations

### Data Privacy
- **All processing happens on-device** - queries never leave your phone
- **GitHub authentication** uses OAuth with minimal scopes
- **Personal repositories** are stored separately from official data

### API Security
- **GitHub tokens** stored in iOS Keychain (encrypted)
- **Rate limiting** prevents API abuse
- **Error handling** doesn't leak sensitive information

### Vector Database Security
- **Local encryption** using iOS file system encryption
- **Access control** through iOS sandboxing
- **Backup encryption** if device backup is enabled

---

## 🎯 Success Metrics

### Development Milestones
- [ ] LFM2 model loads and generates embeddings
- [ ] Vector database stores and retrieves embeddings
- [ ] Search returns relevant results for test queries
- [ ] Processing completes for all test regulations
- [ ] Auto-update downloads and processes new files
- [ ] Personal repository integration works end-to-end

### Performance Targets
- **Search Speed**: < 1 second response time
- **Accuracy**: > 90% relevant results for regulation queries
- **Processing**: Complete 1,000 regulations in < 1 hour
- **Updates**: Daily updates complete in < 5 minutes
- **Memory**: Peak usage < 1GB during processing

### User Experience Goals
- **Onboarding**: "Regulation database ready" in < 60 minutes
- **Daily Use**: Instant search with offline capability
- **Updates**: Silent background updates with progress notifications
- **Reliability**: 99.9% uptime for search functionality

---

## 🎉 What Success Looks Like

When everything is working correctly, you'll have:

1. **iPhone with 1000+ regulations instantly searchable offline**
2. **Sub-second responses** to complex regulation queries
3. **Automatic updates** that keep content current without user intervention
4. **Personal repository support** for custom regulations
5. **Perfect LLM integration** with retrieved context for intelligent responses

**Example User Experience**:
```
User: "What are the regulations for software procurement over $500K?"
App: [Searches 1,219 regulations in 0.3 seconds]
App: "Found 7 relevant regulations. Here's the summary..."
[Shows exact citations: FAR 15.202, DFARS 212.301, etc.]
```

**This is the future of regulation research - powered by your device, instant, private, and always current.**

---

**Ready to Start?** Begin with Step 1: Download the LFM2 model. Each step builds on the previous one, so take your time and test thoroughly at each stage.

**Questions?** Review the troubleshooting section or check the test files for working examples.

**Remember**: This is advanced AI technology, but we've broken it down into manageable steps. Follow the guide systematically, and you'll have a world-class regulation intelligence system running on your iPhone.