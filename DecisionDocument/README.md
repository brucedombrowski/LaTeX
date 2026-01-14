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
├── logo.png                # Header logo (orbit-styled "Logo")
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

Replace `logo.png` with your organization's logo. The logo should be approximately 1 inch tall for optimal header display.

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

**Example output (human signer):**
```
Digital Signature Info of: decision_document_signed.pdf
Signature #1:
  - Signer Certificate Common Name: Test Signer
  - Signer full Distinguished Name: CN=Test Signer,O=Test Organization,C=US
  - Signing Time: Jan 13 2026 22:40:00
  - Signing Hash Algorithm: SHA-256
  - Signature Type: adbe.pkcs7.detached
  - Signature Validation: Signature is Valid.
  - Certificate Validation: Certificate issuer is unknown.
```

**Example output (AI agent signer):**
```
Digital Signature Info of: decision_document_signed.pdf
Signature #1:
  - Signer Certificate Common Name: decision_document.tex
  - Signer full Distinguished Name: CN=decision_document.tex,OU=sha256:2479bac33557,O=AI Agent,C=US
  - Signing Time: Jan 13 2026 22:35:00
  - Signing Hash Algorithm: SHA-256
  - Signature Type: adbe.pkcs7.detached
  - Signature Validation: Signature is Valid.
  - Certificate Validation: Certificate issuer is unknown.
```

For AI agent signatures, the certificate provides source traceability:
- **CN** (Common Name): The source `.tex` filename that generated the PDF
- **OU** (Organizational Unit): `sha256:<hash>` - first 12 characters of the source file's SHA-256 hash

To verify an AI-signed PDF was generated from a specific `.tex` file:
```bash
# Get hash from signature
./sign.sh verify decision_document_signed.pdf | grep "OU=sha256"

# Compare with current source file
shasum -a 256 decision_document.tex | cut -c1-12
```

If the hashes match, the PDF was generated from that exact source.

The "Certificate issuer is unknown" warning is expected for self-signed certificates. For production use, obtain certificates from a trusted Certificate Authority (CA) or use PIV/CAC smart cards.

### Security Notes

- **Private keys** (`.pem`, `.p12`) are excluded from git via `.gitignore`
- **Never commit** private keys or certificates to version control
- **Self-signed certificates** are for testing only - they won't be trusted by default
- **Production signing** should use CA-issued certificates or government-issued smart cards (PIV/CAC)

## Secure Document Development

When creating documents containing sensitive information (CUI, PII, proprietary data, ITAR, etc.), follow these practices to prevent accidental disclosure.

### Getting Started: Fork First

**Always start by forking this template repository.** This creates your own copy that you fully control.

1. Click **Fork** on GitHub (or your Git hosting platform)
2. Clone your fork (not the original):
   ```bash
   git clone https://github.com/YOUR-USERNAME/LaTeX.git
   cd LaTeX/DecisionDocument
   ```
3. Your fork is now your working repository

This keeps the original template clean and gives you full control over your copy.

### Option 1: Local-Only Development (Recommended for Sensitive Data)

After forking, disconnect from all remotes for air-tight security:

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/LaTeX.git
cd LaTeX/DecisionDocument

# Remove remote connection to prevent accidental push
git remote remove origin

# Verify no remotes exist
git remote -v
# (should show nothing)

# Continue with local-only version control
git add .
git commit -m "Initial document draft"
```

Your document history stays entirely local. No risk of pushing anywhere.

### Option 2: Private Fork

For team collaboration on sensitive documents, fork to a private repository:

```bash
# Fork to your organization's private GitHub/GitLab
# Then clone the private fork
git clone https://github.com/YOUR-ORG/private-decisions.git
cd private-decisions/DecisionDocument
```

Or convert your fork to private after cloning:
```bash
# Clone your public fork first
git clone https://github.com/YOUR-USERNAME/LaTeX.git
cd LaTeX

# Change remote to your private repository
git remote set-url origin git@your-private-server:decisions.git

# Push to establish the private copy
git push -u origin main
```

Ensure your private repository has appropriate access controls.

### Option 3: No Version Control

For maximum isolation, work without git entirely:

```bash
# Download as ZIP (no git history)
# From GitHub: Code → Download ZIP

# Or clone and remove git
git clone https://github.com/YOUR-USERNAME/LaTeX.git
cd LaTeX
rm -rf .git

