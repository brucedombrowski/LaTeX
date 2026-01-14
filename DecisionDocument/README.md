# Program Decision Document Templates

LaTeX templates for formal program decision documentation, adapted from NASA's Memorandum of Agreement format.

## Templates

| Template | Description | Use Case |
|----------|-------------|----------|
| `moa_template.tex` | Memorandum of Agreement | Brief, single-page decisions with standard memo format |
| `decision_document.tex` | Comprehensive Decision Document | Detailed decisions requiring full documentation |

## Files

```
DecisionDocument/
├── moa_template.tex        # Brief MOA template
├── decision_document.tex   # Comprehensive decision template
├── logo_placeholder.png    # Placeholder logo for header
├── Template.docx           # Original Word template (reference)
├── build.sh                # Build script (macOS/Linux)
├── build.ps1               # Build script (Windows)
└── README.md               # This file
```

## Requirements

- LaTeX distribution (TeX Live, MiKTeX, or MacTeX)
- Required packages:
  - geometry, graphicx, fancyhdr, lastpage
  - titlesec, enumitem, booktabs, longtable
  - xcolor, hyperref, datetime2, tabularx

## Quick Start

### macOS / Linux

```bash
# Make build script executable (first time only)
chmod +x build.sh

# Run build script
./build.sh
```

### Windows (PowerShell)

```powershell
# Allow script execution (first time only, run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run build script
.\build.ps1
```

### Build Options

The build script provides three options:

1. **MOA Template** - Builds `moa_template.pdf`
2. **Comprehensive Decision Document** - Builds `decision_document.pdf`
3. **Both** - Builds both PDFs

You can also specify the document directly:

```bash
# macOS/Linux
./build.sh moa_template
./build.sh decision_document
./build.sh both

# Windows
.\build.ps1 moa_template
.\build.ps1 decision_document
.\build.ps1 both
```

## Template Customization

### MOA Template (`moa_template.tex`)

Edit the document variables near the top of the file:

```latex
\newcommand{\UniqueID}{MOA-2025-001}
\newcommand{\DocumentDate}{October XX, 20XX}
\newcommand{\AuthorName}{Author Name}
\newcommand{\AuthorTitle}{Title}
\newcommand{\ToField}{Distribution}
\newcommand{\SubjectField}{Subject Line Here}
\newcommand{\OPRField}{Office Name}
```

**Structure:**
- Header with logo and "Memorandum of Agreement"
- Signature block with author info
- Memo fields (DATE, TO, SUBJECT, OFFICE OF PRIMARY RESPONSIBILITY)
- Numbered sections: Purpose, Background, Scope, Agreement
- Footer with document ID, page numbers, and date

### Comprehensive Decision Document (`decision_document.tex`)

Edit the document variables near the top of the file:

```latex
\newcommand{\DocumentTitle}{Program Decision Document}
\newcommand{\DocumentNumber}{PDD-XXXX-XXX}
\newcommand{\DocumentVersion}{1.0}
\newcommand{\EffectiveDate}{\today}
\newcommand{\ProgramName}{Program Name}
\newcommand{\ProjectName}{Project Name}
\newcommand{\DecisionTitle}{Decision Title}
```

**Structure:**
| Section | Purpose |
|---------|---------|
| Title Page | Document identification and program details |
| Document Control | Revision history and approval signatures |
| Purpose | Why the document exists |
| Scope | Applicability and period of performance |
| Background | Context, problem statement, alternatives considered |
| Decision | Formal decision statement and rationale |
| Roles and Responsibilities | Organization assignments and agreements |
| Implementation | Action items with owners, dates, and status |
| Risk Assessment | Identified risks with mitigation strategies |
| Resources | Funding, personnel, and facilities |
| Documentation and Reporting | Related documents and requirements |
| Dispute Resolution | Escalation procedures |
| Amendment Procedures | Process for modifying the decision |
| Appendices | Supporting data, acronyms, references |

### Adding Your Logo

Replace `logo_placeholder.png` with your organization's logo. The logo should be approximately 1 inch tall for optimal header display.

## Installing Missing Packages

If compilation fails due to missing packages:

### TeX Live (macOS/Linux)

```bash
sudo tlmgr update --self
sudo tlmgr install titlesec enumitem booktabs longtable lastpage datetime2 tabularx
```

### MiKTeX (Windows)

MiKTeX typically installs missing packages automatically. If not, use the MiKTeX Console to install packages manually.

## Manual Compilation

If you prefer not to use the build scripts:

```bash
# Run pdflatex 3 times for proper TOC and page references
pdflatex moa_template.tex
pdflatex moa_template.tex
pdflatex moa_template.tex

# Clean up auxiliary files
rm -f *.aux *.log *.out *.toc
```

## Usage Tips

1. **MOA Template**: Best for straightforward decisions that need formal documentation but don't require extensive detail
2. **Comprehensive Template**: Use when decisions require full traceability, risk assessment, and multiple stakeholder agreements
3. **Signatures**: Obtain all required signatures before distribution
4. **Version Control**: Update the revision history table with each document change
5. **Traceability**: Reference related documents by their formal document numbers

## License

This template is provided for government and public use.
