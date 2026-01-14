# AGENTS.md

Instructions for AI agents working with this repository.

## Project Overview

This repository contains LaTeX templates for formal program decision documentation, adapted from NASA's Memorandum of Agreement format.

## Templates

| File | Description |
|------|-------------|
| `decision_memo.tex` | Brief Decision Memorandum format for single-page decisions |
| `decision_document.tex` | Comprehensive decision document with full traceability |

## Build Instructions

Use the provided build scripts:

```bash
# macOS/Linux
./build.sh [decision_memo|decision_document|both]

# Windows
.\build.ps1 [decision_memo|decision_document|both]
```

The build scripts:
- Run pdflatex 3 times (for TOC and page references)
- Automatically clean up auxiliary files
- Prompt to install missing LaTeX packages if needed
- Optional `--docx` flag generates Word documents via pandoc

**Word output note:** The `--docx` flag is for user convenience only. AI agents should always use PDF output for signing. Digital signatures are not supported for Word documents.

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
├── decision_memo.tex             # Brief Decision Memorandum template
├── decision_document.tex         # Comprehensive decision template
├── decision_document.pdf         # Example generated PDF
├── decision_document_signed.pdf  # Example signed PDF
├── logo.png                      # Header logo (orbit-styled "Logo")
├── logo.svg                      # Logo source file (editable vector)
├── build.sh                      # Build script (macOS/Linux)
├── build.ps1                     # Build script (Windows)
├── sign.sh                       # PDF signing script (macOS/Linux)
├── sign.ps1                      # PDF signing script (Windows)
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

The repository includes scripts for digitally signing PDFs. Both `sign.sh` (macOS/Linux) and `sign.ps1` (Windows) have feature parity.

### Sign a PDF

**macOS/Linux:**
```bash
# Interactive mode (recommended)
./sign.sh

# Command-line: sign with software certificate
./sign.sh sign-p12 mycert.p12 document.pdf

# Command-line: sign with smart card (PIV/CAC)
./sign.sh sign document.pdf

# Verify a signature
./sign.sh verify document_signed.pdf
```

**Windows PowerShell:**
```powershell
# Interactive mode (recommended)
.\sign.ps1

# Command-line: sign with software certificate
.\sign.ps1 sign-p12 mycert.p12 document.pdf

# Command-line: sign with smart card (PIV/CAC)
.\sign.ps1 sign document.pdf

# Verify a signature
.\sign.ps1 verify document_signed.pdf
```

### Create a test certificate

```bash
# macOS/Linux
./sign.sh create-cert

# Windows
.\sign.ps1 create-cert
```

This generates:
- `<name>_key.pem` - Private key (never commit!)
- `<name>_cert.pem` - Public certificate
- `<name>.p12` - PKCS#12 bundle for signing

### Dependencies for signing

```bash
# macOS (Homebrew)
brew install opensc poppler nss
```

```powershell
# Windows (Chocolatey)
choco install openssl poppler
# Also install OpenSC from: https://github.com/OpenSC/OpenSC/releases
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
