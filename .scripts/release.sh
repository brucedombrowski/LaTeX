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
DIST_DIR="$REPO_ROOT/.dist"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/external-deps.sh"

echo "=========================================="
echo "LaTeX Toolkit Release Build"
echo "=========================================="

# Check if pdflatex is installed
if ! command -v pdflatex &> /dev/null; then
    echo -e "${RED}Error: pdflatex not found. Please install TeX Live.${NC}"
    exit 1
fi

# Check external dependencies (non-blocking)
check_external_deps || true

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

    # Determine compiler using common utility
    local COMPILER=$(determine_compiler "$tex_file")

    if $COMPILER -interaction=nonstopmode "${basename}.tex" > /dev/null 2>&1; then
        $COMPILER -interaction=nonstopmode "${basename}.tex" > /dev/null 2>&1

        # Copy PDF to dist
        if [ -f "${basename}.pdf" ]; then
            cp "${basename}.pdf" "$output_dir/"
            print_success "  ✓ ${basename}.pdf ($COMPILER)"
            ((BUILT++))
        fi

        # Clean auxiliary files
        cleanup_aux_files "."
    else
        print_error "  ✗ Failed to build ${basename}.tex ($COMPILER)"
        ((FAILED++))
        FAILED_FILES="$FAILED_FILES\n  - ${tex_file#$REPO_ROOT/}"
        # Clean auxiliary files even on failure
        cleanup_aux_files "."
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

    # Determine compiler using common utility
    local COMPILER=$(determine_compiler "$tex_file")

    if $COMPILER -interaction=nonstopmode "${basename}.tex" > /dev/null 2>&1; then
        $COMPILER -interaction=nonstopmode "${basename}.tex" > /dev/null 2>&1

        if [ -f "${basename}.pdf" ]; then
            print_success "  ✓ ${basename}.pdf ($COMPILER)"
            ((BUILT++))

            # Generate PNG if pdftoppm is available
            if command -v pdftoppm &> /dev/null; then
                pdftoppm -png -r 150 -singlefile "${basename}.pdf" "${basename}"
                print_success "  ✓ ${basename}.png"
            fi
        fi

        # Clean auxiliary files
        cleanup_aux_files "."
    else
        print_error "  ✗ Failed to build ${basename}.tex ($COMPILER)"
        ((FAILED++))
        FAILED_FILES="$FAILED_FILES\n  - ${tex_file#$REPO_ROOT/}"
        # Clean auxiliary files even on failure
        cleanup_aux_files "."
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

# Generate Software Attestation
echo ""
echo -e "${YELLOW}Generating Software Attestation...${NC}"
if [ -f "$SCRIPT_DIR/generate-attestation.sh" ]; then
    if "$SCRIPT_DIR/generate-attestation.sh"; then
        ((BUILT++))
    else
        echo -e "${YELLOW}  Attestation generation skipped or failed${NC}"
    fi
else
    echo -e "${YELLOW}  generate-attestation.sh not found${NC}"
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