# No version control - just edit files directly
```

### Sensitive Data Checklist

Before committing or sharing any document:

- [ ] **CUI**: Controlled Unclassified Information requires proper handling per 32 CFR Part 2002
- [ ] **PII**: Remove or redact personally identifiable information
- [ ] **Proprietary**: Ensure trade secrets and proprietary data are protected
- [ ] **ITAR/EAR**: Export-controlled data requires authorized access
- [ ] **FOUO**: For Official Use Only documents need appropriate distribution
- [ ] **Attorney-Client**: Privileged communications require protection

### Additional Safeguards

1. **Work offline**: Disable network when editing sensitive documents
2. **Encrypted storage**: Use FileVault (macOS) or BitLocker (Windows)
3. **Secure deletion**: Use `srm` or secure empty trash for drafts
4. **Air-gapped systems**: For classified or highly sensitive work
5. **Access controls**: Restrict file permissions (`chmod 600 document.tex`)

### Classification Markings

Add classification banners to your documents by editing the header/footer in the `.tex` file:

```latex
% In the fancyhdr setup section, add:
\lhead{\textcolor{red}{\textbf{CUI // SP-PRVCY}}}
\rhead{\textcolor{red}{\textbf{CUI // SP-PRVCY}}}
```

Common CUI categories: `SP-PRVCY` (Privacy), `SP-PROPIN` (Proprietary), `SP-EXPT` (Export Controlled)

### Working Across Boundaries

When collaborating across organizational, classification, or network boundaries:

**Cross-Domain Considerations:**
- Never transfer files directly between classified and unclassified systems
- Use approved cross-domain solutions (CDS) when authorized
- Sanitize documents before moving to lower classification levels
- Maintain separate working copies for each domain

**Multi-Organization Collaboration:**
```bash
# Create separate branches for different stakeholders
git checkout -b partner-review

# Share only approved content
git archive --format=zip HEAD:DecisionDocument -o approved_release.zip

# Or export specific files without git history
cp decision_document.pdf /path/to/shared/location/
```

**Template vs. Content Separation:**
- Keep the template repository public (no sensitive data)
- Keep document content in separate, controlled repositories
- Use the template as a starting point, not a working repository

**Air-Gap Workflows:**
```bash
# On connected system: export template
git archive --format=zip HEAD -o template.zip

# Transfer via approved removable media to air-gapped system
# On air-gapped system:
unzip template.zip -d my-document
cd my-document/DecisionDocument
# Edit documents locally, never connect to network
```

**Redaction Before Release:**
1. Create a copy of the document for release
2. Remove or redact sensitive sections
3. Rebuild PDF from redacted `.tex` source
4. Verify no metadata leakage (`pdfinfo`, `exiftool`)
5. Document the redaction in revision history

### Email and File Transfer

Let's be realistic: at some point, a PDF is getting emailed.

**Before Emailing Any Document:**
1. Verify recipient is authorized to receive the content
2. Confirm you're using an approved email system for the classification level
3. Check that attachments don't exceed size limits (encrypt large files separately)

**Email Encryption Options:**

| Method | Use Case | Setup |
|--------|----------|-------|
| S/MIME | Org-to-org with PKI | Requires certificates from both parties |
| PGP/GPG | Technical recipients | `gpg --encrypt --recipient user@example.com document.pdf` |
| Password-protected ZIP | Quick sharing | `zip -e secure.zip document.pdf` (share password separately) |
| Encrypted PDF | Built-in protection | Use `qpdf` or Adobe to add password |

**Password-Protect a PDF:**
```bash
# Using qpdf (brew install qpdf)
qpdf --encrypt userpass ownerpass 256 -- input.pdf protected.pdf

# Using pdftk (brew install pdftk-java)
pdftk input.pdf output protected.pdf user_pw PASSWORD
```

**For CUI via Email:**
- Use organization-approved encrypted email (Microsoft 365 Message Encryption, Virtru, etc.)
- Include CUI marking in subject line: `[CUI] Decision Document for Review`
- Add distribution statement in email body
- Request read receipt for accountability

**Secure File Transfer Alternatives:**
- DoD SAFE (Secure Access File Exchange)
- Organization SharePoint/OneDrive with appropriate permissions
- SFTP to controlled servers
- Encrypted USB via approved courier

**What NOT to Do:**
- Never email classified information on unclassified systems
- Don't use personal email for official documents
- Avoid cloud storage (Dropbox, Google Drive) for sensitive data unless approved
- Don't send passwords in the same email as encrypted files

**Metadata Scrubbing Before Send:**
```bash
# Check what metadata exists
pdfinfo document.pdf
exiftool document.pdf

# Remove metadata with exiftool
exiftool -all= document.pdf

# Or use qpdf to linearize (removes some metadata)
qpdf --linearize input.pdf clean.pdf
```

## Usage Tips

1. **Decision Memorandum**: Best for straightforward decisions that need formal documentation but don't require extensive detail
2. **Comprehensive Template**: Use when decisions require full traceability, risk assessment, and multiple stakeholder agreements
3. **Signatures**: Obtain all required signatures before distribution
4. **Version Control**: Update the revision history table with each document change
5. **Traceability**: Reference related documents by their formal document numbers

## License

This template is provided for government and public use.
