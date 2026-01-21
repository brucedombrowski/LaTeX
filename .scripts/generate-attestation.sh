#!/bin/bash

# ============================================================================
# GENERATE SOFTWARE ATTESTATION
# ============================================================================
# Creates a software attestation PDF documenting versions, checksums, and URLs
# for external binaries used by the LaTeX Toolkit.
#
# Usage: ./scripts/generate-attestation.sh
# Output: Attestations/software-attestation-YYYYMMDD.pdf
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$REPO_ROOT/Documentation-Generation/Attestations/templates"
EXAMPLES_DIR="$REPO_ROOT/Documentation-Generation/Attestations/examples"
OUTPUT_DIR="$REPO_ROOT/Attestations"
BIN_DIR="$REPO_ROOT/.bin"

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

echo "=========================================="
echo "Generate Software Attestation"
echo "=========================================="

# Check if pdflatex is installed
if ! command -v pdflatex &> /dev/null; then
    echo -e "${YELLOW}Warning: pdflatex not found. Skipping attestation generation.${NC}"
    exit 2
fi

# Get current date and timestamp
DATE_DISPLAY=$(date "+%B %d, %Y")
DATE_STAMP=$(date "+%Y%m%d")
TIMESTAMP=$(date -u "+%Y-%m-%dT%H:%M:%SZ")

# Get toolkit version info
if git -C "$REPO_ROOT" describe --tags --always &>/dev/null; then
    TOOLKIT_VERSION=$(git -C "$REPO_ROOT" describe --tags --always 2>/dev/null || echo "dev")
else
    TOOLKIT_VERSION="dev"
fi
TOOLKIT_COMMIT=$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Generate attestation ID
ATT_ID="ATT-${DATE_STAMP}-001"

echo ""
echo -e "${YELLOW}Collecting software information...${NC}"

# PdfSigner information
PDFSIGNER_VERSION="unknown"
PDFSIGNER_CHECKSUM="not-available"
PDFSIGNER_URL="https://github.com/brucedombrowski/PDFSigner/releases/latest"

# Try to get PdfSigner version from GitHub API
if command -v curl &> /dev/null; then
    PDFSIGNER_API="https://api.github.com/repos/brucedombrowski/PDFSigner/releases/latest"
    PDFSIGNER_INFO=$(curl -s --max-time 10 "$PDFSIGNER_API" 2>/dev/null || echo "")

    if [ -n "$PDFSIGNER_INFO" ]; then
        PDFSIGNER_VERSION=$(echo "$PDFSIGNER_INFO" | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4 || echo "unknown")
        # Get download URL for the zip release (release is a .zip, not standalone .exe)
        PDFSIGNER_URL=$(echo "$PDFSIGNER_INFO" | grep -o '"browser_download_url": *"[^"]*\.zip"' | head -1 | cut -d'"' -f4 || echo "$PDFSIGNER_URL")
    fi
fi

# Calculate checksum if PdfSigner.exe exists locally
if [ -f "$BIN_DIR/PdfSigner.exe" ]; then
    PDFSIGNER_CHECKSUM=$(shasum -a 256 "$BIN_DIR/PdfSigner.exe" 2>/dev/null | cut -d' ' -f1 || echo "calculation-failed")
    echo -e "${GREEN}  PdfSigner.exe found - checksum calculated${NC}"
else
    echo -e "${YELLOW}  PdfSigner.exe not found in bin/ - checksum not available${NC}"
fi

echo -e "${GREEN}  PdfSigner version: $PDFSIGNER_VERSION${NC}"
echo -e "${GREEN}  PdfSigner URL: $PDFSIGNER_URL${NC}"

# Escape special LaTeX characters
escape_latex() {
    echo "$1" | sed 's/\\/\\textbackslash{}/g' | \
                sed 's/_/\\_/g' | \
                sed 's/&/\\&/g' | \
                sed 's/%/\\%/g' | \
                sed 's/\$/\\$/g' | \
                sed 's/#/\\#/g' | \
                sed 's/{/\\{/g' | \
                sed 's/}/\\}/g'
}

