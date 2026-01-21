# AGENTS.md

Instructions for AI agents working with DecisionDocument signing infrastructure.

## Overview

This component contains:
1. **Template:** `templates/decision_document.tex` - Multi-page program decisions
2. **Signing Scripts:** Wrapper scripts for digital signatures (sign.sh, sign.bat, sign.ps1)
3. **PdfSigner.exe:** Pre-built binary from [github.com/brucedombrowski/PDFSigner](https://github.com/brucedombrowski/PDFSigner)

**Parent:** See [../AGENTS.md](../AGENTS.md) for Documentation-Generation instructions.

**Note:** Other components (DecisionMemorandum) symlink to the signing scripts here.

## Digital Signatures

### Windows (Primary Target)

Double-click `sign.bat` for interactive mode, or use command line:

```batch
:: Interactive mode
sign.bat

:: Sign a specific PDF
sign.bat document.pdf

:: Verify a signature
sign.bat verify document_signed.pdf

:: Create a test certificate (requires OpenSSL)
sign.bat create-cert

:: List available certificates
sign.bat list
```

**PdfSigner.exe** (from [PDFSigner repo](https://github.com/brucedombrowski/PDFSigner)) handles signing via Windows Certificate Store:
- PIV/CAC smart card support (triggers Windows Security PIN dialog)
- Software certificate support
- Multi-signature support
- Only shows valid signing certs (Email Protection or Document Signing EKU)
- PIV/CAC certificates prioritized

### macOS/Linux

```bash
# Interactive mode
./sign.sh

# Sign with smart card
./sign.sh sign document.pdf

# Sign with software certificate
./sign.sh sign-p12 mycert.p12 document.pdf

# Verify
./sign.sh verify document_signed.pdf

# Create test certificate
./sign.sh create-cert
```

**Dependencies:**
```bash
brew install opensc poppler nss
```

## AI Agent Build and Sign Workflow

When building and signing PDFs as an AI agent:

```bash
# 1. Build the document
./scripts/build.sh Documentation-Generation/DecisionDocument/templates/decision_document.tex

# 2. Create certificate with source hash for traceability
cd Documentation-Generation/DecisionDocument
TEX_HASH=$(shasum -a 256 templates/decision_document.tex | cut -c1-12)
openssl req -x509 -newkey rsa:2048 \
  -keyout doc_key.pem -out doc_cert.pem \
  -days 365 -nodes \
  -subj "/C=US/O=AI Agent/OU=sha256:${TEX_HASH}/CN=decision_document.tex" \
  -addext "keyUsage=digitalSignature" \
  -addext "extendedKeyUsage=emailProtection" 2>/dev/null
openssl pkcs12 -export -out doc.p12 \
  -inkey doc_key.pem -in doc_cert.pem \
  -passout pass:agent123

# 3. Sign the PDF
./sign.sh sign-p12 doc.p12 templates/decision_document.pdf <<< "agent123"

# 4. Verify
./sign.sh verify templates/decision_document_signed.pdf

# 5. Clean up
rm -f *.pem *.p12
```

**Certificate details:**
- Common Name: `<source-filename>.tex`
- Organization: `AI Agent`
- Organizational Unit: `sha256:<first-12-chars-of-tex-hash>` (traceability)
- Password: `agent123`

**Verifying source traceability:**
```bash
# Get hash from signed PDF
./sign.sh verify document_signed.pdf | grep "OU=sha256"

# Compare with source
shasum -a 256 templates/decision_document.tex | cut -c1-12
```

## File Structure

```
DecisionDocument/
├── templates/
│   ├── decision_document.tex
│   └── logo.* -> ../../../assets/
├── examples/
│   ├── decision_document.pdf
│   └── decision_document_signed.pdf
├── sign.sh / sign.bat / sign.ps1
├── PdfSigner.exe
├── README.md
└── AGENTS.md           # This file
```

## Multi-Signature Workflow (Windows)

```batch
:: Interactive menu
sign.bat
::   [1] Sign a PDF              - initial signature
::   [2] Add signature to signed PDF  - additional signatures
::   [3] Verify a signed PDF
::   [4] Create test certificate
::   [5] List certificates

:: Command line
sign.bat document.pdf           :: First signature
sign.bat document_signed.pdf    :: Add second signature
```
