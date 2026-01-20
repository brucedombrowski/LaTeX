#!/bin/bash

# Build script for SF901 example cover sheets
# Compiles all .tex files in this directory using xelatex

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}==========================================${NC}"
echo -e "${CYAN}SF901 Examples Build Script${NC}"
echo -e "${CYAN}==========================================${NC}"
echo ""

# Clean up old PDFs and PNGs first
echo -e "${YELLOW}Cleaning old PDFs and PNGs...${NC}"
rm -f *.pdf *.png 2>/dev/null
echo -e "${GREEN}Done.${NC}"
echo ""

# Check if xelatex is installed
if ! command -v xelatex &> /dev/null; then
    echo -e "${RED}Error: xelatex not found. Please install TeX Live.${NC}"
    exit 1
fi

# Find all .tex files
TEX_FILES=(*.tex)

if [ ${#TEX_FILES[@]} -eq 0 ]; then
    echo -e "${RED}No .tex files found in current directory.${NC}"
    exit 1
fi

echo -e "${YELLOW}Found ${#TEX_FILES[@]} .tex files to compile:${NC}"
for f in "${TEX_FILES[@]}"; do
    echo "  - $f"
done
echo ""

# Compile each file (twice for TikZ overlay / page refs)
FAILED=()
for texfile in "${TEX_FILES[@]}"; do
    basename="${texfile%.tex}"
    echo -e "${YELLOW}Compiling $texfile...${NC}"

    # Check if file uses fontspec (requires xelatex) or can use pdflatex
    if grep -q '\\usepackage{fontspec}' "$texfile" 2>/dev/null; then
        COMPILER="xelatex"
    else
        COMPILER="pdflatex"
    fi

    if $COMPILER -interaction=nonstopmode "$texfile" > /dev/null 2>&1; then
        # Run twice to ensure TikZ overlays and page refs render correctly
        $COMPILER -interaction=nonstopmode "$texfile" > /dev/null 2>&1
        echo -e "${GREEN}  ✓ ${basename}.pdf ($COMPILER)${NC}"
    else
        echo -e "${RED}  ✗ Failed${NC}"
        FAILED+=("$texfile")
    fi
done

# Generate PNG previews
echo ""
if command -v pdftoppm &> /dev/null; then
    echo -e "${YELLOW}Generating PNG previews...${NC}"
    for texfile in "${TEX_FILES[@]}"; do
        basename="${texfile%.tex}"
        if [ -f "${basename}.pdf" ]; then
            pdftoppm -png -r 150 -singlefile "${basename}.pdf" "${basename}"
            echo -e "${GREEN}  ✓ ${basename}.png${NC}"
        fi
    done
else
    echo -e "${YELLOW}pdftoppm not found - skipping PNG generation.${NC}"
    echo -e "${YELLOW}Install poppler for PNG support: brew install poppler${NC}"
fi

# Clean up auxiliary files
echo ""
echo -e "${YELLOW}Cleaning up auxiliary files...${NC}"
rm -f *.aux *.log *.out 2>/dev/null
echo -e "${GREEN}Done.${NC}"

# Summary
echo ""
echo -e "${CYAN}==========================================${NC}"
if [ ${#FAILED[@]} -eq 0 ]; then
    echo -e "${GREEN}All ${#TEX_FILES[@]} files compiled successfully.${NC}"
else
    echo -e "${RED}${#FAILED[@]} file(s) failed to compile:${NC}"
    for f in "${FAILED[@]}"; do
        echo -e "${RED}  - $f${NC}"
    done
fi
echo -e "${CYAN}==========================================${NC}"
