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

    if pdflatex -interaction=nonstopmode "${basename}.tex" > /dev/null 2>&1; then
        pdflatex -interaction=nonstopmode "${basename}.tex" > /dev/null 2>&1
        pdflatex -interaction=nonstopmode "${basename}.tex" > /dev/null 2>&1

        # Copy PDF to dist
        if [ -f "${basename}.pdf" ]; then
            cp "${basename}.pdf" "$output_dir/"
            echo -e "${GREEN}  ✓ ${basename}.pdf${NC}"
            ((BUILT++))
        fi

        # Clean auxiliary files
        rm -f *.aux *.log *.out *.toc *.fdb_latexmk *.fls *.nav *.snm *.vrb
    else
        echo -e "${RED}  ✗ Failed to build ${basename}.tex${NC}"
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

# CUI Cover Sheets
for tex_file in "$REPO_ROOT/Compliance-Marking/CUI"/*.tex; do
    [ -e "$tex_file" ] && build_tex "$tex_file" "$DIST_DIR/compliance"
done

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
