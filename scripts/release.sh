#!/bin/bash

# ============================================================================
# RELEASE BUILD SCRIPT
# ============================================================================
# Builds all LaTeX documents and outputs to dist/ directory.
# Usage: ./scripts/release.sh [--clean]
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$REPO_ROOT/dist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "LaTeX Toolkit Release Build"
echo "=========================================="

# Check if pdflatex is installed
if ! command -v pdflatex &> /dev/null; then
    echo -e "${RED}Error: pdflatex not found. Please install TeX Live.${NC}"
    exit 1
fi

# Check for PdfSigner.exe updates (non-blocking)
check_pdfsigner_update() {
    local BIN_DIR="$REPO_ROOT/bin"
    local PDFSIGNER_URL="https://api.github.com/repos/brucedombrowski/PDFSigner/releases/latest"

    # Skip if no internet or curl not available
    if ! command -v curl &> /dev/null; then
        return
    fi

    echo -e "${YELLOW}Checking for PdfSigner.exe updates...${NC}"

    # Get latest release info (timeout after 5 seconds)
    local LATEST_INFO=$(curl -s --max-time 5 "$PDFSIGNER_URL" 2>/dev/null)
    if [ -z "$LATEST_INFO" ]; then
        echo -e "${YELLOW}  Could not reach GitHub (offline or timeout)${NC}"
        return
    fi

    # Extract latest version tag
    local LATEST_VERSION=$(echo "$LATEST_INFO" | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -z "$LATEST_VERSION" ]; then
        return
    fi

    # Check if PdfSigner.exe exists locally
    if [ ! -f "$BIN_DIR/PdfSigner.exe" ]; then
        echo -e "${YELLOW}  PdfSigner.exe not found in bin/${NC}"
        echo -e "${YELLOW}  Download latest ($LATEST_VERSION) from:${NC}"
        echo -e "${BLUE}  https://github.com/brucedombrowski/PDFSigner/releases/latest${NC}"
    else
        echo -e "${GREEN}  Latest release: $LATEST_VERSION${NC}"
        echo -e "${GREEN}  PdfSigner.exe found in bin/${NC}"
    fi
}

# Run update check (don't fail if it errors)
check_pdfsigner_update || true

# Parse arguments
CLEAN_ONLY=0
for arg in "$@"; do
    if [ "$arg" = "--clean" ]; then
        CLEAN_ONLY=1
    fi
done

# Clean dist directory
if [ -d "$DIST_DIR" ]; then
    echo -e "${YELLOW}Cleaning existing dist/ directory...${NC}"
    rm -rf "$DIST_DIR"
fi

if [ $CLEAN_ONLY -eq 1 ]; then
    echo -e "${GREEN}Clean complete.${NC}"
    exit 0
fi

# Create dist directory structure
mkdir -p "$DIST_DIR"/{decisions,meetings,compliance}

# Track build statistics
BUILT=0
FAILED=0
FAILED_FILES=""

# Build function
build_tex() {
    local tex_file="$1"
    local output_dir="$2"
    local basename=$(basename "$tex_file" .tex)
    local dirname=$(dirname "$tex_file")

    echo ""
    echo -e "${BLUE}Building: ${tex_file#$REPO_ROOT/}${NC}"

    cd "$dirname"

    # Check if file uses fontspec (requires xelatex)
    # Also check if it inputs SF901-template which uses fontspec
    if grep -q '\\usepackage{fontspec}' "$tex_file" 2>/dev/null || \
       grep -q 'SF901-template' "$tex_file" 2>/dev/null; then
        COMPILER="xelatex"
    else
        COMPILER="pdflatex"
    fi

    if $COMPILER -interaction=nonstopmode "${basename}.tex" > /dev/null 2>&1; then
        $COMPILER -interaction=nonstopmode "${basename}.tex" > /dev/null 2>&1

        # Copy PDF to dist
        if [ -f "${basename}.pdf" ]; then
            cp "${basename}.pdf" "$output_dir/"
            echo -e "${GREEN}  ✓ ${basename}.pdf ($COMPILER)${NC}"
            ((BUILT++))
        fi

        # Clean auxiliary files
        rm -f *.aux *.log *.out *.toc *.fdb_latexmk *.fls *.nav *.snm *.vrb
    else
        echo -e "${RED}  ✗ Failed to build ${basename}.tex ($COMPILER)${NC}"
        ((FAILED++))
        FAILED_FILES="$FAILED_FILES\n  - ${tex_file#$REPO_ROOT/}"
        # Clean auxiliary files even on failure
        rm -f *.aux *.log *.out *.toc *.fdb_latexmk *.fls *.nav *.snm *.vrb
    fi

    cd "$REPO_ROOT"
}

