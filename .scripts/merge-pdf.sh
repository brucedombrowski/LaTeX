#!/bin/bash

# PDF Merge Tool - Unix/Linux
# Merges multiple PDFs using LaTeX pdfpages package
#
# Usage: ./build.sh [directory]
#   directory  Optional path to folder containing PDFs (default: current directory)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

# Remember where we started (output goes here)
START_DIR="$(pwd)"

# Working directory (default to current, or use argument)
WORK_DIR="${1:-.}"

# Validate directory exists
if [ ! -d "$WORK_DIR" ]; then
    echo -e "${RED}Error: Directory not found: $WORK_DIR${NC}"
    exit 1
fi

# Get absolute path to work dir
WORK_DIR="$(cd "$WORK_DIR" && pwd)"

# Change to working directory
cd "$WORK_DIR"

# Temporary files
TEMP_TEX="merge_temp.tex"
TEMP_AUX="merge_temp.aux"
TEMP_LOG="merge_temp.log"
OUTPUT_PDF="merged.pdf"

# Cleanup function
cleanup() {
    rm -f "$TEMP_TEX" "$TEMP_AUX" "$TEMP_LOG" "merge_temp.pdf" 2>/dev/null
}

# Cleanup on exit
trap cleanup EXIT

echo -e "${CYAN}==========================================${NC}"
echo -e "${CYAN}PDF Merge Tool${NC}"
echo -e "${CYAN}==========================================${NC}"
if [ "$WORK_DIR" != "." ]; then
    echo -e "${CYAN}Directory: $WORK_DIR${NC}"
fi
echo ""

# Check if pdflatex is installed
if ! command -v pdflatex &> /dev/null; then
    echo -e "${RED}Error: pdflatex not found.${NC}"
    echo ""
    echo "Please install LaTeX:"
    echo "  macOS:  brew install --cask mactex"
    echo "  Ubuntu: sudo apt install texlive-latex-base"
    echo "  Fedora: sudo dnf install texlive-latex"
    exit 1
fi

# Find PDF files in directory (excluding temp files and common merge outputs)
PDF_FILES=()
while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    # Skip temp files and files that look like merge outputs
    if [[ "$filename" != merge_temp* && "$filename" != *_merged.pdf && "$filename" != *_merged_*.pdf && "$filename" != "merged.pdf" ]]; then
        PDF_FILES+=("$file")
    fi
done < <(find . -maxdepth 1 -type f -iname "*.pdf" -print0 | sort -z)

# Check if we found any PDFs
if [ ${#PDF_FILES[@]} -eq 0 ]; then
    echo -e "${RED}No PDF files found in current directory.${NC}"
    echo ""
    echo "Place PDF files in the same folder as this script and run again."
    exit 1
fi

if [ ${#PDF_FILES[@]} -lt 2 ]; then
    echo -e "${YELLOW}Only one PDF found. Need at least 2 PDFs to merge.${NC}"
    echo ""
    echo "Found: ${PDF_FILES[0]}"
    exit 1
fi

# Display found PDFs
echo -e "${GREEN}Found PDFs in current directory:${NC}"
echo ""
for i in "${!PDF_FILES[@]}"; do
    num=$((i + 1))
    filename=$(basename "${PDF_FILES[$i]}")
    echo "  [$num] $filename"
done
echo ""

# Prompt for order
echo -e "Enter the order to merge (e.g., \"2 1\" or \"2,1\"):"
read -p "> " order_input

# Parse the order input (handle spaces, commas, or both)
order_input=$(echo "$order_input" | tr ',' ' ')
read -ra ORDER <<< "$order_input"

# Validate order input
if [ ${#ORDER[@]} -lt 2 ]; then
    echo -e "${RED}Error: Please specify at least 2 PDFs to merge.${NC}"
    exit 1
fi

# Validate each number
SELECTED_FILES=()
for num in "${ORDER[@]}"; do
    # Check if it's a valid number
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: '$num' is not a valid number.${NC}"
        exit 1
    fi

    # Check if it's in range
    if [ "$num" -lt 1 ] || [ "$num" -gt ${#PDF_FILES[@]} ]; then
        echo -e "${RED}Error: $num is out of range (1-${#PDF_FILES[@]}).${NC}"
        exit 1
    fi

    # Get the file (convert to 0-indexed)
    idx=$((num - 1))
    SELECTED_FILES+=("${PDF_FILES[$idx]}")
done

# Show what we're merging
echo ""
echo -e "${YELLOW}Merging PDFs in order:${NC}"
for i in "${!SELECTED_FILES[@]}"; do
    num=$((i + 1))
    filename=$(basename "${SELECTED_FILES[$i]}")
    echo "  $num. $filename"
done
echo ""

# Get the first selected file's name (without .pdf) for default naming
FIRST_FILE=$(basename "${SELECTED_FILES[0]}" .pdf)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Prompt for output filename
echo -e "Output filename options:"
echo "  [1] merged.pdf (default)"
echo "  [2] ${FIRST_FILE}_merged.pdf"
echo "  [3] ${FIRST_FILE}_merged_${TIMESTAMP}.pdf"
echo "  [4] Custom name"
echo ""
read -p "Choose [1-4] or press Enter for default: " name_choice

case "$name_choice" in
    2)
        OUTPUT_PDF="${FIRST_FILE}_merged.pdf"
        ;;
    3)
        OUTPUT_PDF="${FIRST_FILE}_merged_${TIMESTAMP}.pdf"
        ;;
    4)
        read -p "Enter filename (without .pdf): " custom_name
        if [ -z "$custom_name" ]; then
            OUTPUT_PDF="merged.pdf"
        else
            OUTPUT_PDF="${custom_name}.pdf"
        fi
        ;;
    *)
        OUTPUT_PDF="merged.pdf"
        ;;
esac

echo ""

# Generate LaTeX file
echo -e "${YELLOW}Creating $OUTPUT_PDF...${NC}"

cat > "$TEMP_TEX" << 'HEADER'
\documentclass{article}
\usepackage{pdfpages}
\begin{document}
HEADER

for file in "${SELECTED_FILES[@]}"; do
    # Get just the filename without path
    filename=$(basename "$file")
    # Escape special LaTeX characters in filename
    escaped_filename=$(echo "$filename" | sed 's/_/\\_/g')
    echo "\\includepdf[pages=-]{$filename}" >> "$TEMP_TEX"
done

echo '\end{document}' >> "$TEMP_TEX"

# Run pdflatex
if pdflatex -interaction=nonstopmode "$TEMP_TEX" > /dev/null 2>&1; then
    # Move output to the directory where script was run from
    mv "merge_temp.pdf" "$START_DIR/$OUTPUT_PDF"
    echo -e "${GREEN}Done! Output: $START_DIR/$OUTPUT_PDF${NC}"
else
    echo -e "${RED}Error: PDF merge failed.${NC}"
    echo ""
    echo "Check that all input PDFs are valid and readable."
    echo "Run with verbose output for details:"
    echo "  pdflatex $TEMP_TEX"
    exit 1
fi

echo ""
echo -e "${CYAN}==========================================${NC}"
