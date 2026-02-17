#!/usr/bin/env bash
# Build all requirements PDFs from JSON source files.
# JSON is the single source of truth; LaTeX/PDF are generated outputs.
#
# Usage: ./build.sh              # Build all REQ-*.json files
#        ./build.sh file.json    # Build a specific file

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 "$SCRIPT_DIR/build-requirements-pdf.py" "$@"