# Build function for in-place builds (keeps PDF in source dir, generates PNG)
build_tex_inplace() {
    local tex_file="$1"
    local basename=$(basename "$tex_file" .tex)
    local dirname=$(dirname "$tex_file")

    echo ""
    echo -e "${BLUE}Building: ${tex_file#$REPO_ROOT/}${NC}"

    cd "$dirname"

    # Check if file uses fontspec (requires xelatex)
    # Also check if it inputs SF901-template which uses fontspec
    if grep -q '\\usepackage{fontspec}' "$tex_file" 2>/dev/null || \
       grep -q 'SF901-template' "$tex_file" 2>/dev/null; then
        COMPILER="xelatex"
    else
        COMPILER="pdflatex"
    fi

    if $COMPILER -interaction=nonstopmode "${basename}.tex" > /dev/null 2>&1; then
        $COMPILER -interaction=nonstopmode "${basename}.tex" > /dev/null 2>&1

        if [ -f "${basename}.pdf" ]; then
            echo -e "${GREEN}  ✓ ${basename}.pdf ($COMPILER)${NC}"
            ((BUILT++))

            # Generate PNG if pdftoppm is available
            if command -v pdftoppm &> /dev/null; then
                pdftoppm -png -r 150 -singlefile "${basename}.pdf" "${basename}"
                echo -e "${GREEN}  ✓ ${basename}.png${NC}"
            fi
        fi

        # Clean auxiliary files
        rm -f *.aux *.log *.out *.toc *.fdb_latexmk *.fls *.nav *.snm *.vrb
    else
        echo -e "${RED}  ✗ Failed to build ${basename}.tex ($COMPILER)${NC}"
        ((FAILED++))
        FAILED_FILES="$FAILED_FILES\n  - ${tex_file#$REPO_ROOT/}"
        # Clean auxiliary files even on failure
        rm -f *.aux *.log *.out *.toc *.fdb_latexmk *.fls *.nav *.snm *.vrb
    fi

    cd "$REPO_ROOT"
}

echo ""
echo -e "${YELLOW}Building Decision Documents...${NC}"

# Decision Memorandum
if [ -f "$REPO_ROOT/Documentation-Generation/DecisionMemorandum/templates/decision_memo.tex" ]; then
    build_tex "$REPO_ROOT/Documentation-Generation/DecisionMemorandum/templates/decision_memo.tex" "$DIST_DIR/decisions"
fi

# Decision Document
if [ -f "$REPO_ROOT/Documentation-Generation/DecisionDocument/templates/decision_document.tex" ]; then
    build_tex "$REPO_ROOT/Documentation-Generation/DecisionDocument/templates/decision_document.tex" "$DIST_DIR/decisions"
fi

echo ""
echo -e "${YELLOW}Building Meeting Agendas...${NC}"

# Meeting Agenda Template
if [ -f "$REPO_ROOT/Documentation-Generation/MeetingAgenda/templates/meeting_agenda.tex" ]; then
    build_tex "$REPO_ROOT/Documentation-Generation/MeetingAgenda/templates/meeting_agenda.tex" "$DIST_DIR/meetings"
fi

