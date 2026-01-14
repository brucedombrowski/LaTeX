#!/bin/bash

# Digital signature script for Decision Documents using smart card (PIV/CAC)
# Requires: OpenSC, osslsigncode, or JSignPDF

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "PDF Digital Signature Script (Smart Card)"
echo "=========================================="

# Check for required tools
check_tools() {
    local tool_found=false

    if command -v pdfsig &> /dev/null; then
        echo -e "${GREEN}Found: pdfsig (Poppler)${NC}"
        SIGN_TOOL="pdfsig"
        tool_found=true
    fi

    if command -v JSignPdf &> /dev/null || [ -f "/usr/local/bin/JSignPdf.jar" ] || [ -f "$HOME/JSignPdf/JSignPdf.jar" ]; then
        echo -e "${GREEN}Found: JSignPDF${NC}"
        SIGN_TOOL="jsignpdf"
        tool_found=true
    fi

    if command -v pkcs11-tool &> /dev/null; then
        echo -e "${GREEN}Found: pkcs11-tool (OpenSC)${NC}"
    fi

    if ! $tool_found; then
        echo -e "${RED}Error: No PDF signing tool found.${NC}"
        echo ""
        echo "Please install one of the following:"
        echo "  macOS:   brew install poppler    # for pdfsig"
        echo "           brew install jsignpdf   # for JSignPDF"
        echo "  Linux:   sudo apt install poppler-utils"
        echo "           sudo apt install opensc  # for smart card support"
        echo ""
        echo "For JSignPDF (recommended for smart cards):"
        echo "  Download from: http://jsignpdf.sourceforge.net/"
        exit 1
    fi
}

# Detect PKCS#11 library for smart card
detect_pkcs11_lib() {
    # Common PKCS#11 library locations
    local libs=(
        "/usr/lib/opensc-pkcs11.so"                    # Linux OpenSC
        "/usr/local/lib/opensc-pkcs11.so"             # Linux OpenSC alt
        "/Library/OpenSC/lib/opensc-pkcs11.so"        # macOS OpenSC
        "/usr/local/lib/libykcs11.dylib"              # macOS YubiKey
        "/usr/lib/x86_64-linux-gnu/opensc-pkcs11.so"  # Debian/Ubuntu
        "/opt/homebrew/lib/opensc-pkcs11.so"          # macOS ARM Homebrew
    )

    for lib in "${libs[@]}"; do
        if [ -f "$lib" ]; then
            PKCS11_LIB="$lib"
            echo -e "${GREEN}Found PKCS#11 library: $lib${NC}"
            return 0
        fi
    done

    echo -e "${YELLOW}Warning: No PKCS#11 library found automatically.${NC}"
    echo "You may need to specify the path manually."
    return 1
}

# List available certificates on smart card
list_certificates() {
    echo ""
    echo -e "${YELLOW}Checking for smart card certificates...${NC}"

    if [ -n "$PKCS11_LIB" ]; then
        pkcs11-tool --module "$PKCS11_LIB" --list-objects --type cert 2>/dev/null || \
            echo -e "${YELLOW}Could not list certificates. Is your smart card inserted?${NC}"
    else
        echo -e "${YELLOW}PKCS#11 library not found. Cannot list certificates.${NC}"
    fi
}

# Sign PDF using JSignPDF (best smart card support)
sign_with_jsignpdf() {
    local input_pdf="$1"
    local output_pdf="$2"

    # Find JSignPDF jar
    local jsign_jar=""
    for path in "/usr/local/bin/JSignPdf.jar" "$HOME/JSignPdf/JSignPdf.jar" "/opt/JSignPdf/JSignPdf.jar"; do
        if [ -f "$path" ]; then
            jsign_jar="$path"
            break
        fi
    done

    if [ -z "$jsign_jar" ]; then
        echo -e "${RED}JSignPDF jar not found.${NC}"
        return 1
    fi

    echo ""
    echo -e "${YELLOW}Signing with JSignPDF...${NC}"
    echo "Please enter your smart card PIN when prompted."
    echo ""

    java -jar "$jsign_jar" \
        --keystore-type "PKCS11" \
        --keystore-file "$PKCS11_LIB" \
        --out-directory "$(dirname "$output_pdf")" \
        --out-suffix "_signed" \
        "$input_pdf"
}

# Sign PDF using pdfsig (Poppler)
sign_with_pdfsig() {
    local input_pdf="$1"
    local output_pdf="$2"

    echo ""
    echo -e "${YELLOW}Signing with pdfsig...${NC}"
    echo "Please enter your smart card PIN when prompted."
    echo ""

    # Note: pdfsig requires NSS database setup for smart card signing
    # This is a simplified example - actual usage may require additional configuration
    pdfsig -sign "$input_pdf" "$output_pdf"
}

# Main signing function
sign_pdf() {
    local input_pdf="$1"

    if [ ! -f "$input_pdf" ]; then
        echo -e "${RED}Error: File not found: $input_pdf${NC}"
        exit 1
    fi

    local base_name="${input_pdf%.pdf}"
    local output_pdf="${base_name}_signed.pdf"

    echo ""
    echo "Input:  $input_pdf"
    echo "Output: $output_pdf"

    case "$SIGN_TOOL" in
        "jsignpdf")
            sign_with_jsignpdf "$input_pdf" "$output_pdf"
            ;;
        "pdfsig")
            sign_with_pdfsig "$input_pdf" "$output_pdf"
            ;;
        *)
            echo -e "${RED}No signing tool configured.${NC}"
            exit 1
            ;;
    esac

    if [ -f "$output_pdf" ]; then
        echo ""
        echo -e "${GREEN}Successfully signed: $output_pdf${NC}"
    fi
}

# Verify signature on PDF
verify_pdf() {
    local pdf_file="$1"

    if [ ! -f "$pdf_file" ]; then
        echo -e "${RED}Error: File not found: $pdf_file${NC}"
        exit 1
    fi

    echo ""
    echo -e "${YELLOW}Verifying signatures in: $pdf_file${NC}"

    if command -v pdfsig &> /dev/null; then
        pdfsig "$pdf_file"
    else
        echo -e "${YELLOW}pdfsig not found. Install poppler-utils to verify signatures.${NC}"
    fi
}

# Main script
main() {
    local action="$1"
    local pdf_file="$2"

    check_tools
    detect_pkcs11_lib

    case "$action" in
        "sign")
            if [ -z "$pdf_file" ]; then
                echo ""
                echo "Available PDFs:"
                ls -1 *.pdf 2>/dev/null || echo "  No PDF files found"
                echo ""
                read -p "Enter PDF filename to sign: " pdf_file
            fi
            sign_pdf "$pdf_file"
            ;;
        "verify")
            if [ -z "$pdf_file" ]; then
                echo ""
                read -p "Enter PDF filename to verify: " pdf_file
            fi
            verify_pdf "$pdf_file"
            ;;
        "list")
            list_certificates
            ;;
        *)
            echo ""
            echo "Usage: $0 <action> [pdf_file]"
            echo ""
            echo "Actions:"
            echo "  sign <file.pdf>   - Sign a PDF with smart card"
            echo "  verify <file.pdf> - Verify signatures in a PDF"
            echo "  list              - List certificates on smart card"
            echo ""
            echo "Examples:"
            echo "  $0 sign decision_document.pdf"
            echo "  $0 verify decision_document_signed.pdf"
            echo "  $0 list"
            ;;
    esac
}

main "$@"
