# Binaries

Place executable binaries in this folder. These are not tracked in git.

## Required Binaries

| Binary | Description | Download |
|--------|-------------|----------|
| `PdfSigner.exe` | PDF digital signing tool for Windows | [PDFSigner releases](https://github.com/brucedombrowski/PDFSigner/releases) |

## Installation

1. Download the binary from the link above
2. Place it in this `.bin/` folder
3. The signing scripts will automatically find it here

## Usage

The signing scripts (`.scripts/sign-pdf.*`) reference binaries in this folder.
Symlinks in `Documentation-Generation/DecisionDocument/` and `DecisionMemorandum/`
point here for convenience.
