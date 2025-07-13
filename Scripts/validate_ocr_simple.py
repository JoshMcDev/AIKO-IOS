#!/usr/bin/env python3
"""
OCR Validation Script
Tests OCR accuracy on quote files
"""

import os
import time
import re
from datetime import datetime

# File paths
IMAGE_FILE = "/Users/J/Desktop/quote pic.jpeg"
PDF_FILE = "/Users/J/Desktop/quote scan.pdf"

def validate_files():
    """Check if test files exist"""
    print("🔍 OCR Validation Report")
    print("=" * 50)
    print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    print("📁 Test Files:")
    for file_path in [IMAGE_FILE, PDF_FILE]:
        if os.path.exists(file_path):
            size = os.path.getsize(file_path) / 1024
            print(f"  ✅ {os.path.basename(file_path)} ({size:.1f} KB)")
        else:
            print(f"  ❌ {os.path.basename(file_path)} - NOT FOUND")
            return False
    return True

def analyze_ocr_requirements():
    """Analyze OCR requirements for AIKO"""
    print("\n📋 OCR Requirements Analysis:")
    print("  - Target Accuracy: 95%")
    print("  - Document Types: PDF, Images (JPEG, PNG, HEIC)")
    print("  - Required Data Extraction:")
    print("    • Vendor name and contact info")
    print("    • Quote number and date")
    print("    • Line items with descriptions")
    print("    • Prices and totals")
    print("    • Payment terms")
    print("    • Delivery information")

def suggest_test_approach():
    """Suggest manual testing approach"""
    print("\n🧪 Manual Testing Approach:")
    print()
    print("1. Visual Inspection:")
    print("   - Open both quote files on desktop")
    print("   - Note the following information:")
    print("     • Vendor/Company name")
    print("     • Quote number")
    print("     • Date of quote")
    print("     • Total amount")
    print("     • Number of line items")
    print("     • Any special terms or conditions")
    print()
    print("2. Expected OCR Results:")
    print("   - All text should be clearly readable")
    print("   - Numbers and prices extracted accurately")
    print("   - Table structure preserved (for line items)")
    print("   - Contact information captured")
    print()
    print("3. Accuracy Metrics:")
    print("   - Character accuracy: >95%")
    print("   - Entity extraction: All key fields found")
    print("   - Structure preservation: Tables/lists intact")
    print("   - Processing time: <5s for images, <10s for PDFs")

def document_validation_results():
    """Create validation results template"""
    print("\n📊 Validation Results Template:")
    print()
    print("Fill in the following after manual inspection:")
    print()
    print("IMAGE FILE (quote pic.jpeg):")
    print("  [ ] Vendor name extracted correctly")
    print("  [ ] Quote number found")
    print("  [ ] Date extracted")
    print("  [ ] Total price accurate")
    print("  [ ] Line items readable")
    print("  [ ] Contact info captured")
    print("  Estimated accuracy: ____%")
    print()
    print("PDF FILE (quote scan.pdf):")
    print("  [ ] Vendor name extracted correctly")
    print("  [ ] Quote number found")
    print("  [ ] Date extracted")
    print("  [ ] Total price accurate")
    print("  [ ] Line items readable")
    print("  [ ] Contact info captured")
    print("  Estimated accuracy: ____%")
    print()
    print("OVERALL ASSESSMENT:")
    print("  [ ] Meets 95% accuracy threshold")
    print("  [ ] Performance acceptable")
    print("  [ ] Ready for production use")

def create_validation_report():
    """Create a validation report file"""
    report_path = "/Users/J/aiko/Tests/OCRValidation/ValidationReport.md"
    
    report_content = """# OCR Validation Report

## Test Date
{date}

## Test Files
- Image: `/Users/J/Desktop/quote pic.jpeg`
- PDF: `/Users/J/Desktop/quote scan.pdf`

## OCR Configuration
- Framework: Vision (Apple)
- Recognition Level: Accurate
- Language: English (US)
- Language Correction: Enabled

## Expected Data Points

### Critical Fields (Must Extract)
- [ ] Vendor/Company Name
- [ ] Quote Number
- [ ] Total Price
- [ ] Quote Date

### Important Fields (Should Extract)
- [ ] Line Items with Descriptions
- [ ] Individual Prices
- [ ] Contact Email
- [ ] Contact Phone
- [ ] Payment Terms
- [ ] Valid Until Date

### Nice to Have
- [ ] Address Information
- [ ] Tax/Shipping Details
- [ ] Special Instructions

## Test Results

### Image OCR Results
**File:** quote pic.jpeg  
**Processing Time:** ___ seconds  
**Confidence Score:** ___%  

**Extracted Data:**
- Vendor: _______________
- Quote #: _______________
- Total: $_______________
- Date: _______________
- Items Found: _______________

**Accuracy Assessment:** ____%

### PDF OCR Results
**File:** quote scan.pdf  
**Processing Time:** ___ seconds  
**Confidence Score:** ___%  

**Extracted Data:**
- Vendor: _______________
- Quote #: _______________
- Total: $_______________
- Date: _______________
- Items Found: _______________

**Accuracy Assessment:** ____%

## Accuracy Calculation

### Scoring Criteria
1. **Text Extraction (40%)**
   - Complete text extracted
   - Minimal garbled characters
   - Proper line breaks preserved

2. **Entity Recognition (40%)**
   - Key fields identified
   - Values extracted correctly
   - Relationships preserved

3. **Confidence Metrics (20%)**
   - Vision API confidence scores
   - Consistency across pages/sections

### Final Scores
- Image OCR: ___/100
- PDF OCR: ___/100
- **Average: ___/100**

## Pass/Fail Determination
**Threshold:** 95/100  
**Result:** [ ] PASS / [ ] FAIL

## Recommendations
- [ ] Current implementation meets requirements
- [ ] Minor adjustments needed:
  - _______________
- [ ] Major improvements required:
  - _______________

## Next Steps
1. If PASS: Proceed with integration testing
2. If FAIL: 
   - Adjust OCR parameters
   - Consider preprocessing steps
   - Test alternative recognition levels

---
*Report prepared for AIKO OCR validation*
""".format(date=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    
    with open(report_path, 'w') as f:
        f.write(report_content)
    
    print(f"\n✅ Validation report template created:")
    print(f"   {report_path}")

def main():
    """Main validation routine"""
    if not validate_files():
        print("\n❌ Cannot proceed - test files missing")
        return
    
    analyze_ocr_requirements()
    suggest_test_approach()
    document_validation_results()
    create_validation_report()
    
    print("\n" + "=" * 50)
    print("📝 Next Steps:")
    print("1. Run the Swift test with: swift test --filter OCRAccuracyTest")
    print("2. Or manually inspect the quote files and fill out the report")
    print("3. Update ValidationReport.md with actual results")
    print("4. Determine if 95% threshold is met")

if __name__ == "__main__":
    main()