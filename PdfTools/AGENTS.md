# AGENTS.md

Instructions for AI agents working with this repository.

## Project Overview

PDF manipulation tools for LaTeX workflows. Provides user-friendly scripts for merging, splitting, and manipulating PDF documents generated from LaTeX or other sources.

## Target Environment

Cross-platform support:
- **Windows 11** (primary target) - Airgapped environments with security hardening
- **macOS/Linux** - Development and secondary deployment

Users are expected to have LaTeX already installed (MiKTeX on Windows, TeX Live on Unix/Linux).

## Tools

| Tool | Description | Status |
|------|-------------|--------|
| PDF Merge | Combine multiple PDFs into one | Implemented |
| PDF Split | Extract pages from PDF | Future |
| PDF Reorder | Rearrange pages | Future |

## User Workflow (Windows)

The primary use case is a Windows user who:
1. Downloads a single script (`build.ps1`)
2. Creates a folder with the script and their PDFs
3. Runs the script
4. Interactively selects PDF order
5. Gets a merged output PDF

```
UserFolder/
├── build.ps1        # Downloaded script
├── document1.pdf    # User's first PDF
├── document2.pdf    # User's second PDF
└── merged.pdf       # Output (generated)
```

## Technical Requirements

### PDF Merging

**Dependencies:**
- **Windows:** Uses `pdflatex` with the `pdfpages` package (included with MiKTeX)
- **Unix/Linux:** Uses `pdflatex` with the `pdfpages` package (included with TeX Live)

No additional tools required beyond the LaTeX installation users already have.

### LaTeX-Based Approach

Uses a dynamically generated `.tex` file with the `pdfpages` package:

```latex
\documentclass{article}
\usepackage{pdfpages}
\begin{document}
\includepdf[pages=-]{document1.pdf}
\includepdf[pages=-]{document2.pdf}
\end{document}
```

**Advantages:**
- No additional dependencies beyond LaTeX
- Works on airgapped systems
- Consistent with the LaTeX ecosystem
- Handles large PDFs reliably

## Script Behavior

### Interactive Mode (Default)

1. Script scans current directory for `.pdf` files
2. Lists found PDFs with numbers
3. Prompts user to enter order (e.g., "2 1 3" or "2,1,3")
4. Generates merged PDF
5. Cleans up temporary files

### Future Enhancements

- Support for unlimited PDFs (currently 2+)
- Page range selection per PDF
- Output filename customization
- Batch mode for scripting

## Code Style Guidelines

### PowerShell Conventions

1. Use `Write-Host` with `-ForegroundColor` for colored output
2. Use `$ErrorActionPreference = "Stop"` for fail-fast behavior
3. Validate user input with clear error messages
4. Clean up temporary files on success and failure

### Bash Conventions

1. Use `set -e` for fail-fast behavior
2. Use color variables for consistent output styling
3. Use `trap` for cleanup on exit
4. Quote all variables to handle spaces in filenames

## File Structure

```
PdfTools/
├── build.sh          # Unix/Linux merge script
├── build.ps1         # Windows PowerShell merge script
├── release.sh        # Cleans generated files for git commits
├── README.md         # User documentation
├── AGENTS.md         # This file
└── Examples/         # Sample CUI cover sheets
    ├── build_tex_to_pdf.sh   # Compiles .tex files, generates PNGs
    ├── CUI_Introduction.tex  # Title page for document package
    ├── SF901_BASIC.tex       # CUI//BASIC example
    ├── SF901_CTI.tex         # CUI//SP-CTI example
    ├── SF901_PROCURE.tex     # CUI//SP-PROCURE example
    └── SF901_PRVCY.tex       # CUI//SP-PRVCY example
```

## Testing

After modifying scripts:

1. Create a test folder with 2-3 sample PDFs
2. Run the script and verify:
   - PDFs are detected correctly
   - Interactive ordering works
   - Output PDF contains all pages in correct order
   - Temporary files are cleaned up

Test with PDFs containing:
- Different page sizes
- Spaces in filenames
- Unicode characters in filenames (Windows)

## Dependencies

Required LaTeX packages:
- `pdfpages` (typically pre-installed with MiKTeX/TeX Live)

The scripts check for `pdflatex` and provide installation guidance if missing.
