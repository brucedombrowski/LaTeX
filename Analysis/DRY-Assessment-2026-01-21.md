# DRY (Don't Repeat Yourself) Assessment

**Assessment ID:** ASSESS-2026-001
**Date:** January 21, 2026
**Scope:** LaTeX Toolkit Repository
**Overall Score:** 7/10

---

## Executive Summary

The LaTeX Toolkit repository demonstrates **strong DRY practices overall**, with excellent template patterns in SF901 cover sheets and the attestation system. However, there are opportunities for improvement in decision memoranda and meeting agenda documents, which currently duplicate significant preamble code.

**Key Findings:**
- ~440 lines of duplicated code identified
- 89% reduction achievable with recommended improvements
- Two document families need refactoring to match SF901 pattern

---

## What Follows DRY Principles Well

### 1. SF901 Cover Sheet System (Excellent)

```
Compliance-Marking/CUI/
├── SF901-template.tex          # Shared base template (~150 lines)
└── Examples/
    ├── SF901_BASIC.tex         # Thin wrapper (~26 lines)
    ├── SF901_PROCURE.tex       # Thin wrapper (~26 lines)
    ├── SF901_PRVCY.tex         # Thin wrapper (~26 lines)
    └── SF901_CTI.tex           # Thin wrapper (~26 lines)
```

- Each example defines only `\cuicategories` and calls `\input{../SF901-template.tex}`
- **86% code reuse** between examples
- Format changes auto-apply to all variants

### 2. Attestation System (Excellent)

```
Documentation-Generation/Attestations/
├── templates/
│   └── attestation-template.tex    # Shared core
└── examples/
    └── software_attestation.tex    # Thin wrapper with variables
```

- Clean separation of structure (template) from content (wrapper)
- Variable substitution via sed in generate-attestation.sh
- Easy to create new attestation types

### 3. Build Script Functions (Good)

- `release.sh` uses reusable functions: `build_tex()`, `build_tex_inplace()`
- Functions are single-purpose and composable
- `check_pdfsigner_update()` is a clean utility function

### 4. Package Management (Excellent)

- Each file imports only necessary packages
- No bloated preambles with unused packages
- Common packages (geometry, xcolor, fancyhdr) appropriately shared

---

## What Violates DRY Principles

### 1. Decision Memoranda (High Priority)

**Problem:** 4 decision documents duplicate ~70 lines of identical preamble each.

| File | Total Lines | Duplicated Lines |
|------|-------------|------------------|
| decision_memo.tex (template) | 137 | - |
| dm_sf901_decision.tex | 183 | ~70 |
| DM-2026-002_sf901_font_decision.tex | 206 | ~70 |
| DM-2026-003_sf901_tikz_layout.tex | 226 | ~70 |

**Duplicated Content:**
- Document class and geometry settings
- Package imports (graphicx, fancyhdr, lastpage, enumitem, xcolor, hyperref)
- Header/footer configuration
- List formatting settings
- Custom commands

**Impact:** ~280 lines of redundant code

**Recommendation:** Convert decision documents to thin wrappers like SF901 examples:
```latex
% DM-2026-002.tex - Thin wrapper
\newcommand{\dmNumber}{DM-2026-002}
\newcommand{\dmTitle}{SF901 Font Decision}
\newcommand{\dmDate}{January 15, 2026}
\newcommand{\dmContent}{...}
\input{../Documentation-Generation/DecisionMemorandum/templates/decision_memo.tex}
```

### 2. Meeting Agenda Examples (High Priority)

**Problem:** `project_kickoff.tex` and `requirements_review.tex` are full documents, not thin wrappers.

**Current State:**
- Each example duplicates 100% of the template preamble
- Only meeting content (agenda items, attendees) differs
- Inconsistent with SF901/attestation pattern

**Impact:** ~110 lines of redundant code

**Recommendation:** Refactor to thin wrapper pattern:
```latex
% project_kickoff.tex - Should be thin wrapper
\newcommand{\meetingTitle}{Project Kickoff}
\newcommand{\meetingDate}{January 21, 2026}
\newcommand{\meetingAgendaItems}{...}
\input{../templates/meeting_agenda_base.tex}
```