# Meeting Agenda Examples
for tex_file in "$REPO_ROOT/Documentation-Generation/MeetingAgenda/examples"/*.tex; do
    [ -e "$tex_file" ] && build_tex "$tex_file" "$DIST_DIR/meetings"
done

echo ""
echo -e "${YELLOW}Building Compliance Documents...${NC}"

# CUI Cover Sheets (build in-place with PNG preview)
# Skip template files (they are meant to be \input, not compiled directly)
for tex_file in "$REPO_ROOT/Compliance-Marking/CUI"/*.tex; do
    [ -e "$tex_file" ] || continue
    [[ "$tex_file" == *"-template.tex" ]] && continue
    build_tex_inplace "$tex_file"
done

# CUI Examples (build in-place with PNG preview)
for tex_file in "$REPO_ROOT/Compliance-Marking/CUI/Examples"/*.tex; do
    [ -e "$tex_file" ] && build_tex_inplace "$tex_file"
done

# Create CUI Cover Packet Example (merged PDF) for dist
echo ""
echo -e "${BLUE}Creating CUI Cover Packet Example...${NC}"
CUI_EXAMPLES_DIR="$REPO_ROOT/Compliance-Marking/CUI/Examples"
if [ -f "$CUI_EXAMPLES_DIR/CUI_Introduction.pdf" ] && \
   [ -f "$CUI_EXAMPLES_DIR/SF901_BASIC.pdf" ] && \
   [ -f "$CUI_EXAMPLES_DIR/SF901_CTI.pdf" ] && \
   [ -f "$CUI_EXAMPLES_DIR/SF901_PROCURE.pdf" ] && \
   [ -f "$CUI_EXAMPLES_DIR/SF901_PRVCY.pdf" ]; then
    cd "$CUI_EXAMPLES_DIR"
    cat > merge_temp.tex << 'EOF'
\documentclass{article}
\usepackage{pdfpages}
\begin{document}
\includepdf[pages=-]{CUI_Introduction.pdf}
\includepdf[pages=-]{SF901_PROCURE.pdf}
\includepdf[pages=-]{SF901_BASIC.pdf}
\includepdf[pages=-]{SF901_PRVCY.pdf}
\includepdf[pages=-]{SF901_CTI.pdf}
\end{document}
EOF
    if pdflatex -interaction=nonstopmode merge_temp.tex > /dev/null 2>&1; then
        cp merge_temp.pdf "$DIST_DIR/compliance/CUI_Cover_Packet_Example.pdf"
        echo -e "${GREEN}  ✓ CUI_Cover_Packet_Example.pdf${NC}"
        ((BUILT++))
    else
        echo -e "${RED}  ✗ Failed to create CUI_Cover_Packet_Example.pdf${NC}"
        ((FAILED++))
    fi
    rm -f merge_temp.*
    cd "$REPO_ROOT"
else
    echo -e "${YELLOW}  Skipping CUI Cover Packet - not all example PDFs available${NC}"
fi

# Clean up auxiliary files across the entire repo
echo ""
echo -e "${YELLOW}Cleaning auxiliary files across repo...${NC}"
find "$REPO_ROOT" -type f \( -name "*.aux" -o -name "*.log" -o -name "*.out" -o -name "*.toc" \
    -o -name "*.fdb_latexmk" -o -name "*.fls" -o -name "*.nav" -o -name "*.snm" -o -name "*.vrb" \
    -o -name "*.synctex.gz" -o -name "*.bbl" -o -name "*.blg" \) -delete 2>/dev/null
echo -e "${GREEN}Auxiliary files cleaned.${NC}"

# Summary
echo ""
echo "=========================================="
echo "Release Build Complete"
echo "=========================================="
echo -e "${GREEN}Built: $BUILT documents${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED documents${NC}"
    echo -e "${RED}Failed files:${FAILED_FILES}${NC}"
fi
echo ""
echo "Output directory: $DIST_DIR/"
echo ""

# List built files
echo "Built documents:"
find "$DIST_DIR" -name "*.pdf" -type f | while read -r f; do
    echo "  ${f#$REPO_ROOT/}"
done

echo ""
echo "=========================================="
