# AGENTS.md

Instructions for AI agents working with this repository.

## Project Overview

LaTeX templates for compliance-related document components:

1. **CUI** - Controlled Unclassified Information (32 CFR Part 2002)
2. **Export** - Export control markings (ITAR, EAR) - future
3. **Security** - Security compliance templates - future

## Use Cases

### Primary Use Case: Payload Preliminary Software ICD

**Workflow:**
```
Input PDF Report
    ↓
Add Export Markings (Export/)
    ↓
Prepend CUI Cover Page (CUI/)
    ↓
Final Document (Payload Software Interface Control Document)
```

### Generic Applicability

These templates are reusable for any document requiring:
- CUI cover pages (SF901)
- Export control markings (ITAR, EAR, distribution statements)
- Security compliance documentation

## Decision Documentation Standards

**All significant design and implementation decisions must be documented as formal Decision Memorandums in PDF format.**

### Decision Memorandum Requirements

**When asked to "Create a Decision Memorandum", follow these requirements exactly.**

1. **Format:** LaTeX-generated PDF documents (dogfooding our own templates)
2. **Location:** `../Decisions/` directory (root level)
3. **Unique ID Format:** `DM-YYYY-NNN` where:
   - `YYYY` = 4-digit year
   - `NNN` = 3-digit sequential number within that year
   - Example: `DM-2026-002`
4. **File Naming Convention:** `DM-YYYY-NNN_<topic>.tex` and corresponding `.pdf`
   - The unique ID MUST be in the filename
   - Example: `DM-2026-002_sf901_font_decision.tex`
5. **Check Index for Next ID:** Before creating a new decision memo, check the Decision Memorandum Index below to determine the next sequential ID number
6. **Required Document Sections:**
   - Header comment with Document ID (matching filename)
   - Decision ID in metadata table (matching filename)
   - Date, Status, Author, Affected Documents
   - Context/background
   - Problem statement
   - Decision (clear statement)
   - Rationale (with subsections as needed)
   - Alternatives considered (table with pros/cons)
   - Implementation details
   - References
   - Impact assessment
   - Approval signature block
7. **After Creating:** Update the Decision Memorandum Index in this file

### Decision Memorandum Index

| ID | File | Title | Date | Status |
|----|------|-------|------|--------|
| DM-2026-001 | dm_sf901_decision | SF901 LaTeX Recreation Decision | 2026-01-19 | Approved |
| DM-2026-002 | DM-2026-002_sf901_font_decision | CUI Header Font Selection (Cinzel vs Trajan) | 2026-01-19 | Approved |
| DM-2026-003 | DM-2026-003_sf901_tikz_layout | SF901 Layout Implementation (TikZ vs Alternatives) | 2026-01-19 | Approved |

---

## Design Decisions

### CUI Cover Page: LaTeX Recreation of SF901

**Decision:** Recreate Standard Form 901 (CUI Coversheet) as a LaTeX template rather than programmatically editing the GSA PDF.

**Rationale:**
- Full control over customizable text area (categories, dissemination controls, POC)
- Parameterized fields via `\newcommand` variables
- Consistent with existing LaTeX document workflows
- No runtime dependency on PDF manipulation tools for cover page generation
- Form has been stable since November 2018 (low maintenance burden)

**Tracking Requirement:** Must periodically verify against official GSA source:
- Form page: https://www.gsa.gov/reference/forms/controlled-unclassified-information-cui-coversheet-1
- PDF (primary): https://www.gsa.gov/system/files/SF901-18a.pdf
- PDF (CDN mirror): https://www.gsa.gov/cdnstatic/SF901-18a.pdf
- Current revision: **SF901 (11-18)** - November 2018
- Authority: 32 CFR Part 2002, Executive Order 13556

**Reference file:** `CUI/SF901-Example.pdf` - official GSA form kept for comparison

**Decision Memo:** `../Decisions/dm_sf901_decision.pdf` (DM-2026-001)

### SF901 Template Fields

The LaTeX template will support these customizable fields:

| Field | Purpose | Example |
|-------|---------|---------|
| CUI Categories | Specific CUI category markings | `CUI//SP-CTI` |
| Dissemination Controls | Limited dissemination indicators | `NOFORN`, `FEDCON` |
| Special Instructions | Handling instructions | `Contact before reproduction` |
| Point of Contact | POC name/info | `J. Smith, 555-1234` |

## Target Environment

**Airgapped Windows 11** with security hardening (same as DecisionDocument):
- CIS Windows 11 Enterprise baseline
- DISA STIG Windows 11 baseline
- Microsoft Security Baseline

## Related Components

| Component | Location | Purpose |
|-----------|----------|---------|
| PdfSigner.exe | `../Documentation-Generation/DecisionDocument/PdfSigner.exe` | Digital signature capability |
| sign.bat | `../Documentation-Generation/DecisionDocument/sign.bat` | Windows signing workflow |
| Decision templates | `../Documentation-Generation/DecisionDocument/` | Decision memo templates |

## File Structure

```
Compliance-Marking/
├── AGENTS.md                     # This file - requirements and analysis
├── CUI/                          # Controlled Unclassified Information
│   ├── SF901-Official-Template.pdf  # Official GSA SF901 for reference
│   ├── SF901.tex                 # LaTeX template for SF901 (base)
│   ├── SF901.pdf                 # Generated cover sheet
│   └── examples/                 # Filled-in examples by CUI category
│       ├── build_tex_to_pdf.sh   # Compiles examples, generates PNGs
│       ├── CUI_Introduction.tex  # Title page for document package
│       ├── SF901_BASIC.tex       # CUI//BASIC example
│       ├── SF901_CTI.tex         # CUI//SP-CTI example
│       ├── SF901_PROCURE.tex     # CUI//SP-PROCURE example
│       └── SF901_PRVCY.tex       # CUI//SP-PRVCY example
├── Export/                       # Export control (ITAR/EAR) - future
└── Security/                     # Security compliance - future

# Decision Memorandums are at repo root: ../Decisions/
```

## Research Needed

- [x] Document CUI cover page requirements (SF901, 32 CFR 2002)
- [x] Create LaTeX SF901 template (`CUI/SF901.tex`)
- [ ] Document export marking requirements (ITAR/EAR specifics)
- [ ] Create export marking templates (`Export/`)
