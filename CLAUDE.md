# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

LaTeX toolkit for generating professional documents (decision memos, slide decks, meeting agendas, compliance cover sheets, software attestations) in secure, compliance-aware environments. Primary target is airgapped Windows 11; also supports macOS/Linux for development.

## Build Commands

```bash
# Build a single .tex file to PDF (runs pdflatex 3x for cross-references)
./.scripts/build-tex.sh path/to/document.tex

# Build with Word output (requires pandoc)
./.scripts/build-tex.sh path/to/document.tex --docx

# Build all documents for release to .dist/
./.scripts/release.sh

# Clean .dist/ directory
./.scripts/release.sh --clean

# Build requirements PDFs from JSON (in Compliance-Marking/Requirements/)
cd Compliance-Marking/Requirements && python3 build-requirements-pdf.py
```

## Architecture

### Template Wrapper Pattern (DRY)

Every document type uses a shared template + thin wrapper pattern:
- **Template** (e.g., `SF901-template.tex`, `_template.tex`) defines `\documentclass`, packages, layout, and renders content from `\newcommand` variables
- **Wrapper** (the actual document) defines variables via `\newcommand` then calls `\input{template.tex}`
- New documents are created by copying an example wrapper, editing variables, and building

### Directory Layout

| Directory | Purpose |
|-----------|---------|
| `Documentation-Generation/` | All document templates organized by type (DecisionMemorandum, DecisionDocument, SlideDecks, MeetingAgenda, TechnicalReport, Attestations, SoftwareICD) |
| `Decisions/` | Archive of finalized Decision Memorandum PDFs |
| `Attestations/` | Generated attestation PDFs |
| `Compliance-Marking/` | CUI cover sheets (SF901), requirements (JSON→PDF), verifications index |
| `Analysis/` | DRY assessment and mitigation plans |
| `.scripts/` | Centralized build tools, signing scripts, PDF merge |
| `.scripts/lib/common.sh` | Shared shell utilities (colors, `determine_compiler`, `cleanup_aux_files`, `require_command`) |
| `.config/external-deps.json` | External dependency definitions (GitHub release sources) |
| `.assets/` | Shared images/logos (symlinked from subfolders) |
| `.bin/` | External binaries like PdfSigner.exe (gitignored, downloaded from GitHub releases) |
| `.dist/` | Release build output |

### Compiler Selection

`determine_compiler` in `.scripts/lib/common.sh` returns `xelatex` if the file uses `fontspec` or inputs `SF901-template`, otherwise `pdflatex`. SF901 CUI cover sheets require xelatex; most other documents use pdflatex.

### Signing Infrastructure

Digital signature tooling lives in `Documentation-Generation/DecisionDocument/` with symlinks from DecisionMemorandum. Uses `.bin/PdfSigner.exe` on Windows (PIV/CAC smart card support) or `sign.sh` on macOS/Linux. Self-signed certificates embed source file SHA256 hash in the OU field for traceability.

### Requirements/Verification (V&V)

- **REQ documents**: JSON source of truth in `Compliance-Marking/Requirements/`, built to PDF via `build-requirements-pdf.py`
- **VER documents**: Live in implementation repos (not this repo), indexed in `Compliance-Marking/Verifications/README.md`

## LaTeX Conventions

- Section separators: `% ====...====` comment blocks; subsections use `% ----...----`
- Document variables: `\newcommand` definitions at top of file under `% DOCUMENT VARIABLES - EDIT THESE`
- Indentation: 4 spaces for nested environments
- Placeholders: Use plain text, NOT brackets `[like this]` (brackets cause LaTeX compilation errors)
- Date placeholders: `YYYY`, `MM`, `DD`, `MMMM` (full month name)
- Tables: Use `longtable` for multi-page; `tabularx` for flexible widths

## Decision Memorandums

- ID format: `DM-YYYY-NNN` (check index in `Compliance-Marking/AGENTS.md` for next sequential ID)
- File naming: `DM-YYYY-NNN_<topic>.tex`
- Location: source in `Decisions/`, templates in `Documentation-Generation/DecisionMemorandum/templates/`
- After creating a DM, update the Decision Memorandum Index in `Compliance-Marking/AGENTS.md`

## Cross-Platform Scripts

Each tool has three variants: `.sh` (macOS/Linux), `.ps1` (PowerShell), `.bat` (Windows double-click). Build scripts source `.scripts/lib/common.sh` for shared utilities.
