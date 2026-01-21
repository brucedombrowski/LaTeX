# AGENTS.md

Instructions for AI agents working with this component.

## Project Overview

This component (`Documentation-Generation/DecisionDocument/`) provides the LaTeX template for comprehensive, multi-page Program Decision Documents, adapted from NASA's Memorandum of Agreement format.

**Parent repository:** See [../../AGENTS.md](../../AGENTS.md) for repository-wide instructions.

**Related components:**
- `../DecisionMemorandum/` - Single-page Decision Memorandum template
- `../../Decisions/` - Where generated decision documents are stored
- `../../assets/` - Shared logos (symlinked here as `logo.png`, `logo.svg`)
- `../../Compliance-Marking/AGENTS.md` - Decision Memorandum Index and requirements

## Target Environment

**Airgapped Windows 11** with security hardening:
- CIS Windows 11 Enterprise baseline
- DISA STIG Windows 11 baseline
- Microsoft Security Baseline

Also supports macOS/Linux for development.

## Template

| File | Description |
|------|-------------|
| `decision_document.tex` | Comprehensive multi-page decision document with full traceability |

## Build Instructions

Use the provided build scripts:

```bash
# macOS/Linux
./build.sh

# Windows (batch - double-click friendly)
build.bat

# Windows (PowerShell)
.\build.ps1
```

The build scripts:
- Run pdflatex 3 times (for TOC and page references)
- Automatically clean up auxiliary files
- Check for MiKTeX and prompt installation if missing

## AI Agent Build and Sign Workflow

When building and signing PDFs as an AI agent, use this automated workflow:

```bash
# 1. Delete old certificates
rm -f *.pem *.p12

# 2. Build PDFs first
./build.sh both

# 3. Sign each PDF with a certificate containing its source .tex hash
# This creates per-document traceability from signed PDF back to source

# Sign decision_memo.pdf
TEX_HASH=$(shasum -a 256 decision_memo.tex | cut -c1-12)
openssl req -x509 -newkey rsa:2048 \
  -keyout memo_key.pem -out memo_cert.pem \
  -days 365 -nodes \
  -subj "/C=US/O=AI Agent/OU=sha256:${TEX_HASH}/CN=decision_memo.tex" \
  -addext "keyUsage=digitalSignature" \
  -addext "extendedKeyUsage=emailProtection" 2>/dev/null
openssl pkcs12 -export -out memo.p12 \
  -inkey memo_key.pem -in memo_cert.pem \
  -passout pass:agent123
./sign.sh sign-p12 memo.p12 decision_memo.pdf <<< "agent123"

# Sign decision_document.pdf
TEX_HASH=$(shasum -a 256 decision_document.tex | cut -c1-12)
openssl req -x509 -newkey rsa:2048 \
  -keyout doc_key.pem -out doc_cert.pem \
  -days 365 -nodes \
  -subj "/C=US/O=AI Agent/OU=sha256:${TEX_HASH}/CN=decision_document.tex" \
  -addext "keyUsage=digitalSignature" \
  -addext "extendedKeyUsage=emailProtection" 2>/dev/null
openssl pkcs12 -export -out doc.p12 \
  -inkey doc_key.pem -in doc_cert.pem \
  -passout pass:agent123
./sign.sh sign-p12 doc.p12 decision_document.pdf <<< "agent123"

# 4. Verify signatures
./sign.sh verify decision_memo_signed.pdf
./sign.sh verify decision_document_signed.pdf

# 5. Clean up certificates
rm -f *.pem *.p12
```

**Certificate details:**
- Common Name: `<source-filename>.tex` (e.g., `decision_document.tex`)
- Organization: `AI Agent`
- Organizational Unit: `sha256:<first-12-chars-of-tex-hash>` (links signature to source .tex file)
- Country: `US`
- Password: `agent123`

**Verifying source traceability:**
```bash
# Get the hash from the signed PDF
./sign.sh verify decision_document_signed.pdf | grep "OU=sha256"

# Compare with the current .tex file hash
shasum -a 256 decision_document.tex | cut -c1-12
```

If the hashes match, the PDF was generated from that exact .tex source.

**Output files:**
- `decision_memo_signed.pdf`
- `decision_document_signed.pdf`

The "Certificate issuer is unknown" warning during verification is expected for self-signed certificates.

## Code Style Guidelines

### LaTeX Conventions

1. **Comments**: Use `%` comment blocks to separate major sections:
   ```latex
   % ============================================================================
   % SECTION NAME
   % ============================================================================
   ```

2. **Subsection separators**: Use shorter comment lines:
   ```latex
   % ----------------------------------------------------------------------------
   ```

3. **Document variables**: Define customizable fields as `\newcommand` at the top of the document under `DOCUMENT VARIABLES - EDIT THESE`

4. **Indentation**: Use 4 spaces for nested environments

5. **Tables**: Use `longtable` for tables that may span pages; use `p{width}` column specifiers for text wrapping

### Placeholder Text

- Do NOT use brackets `[like this]` for placeholders - they cause LaTeX formatting issues
- Use plain descriptive text instead: `Placeholder text here`

