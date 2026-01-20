#!/bin/bash

# Release script for PdfTools
# 1. Cleans up generated files
# 2. Builds example PDFs
# 3. Creates demo merged PDF
# 4. Cleans for git commit (keeps only .tex source files)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}==========================================${NC}"
echo -e "${CYAN}PdfTools Release Script${NC}"
echo -e "${CYAN}==========================================${NC}"
echo ""

cd "$SCRIPT_DIR"

# Step 1: Clean everything first
echo -e "${YELLOW}Step 1: Cleaning old generated files...${NC}"
rm -f *.pdf *.png *.aux *.log *.out 2>/dev/null
rm -f Examples/*.pdf Examples/*.png Examples/*.aux Examples/*.log Examples/*.out 2>/dev/null
echo -e "${GREEN}Done.${NC}"
echo ""

# Step 2: Build example PDFs from .tex files
echo -e "${YELLOW}Step 2: Building example PDFs...${NC}"
cd "$SCRIPT_DIR/Examples"
./build_tex_to_pdf.sh
cd "$SCRIPT_DIR"
echo ""

# Step 3: Create demo merged PDF
echo -e "${YELLOW}Step 3: Creating demo merged PDF...${NC}"

# Build the merge tex file manually (non-interactive)
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

cd "$SCRIPT_DIR/Examples"
cp "$SCRIPT_DIR/merge_temp.tex" .
if pdflatex -interaction=nonstopmode merge_temp.tex > /dev/null 2>&1; then
    mv merge_temp.pdf "$SCRIPT_DIR/CUI_Cover_Packet_Example.pdf"
    echo -e "${GREEN}Created: CUI_Cover_Packet_Example.pdf${NC}"
else
    echo -e "${RED}Failed to create merged PDF${NC}"
fi
rm -f merge_temp.* 2>/dev/null
cd "$SCRIPT_DIR"
rm -f merge_temp.tex 2>/dev/null
echo ""

# Step 4: Clean for git commit (remove generated files from Examples, keep demo PDF)
echo -e "${YELLOW}Step 4: Cleaning Examples/ for git commit...${NC}"
rm -f Examples/*.pdf Examples/*.png Examples/*.aux Examples/*.log Examples/*.out 2>/dev/null
echo -e "${GREEN}Done.${NC}"
echo ""

# Summary
echo -e "${CYAN}==========================================${NC}"
echo -e "${GREEN}Release complete!${NC}"
echo ""
echo -e "${YELLOW}Files ready for commit:${NC}"
find . -type f -not -path './.git/*' -not -name '.DS_Store' | sort | sed 's|^\./|  |'
echo -e "${CYAN}==========================================${NC}"
