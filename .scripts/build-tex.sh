#!/bin/bash

# ============================================================================
# UNIFIED BUILD SCRIPT
# ============================================================================
# Builds any LaTeX document in the repository.
# Usage: ./scripts/build.sh [path/to/file.tex] [--docx]
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

echo "=========================================="
echo "LaTeX Toolkit Build Script"
echo "=========================================="

# Check if pdflatex is installed
if ! command -v pdflatex &> /dev/null; then
    echo -e "${RED}Error: pdflatex not found. Please install TeX Live.${NC}"
    exit 1
fi

# Parse arguments
TEX_FILE=""
GENERATE_DOCX=0
for arg in "$@"; do
    if [ "$arg" = "--docx" ]; then
        GENERATE_DOCX=1
    elif [ -z "$TEX_FILE" ] && [[ "$arg" == *.tex ]]; then
        TEX_FILE="$arg"
    fi
done

# If no file specified, show available files
if [ -z "$TEX_FILE" ]; then
    echo ""
    echo "Available .tex files:"
    echo ""

    # Find all .tex files in templates and examples
    find "$REPO_ROOT" -name "*.tex" -type f | while read -r f; do
        # Get path relative to repo root
        relpath="${f#$REPO_ROOT/}"
        echo "  $relpath"
    done

    echo ""
    read -p "Enter filename to build (relative to repo root): " TEX_FILE
fi

# Handle relative paths
if [[ "$TEX_FILE" != /* ]]; then
    TEX_FILE="$REPO_ROOT/$TEX_FILE"
fi

# Verify file exists
if [ ! -f "$TEX_FILE" ]; then
    echo -e "${RED}Error: File not found: $TEX_FILE${NC}"
    exit 1
fi

# Get base name and directory
BASENAME=$(basename "$TEX_FILE" .tex)
DIRNAME=$(dirname "$TEX_FILE")

# Change to directory containing the file
cd "$DIRNAME"

# Compile the document
compile_doc() {
    echo ""
    echo -e "${YELLOW}Building ${BASENAME}.tex...${NC}"

    if pdflatex -interaction=nonstopmode "${BASENAME}.tex" > /dev/null 2>&1; then
        echo -e "${YELLOW}Compiling (pass 2 of 3)...${NC}"
        pdflatex -interaction=nonstopmode "${BASENAME}.tex" > /dev/null 2>&1
        echo -e "${YELLOW}Compiling (pass 3 of 3)...${NC}"
        pdflatex -interaction=nonstopmode "${BASENAME}.tex" > /dev/null 2>&1
        echo -e "${GREEN}${BASENAME}.pdf built successfully!${NC}"
        return 0
    else
        echo -e "${RED}Compilation failed.${NC}"
        echo -e "${YELLOW}Running verbose compile for debugging...${NC}"
        pdflatex -interaction=nonstopmode "${BASENAME}.tex"
        return 1
    fi
}

# Convert LaTeX to Word using pandoc
convert_to_docx() {
    if ! command -v pandoc &> /dev/null; then
        echo -e "${YELLOW}pandoc not found. Install with: brew install pandoc${NC}"
        echo -e "${YELLOW}Skipping .docx generation.${NC}"
        return 1
    fi

    echo -e "${YELLOW}Converting ${BASENAME}.tex to Word...${NC}"

    # Create temp file with DRAFT notice prepended
    local temp_file=$(mktemp)
    sed 's/\\begin{document}/\\begin{document}\n\n\\begin{center}\\textbf{\\Large *** DRAFT - FOR REVIEW ONLY ***}\\end{center}\n/' \
        "${BASENAME}.tex" > "$temp_file"

    if pandoc "$temp_file" -o "${BASENAME}.docx" \
        --from=latex \
        --to=docx \
        --standalone 2>/dev/null; then
        echo -e "${GREEN}${BASENAME}.docx created successfully!${NC}"
        rm -f "$temp_file"
        return 0
    else
        echo -e "${RED}Failed to convert ${BASENAME}.tex to Word.${NC}"
        rm -f "$temp_file"
        return 1
    fi
}

# Run compilation
compile_doc

# Generate Word document if --docx flag was passed
if [ $GENERATE_DOCX -eq 1 ]; then
    echo ""
    convert_to_docx
fi

# Clean up auxiliary files
echo ""
print_warning "Cleaning up auxiliary files..."
cleanup_aux_files "."
print_success "Auxiliary files cleaned."

echo ""
echo "=========================================="
echo "Done! Output: ${DIRNAME}/${BASENAME}.pdf"
echo "=========================================="
