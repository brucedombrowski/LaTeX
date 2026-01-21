# AGENTS.md

Instructions for AI agents working with this component.

## Project Overview

This component (`Documentation-Generation/DecisionMemorandum/`) provides the LaTeX template for single-page Decision Memorandums - brief, formal records of program decisions.

**Parent repository:** See [../../AGENTS.md](../../AGENTS.md) for repository-wide instructions.

**Related components:**
- `../DecisionDocument/` - Multi-page Program Decision Document template
- `../../Decisions/` - Where generated decision memorandums are stored
- `../../assets/` - Shared logos (symlinked here as `logo.png`, `logo.svg`)
- `../../Compliance-Marking/AGENTS.md` - Decision Memorandum Index and requirements

## Target Environment

**Airgapped Windows 11** with security hardening:
- CIS Windows 11 Enterprise baseline
- DISA STIG Windows 11 baseline
- Microsoft Security Baseline

Also supports macOS/Linux for development.

## Template

| File | Description |
|------|-------------|
| `decision_memo.tex` | Single-page Decision Memorandum for brief decisions |

## Build Instructions

```bash
# Build from repository root using centralized script
./scripts/build.sh Documentation-Generation/DecisionMemorandum/decision_memo.tex

# Or build all documents
./scripts/release.sh
```

The build script:
- Runs pdflatex 3 times (for references)
- Automatically cleans up auxiliary files

## Signing

Signing tools are symlinked from `../DecisionDocument/`:
- `sign.sh` / `sign.bat` / `sign.ps1`
- `PdfSigner.exe`

See [../DecisionDocument/AGENTS.md](../DecisionDocument/AGENTS.md) for full signing workflow.

## File Structure

```
DecisionMemorandum/
├── decision_memo.tex             # Decision Memorandum template
├── logo.png -> ../../assets/logo.png  # Symlink to shared logo
├── logo.svg -> ../../assets/logo.svg  # Symlink to shared logo source
├── sign.sh -> ../DecisionDocument/sign.sh      # Symlink to signing script
├── sign.bat -> ../DecisionDocument/sign.bat    # Symlink to signing script
├── sign.ps1 -> ../DecisionDocument/sign.ps1    # Symlink to signing script
├── PdfSigner.exe -> ../DecisionDocument/PdfSigner.exe  # Symlink to signing tool
└── AGENTS.md                     # This file
```

**Note:** Build scripts are centralized in `scripts/` at repository root.

## Code Style Guidelines

See [../DecisionDocument/AGENTS.md](../DecisionDocument/AGENTS.md) for LaTeX conventions, placeholder text guidelines, and date format standards.

## Decision Memorandum ID Format

- `DM-YYYY-NNN` where:
  - `YYYY` = 4-digit year (e.g., 2026)
  - `NNN` = 3-digit sequential number (e.g., 001)
- Example: `DM-2026-004`

Check [../../Compliance-Marking/AGENTS.md](../../Compliance-Marking/AGENTS.md) for the Decision Memorandum Index to determine the next available ID.