### 3. Shell Script Boilerplate (Medium Priority)

**Problem:** Color definitions and utility patterns repeated in 5 scripts.

**Duplicated Across Scripts:**
```bash
# Repeated in: build-tex.sh, merge-pdf.sh, sign-pdf.sh, release.sh, generate-attestation.sh
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
```

**Impact:** ~50 lines of redundant code

**Recommendation:** Create `/.scripts/lib/common.sh`:
```bash
#!/bin/bash
# Common utilities for LaTeX Toolkit scripts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get repository root
get_repo_root() {
    dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# Cleanup LaTeX auxiliary files
cleanup_aux_files() {
    local dir="${1:-.}"
    rm -f "$dir"/*.aux "$dir"/*.log "$dir"/*.out "$dir"/*.toc
}
```

### 4. Compiler Detection in release.sh (Low Priority)

**Problem:** Same logic duplicated in `build_tex()` and `build_tex_inplace()`.

```bash
# Repeated in two functions (lines 113-118 and 154-161)
if grep -q '\\usepackage{fontspec}' "$tex_file" 2>/dev/null || \
   grep -q 'SF901-template' "$tex_file" 2>/dev/null; then
    COMPILER="xelatex"
else
    COMPILER="pdflatex"
fi
```

**Impact:** 8 lines duplicated

**Recommendation:** Extract to function:
```bash
determine_compiler() {
    local tex_file="$1"
    if grep -q '\\usepackage{fontspec}' "$tex_file" 2>/dev/null || \
       grep -q 'SF901-template' "$tex_file" 2>/dev/null; then
        echo "xelatex"
    else
        echo "pdflatex"
    fi
}
```

---

## Quantified Impact

| Category | Current Duplication | After Fix | Reduction |
|----------|---------------------|-----------|-----------|
| Decision Memos | 280 lines | 40 lines | 86% |
| Meeting Agendas | 110 lines | 20 lines | 82% |
| Shell Scripts | 50 lines | 10 lines | 80% |
| **Total** | **440 lines** | **70 lines** | **84%** |

---

## Recommendations Summary

### Priority 1: High Impact (Recommended Now)

| Item | Effort | Impact | Files Affected |
|------|--------|--------|----------------|
| Decision Memo refactor | 30 min | 280 lines | 4 files |
| Meeting Agenda refactor | 20 min | 110 lines | 3 files |

### Priority 2: Medium Impact (Recommended Soon)

| Item | Effort | Impact | Files Affected |
|------|--------|--------|----------------|
| Shell script common.sh | 45 min | 50 lines | 5 files |
| Color naming unification | 5 min | Consistency | 2 files |

### Priority 3: Low Impact (Nice to Have)

| Item | Effort | Impact | Files Affected |
|------|--------|--------|----------------|
| Compiler detection function | 10 min | 8 lines | 1 file |
| DRY pattern documentation | 20 min | Prevention | README |

---

## Compliance by Component

| Component | DRY Score | Status |
|-----------|-----------|--------|
| SF901 Cover Sheets | 10/10 | Excellent |
| Attestations | 10/10 | Excellent |
| Build Scripts | 7/10 | Good |
| Decision Memos | 4/10 | Needs Work |
| Meeting Agendas | 4/10 | Needs Work |
| Package Management | 9/10 | Excellent |

---

## Conclusion

The repository has a solid foundation with excellent DRY patterns in specialized systems (SF901, attestations). The main opportunities for improvement are:

1. **Decision Memoranda** - Should adopt the thin wrapper pattern
2. **Meeting Agendas** - Examples should be wrappers, not full documents
3. **Shell Scripts** - Common utilities should be extracted

Implementing Priority 1 recommendations would reduce code duplication by 390 lines (89%) and establish consistent patterns across all document types.

---

*Assessment generated by Claude Code*
*LaTeX Toolkit v0.1-17-ga407366*
