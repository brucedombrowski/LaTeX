#!/bin/bash

# Digital signature script for Decision Documents
# Supports: Smart card (PIV/CAC) or software certificates (.p12)
# Requires: OpenSC, JSignPDF, or PortableSigner

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory for finding certificates
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "PDF Digital Signature Script"
echo "========================================"

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

    # Check for PortableSigner (Java-based, works with .p12)
    if command -v java &> /dev/null; then
        echo -e "${GREEN}Found: Java (for PortableSigner/software signing)${NC}"
        HAS_JAVA=true
    fi

    if ! $tool_found && [ "$HAS_JAVA" != "true" ]; then
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

# Sign PDF using software certificate (.p12 file)
sign_with_p12() {
    local input_pdf="$1"
    local output_pdf="$2"
    local p12_file="$3"
    local p12_pass="$4"

    echo ""
    echo -e "${YELLOW}Signing with software certificate...${NC}"

    # Use pdfsig with NSS if available, otherwise use Java-based approach
    if command -v openssl &> /dev/null; then
        # Create temporary NSS database for signing
        local nss_dir=$(mktemp -d)

        # Initialize NSS database
        certutil -N -d "$nss_dir" --empty-password 2>/dev/null || true

        # Import the P12 certificate
        pk12util -i "$p12_file" -d "$nss_dir" -W "$p12_pass" 2>/dev/null

        if command -v pdfsig &> /dev/null; then
            # Get the certificate nickname
            local cert_nick=$(certutil -L -d "$nss_dir" 2>/dev/null | grep -v "Certificate Nickname" | head -1 | awk '{print $1}')

            if [ -n "$cert_nick" ]; then
                pdfsig -nssdir "$nss_dir" -nick "$cert_nick" -sign "$input_pdf" "$output_pdf" 2>/dev/null && {
                    rm -rf "$nss_dir"
                    return 0
                }
            fi
        fi

        rm -rf "$nss_dir"
    fi

    echo -e "${YELLOW}Note: For full .p12 signing support, install JSignPDF${NC}"
    echo "  Download from: http://jsignpdf.sourceforge.net/"
    return 1
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
        "sign-p12")
            local p12_file="$2"
            local pdf_file="$3"
            local p12_pass="${4:-}"

            if [ -z "$p12_file" ]; then
                # Look for .p12 files in script directory
                echo ""
                echo "Available .p12 certificates:"
                ls -1 "$SCRIPT_DIR"/*.p12 2>/dev/null || echo "  No .p12 files found"
                echo ""
                read -p "Enter .p12 certificate path: " p12_file
            fi

            if [ -z "$pdf_file" ]; then
                echo ""
                echo "Available PDFs:"
                ls -1 *.pdf 2>/dev/null || echo "  No PDF files found"
                echo ""
                read -p "Enter PDF filename to sign: " pdf_file
            fi

            if [ -z "$p12_pass" ]; then
                read -s -p "Enter .p12 password: " p12_pass
                echo ""
            fi

            local base_name="${pdf_file%.pdf}"
            local output_pdf="${base_name}_signed.pdf"
            sign_with_p12 "$pdf_file" "$output_pdf" "$p12_file" "$p12_pass"

            if [ -f "$output_pdf" ]; then
                echo ""
                echo -e "${GREEN}Successfully signed: $output_pdf${NC}"
            fi
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
        "create-cert")
            create_test_certificate
            ;;
        *)
            echo ""
            echo "Usage: $0 <action> [options]"
            echo ""
            echo "Actions:"
            echo "  sign <file.pdf>                    - Sign PDF with smart card (PIV/CAC)"
            echo "  sign-p12 <cert.p12> <file.pdf>     - Sign PDF with software certificate"
            echo "  verify <file.pdf>                  - Verify signatures in a PDF"
            echo "  list                               - List certificates on smart card"
            echo "  create-cert                        - Create a self-signed test certificate"
            echo ""
            echo "Examples:"
            echo "  $0 sign decision_document.pdf"
            echo "  $0 sign-p12 test_signer.p12 decision_document.pdf"
            echo "  $0 verify decision_document_signed.pdf"
            echo "  $0 list"
            echo "  $0 create-cert"
            ;;
    esac
}

# Create a self-signed test certificate
create_test_certificate() {
    echo ""
    echo -e "${YELLOW}Creating self-signed test certificate...${NC}"
    echo ""
    echo "This creates a certificate for TESTING PURPOSES ONLY."
    echo "Do not use for production or legal documents."
    echo ""

    # Get certificate details
    read -p "Common Name (your name) [Test Signer]: " cn
    cn="${cn:-Test Signer}"

    read -p "Organization [Test Organization]: " org
    org="${org:-Test Organization}"

    read -p "Country (2-letter code) [US]: " country
    country="${country:-US}"

    read -p "Certificate validity in days [365]: " days
    days="${days:-365}"

    read -s -p "Password for .p12 file: " p12_pass
    echo ""

    local base_name="signer_$(date +%Y%m%d)"
    local key_file="${SCRIPT_DIR}/${base_name}_key.pem"
    local cert_file="${SCRIPT_DIR}/${base_name}_cert.pem"
    local p12_file="${SCRIPT_DIR}/${base_name}.p12"

    echo ""
    echo "Generating RSA key pair..."

    # Step 1: Generate RSA private key (2048-bit)
    # Command: openssl genrsa -out <key_file> 2048
    # This creates the private key used for signing
    openssl genrsa -out "$key_file" 2048 2>/dev/null

    echo "Creating self-signed X.509 certificate..."

    # Step 2: Create self-signed X.509 certificate
    # Command breakdown:
    #   req -x509          : Create a self-signed certificate (not a CSR)
    #   -new               : Generate a new certificate request
    #   -key <key_file>    : Use this private key
    #   -out <cert_file>   : Output certificate to this file
    #   -days <days>       : Certificate validity period
    #   -subj "..."        : Certificate subject (CN=Common Name, O=Org, C=Country)
    #   -addext "..."      : Add X.509v3 extensions for digital signatures
    openssl req -x509 -new \
        -key "$key_file" \
        -out "$cert_file" \
        -days "$days" \
        -subj "/CN=${cn}/O=${org}/C=${country}" \
        -addext "keyUsage = digitalSignature, nonRepudiation" \
        -addext "extendedKeyUsage = emailProtection, codeSigning"

    echo "Creating PKCS#12 (.p12) bundle..."

    # Step 3: Bundle key + certificate into PKCS#12 format
    # Command breakdown:
    #   pkcs12 -export     : Create a PKCS#12 file
    #   -out <p12_file>    : Output file
    #   -inkey <key_file>  : Private key to include
    #   -in <cert_file>    : Certificate to include
    #   -name "..."        : Friendly name for the certificate
    #   -passout pass:...  : Password to protect the .p12 file
    openssl pkcs12 -export \
        -out "$p12_file" \
        -inkey "$key_file" \
        -in "$cert_file" \
        -name "$cn" \
        -passout "pass:${p12_pass}"

    echo ""
    echo -e "${GREEN}Certificate created successfully!${NC}"
    echo ""
    echo "Files created:"
    echo "  Private key:   $key_file"
    echo "  Certificate:   $cert_file"
    echo "  PKCS#12 file:  $p12_file"
    echo ""
    echo "To sign a PDF with this certificate:"
    echo "  $0 sign-p12 $p12_file <your_document.pdf>"
    echo ""
    echo -e "${YELLOW}IMPORTANT: Keep your private key secure!${NC}"
    echo "The .p12 file contains both the private key and certificate."
}

main "$@"
