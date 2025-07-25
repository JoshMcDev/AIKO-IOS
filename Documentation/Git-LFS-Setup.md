# Git LFS Setup for LFM2 Model Files

## Overview

This project uses Git LFS (Large File Storage) to manage large ML model files, particularly the LFM2-700M models which are approximately 149MB each. This prevents repository bloat while allowing version control of model files.

## Why Git LFS?

- **Repository Size**: Without LFS, 149MB model files would bloat the repository
- **Clone Performance**: LFS files are downloaded only when needed
- **Bandwidth Efficiency**: Team members can choose which model versions to download
- **Version Control**: Model files are still tracked and versioned properly

## Initial Setup

### 1. Install Git LFS

**macOS (Homebrew):**
```bash
brew install git-lfs
```

**Windows:**
Download from: https://git-lfs.github.io/

**Linux (Ubuntu/Debian):**
```bash
sudo apt install git-lfs
```

### 2. Initialize Git LFS in Repository

```bash
cd /Users/J/aiko
git lfs install
```

### 3. Verify LFS Configuration

```bash
git lfs track
```

Expected output:
```
Listing tracked patterns
    *.mlmodel (.gitattributes)
    *.gguf (.gitattributes)
    Sources/Resources/Models/LFM2-*.mlmodel (.gitattributes)
    Sources/Resources/Models/LFM2-*.gguf (.gitattributes)
    *.onnx (.gitattributes)
    *.tflite (.gitattributes)
    *.bin (.gitattributes)
    *.safetensors (.gitattributes)
```

## LFS Configuration

The `.gitattributes` file configures which files use LFS:

```gitattributes
# Core ML model files (managed via Git LFS due to large size)
*.mlmodel filter=lfs diff=lfs merge=lfs -text

# GGUF model files (managed via Git LFS due to large size)  
*.gguf filter=lfs diff=lfs merge=lfs -text

# Specific LFM2 model files
Sources/Resources/Models/LFM2-*.mlmodel filter=lfs diff=lfs merge=lfs -text
Sources/Resources/Models/LFM2-*.gguf filter=lfs diff=lfs merge=lfs -text
```

## Adding Model Files

### 1. Create Model Directory
```bash
mkdir -p Sources/Resources/Models
```

### 2. Add Model Files (when available)
```bash
# Copy model files to the appropriate location
cp path/to/LFM2-700M-Unsloth-XL-GraphRAG.mlmodel Sources/Resources/Models/
cp path/to/LFM2-700M-Q6K.gguf Sources/Resources/Models/

# Stage files (LFS will handle them automatically)
git add Sources/Resources/Models/LFM2-*.mlmodel
git add Sources/Resources/Models/LFM2-*.gguf

# Commit as usual
git commit -m "Add LFM2 model files via Git LFS"
```

### 3. Push to Remote
```bash
git push origin newfeet
```

LFS files will be automatically uploaded to the LFS server.

## Working with LFS Files

### Clone Repository
```bash
# Full clone (downloads all LFS files)
git clone https://github.com/username/aiko.git

# Clone without LFS files (faster)
git clone https://github.com/username/aiko.git
cd aiko
git lfs install --skip-smudge
```

### Download LFS Files Later
```bash
# Download all LFS files
git lfs pull

# Download specific files only
git lfs pull --include="Sources/Resources/Models/LFM2-700M-Unsloth-XL-GraphRAG.mlmodel"
```

### Skip LFS Files for Development
```bash
# Configure Git to skip LFS downloads for this repository
git config filter.lfs.smudge "git-lfs smudge --skip"
git config filter.lfs.process "git-lfs filter-process --skip"

# Reset to download LFS files again
git config --unset filter.lfs.smudge
git config --unset filter.lfs.process
git lfs pull
```

## Build Integration

The build system is configured to work with or without LFS files:

### Development Builds (No LFS Files)
```bash
# Default behavior - uses mock embeddings
export AIKO_LFM2_STRATEGY=mock
xcodebuild -scheme AIKO build
```

### Production Builds (With LFS Files)
```bash
# Download model files first
git lfs pull

# Build with hybrid mode
export AIKO_LFM2_STRATEGY=hybrid
xcodebuild -scheme AIKO build
```

## Team Workflow

### For Developers (Daily Work)
1. **Clone without LFS**: `git clone --no-checkout repo && git config filter.lfs.smudge "git-lfs smudge --skip"`
2. **Use mock mode**: `export AIKO_LFM2_STRATEGY=mock`
3. **Fast development**: No large files to download or manage

### For Testing Team
1. **Download specific models**: `git lfs pull --include="**/LFM2-700M-Unsloth-XL-GraphRAG.mlmodel"`
2. **Test with real models**: `export AIKO_LFM2_STRATEGY=hybrid`
3. **Verify functionality**: Real embedding generation with fallback

### For Release Builds
1. **Download all models**: `git lfs pull`
2. **Full production build**: `export AIKO_LFM2_STRATEGY=full`
3. **Archive for distribution**: All model variants included

## Monitoring LFS Usage

### Check LFS Status
```bash
git lfs ls-files
```

### Check LFS Storage Usage
```bash
git lfs env
```

### View LFS File History
```bash
git log --follow Sources/Resources/Models/LFM2-700M-Unsloth-XL-GraphRAG.mlmodel
```

## Troubleshooting

### LFS Files Not Downloading
1. **Check LFS installation**: `git lfs version`
2. **Verify tracking**: `git lfs track`
3. **Manual pull**: `git lfs pull`
4. **Check credentials**: `git lfs env`

### Repository Size Still Large
1. **Verify .gitattributes**: Large files should show as "LFS" in `git lfs ls-files`
2. **Re-track existing files**: 
   ```bash
   git rm --cached large-file.mlmodel
   git add large-file.mlmodel
   git commit -m "Convert to LFS"
   ```

### Build Fails Without Models
1. **Check build configuration**: `export AIKO_LFM2_STRATEGY=mock`
2. **Verify fallback logic**: Should use mock embeddings automatically
3. **Check logs**: Look for "mock-only mode" or "hybrid-lazy mode" messages

## Security Considerations

- **LFS Server Access**: Ensure team has appropriate LFS server permissions
- **Model Licensing**: Verify license compatibility for model distribution
- **Access Control**: Consider private LFS storage for proprietary models

## Performance Tips

- **Partial Clones**: Use `--filter=blob:none` for faster clones
- **Bandwidth Management**: Use `git lfs pull --include` for selective downloads
- **Local Caching**: Configure LFS cache directory for shared storage
- **CI/CD Optimization**: Cache LFS files in build pipelines

## Related Files

- `.gitattributes` - LFS tracking configuration
- `.gitignore` - Excludes local model files from tracking
- `Documentation/LFM2-Build-Configuration.md` - Build configuration guide
- `Sources/AppCore/Configuration/BuildConfiguration.swift` - Runtime configuration