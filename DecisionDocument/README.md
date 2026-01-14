# Program Decision Document Templates

LaTeX templates for formal program decision documentation, adapted from NASA's Memorandum of Agreement format.

## Templates

| Template | Description | Use Case |
|----------|-------------|----------|
| `decision_memo.tex` | Decision Memorandum | Brief, single-page decisions with standard memo format |
| `decision_document.tex` | Comprehensive Decision Document | Detailed decisions requiring full documentation |

## Files

```
DecisionDocument/
├── decision_memo.tex       # Brief Decision Memorandum template
├── decision_document.tex   # Comprehensive decision template
├── logo_placeholder.png    # Placeholder logo for header
├── Template.docx           # Original Word template (reference)
├── build.sh                # Build script (macOS/Linux)
├── build.ps1               # Build script (Windows)
├── sign.sh                 # PDF signing script (macOS/Linux)
├── sign.ps1                # PDF signing script (Windows)
├── AGENTS.md               # AI agent guidance
└── README.md               # This file
```

## Requirements

- LaTeX distribution (TeX Live, MiKTeX, or MacTeX)
- Required packages:
  - geometry, graphicx, fancyhdr, lastpage
  - titlesec, enumitem, booktabs, longtable
  - xcolor, hyperref, datetime2, tabularx

## Quick Start

### macOS / Linux

```bash
# Make build script executable (first time only)
chmod +x build.sh

# Run build script
./build.sh
```

### Windows (PowerShell)

```powershell
# Allow script execution (first time only, run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run build script
.\build.ps1
```

### Build Options

The build script provides three options:

1. **Decision Memorandum** - Builds `decision_memo.pdf`
2. **Comprehensive Decision Document** - Builds `decision_document.pdf`
3. **Both** - Builds both PDFs

You can also specify the document directly:

```bash
# macOS/Linux
./build.sh decision_memo
./build.sh decision_document
./build.sh both

# Windows
.\build.ps1 decision_memo
.\build.ps1 decision_document
.\build.ps1 both
```

## Template Customization

### Decision Memorandum (`decision_memo.tex`)

Edit the document variables near the top of the file:

```latex
\newcommand{\UniqueID}{DM-YYYY-NNN}
\newcommand{\DocumentDate}{MMMM DD, YYYY}
\newcommand{\AuthorName}{Author Name}
\newcommand{\AuthorTitle}{Title}
\newcommand{\ToField}{Distribution}
\newcommand{\SubjectField}{Subject Line Here}
\newcommand{\OPRField}{Office Name}
```

**Structure:**
- Header with logo and "Decision Memorandum"
- Signature block with author info
- Memo fields (DATE, TO, SUBJECT, OFFICE OF PRIMARY RESPONSIBILITY)
- Numbered sections: Purpose, Background, Scope, Agreement
- Footer with document ID, page numbers, and date

### Comprehensive Decision Document (`decision_document.tex`)

Edit the document variables near the top of the file:

```latex
\newcommand{\OrganizationName}{Organization Name}
\newcommand{\OrganizationUnit}{Division/Directorate Name}
\newcommand{\DocumentTitle}{Program Decision Document}
\newcommand{\DocumentNumber}{PDD-XXXX-XXX}
\newcommand{\DocumentVersion}{1.0}
\newcommand{\EffectiveDate}{\today}
\newcommand{\ProgramName}{Program Name}
\newcommand{\ProjectName}{Project Name}
\newcommand{\DecisionTitle}{Decision Title}
```

**Structure:**
| Section | Purpose |
|---------|---------|
| Title Page | Document identification and program details |
| Document Control | Revision history and approval signatures |
| Purpose | Why the document exists |
| Scope | Applicability and period of performance |
| Background | Context, problem statement, alternatives considered |
| Decision | Formal decision statement and rationale |
| Roles and Responsibilities | Organization assignments and agreements |
| Implementation | Action items with owners, dates, and status |
| Risk Assessment | Identified risks with mitigation strategies |
| Resources | Funding, personnel, and facilities |
| Documentation and Reporting | Related documents and requirements |
| Dispute Resolution | Escalation procedures |
| Amendment Procedures | Process for modifying the decision |
| Appendices | Supporting data, acronyms, references |

### Adding Your Logo

Replace `logo_placeholder.png` with your organization's logo. The logo should be approximately 1 inch tall for optimal header display.

## Installing Missing Packages

If compilation fails due to missing packages:

### TeX Live (macOS/Linux)

```bash
sudo tlmgr update --self
sudo tlmgr install titlesec enumitem booktabs longtable lastpage datetime2 tabularx
```

### MiKTeX (Windows)

MiKTeX typically installs missing packages automatically. If not, use the MiKTeX Console to install packages manually.

## Manual Compilation

If you prefer not to use the build scripts:

