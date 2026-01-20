#!/bin/bash
# Build script for SF901 CUI Cover Sheet LaTeX template
# Requires xelatex (part of TeX Live or MacTeX)
# Requires pdftoppm (from poppler) for PNG conversion

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Build SF901.tex
echo "Building SF901.tex..."
xelatex -interaction=nonstopmode SF901.tex

# Build test-margin.tex if it exists
if [ -f "test-margin.tex" ]; then
    echo "Building test-margin.tex..."
    xelatex -interaction=nonstopmode test-margin.tex
fi

# Clean up auxiliary files
rm -f *.aux *.log *.out

# Generate PNG comparisons
echo "Generating PNG files for comparison..."

if command -v pdftoppm &> /dev/null; then
    # Convert original template to PNG
    if [ -f "SF901-Official-Template.pdf" ]; then
        pdftoppm -png -r 150 SF901-Official-Template.pdf original
        echo "  -> original-1.png"
    fi

    # Convert our SF901 to PNG
    if [ -f "SF901.pdf" ]; then
        pdftoppm -png -r 150 SF901.pdf sf901-output
        echo "  -> sf901-output-1.png"
    fi

    # Convert test-margin to PNG
    if [ -f "test-margin.pdf" ]; then
        pdftoppm -png -r 150 test-margin.pdf test-margin-output
        echo "  -> test-margin-output-1.png"
    fi
else
    echo "Warning: pdftoppm not found. Install poppler for PNG conversion:"
    echo "  brew install poppler"
fi

echo "Done!"
