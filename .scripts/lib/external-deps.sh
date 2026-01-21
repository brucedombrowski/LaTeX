#!/bin/bash

# ============================================================================
# EXTERNAL DEPENDENCY MANAGEMENT
# ============================================================================
# Functions for checking, downloading, and documenting external dependencies.
# Configuration is read from .config/external-deps.json
#
# Usage:
#   source "$SCRIPT_DIR/lib/external-deps.sh"
#   check_external_deps              # Check all dependencies
#   download_dependency "PdfSigner"  # Download a specific dependency
#   get_dep_info "PdfSigner"         # Get info for attestation
# ============================================================================

# Get repo root (assumes script is in .scripts/lib/)
_get_repo_root() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    dirname "$(dirname "$script_dir")"
}

REPO_ROOT="$(_get_repo_root)"
CONFIG_FILE="$REPO_ROOT/.config/external-deps.json"
BIN_DIR="$REPO_ROOT/.bin"

# Check if jq is available (for JSON parsing)
_has_jq() {
    command -v jq &> /dev/null
}

# Parse JSON without jq (basic grep-based fallback)
_json_get() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\": *\"[^\"]*\"" | head -1 | cut -d'"' -f4
}

# Get GitHub latest release info for a repo
# Usage: get_github_release "owner/repo"
# Returns: JSON with tag_name, assets array, etc.
get_github_release() {
    local repo="$1"
    local api_url="https://api.github.com/repos/$repo/releases/latest"

    if ! command -v curl &> /dev/null; then
        return 1
    fi

    curl -s --max-time 10 "$api_url" 2>/dev/null
}

# Get download URL for an asset matching a pattern
# Usage: get_asset_url "$release_json" "pattern"
get_asset_url() {
    local release_json="$1"
    local pattern="$2"

    if _has_jq; then
        # Use contains instead of regex test to avoid escape issues
        echo "$release_json" | jq -r ".assets[] | select(.name | endswith(\".zip\")) | .browser_download_url" | head -1
    else
        # Fallback: grep for browser_download_url matching pattern
        echo "$release_json" | grep -o '"browser_download_url": *"[^"]*'"$pattern"'[^"]*"' | head -1 | cut -d'"' -f4
    fi
}

# Get version tag from release JSON
get_release_version() {
    local release_json="$1"

    if _has_jq; then
        echo "$release_json" | jq -r '.tag_name'
    else
        _json_get "$release_json" "tag_name"
    fi
}

# Check if a dependency is installed
# Usage: is_dep_installed "PdfSigner"
is_dep_installed() {
    local dep_name="$1"
    local install_path

    case "$dep_name" in
        PdfSigner)
            install_path="$BIN_DIR/PdfSigner.exe"
            ;;
        *)
            return 1
            ;;
    esac

    [ -f "$install_path" ]
}

# Get dependency info from config
# Usage: get_dep_config "PdfSigner" "github_repo"
get_dep_config() {
    local dep_name="$1"
    local field="$2"

    if [ ! -f "$CONFIG_FILE" ]; then
        return 1
    fi

    if _has_jq; then
        jq -r ".dependencies.$dep_name.$field // empty" "$CONFIG_FILE"
    else
        # Simplified fallback - works for basic string fields
        grep -A20 "\"$dep_name\"" "$CONFIG_FILE" | grep "\"$field\"" | head -1 | cut -d'"' -f4
    fi
}

