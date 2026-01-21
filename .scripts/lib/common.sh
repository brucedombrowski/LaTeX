#!/bin/bash

# ============================================================================
# COMMON UTILITIES FOR LATEX TOOLKIT SCRIPTS
# ============================================================================
# Source this file in other scripts:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
#
# Or if sourcing from a different location:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib/common.sh"
# ============================================================================

# ============================================================================
# COLORS FOR OUTPUT
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# DIRECTORY DETECTION
# ============================================================================

# Get the directory containing the calling script
# Usage: SCRIPT_DIR="$(get_script_dir)"
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[1]}")" && pwd
}

# Get the repository root directory
# Assumes scripts are in .scripts/ folder
# Usage: REPO_ROOT="$(get_repo_root)"
get_repo_root() {
    local script_dir
    script_dir="$(get_script_dir)"
    dirname "$script_dir"
}

# ============================================================================
# LATEX COMPILATION
# ============================================================================

# Determine the appropriate compiler for a .tex file
# Returns "xelatex" if fontspec is used or file inputs SF901-template
# Returns "pdflatex" otherwise
# Usage: COMPILER=$(determine_compiler "$tex_file")
determine_compiler() {
    local tex_file="$1"
    if grep -q '\\usepackage{fontspec}' "$tex_file" 2>/dev/null || \
       grep -q 'SF901-template' "$tex_file" 2>/dev/null; then
        echo "xelatex"
    else
        echo "pdflatex"
    fi
}

# Cleanup LaTeX auxiliary files in a directory
# Usage: cleanup_aux_files [directory]
cleanup_aux_files() {
    local dir="${1:-.}"
    rm -f "$dir"/*.aux "$dir"/*.log "$dir"/*.out "$dir"/*.toc \
          "$dir"/*.fdb_latexmk "$dir"/*.fls "$dir"/*.synctex.gz \
          "$dir"/*.bbl "$dir"/*.blg "$dir"/*.nav "$dir"/*.snm "$dir"/*.vrb
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Print an error message in red
# Usage: print_error "Something went wrong"
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

# Print a success message in green
# Usage: print_success "Build complete"
print_success() {
    echo -e "${GREEN}$1${NC}"
}

# Print a warning message in yellow
# Usage: print_warning "Optional dependency missing"
print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

# Print an info message in blue
# Usage: print_info "Building document..."
print_info() {
    echo -e "${BLUE}$1${NC}"
}

# Check if a command exists
# Usage: if require_command pdflatex "Install TeX Live"; then ...
require_command() {
    local cmd="$1"
    local help_text="$2"
    if ! command -v "$cmd" &> /dev/null; then
        print_error "$cmd not found. $help_text"
        return 1
    fi
    return 0
}
