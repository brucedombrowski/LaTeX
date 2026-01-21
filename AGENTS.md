# AGENTS.md

Instructions for AI agents working with this repository.

## Repository Overview

**LaTeX Toolkit** - LaTeX templates, build scripts, and PDF tools for producing professional documents in secure, compliance-aware environments.

### Philosophy

This toolkit follows the [SpeakUp project](https://github.com/brucedombrowski/SpeakUp) philosophy:
- **Structured systems** - All work performed in version-controlled, reproducible workflows
- **Traceability** - Source-to-output chains via digital signatures with embedded hashes
- **Automation** - Cross-platform build scripts, AI agent workflows, PDF manipulation
- **Auditability** - Formal decision documentation, compliance markings, signing infrastructure

### Capabilities

| Capability | Component | Status |
|------------|-----------|--------|
| **Decision Memorandums** | Documentation-Generation/DecisionMemorandum/ | Production |
| **Decision Documents** | Documentation-Generation/DecisionDocument/ | Production |
| **Slide Decks** | Documentation-Generation/SlideDecks/ | Planned |
| **Meeting Agendas** | Documentation-Generation/MeetingAgenda/ | Production |
| **CUI Cover Sheets** | Compliance-Marking/CUI/ | Production |
| **Export Markings** | Compliance-Marking/Export/ | Planned |
| **PDF Merging** | scripts/merge-pdf.* | Production |
| **Digital Signatures** | Documentation-Generation/DecisionDocument/ | Production |

### Key Features

**Document Generation:**
- Decision Memorandums (single-page) and Program Decision Documents (multi-page)
- Beamer presentation slide decks
- Structured meeting agendas with timed items

**Compliance & Security:**
- SF901 CUI cover sheets (32 CFR Part 2002 compliant)
- Export control markings (ITAR/EAR) - planned
- Digital signatures with PIV/CAC smart card support
- Self-signed certificates with source hash traceability

**PDF Operations:**
- Merge multiple PDFs with user-defined ordering
- LaTeX-based (pdfpages) - no external dependencies
- Works on airgapped systems

**Cross-Platform:**
- Windows: `.bat` (double-click), `.ps1` (PowerShell)
- macOS/Linux: `.sh` (bash)
- All tools work offline after LaTeX installation

## Target Environment

**Primary:** Airgapped Windows 11 with security hardening
- CIS Windows 11 Enterprise baseline
- DISA STIG Windows 11 baseline
- Microsoft Security Baseline

**Secondary:** macOS/Linux for development

## Components

| Component | Description | AGENTS.md |
|-----------|-------------|-----------|
| [scripts/](scripts/) | Build tools, release scripts, PDF merge utilities | — |
| [assets/](assets/) | Shared images and logos | — |
| [Documentation-Generation/](Documentation-Generation/) | Document templates (decisions, slides, agendas) | [Documentation-Generation/AGENTS.md](Documentation-Generation/AGENTS.md) |
| [Decisions/](Decisions/) | Formal Decision Memorandums archive | — |
| [Compliance-Marking/](Compliance-Marking/) | CUI cover pages, export markings, security compliance | [Compliance-Marking/AGENTS.md](Compliance-Marking/AGENTS.md) |

## Documentation-Generation

Document templates following the [SpeakUp project](https://github.com/brucedombrowski/SpeakUp) workflow.

### Workflow Model

```
Mobile Ideation (AI agent, text/voice)
    ↓
IDE-Integrated Execution (LaTeX source → PDF)
    ↓
Verification (build, compliance checks)
    ↓
Distributable Output (PDF)
```

### Documentation Structure

All components follow a consistent `templates/` and `examples/` structure:

```
Documentation-Generation/
├── AGENTS.md                 # Documentation-Generation instructions
│
├── DecisionMemorandum/       # Single-page decision memos
│   ├── templates/
│   │   └── decision_memo.tex
│   ├── examples/
│   └── sign.* -> ../DecisionDocument/sign.*  # Symlinks to signing tools
│
├── DecisionDocument/         # Multi-page program decisions
│   ├── AGENTS.md             # Signing-specific instructions
│   ├── README.md
│   ├── templates/
│   │   └── decision_document.tex
│   ├── examples/
│   ├── sign.sh / sign.ps1 / sign.bat
│   └── PdfSigner.exe         # From github.com/brucedombrowski/PDFSigner
│
├── SlideDecks/               # Presentation slide decks (Beamer)
│   ├── templates/
│   │   └── standard_brief.tex
│   └── examples/
│
└── MeetingAgenda/            # Meeting agenda documents
    ├── templates/
    │   └── meeting_agenda.tex
    └── examples/
        ├── project_kickoff.tex
        └── requirements_review.tex
```

### DecisionMemorandum - Brief Decisions

**Purpose:** Single-page formal records of program decisions

Template: `templates/decision_memo.tex`

### DecisionDocument - Comprehensive Decisions

**Purpose:** Multi-page program decision documentation with full traceability

**AGENTS.md:** [Documentation-Generation/DecisionDocument/AGENTS.md](Documentation-Generation/DecisionDocument/AGENTS.md) - signing workflows

Template: `templates/decision_document.tex`

**Note:** Signing scripts live here; PdfSigner.exe from [PDFSigner repo](https://github.com/brucedombrowski/PDFSigner).

### SlideDecks - Beamer Presentations

**Purpose:** Formal briefings, status updates, technical presentations

**Conventions:**
1. **Document class:** Use `beamer` class
2. **Theme:** Prefer minimal themes (e.g., `default`, `metropolis`)
3. **Frames:** One concept per frame

Example minimal slide deck:

```latex
\documentclass{beamer}
\usetheme{default}
\title{Brief Title}
\author{Author Name}
\date{\today}

\begin{document}
\frame{\titlepage}

\begin{frame}{Agenda}
\begin{itemize}
    \item Topic 1
    \item Topic 2
    \item Topic 3
\end{itemize}
\end{frame}

\begin{frame}{Key Point}
Content goes here.
\end{frame}
\end{document}
```

### MeetingAgenda - Structured Agendas

**Purpose:** Meeting preparation, action item tracking, time allocation

**Conventions:**
1. **Document class:** Use `article` class with custom formatting
2. **Structure:** Header with meeting metadata, timed agenda items, action items section
3. **Tables:** Use `tabularx` for flexible column widths

Example minimal agenda:

```latex
\documentclass[11pt]{article}
\usepackage[margin=1in]{geometry}
\usepackage{tabularx}
\usepackage{booktabs}

\begin{document}

\begin{center}
\Large\textbf{Meeting Agenda}\\[0.5em]
\normalsize Project Status Review\\
January 21, 2026 | 10:00 AM | Conference Room A
\end{center}

\vspace{1em}

\begin{tabularx}{\textwidth}{@{}lXr@{}}
\toprule
\textbf{Time} & \textbf{Topic} & \textbf{Lead} \\
\midrule
10:00 & Welcome and introductions & Chair \\
10:05 & Review previous action items & All \\
10:15 & Status update: Component A & J. Smith \\
10:30 & Status update: Component B & M. Jones \\
10:45 & Open discussion & All \\
10:55 & Next steps and action items & Chair \\
\bottomrule
\end{tabularx}

\vspace{1em}
\textbf{Attendees:} Name 1, Name 2, Name 3

\end{document}
```

## Repository-Wide Conventions

### LaTeX Style

1. **Section separators:** Use comment blocks
   ```latex
   % ============================================================================
   % SECTION NAME
   % ============================================================================
   ```

2. **Document variables:** Define as `\newcommand` at top of file under `DOCUMENT VARIABLES - EDIT THESE`

3. **Indentation:** 4 spaces for nested environments

4. **Placeholders:** Use plain text, NOT brackets `[like this]` (causes LaTeX issues)

### Date Format Placeholders

| Placeholder | Meaning | Example |
|-------------|---------|---------|
| `YYYY` | 4-digit year | 2026 |
| `MM` | 2-digit month | 01 |
| `DD` | 2-digit day | 15 |
| `MMMM` | Full month name | January |

### Build Scripts

Centralized build tools in `scripts/`:

| Script | Purpose |
|--------|---------|
| `scripts/build-tex.sh` | Build any single .tex file |
| `scripts/release.sh` | Build all documents to `dist/` |
| `scripts/merge-pdf.sh` | Merge multiple PDFs (interactive) |
| `scripts/merge-pdf.ps1` | Merge multiple PDFs (Windows PowerShell) |

**Usage:**

```bash
# Build a single document
./scripts/build-tex.sh path/to/document.tex

# Build with Word output (requires pandoc)
./scripts/build-tex.sh path/to/document.tex --docx

# Build all documents for release
./scripts/release.sh

# Clean dist/ directory
./scripts/release.sh --clean

# Merge PDFs (interactive - run from folder containing PDFs)
./scripts/merge-pdf.sh
```

**Output:**
- Single builds: PDF in same directory as source
- Release builds: All PDFs in `dist/` (organized by type)
- Merge: Creates `merged.pdf` in current directory

### Digital Signatures

Use the signing infrastructure in `Documentation-Generation/DecisionDocument/`:
- `sign.sh` / `sign.bat` / `sign.ps1`
- `PdfSigner.exe` for Windows
- PIV/CAC smart card support
- Software certificate support

### AI Agent Build Workflow

When building documents as an AI agent:

```bash
# Build a single document
./scripts/build-tex.sh Documentation-Generation/DecisionDocument/decision_document.tex

# Build all documents for release
./scripts/release.sh

# Optionally sign with source traceability
cd Documentation-Generation/DecisionDocument/
TEX_HASH=$(shasum -a 256 decision_document.tex | cut -c1-12)
./sign.sh decision_document.pdf
# ... (see Documentation-Generation/DecisionDocument/AGENTS.md for full workflow)
```

### Decision Documentation

All significant design decisions must be documented as formal Decision Memorandums:
- Format: LaTeX-generated PDF
- Location: `Decisions/`
- ID format: `DM-YYYY-NNN`
- See [Compliance-Marking/AGENTS.md](Compliance-Marking/AGENTS.md) for requirements and the Decision Memorandum Index

## Dependencies

### Required LaTeX Packages

Core packages used across components:
- `geometry`, `graphicx`, `fancyhdr`, `lastpage`
- `titlesec`, `enumitem`, `booktabs`, `longtable`
- `xcolor`, `hyperref`, `datetime2`, `tabularx`
- `pdfpages` (PDF merging)
- `tikz` (CUI layout)
- `beamer` (presentations)

### Installation

**Windows (MiKTeX):**
- Download from https://miktex.org/download
- 250MB basic installer, packages install on-demand

**macOS:**
```bash
brew install --cask mactex
```

**Linux:**
```bash
# Debian/Ubuntu
sudo apt install texlive-latex-base texlive-latex-extra texlive-fonts-recommended

# Fedora
sudo dnf install texlive-scheme-medium
```

## File Structure

```
LaTeX/
├── AGENTS.md                 # This file - repository-wide instructions
├── README.md                 # User documentation
├── .gitignore                # Git ignore rules
│
├── scripts/                  # Centralized build and utility scripts
│   ├── build-tex.sh          # Build any single .tex file
│   ├── release.sh            # Build all documents to dist/
│   ├── merge-pdf.sh          # PDF merge utility (macOS/Linux)
│   └── merge-pdf.ps1         # PDF merge utility (Windows)
│
├── assets/                   # Shared images, logos (symlinked from subfolders)
│   ├── logo.png
│   └── logo.svg
│
├── dist/                     # Build output (tracked for examples)
│   ├── decisions/
│   ├── meetings/
│   └── compliance/
│
├── Documentation-Generation/ # All document generation
│   ├── DecisionMemorandum/   # Single-page decision memos
│   ├── DecisionDocument/     # Multi-page decisions (with signing tools)
│   ├── SlideDecks/           # Beamer presentations
│   └── MeetingAgenda/        # Meeting agendas
│
├── Decisions/                # Formal Decision Memorandums (cross-cutting)
│
└── Compliance-Marking/       # Compliance templates
    ├── AGENTS.md
    └── CUI/                  # SF901 cover sheets
```

## Common Tasks

### Creating a New Component

1. Create directory with descriptive name
2. Add `AGENTS.md` with component-specific instructions
3. Add `README.md` with user documentation
4. Add build scripts following existing patterns
5. Update this root `AGENTS.md` with component entry

### Creating a New Decision Memorandum

1. Copy template from `Documentation-Generation/DecisionMemorandum/templates/decision_memo.tex`
2. Edit document variables at top of `.tex` file
3. Build: `./scripts/build-tex.sh path/to/your_memo.tex`
4. Sign with `./sign.sh` for distribution (from DecisionMemorandum/)
5. Move final PDF to `Decisions/`

### Creating a New Decision Document

1. Copy template from `Documentation-Generation/DecisionDocument/templates/decision_document.tex`
2. Edit document variables at top of `.tex` file
3. Build: `./scripts/build-tex.sh path/to/your_document.tex`
4. Sign with `./sign.sh` for distribution (from DecisionDocument/)
5. Move final PDF to `Decisions/`

### Creating a New Slide Deck

1. Copy template from `Documentation-Generation/SlideDecks/templates/`
2. Edit content in `.tex` file
3. Build: `./scripts/build-tex.sh path/to/your_slides.tex`
4. Review generated PDF
5. Optionally sign for distribution

### Creating a New Meeting Agenda

1. Copy template from `Documentation-Generation/MeetingAgenda/templates/meeting_agenda.tex`
2. Edit meeting metadata (date, time, location, attendees)
3. Fill in timed agenda items
4. Build: `./scripts/build-tex.sh path/to/your_agenda.tex`
5. Review generated PDF

### Building All Documents

```bash
# Build everything and output to dist/
./scripts/release.sh

# Clean the dist/ directory
./scripts/release.sh --clean
```

### Testing Changes

After modifying any component:
1. Build with `./scripts/build-tex.sh path/to/file.tex`
2. Verify PDF generates without errors
3. Check formatting and layout
4. Verify cross-references and page numbers
5. Run full release build: `./scripts/release.sh`
6. Test on target platform (Windows if possible)
