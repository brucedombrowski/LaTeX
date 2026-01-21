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
| **Decision Documents** | Documentation-Generation/DecisionDocument/ | Production |
| **Slide Decks** | Documentation-Generation/SlideDecks/ | Planned |
| **Meeting Agendas** | Documentation-Generation/MeetingAgenda/ | Planned |
| **CUI Cover Sheets** | Compliance-Marking/CUI/ | Production |
| **Export Markings** | Compliance-Marking/Export/ | Planned |
| **PDF Merging** | PdfTools/ | Production |
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
| [assets/](assets/) | Shared images and logos | — |
| [Documentation-Generation/](Documentation-Generation/) | Document templates (decisions, slides, agendas) | See below |
| [Decisions/](Decisions/) | Formal Decision Memorandums archive | — |
| [Compliance-Marking/](Compliance-Marking/) | CUI cover pages, export markings, security compliance | [Compliance-Marking/AGENTS.md](Compliance-Marking/AGENTS.md) |
| [PdfTools/](PdfTools/) | PDF manipulation tools (merge, split) | [PdfTools/AGENTS.md](PdfTools/AGENTS.md) |

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

```
Documentation-Generation/
├── DecisionDocument/         # Formal program decisions
│   ├── AGENTS.md             # Component-specific instructions
│   ├── README.md             # User documentation
│   ├── decision_memo.tex     # Brief single-page memo
│   ├── decision_document.tex # Comprehensive multi-page document
│   ├── build.sh / build.ps1 / build.bat
│   ├── sign.sh / sign.ps1 / sign.bat
│   └── PdfSigner.exe         # Windows signing tool
│
├── SlideDecks/               # Presentation slide decks (Beamer)
│   ├── build.sh              # Unix/Linux build script
│   ├── build.ps1             # Windows PowerShell build script
│   ├── templates/            # Reusable slide templates
│   │   └── standard_brief.tex
│   └── examples/             # Example presentations
│
└── MeetingAgenda/            # Meeting agenda documents
    ├── build.sh              # Unix/Linux build script
    ├── build.ps1             # Windows PowerShell build script
    ├── templates/            # Reusable agenda templates
    │   └── standard_agenda.tex
    └── examples/             # Example agendas
```

### DecisionDocument - Formal Decisions

**Purpose:** Program decision documentation with digital signatures and full traceability

**AGENTS.md:** [Documentation-Generation/DecisionDocument/AGENTS.md](Documentation-Generation/DecisionDocument/AGENTS.md)

Templates:
- `decision_memo.tex` - Brief single-page Decision Memorandum
- `decision_document.tex` - Comprehensive multi-page Program Decision Document

### SlideDecks - Beamer Presentations

**Purpose:** Formal briefings, status updates, technical presentations

**Conventions:**
1. **Document class:** Use `beamer` class
2. **Theme:** Prefer minimal themes (e.g., `default`, `metropolis`)
3. **Frames:** One concept per frame
4. **Build scripts:** Follow existing patterns from DecisionDocument/

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

All components follow the same patterns:
- `build.sh` for Unix/Linux (bash)
- `build.ps1` for Windows PowerShell
- `build.bat` for Windows batch (double-click friendly)

Scripts should:
- Check for LaTeX installation
- Run compiler appropriate number of times (typically 2-3 for references)
- Clean up auxiliary files (`.aux`, `.log`, `.out`, `.toc`, etc.)
- Provide clear error messages

### Digital Signatures

Use the signing infrastructure in `Documentation-Generation/DecisionDocument/`:
- `sign.sh` / `sign.bat` / `sign.ps1`
- `PdfSigner.exe` for Windows
- PIV/CAC smart card support
- Software certificate support

### AI Agent Build Workflow

When building documents as an AI agent:

```bash
# Navigate to component directory
cd Documentation-Generation/DecisionDocument/

# Build PDF(s)
./build.sh

# Optionally sign with source traceability
TEX_HASH=$(shasum -a 256 document.tex | cut -c1-12)
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
├── assets/                   # Shared images, logos (symlinked from subfolders)
│   ├── logo.png
│   └── logo.svg
│
├── Documentation-Generation/ # All document generation
│   ├── DecisionDocument/     # Formal decisions (with signing)
│   ├── SlideDecks/           # Beamer presentations
│   └── MeetingAgenda/        # Meeting agendas
│
├── Decisions/                # Formal Decision Memorandums (cross-cutting)
│
├── Compliance-Marking/               # Compliance templates
│   ├── AGENTS.md
│   ├── CUI/                  # SF901 cover sheets
│   ├── Export/               # Export control (future)
│   └── Security/             # Security compliance (future)
│
└── PdfTools/                 # PDF manipulation
    ├── AGENTS.md
    ├── README.md
    ├── build.sh / build.ps1
    └── Examples/
```

## Common Tasks

### Creating a New Component

1. Create directory with descriptive name
2. Add `AGENTS.md` with component-specific instructions
3. Add `README.md` with user documentation
4. Add build scripts following existing patterns
5. Update this root `AGENTS.md` with component entry

### Creating a New Decision Document

1. Copy template from `Documentation-Generation/DecisionDocument/`
2. Edit document variables at top of `.tex` file
3. Run `./build.sh` from `Documentation-Generation/DecisionDocument/`
4. Sign with `./sign.sh` for distribution

### Creating a New Slide Deck

1. Copy template from `Documentation-Generation/SlideDecks/templates/`
2. Edit content in `.tex` file
3. Run `./build.sh` or `.\build.ps1` from `Documentation-Generation/SlideDecks/`
4. Review generated PDF
5. Optionally sign for distribution

### Creating a New Meeting Agenda

1. Copy template from `Documentation-Generation/MeetingAgenda/templates/`
2. Edit meeting metadata (date, time, location, attendees)
3. Fill in timed agenda items
4. Run `./build.sh` or `.\build.ps1` from `Documentation-Generation/MeetingAgenda/`
5. Review generated PDF

### Testing Changes

After modifying any component:
1. Run the build script
2. Verify PDF generates without errors
3. Check formatting and layout
4. Verify cross-references and page numbers
5. Test on target platform (Windows if possible)
