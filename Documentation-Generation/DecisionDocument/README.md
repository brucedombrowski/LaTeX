# Program Decision Document

LaTeX template for comprehensive, multi-page program decision documentation.

**For single-page Decision Memorandums, see:** [../DecisionMemorandum/](../DecisionMemorandum/)

## Target Environment

**Airgapped Windows 11** with security hardening. Recommended baselines:

| Baseline | Source | VM Available |
|----------|--------|--------------|
| CIS Windows 11 Enterprise | [CIS Benchmarks](https://www.cisecurity.org/benchmark/microsoft_windows_desktop) | CIS Hardened Images |
| DISA STIG Windows 11 | [DoD Cyber Exchange](https://public.cyber.mil/stigs/) | [DISA STIG VMs](https://public.cyber.mil/stigs/supplemental-automation-content/) |
| Microsoft Security Baseline | [Security Compliance Toolkit](https://www.microsoft.com/en-us/download/details.aspx?id=55319) | Windows 11 Enterprise Evaluation |

For development/testing, Microsoft provides free evaluation VMs:
- [Windows 11 Development Environment](https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/)

## Quick Start (Windows)

### Prerequisites

Before using on an airgapped system, download and transfer via approved media:

1. **MiKTeX** - LaTeX distribution (required to build PDFs)
   - Download from: https://miktex.org/download
   - Choose "Basic MiKTeX Installer" (~250MB)
   - Install with default options

### Build a PDF

1. Edit `decision_document.tex` with any text editor (Notepad, VS Code, etc.)

2. Double-click `build.bat` to compile the PDF

3. Output: `decision_document.pdf`

### Sign a PDF

1. Double-click `sign.bat`
2. Select the PDF to sign
3. Choose your certificate (PIV/CAC smart card or software cert)
4. Enter PIN when prompted

Output: `<filename>_signed.pdf`

---

## Template

| Template | Description |
|----------|-------------|
| `decision_document.tex` | Comprehensive multi-page decision document |

## Files

```
DecisionDocument/
├── decision_document.tex   # Comprehensive template
├── logo.png                # Symlink to ../../assets/logo.png
├── build.bat               # Build script (Windows)
├── sign.bat                # Sign script (Windows)
├── PdfSigner.exe           # PDF signing tool
├── build.ps1               # Build script (PowerShell)
├── sign.ps1                # Sign script (PowerShell)
├── build.sh                # Build script (macOS/Linux)
├── sign.sh                 # Sign script (macOS/Linux)
└── README.md               # This file
```

## Template Customization

### Decision Document

Edit the variables at the top of `decision_document.tex`:

```latex
\newcommand{\OrganizationName}{Organization Name}
\newcommand{\DocumentTitle}{Program Decision Document}
\newcommand{\DocumentNumber}{PDD-XXXX-XXX}
\newcommand{\ProgramName}{Program Name}
\newcommand{\DecisionTitle}{Decision Title}
```

## Build Options

```batch
:: Build the template
build.bat
```

## Signing Details

### Smart Card (PIV/CAC)

Insert your smart card and run `sign.bat`. The Windows Security PIN dialog will prompt for your PIN automatically.

### Software Certificate

Create a test certificate:
```batch
sign.bat create-cert
```

This generates:
- `<name>_key.pem` - Private key (keep secure)
- `<name>_cert.pem` - Public certificate
- `<name>.p12` - Bundle for signing

### Verify a Signature

```batch
sign.bat verify document_signed.pdf
```

## macOS/Linux Users

```bash
# Make scripts executable
chmod +x build.sh sign.sh

# Build
./build.sh

# Sign
./sign.sh
```

Requirements:
```bash
brew install opensc poppler nss
```

## Troubleshooting

### "pdflatex not found"
MiKTeX is not installed or not in PATH. Install MiKTeX and restart your command prompt.

### Missing LaTeX packages
MiKTeX automatically downloads missing packages on first use. On airgapped systems, pre-install packages using MiKTeX Console before disconnecting from the network.

### "Certificate issuer is unknown"
Expected for self-signed certificates. For production use, obtain certificates from your organization's PKI or use PIV/CAC smart cards.

## License

This template is provided for government and public use.