### Date Format Placeholders

Use ANSI/NIST standard date format placeholders:

| Placeholder | Meaning | Example |
|-------------|---------|---------|
| `YYYY` | 4-digit year | 2026 |
| `MM` | 2-digit month (01-12) | 01 |
| `DD` | 2-digit day (01-31) | 15 |
| `MMMM` | Full month name | January |
| `MMM` | Abbreviated month | Jan |

**Standard formats used in templates:**
- `MMMM DD, YYYY` - For US-style dates (e.g., January 15, 2026)
- `YYYY-MM-DD` - For ISO 8601 dates (e.g., 2026-01-15)

### Document Identifier Placeholders

| Placeholder | Meaning | Example |
|-------------|---------|---------|
| `YYYY` | 4-digit year | 2026 |
| `NNN` | 3-digit sequence number | 001 |
| `XXXX` | Alphanumeric code | PROJ |

**Standard formats used in templates:**
- `DM-YYYY-NNN` - Decision Memorandum (e.g., DM-2026-001)
- `PDD-XXXX-NNN` - Program Decision Document (e.g., PDD-PROJ-001)

## File Structure

```
DecisionDocument/
├── decision_document.tex         # Comprehensive decision template
├── logo.png -> ../../assets/logo.png  # Symlink to shared logo
├── logo.svg -> ../../assets/logo.svg  # Symlink to shared logo source
├── build.bat                     # Build script (Windows batch - double-click)
├── build.ps1                     # Build script (Windows PowerShell)
├── build.sh                      # Build script (macOS/Linux)
├── sign.bat                      # PDF signing script (Windows batch - double-click)
├── sign.ps1                      # PDF signing script (Windows PowerShell)
├── sign.sh                       # PDF signing script (macOS/Linux)
├── PdfSigner.exe                 # Windows PDF signing tool (self-contained)
├── .gitignore                    # Git ignore rules
├── README.md                     # User documentation
└── AGENTS.md                     # This file
```

## Common Tasks

### Adding a new section

1. Add a comment separator before the section
2. Use `\section{}` for main sections, `\subsection{}` for subsections
3. Follow existing formatting patterns

### Modifying tables

- Ensure column widths sum to approximately `\textwidth` minus padding
- Include `\endfirsthead` and `\endhead` for multi-page table headers

### Updating references

- All URLs should use `\url{}` command
- Verify URLs are not redirected before adding

## Dependencies

Required LaTeX packages:
- geometry, graphicx, fancyhdr, lastpage
- titlesec, enumitem, booktabs, longtable
- xcolor, hyperref, datetime2, tabularx

Install via TeX Live:
```bash
sudo tlmgr install titlesec enumitem booktabs longtable lastpage datetime2 tabularx
```

## Digital Signatures

The repository includes scripts for digitally signing PDFs.

### Windows (Primary Target)

Double-click `sign.bat` for interactive mode, or use command line:

```batch
:: Interactive mode
sign.bat

:: Sign a specific PDF
sign.bat document.pdf

:: Verify a signature
sign.bat verify document_signed.pdf

:: Create a test certificate (requires OpenSSL)
sign.bat create-cert

:: List available certificates
sign.bat list
```

**PdfSigner.exe** handles signing via Windows Certificate Store. Features:
- PIV/CAC smart card support (triggers Windows Security PIN dialog)
- Software certificate support
- Multi-signature support (add multiple signatures to one PDF)
- Only shows valid signing certs (Email Protection or Document Signing EKU)
- Excludes VPN/network security certs, device certs, and authentication-only certs
- PIV/CAC certificates prioritized over other certificates

**PdfSigner source code:** [github.com/brucedombrowski/PDFSigner](https://github.com/brucedombrowski/PDFSigner)

### Multi-Signature Workflow (Windows)

The sign.bat menu provides option [2] to add signatures to already-signed PDFs:

```batch
:: Interactive menu
sign.bat
::   [1] Sign a PDF              - initial signature
::   [2] Add signature to signed PDF  - additional signatures
::   [3] Verify a signed PDF
::   [4] Create test certificate
::   [5] List certificates
```

Or via command line:
```batch
:: First signature
sign.bat document.pdf

:: Add second signature to the signed PDF
sign.bat document_signed.pdf
```

### macOS/Linux

```bash
# Interactive mode
./sign.sh

# Sign with smart card
./sign.sh sign document.pdf

# Sign with software certificate
./sign.sh sign-p12 mycert.p12 document.pdf

# Verify
./sign.sh verify document_signed.pdf

# Create test certificate
./sign.sh create-cert
```

**Dependencies:**
```bash
brew install opensc poppler nss
```

## Testing Changes

After modifying any `.tex` file:
1. Run the build script to compile
2. Review the generated PDF for formatting issues
3. Check page numbers display correctly (especially "Page X of Y")
4. Verify all URLs are clickable in the PDF

After modifying `sign.sh`:
1. Test certificate creation: `./sign.sh create-cert`
2. Test signing: `./sign.sh sign-p12 test.p12 decision_document.pdf`
3. Test verification: `./sign.sh verify decision_document_signed.pdf`
