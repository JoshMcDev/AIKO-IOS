# AIKO Regulation Knowledge Base

## Overview
This directory contains the complete set of Federal Acquisition Regulations (FAR) and supplemental regulations used by AIKO for automated contract generation and compliance checking.

## Regulation Structure

### 1. FAR - Federal Acquisition Regulation
- **Location**: `/FAR/`
- **Files**: 3,899 HTML files
- **Content**: Complete FAR Parts 1-53
- **Description**: The primary regulation governing all federal acquisitions

### 2. DFARS - Defense Federal Acquisition Regulation Supplement
- **Location**: `/DFARS/`
- **Files**: 2,867 HTML files
- **Content**: DoD-specific acquisition regulations
- **Description**: Supplements to the FAR for Department of Defense acquisitions

### 3. DFARS PGI - DFARS Procedures, Guidance, and Information
- **Location**: `/DFARS PGI/`
- **Files**: 1,224 HTML files
- **Content**: Non-regulatory procedures and guidance
- **Description**: Companion resource to DFARS with additional implementation guidance

### 4. AFARS - Army Federal Acquisition Regulation Supplement
- **Location**: `/AFARS/`
- **Files**: 1,226 HTML files
- **Content**: Army-specific acquisition regulations
- **Description**: Army's supplement to the FAR and DFARS

### 5. DAFFARS - Department of the Air Force Federal Acquisition Regulation Supplement
- **Location**: `/DAFFARS/`
- **Files**: 650 HTML files
- **Content**: Air Force-specific acquisition regulations
- **Description**: Air Force's supplement to the FAR and DFARS

### 6. DAFFARS MP - DAFFARS Mandatory Procedures
- **Location**: `/DAFFARS MP/`
- **Files**: 650 HTML files
- **Content**: Mandatory procedures for Air Force acquisitions
- **Description**: Required procedures for implementing DAFFARS

### 7. SOFARS - Special Operations Federal Acquisition Regulation Supplement
- **Location**: `/SOFARS/`
- **Files**: 417 HTML files
- **Content**: Special Operations Command acquisition regulations
- **Description**: SOCOM-specific supplement to the FAR and DFARS

## Total Files
- **Total Regulation Files**: 10,887 HTML files
- **Last Updated**: July 14, 2025

## File Naming Convention
Files follow the pattern: `[PART].[SECTION]-[SUBSECTION].html`
- Example: `52.217-8.html` contains FAR clause 52.217-8 (Option to Extend Services)

## Integration with AIKO

These regulations are used by AIKO's Clause Selection Engine to:
1. Automatically select appropriate clauses based on contract attributes
2. Retrieve full clause text for insertion into documents
3. Validate clause applicability and requirements
4. Ensure compliance with current regulations

## Usage in AIKO

```javascript
// Example: Retrieve clause text
const clauseText = await getClauseText('FAR', '52.217-8');

// Example: Search regulations
const results = await searchRegulations('option to extend services');

// Example: Validate clause reference
const isValid = await validateClauseReference('DFARS', '252.225-7001');
```

## Maintenance
- Regulations should be updated quarterly or when significant changes occur
- Use official government sources for updates:
  - FAR: https://www.acquisition.gov/far/
  - DFARS: https://www.acquisition.gov/dfars/
  - Service supplements: From respective service acquisition websites

## Notes
- All files are in HTML format for easy parsing and display
- Files contain the official regulation text as published
- Cross-references between regulations are preserved
- Includes all current clauses, provisions, and prescriptions