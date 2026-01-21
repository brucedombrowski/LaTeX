# PDF Tools

Simple PDF manipulation tools for LaTeX users. Merge multiple PDFs with an easy interactive workflow.

## Quick Start (Windows)

### Prerequisites

- **LaTeX installed** (MiKTeX recommended)
  - Download from: https://miktex.org/download
  - The `pdfpages` package is included by default

### Merge PDFs

1. Create a new folder anywhere on your computer
2. Copy `merge-pdf.ps1` into that folder
3. Copy the PDFs you want to merge into the same folder
4. Right-click `merge-pdf.ps1` and select "Run with PowerShell"
5. Follow the prompts to select merge order
6. Output: `merged.pdf`

```
MyFolder/
├── merge-pdf.ps1     # The script
├── report.pdf        # Your first PDF
├── appendix.pdf      # Your second PDF
└── merged.pdf        # Output (created by script)
```

## Quick Start (macOS/Linux)

```bash
# Make executable (one time)
chmod +x merge-pdf.sh

# Run
./merge-pdf.sh
```

## Usage

### Interactive Mode

Run the script with no arguments. It will:

1. Find all PDFs in the current directory
2. Display them with numbers
3. Ask you to specify the order
4. Create `merged.pdf`

Example session:

```
==========================================
PDF Merge Tool
==========================================

Found PDFs in current directory:
  [1] appendix.pdf
  [2] report.pdf

Enter the order to merge (e.g., "2 1" or "2,1"):
> 2 1

Merging PDFs in order:
  1. report.pdf
  2. appendix.pdf

Creating merged.pdf...
Done! Output: merged.pdf
```

### Specifying Order

You can enter the order in several formats:
- Space-separated: `2 1 3`
- Comma-separated: `2,1,3`
- Mixed: `2, 1, 3`

## How It Works

The tool uses LaTeX's `pdfpages` package to merge PDFs. It:

1. Generates a temporary `.tex` file
2. Runs `pdflatex` to create the merged PDF
3. Cleans up temporary files

This approach requires no additional software beyond your existing LaTeX installation.

## Troubleshooting

### "pdflatex not found"

LaTeX is not installed or not in PATH.

**Windows:** Install MiKTeX from https://miktex.org/download

**macOS:** Install MacTeX or use Homebrew:
```bash
brew install --cask mactex
```

**Linux:**
```bash
sudo apt install texlive-latex-base  # Debian/Ubuntu
sudo dnf install texlive-latex       # Fedora
```

### "No PDF files found"

Make sure:
- PDFs are in the same folder as the script
- Files have `.pdf` extension (case-insensitive)
- Files are not hidden (no `.` prefix)

### "Package pdfpages not found"

The `pdfpages` package should be included with standard LaTeX installations.

**MiKTeX:** Will auto-install on first use (requires internet on first run)

**TeX Live:**
```bash
sudo tlmgr install pdfpages
```

## Limitations

- Requires LaTeX installation
- PDFs must be valid/readable
- Very large PDFs may require increased memory limits

## Files

```
PdfTools/
├── merge-pdf.ps1     # Windows PowerShell script
├── merge-pdf.sh      # macOS/Linux script
├── README.md         # This file
├── AGENTS.md         # AI agent instructions
└── Examples/         # Sample CUI cover sheets for testing
    ├── build_tex_to_pdf.sh   # Compiles examples, generates PNGs
    ├── CUI_Introduction.tex  # Title page for document package
    ├── SF901_BASIC.tex       # CUI//BASIC example
    ├── SF901_CTI.tex         # CUI//SP-CTI example
    ├── SF901_PROCURE.tex     # CUI//SP-PROCURE example
    └── SF901_PRVCY.tex       # CUI//SP-PRVCY example
```

## Examples

The `Examples/` folder contains sample SF901 CUI cover sheets for testing the merge functionality. These are derived from the canonical template at [Compliance-Marking/CUI/SF901.tex](../Compliance-Marking/CUI/SF901.tex):

| File | CUI Category | Example Document |
|------|--------------|------------------|
| CUI_Introduction | — | Title page for Example Aerospace Corp |
| SF901_BASIC | CUI//BASIC | Internal Policy Document |
| SF901_CTI | CUI//SP-CTI | Payload Software Interface Control Document |
| SF901_PROCURE | CUI//SP-PROCURE | Source Selection Evaluation Report |
| SF901_PRVCY | CUI//SP-PRVCY | Personnel Security Investigation Report |

To test:
```bash
cd Examples
./build_tex_to_pdf.sh   # Compile all .tex files and generate PNGs
cd ..
./merge-pdf.sh          # Merge the PDFs interactively
```

## Future Features

- PDF splitting (extract specific pages)
- Page reordering within a single PDF
- Batch mode for automation
- Custom output filename