# Check and report status of all external dependencies
# Returns info suitable for release.sh output
check_external_deps() {
    local dep_name
    local github_repo
    local release_info
    local latest_version
    local install_path
    local status

    echo "Checking external dependencies..."

    # PdfSigner
    dep_name="PdfSigner"
    github_repo="brucedombrowski/PDFSigner"
    install_path="$BIN_DIR/PdfSigner.exe"

    # Get latest release info
    release_info=$(get_github_release "$github_repo" 2>/dev/null)

    if [ -z "$release_info" ]; then
        print_warning "  Could not reach GitHub (offline or timeout)"
        PDFSIGNER_VERSION="unknown"
        PDFSIGNER_URL="https://github.com/$github_repo/releases/latest"
    else
        PDFSIGNER_VERSION=$(get_release_version "$release_info")
        PDFSIGNER_URL=$(get_asset_url "$release_info" '\.zip')

        if [ -z "$PDFSIGNER_URL" ]; then
            PDFSIGNER_URL="https://github.com/$github_repo/releases/latest"
        fi
    fi

    if [ -f "$install_path" ]; then
        print_success "  PdfSigner.exe found (latest: $PDFSIGNER_VERSION)"
        PDFSIGNER_CHECKSUM=$(shasum -a 256 "$install_path" 2>/dev/null | cut -d' ' -f1 || echo "calculation-failed")
    else
        print_warning "  PdfSigner.exe not found in .bin/"
        print_info "    Download: $PDFSIGNER_URL"
        PDFSIGNER_CHECKSUM="not-available"
    fi

    # Export variables for use by other scripts
    export PDFSIGNER_VERSION
    export PDFSIGNER_URL
    export PDFSIGNER_CHECKSUM
}

# Download and install a dependency
# Usage: download_dependency "PdfSigner"
download_dependency() {
    local dep_name="$1"
    local github_repo
    local release_info
    local download_url
    local temp_dir

    case "$dep_name" in
        PdfSigner)
            github_repo="brucedombrowski/PDFSigner"
            ;;
        *)
            print_error "Unknown dependency: $dep_name"
            return 1
            ;;
    esac

    print_info "Downloading $dep_name..."

    # Get release info
    release_info=$(get_github_release "$github_repo")
    if [ -z "$release_info" ]; then
        print_error "Could not fetch release info from GitHub"
        return 1
    fi

    # Get download URL
    download_url=$(get_asset_url "$release_info" '\.zip')
    if [ -z "$download_url" ]; then
        print_error "Could not find download URL"
        return 1
    fi

    # Create temp directory
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    # Download
    print_info "  Downloading from: $download_url"
    if ! curl -L -o "$temp_dir/download.zip" "$download_url" 2>/dev/null; then
        print_error "Download failed"
        return 1
    fi

    # Extract
    print_info "  Extracting..."
    if ! unzip -q "$temp_dir/download.zip" -d "$temp_dir" 2>/dev/null; then
        print_error "Extraction failed"
        return 1
    fi

    # Install
    mkdir -p "$BIN_DIR"
    case "$dep_name" in
        PdfSigner)
            if [ -f "$temp_dir/PdfSigner.exe" ]; then
                cp "$temp_dir/PdfSigner.exe" "$BIN_DIR/"
            elif [ -f "$temp_dir/*/PdfSigner.exe" ]; then
                cp "$temp_dir"/*/PdfSigner.exe "$BIN_DIR/"
            else
                # Search for it
                local exe_path
                exe_path=$(find "$temp_dir" -name "PdfSigner.exe" -type f | head -1)
                if [ -n "$exe_path" ]; then
                    cp "$exe_path" "$BIN_DIR/"
                else
                    print_error "PdfSigner.exe not found in archive"
                    return 1
                fi
            fi
            ;;
    esac

    print_success "  Installed to $BIN_DIR/"
    return 0
}

# Interactive prompt to download missing dependencies
# Usage: prompt_download_deps
prompt_download_deps() {
    local missing=()

    if ! is_dep_installed "PdfSigner"; then
        missing+=("PdfSigner")
    fi

    if [ ${#missing[@]} -eq 0 ]; then
        return 0
    fi

    echo ""
    print_warning "Missing dependencies: ${missing[*]}"
    echo ""
    read -p "Download missing dependencies? [y/N] " response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        for dep in "${missing[@]}"; do
            download_dependency "$dep"
        done
    fi
}
