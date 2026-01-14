# AGENTS.md

Instructions for AI agents working with this repository.

## Project Overview

This repository contains LaTeX templates for formal program decision documentation, adapted from NASA's Memorandum of Agreement format.

## Templates

| File | Description |
|------|-------------|
| `moa_template.tex` | Brief Memorandum of Agreement format for single-page decisions |
| `decision_document.tex` | Comprehensive decision document with full traceability |

## Build Instructions

Use the provided build scripts:

```bash
# macOS/Linux
./build.sh [moa_template|decision_document|both]

# Windows
.\build.ps1 [moa_template|decision_document|both]
```

The build scripts:
- Run pdflatex 3 times (for TOC and page references)
- Automatically clean up auxiliary files
- Prompt to install missing LaTeX packages if needed

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

## File Structure

```
DecisionDocument/
├── moa_template.tex        # Brief MOA template
├── decision_document.tex   # Comprehensive decision template
├── logo_placeholder.png    # Header logo placeholder
├── Template.docx           # Original Word template (reference)
├── build.sh                # Build script (macOS/Linux)
├── build.ps1               # Build script (Windows)
├── .gitignore              # Git ignore rules
├── README.md               # User documentation
└── AGENTS.md               # This file
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

## Testing Changes

After modifying any `.tex` file:
1. Run the build script to compile
2. Review the generated PDF for formatting issues
3. Check page numbers display correctly (especially "Page X of Y")
4. Verify all URLs are clickable in the PDF
