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

## AI Agent Build and Sign Workflow

When building and signing PDFs as an AI agent, use this automated workflow:

```bash
# 1. Delete old certificates
rm -f *.pem *.p12

# 2. Get git commit hash for traceability
COMMIT_HASH=$(git rev-parse --short HEAD)

# 3. Create new AI agent certificate with commit hash (non-interactive)
openssl req -x509 -newkey rsa:2048 \
  -keyout ai_agent_key.pem -out ai_agent_cert.pem \
  -days 365 -nodes \
  -subj "/C=US/O=AI Agent/OU=commit:${COMMIT_HASH}/CN=Claude Code Agent" \
  -addext "keyUsage=digitalSignature" \
  -addext "extendedKeyUsage=emailProtection"

# 4. Create PKCS#12 bundle
openssl pkcs12 -export -out ai_agent.p12 \
  -inkey ai_agent_key.pem -in ai_agent_cert.pem \
  -passout pass:agent123

# 5. Build PDFs
./build.sh both

# 6. Sign PDFs (pipe password to avoid interactive prompt)
./sign.sh sign-p12 ai_agent.p12 decision_memo.pdf <<< "agent123"
./sign.sh sign-p12 ai_agent.p12 decision_document.pdf <<< "agent123"

# 7. Verify signatures
./sign.sh verify decision_memo_signed.pdf
./sign.sh verify decision_document_signed.pdf
```

**Certificate details:**
- Common Name: `Claude Code Agent`
- Organization: `AI Agent`
- Organizational Unit: `commit:<git-short-hash>` (links signature to repo state)
- Country: `US`
- Password: `agent123`

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
├── logo.png                      # Header logo (orbit-styled "LOgO")
├── Template.docx                 # Original Word template (reference)
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
