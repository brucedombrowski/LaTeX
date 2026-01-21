# AGENTS.md

Instructions for AI agents working with Documentation-Generation components.

## Overview

This directory contains LaTeX templates for formal documentation:

| Component | Description | Status |
|-----------|-------------|--------|
| DecisionMemorandum/ | Single-page decision memos | Production |
| DecisionDocument/ | Multi-page program decisions | Production |
| SlideDecks/ | Beamer presentations | Planned |
| MeetingAgenda/ | Meeting agendas | Production |

**Parent repository:** See [../AGENTS.md](../AGENTS.md) for repository-wide instructions.

## Directory Structure

All components follow a consistent structure:

```
Component/
├── templates/          # Reusable LaTeX templates
│   ├── template.tex
│   └── logo.* -> ../../../assets/  # Symlinks to shared assets
├── examples/           # Example outputs and filled-in documents
│   └── example.pdf
└── AGENTS.md           # Component-specific docs (if needed)
```

## Build Instructions

Use centralized build scripts from repository root:

```bash
# Build a single document
./scripts/build.sh Documentation-Generation/DecisionMemorandum/templates/decision_memo.tex

# Build all documents
./scripts/release.sh
```

## Components

### DecisionMemorandum

**Purpose:** Single-page formal records of program decisions

**Template:** `templates/decision_memo.tex`

**ID Format:** `DM-YYYY-NNN` (e.g., DM-2026-001)

### DecisionDocument

**Purpose:** Multi-page program decision documentation with full traceability

**Template:** `templates/decision_document.tex`

**ID Format:** `PDD-XXXX-NNN` (e.g., PDD-PROJ-001)

**Note:** Signing tools (PdfSigner.exe, sign scripts) live here.

### MeetingAgenda

**Purpose:** Structured meeting agendas with timed items

**Template:** `templates/meeting_agenda.tex`

**Examples:** SE lifecycle meetings (project kickoff, requirements review)

### SlideDecks (Planned)

**Purpose:** Beamer presentations for briefings

**Template:** `templates/standard_brief.tex`

## Digital Signatures

Signing infrastructure lives in `DecisionDocument/`:
- `sign.sh` / `sign.bat` / `sign.ps1`
- `PdfSigner.exe` for Windows
- PIV/CAC smart card support
- Software certificate support

See [DecisionDocument/AGENTS.md](DecisionDocument/AGENTS.md) for detailed signing workflows.

## Code Style Guidelines

### LaTeX Conventions

1. **Section separators:** Use comment blocks
   ```latex
   % ============================================================================
   % SECTION NAME
   % ============================================================================
   ```

2. **Subsection separators:** Use shorter lines
   ```latex
   % ----------------------------------------------------------------------------
   ```

3. **Document variables:** Define as `\newcommand` at top under `DOCUMENT VARIABLES - EDIT THESE`

4. **Indentation:** 4 spaces for nested environments

5. **Tables:** Use `longtable` for multi-page tables; use `p{width}` for text wrapping

### Placeholder Text

- Do NOT use brackets `[like this]` - causes LaTeX issues
- Use plain descriptive text: `Placeholder text here`

### Date Format Placeholders

| Placeholder | Meaning | Example |
|-------------|---------|---------|
| `YYYY` | 4-digit year | 2026 |
| `MM` | 2-digit month | 01 |
| `DD` | 2-digit day | 15 |
| `MMMM` | Full month name | January |

**Standard formats:**
- `MMMM DD, YYYY` - US-style (January 15, 2026)
- `YYYY-MM-DD` - ISO 8601 (2026-01-15)

## Dependencies

Required LaTeX packages:
- `geometry`, `graphicx`, `fancyhdr`, `lastpage`
- `titlesec`, `enumitem`, `booktabs`, `longtable`
- `xcolor`, `hyperref`, `datetime2`, `tabularx`
- `beamer` (for SlideDecks)

## Target Environment

**Primary:** Airgapped Windows 11 with security hardening
- CIS Windows 11 Enterprise baseline
- DISA STIG Windows 11 baseline

**Secondary:** macOS/Linux for development
