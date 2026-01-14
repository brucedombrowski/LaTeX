#!/bin/bash

# Build script for Decision Document LaTeX templates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Decision Document Build Script"
echo "=========================================="

# Check if pdflatex is installed
if ! command -v pdflatex &> /dev/null; then
    echo -e "${RED}Error: pdflatex not found. Please install TeX Live.${NC}"
    exit 1
fi

# Determine which document to build
DOC="$1"
if [ -z "$DOC" ]; then
    echo ""
    echo "Which document would you like to build?"
    echo "  1) moa_template.tex (Memorandum of Agreement - brief)"
    echo "  2) decision_document.tex (Comprehensive Decision Document)"
    echo "  3) Both"
    echo ""
    read -p "Enter choice [1-3]: " choice
    case $choice in
        1) DOC="moa_template" ;;
        2) DOC="decision_document" ;;
        3) DOC="both" ;;
        *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
    esac
fi

# Check for required packages and install if missing
PACKAGES="titlesec enumitem booktabs longtable lastpage datetime2 tabularx"

install_packages() {
    echo -e "${YELLOW}Updating tlmgr...${NC}"
    sudo tlmgr update --self

    echo -e "${YELLOW}Installing missing packages...${NC}"
    sudo tlmgr install $PACKAGES
}

# Compile a single document
compile_doc() {
    local docname=$1
    echo ""
    echo -e "${YELLOW}Building ${docname}.tex...${NC}"

    if pdflatex -interaction=nonstopmode "${docname}.tex" > /dev/null 2>&1; then
        echo -e "${YELLOW}Compiling (pass 2 of 3)...${NC}"
        pdflatex -interaction=nonstopmode "${docname}.tex" > /dev/null 2>&1
        echo -e "${YELLOW}Compiling (pass 3 of 3)...${NC}"
        pdflatex -interaction=nonstopmode "${docname}.tex" > /dev/null 2>&1
        echo -e "${GREEN}${docname}.pdf built successfully!${NC}"
        return 0
    else
        return 1
    fi
}

# Main build logic
build_failed=0

if [ "$DOC" = "both" ]; then
    for doc in moa_template decision_document; do
        if ! compile_doc "$doc"; then
            build_failed=1
            break
        fi
    done
else
    if ! compile_doc "$DOC"; then
        build_failed=1
    fi
fi

# Handle build failure
if [ $build_failed -eq 1 ]; then
    echo -e "${RED}Compilation failed. Missing packages may be needed.${NC}"
    echo ""
    read -p "Would you like to install missing packages? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_packages
        echo ""
        # Retry build
        if [ "$DOC" = "both" ]; then
            for doc in moa_template decision_document; do
                compile_doc "$doc"
            done
        else
            compile_doc "$DOC"
        fi
    else
        echo -e "${YELLOW}Please run the following commands manually:${NC}"
        echo "  sudo tlmgr update --self"
        echo "  sudo tlmgr install $PACKAGES"
        exit 1
    fi
fi

# Clean up auxiliary files by default
echo ""
echo -e "${YELLOW}Cleaning up auxiliary files...${NC}"
rm -f *.aux *.log *.out *.toc *.fdb_latexmk *.fls
echo -e "${GREEN}Auxiliary files cleaned.${NC}"

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="