# Create working directory
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

# Copy template and example files to work directory
cp "$TEMPLATE_DIR/attestation-template.tex" "$WORK_DIR/"
cp "$EXAMPLES_DIR/software_attestation.tex" "$WORK_DIR/"

echo ""
echo -e "${YELLOW}Generating attestation document...${NC}"

# Perform variable substitution
cd "$WORK_DIR"

# Escape URL for sed (replace / with \/)
PDFSIGNER_URL_ESCAPED=$(echo "$PDFSIGNER_URL" | sed 's/\//\\\//g')

# Replace placeholders in software_attestation.tex
sed -i.bak "s/ATT-PLACEHOLDER-ID/$ATT_ID/g" software_attestation.tex
sed -i.bak "s/PLACEHOLDER-DATE/$DATE_DISPLAY/g" software_attestation.tex
sed -i.bak "s/PLACEHOLDER-VERSION/$TOOLKIT_VERSION/g" software_attestation.tex
sed -i.bak "s/PLACEHOLDER-COMMIT/$TOOLKIT_COMMIT/g" software_attestation.tex
sed -i.bak "s/PDFSIGNER-VERSION/$PDFSIGNER_VERSION/g" software_attestation.tex
sed -i.bak "s/PDFSIGNER-CHECKSUM/$PDFSIGNER_CHECKSUM/g" software_attestation.tex
sed -i.bak "s/PDFSIGNER-URL/$PDFSIGNER_URL_ESCAPED/g" software_attestation.tex

# Compile the document (twice for cross-references)
# Note: pdflatex may return non-zero for warnings even when PDF is generated
pdflatex -interaction=nonstopmode software_attestation.tex > /dev/null 2>&1 || true
pdflatex -interaction=nonstopmode software_attestation.tex > /dev/null 2>&1 || true

# Check if PDF was actually generated
if [ -f "software_attestation.pdf" ]; then
    # Copy to Attestations/ directory
    OUTPUT_FILE="$OUTPUT_DIR/software-attestation-${DATE_STAMP}.pdf"
    cp software_attestation.pdf "$OUTPUT_FILE"
    echo -e "${GREEN}  Generated: Attestations/software-attestation-${DATE_STAMP}.pdf${NC}"

    # Also create a "latest" symlink
    ln -sf "software-attestation-${DATE_STAMP}.pdf" "$OUTPUT_DIR/software-attestation-latest.pdf"

    # Copy to .dist/attestations/ for release distribution
    DIST_ATT_DIR="$REPO_ROOT/.dist/attestations"
    mkdir -p "$DIST_ATT_DIR"
    cp software_attestation.pdf "$DIST_ATT_DIR/software-attestation-${DATE_STAMP}.pdf"
    ln -sf "software-attestation-${DATE_STAMP}.pdf" "$DIST_ATT_DIR/software-attestation-latest.pdf"
    echo -e "${GREEN}  Generated: .dist/attestations/software-attestation-${DATE_STAMP}.pdf${NC}"

    echo ""
    echo "=========================================="
    echo -e "${GREEN}Attestation generated successfully${NC}"
    echo "=========================================="
    echo ""
    echo "Document ID: $ATT_ID"
    echo "Date: $DATE_DISPLAY"
    echo "Toolkit: $TOOLKIT_VERSION ($TOOLKIT_COMMIT)"
    echo ""
    echo "Software documented:"
    echo "  - PdfSigner.exe $PDFSIGNER_VERSION"
    echo ""
else
    echo -e "${RED}Failed to compile attestation document${NC}"
    # Show error output for debugging
    pdflatex -interaction=nonstopmode software_attestation.tex 2>&1 | tail -20
    exit 1
fi