```bash
# Run pdflatex 3 times for proper TOC and page references
pdflatex decision_memo.tex
pdflatex decision_memo.tex
pdflatex decision_memo.tex

# Clean up auxiliary files
rm -f *.aux *.log *.out *.toc
```

## Digital Signatures

The repository includes scripts for digitally signing PDFs using smart cards (PIV/CAC) or software certificates. Digital signatures provide cryptographic proof of document authenticity and integrity.

### How It Works

Digital signatures embed cryptographic data into the PDF metadata (not visible on the page). When you open a signed PDF in Adobe Acrobat, Preview, or other PDF readers, the signature panel displays:

- **Signer identity**: Certificate common name and organization
- **Signing time**: When the document was signed
- **Document integrity**: Whether the document has been modified since signing
- **Certificate validity**: Trust chain status (valid CA vs. self-signed)

This provides tamper-detection - any modification to the signed PDF will invalidate the signature.

### Requirements

Install the required tools:

```bash
# macOS (Homebrew)
brew install opensc poppler nss

# The tools provide:
# - opensc: Smart card (PIV/CAC) support
# - poppler: pdfsig for signing and verification
# - nss: certutil and pk12util for certificate management
```

```powershell
# Windows (Chocolatey)
choco install openssl poppler

# For smart card support, install OpenSC from:
# https://github.com/OpenSC/OpenSC/releases

# Optional: JSignPDF for an alternative signing tool
# http://jsignpdf.sourceforge.net/
```

### Interactive Mode

Run the script without arguments for a user-friendly menu:

```bash
# macOS/Linux
./sign.sh

# Windows PowerShell
.\sign.ps1
```

This presents options to:
1. Sign a PDF (software cert or smart card)
2. Verify a signed PDF
3. Create a test certificate
4. List smart card certificates
5. Show command-line usage

### Command-Line Usage

**macOS/Linux:**
```bash
# Make script executable (first time only)
chmod +x sign.sh

# Create a self-signed test certificate
./sign.sh create-cert

# Sign with smart card (PIV/CAC)
./sign.sh sign decision_document.pdf

# Sign with software certificate (.p12)
./sign.sh sign-p12 mycert.p12 decision_document.pdf

# Verify signatures
./sign.sh verify decision_document_signed.pdf

# List certificates on smart card
./sign.sh list
```

**Windows PowerShell:**
```powershell
# Create a self-signed test certificate
.\sign.ps1 create-cert

# Sign with smart card (PIV/CAC)
.\sign.ps1 sign decision_document.pdf

# Sign with software certificate (.p12/.pfx)
.\sign.ps1 sign-p12 mycert.p12 decision_document.pdf

# Verify signatures
.\sign.ps1 verify decision_document_signed.pdf

# List certificates on smart card
.\sign.ps1 list
```

### Certificate Creation

The `create-cert` command generates a self-signed certificate for testing:

1. **Prompts for signer information**: Name, organization, country, password
2. **Generates RSA private key** (2048-bit) saved as `<name>_key.pem`
3. **Creates X.509 certificate** with digital signature extensions saved as `<name>_cert.pem`
4. **Bundles into PKCS#12 (.p12)** format for signing

Example output files for "Test Signer":
- `test_signer_key.pem` - Private key (keep secure!)
- `test_signer_cert.pem` - Public certificate
- `test_signer.p12` - Combined bundle for signing

### Verifying Signatures

After signing, verify with:

```bash
./sign.sh verify decision_document_signed.pdf
```

Example output:
```
Digital Signature Info of: decision_document_signed.pdf
Signature #1:
  - Signer Certificate Common Name: Claude Code Agent
  - Signer full Distinguished Name: CN=Claude Code Agent,OU=commit:1376440,O=AI Agent,C=US
  - Signing Time: Jan 13 2026 22:06:48
  - Signing Hash Algorithm: SHA-256
  - Signature Type: adbe.pkcs7.detached
  - Signature Validation: Signature is Valid.
  - Certificate Validation: Certificate issuer is unknown.
```

The `OU=commit:<hash>` field links the signature to the specific git commit, providing cryptographic traceability.

The "Certificate issuer is unknown" warning is expected for self-signed certificates. For production use, obtain certificates from a trusted Certificate Authority (CA) or use PIV/CAC smart cards.

### Security Notes

- **Private keys** (`.pem`, `.p12`) are excluded from git via `.gitignore`
- **Never commit** private keys or certificates to version control
- **Self-signed certificates** are for testing only - they won't be trusted by default
- **Production signing** should use CA-issued certificates or government-issued smart cards (PIV/CAC)

## Usage Tips

1. **Decision Memorandum**: Best for straightforward decisions that need formal documentation but don't require extensive detail
2. **Comprehensive Template**: Use when decisions require full traceability, risk assessment, and multiple stakeholder agreements
3. **Signatures**: Obtain all required signatures before distribution
4. **Version Control**: Update the revision history table with each document change
5. **Traceability**: Reference related documents by their formal document numbers

## License

This template is provided for government and public use.
